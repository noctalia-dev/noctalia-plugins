import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI

Item {
    id: root

    property var pluginApi: null

    readonly property bool debugMode: Quickshell.env("NOCTALIA_DEBUG") === "1"

    function logDebug(msg) {
        if (root.debugMode) Logger.d("GitHubFeed", msg)
    }

    property var rawEvents: []
    readonly property var events: filterEvents(rawEvents)

    property var followingList: []
    property bool isLoading: false
    property bool hasError: false
    property string errorMessage: ""
    property int lastFetchTimestamp: 0

    readonly property string username: pluginApi?.pluginSettings?.username || ""
    readonly property string token: pluginApi?.pluginSettings?.token || ""
    readonly property int refreshInterval: pluginApi?.pluginSettings?.refreshInterval || 1800
    readonly property int maxEvents: pluginApi?.pluginSettings?.maxEvents || 50

    readonly property int batchSize: 8
    readonly property int parallelCount: 6
    readonly property int maxRetries: 3
    readonly property int maxStarsPerUser: 3
    readonly property int maxReposPerUser: 2
    readonly property int maxForksPerUser: 2
    readonly property int maxPRsPerUser: 2

    readonly property bool showStars: pluginApi?.pluginSettings?.showStars ?? true
    readonly property bool showForks: pluginApi?.pluginSettings?.showForks ?? true
    readonly property bool showPRs: pluginApi?.pluginSettings?.showPRs ?? true
    readonly property bool showRepoCreations: pluginApi?.pluginSettings?.showRepoCreations ?? true
    readonly property bool showMyRepoStars: pluginApi?.pluginSettings?.showMyRepoStars ?? true
    readonly property bool showMyRepoForks: pluginApi?.pluginSettings?.showMyRepoForks ?? true

    readonly property string cacheDir: pluginApi?.pluginDir ? pluginApi.pluginDir + "/cache" : ""
    readonly property string eventsCachePath: cacheDir + "/events.json"
    readonly property string avatarsDir: cacheDir + "/avatars"

    property var collectedEvents: []
    property var availableAvatars: ({})

    property var userBatches: []
    property var batchQueue: []
    property int completedBatches: 0
    property int totalBatches: 0
    property int totalGraphQLCost: 0
    property double fetchStartTime: 0

    function filterEvents(rawList) {
        if (!rawList || rawList.length === 0) return []

        var now = Date.now()
        var sevenDaysAgo = now - (7 * 24 * 60 * 60 * 1000)

        var filtered = rawList.filter(function(event) {
            var eventDate = new Date(event.created_at).getTime()
            if (eventDate < sevenDaysAgo) return false

            if (event.isMyRepoEvent) {
                if (event.type === "WatchEvent") return root.showMyRepoStars
                if (event.type === "ForkEvent") return root.showMyRepoForks
                return true
            }

            switch (event.type) {
                case "WatchEvent":
                    return root.showStars
                case "ForkEvent":
                    return root.showForks
                case "PullRequestEvent":
                    return root.showPRs
                case "CreateEvent":
                    return root.showRepoCreations
                default:
                    return true
            }
        })

        return filtered.slice(0, root.maxEvents)
    }

    FileView {
        id: eventsCacheFile
        path: root.eventsCachePath
        watchChanges: false

        onLoaded: {
            logDebug("Cache loaded from disk")
            loadFromCache()
        }

        onLoadFailed: function(error) {
            logDebug("No cache file found, will fetch fresh data")
            if (root.username && root.token) {
                fetchFromGitHub()
            }
        }
    }

    function loadFromCache() {
        try {
            var content = eventsCacheFile.text()
            if (!content || content.trim() === "") {
                if (root.username && root.token) fetchFromGitHub()
                return
            }

            var cached = JSON.parse(content)
            if (!cached || !cached.events) {
                if (root.username && root.token) fetchFromGitHub()
                return
            }

            root.lastFetchTimestamp = cached.timestamp || 0
            root.followingList = cached.following || []
            var now = Math.floor(Date.now() / 1000)
            var age = now - root.lastFetchTimestamp

            if (age < root.refreshInterval) {
                root.rawEvents = cached.events
                Logger.i("GitHubFeed", "Using cached data (" + cached.events.length + " events), age: " + Math.floor(age / 60) + " min")
            } else {
                Logger.i("GitHubFeed", "Cache expired, fetching fresh data")
                if (root.username && root.token) fetchFromGitHub()
            }
        } catch (e) {
            Logger.e("GitHubFeed", "Failed to parse cache: " + e)
            if (root.username && root.token) fetchFromGitHub()
        }
    }

    function saveToCache() {
        if (!root.cacheDir) return

        try {
            var cacheData = {
                events: root.rawEvents,
                following: root.followingList,
                timestamp: Math.floor(Date.now() / 1000)
            }
            eventsCacheFile.setText(JSON.stringify(cacheData, null, 2))
            logDebug("Cache saved with " + root.rawEvents.length + " events")
        } catch (e) {
            Logger.e("GitHubFeed", "Failed to save cache: " + e)
        }
    }

    property int followingPage: 1
    property var allFollowingUsers: []

    Process {
        id: followingProcess

        property int page: 1

        command: root.username && root.token ? [
            "curl", "-s", "--max-time", "30",
            "-H", "Authorization: Bearer " + root.token,
            "-H", "Accept: application/vnd.github.v3+json",
            "https://api.github.com/users/" + root.username + "/following?per_page=100&page=" + page
        ] : ["echo", "[]"]

        stdout: StdioCollector {
            onStreamFinished: {
                handleFollowingResponse(this.text)
            }
        }

        stderr: StdioCollector {}
    }

    function handleFollowingResponse(responseText) {
        try {
            var users = JSON.parse(responseText)

            if (!Array.isArray(users)) {
                if (users.message) {
                    Logger.e("GitHubFeed", "Following API error: " + users.message)
                    root.hasError = true
                    root.errorMessage = users.message
                }
                finishFollowingFetch()
                return
            }

            users.forEach(function(u) {
                if (u && u.login) {
                    root.allFollowingUsers.push(u.login)
                }
            })

            if (users.length === 100) {
                followingProcess.page++
                logDebug("Fetching following page " + followingProcess.page + " (got " + root.allFollowingUsers.length + " so far)")
                followingProcess.running = true
            } else {
                finishFollowingFetch()
            }

        } catch (e) {
            Logger.e("GitHubFeed", "Failed to parse following response: " + e)
            finishFollowingFetch()
        }
    }

    function finishFollowingFetch() {
        root.followingList = root.allFollowingUsers
        Logger.i("GitHubFeed", "Following " + root.followingList.length + " users")

        if (root.followingList.length === 0) {
            Logger.w("GitHubFeed", "No following users found")
            fetchMyRepoEvents()
            return
        }

        root.userBatches = []
        for (var i = 0; i < root.followingList.length; i += root.batchSize) {
            root.userBatches.push(root.followingList.slice(i, i + root.batchSize))
        }

        root.totalBatches = root.userBatches.length
        root.completedBatches = 0
        root.collectedEvents = []
        root.totalGraphQLCost = 0
        root.fetchStartTime = Date.now()

        root.batchQueue = []
        for (var j = 0; j < root.totalBatches; j++) {
            root.batchQueue.push({ index: j, retryCount: 0 })
        }

        Logger.i("GitHubFeed", "Starting parallel fetch: " + root.totalBatches + " batches, " + root.parallelCount + " parallel")

        startParallelFetches()
    }

    function startParallelFetches() {
        var workers = [worker0, worker1, worker2, worker3, worker4, worker5]
        for (var i = 0; i < root.parallelCount; i++) {
            assignNextBatch(workers[i])
        }
    }

    function assignNextBatch(worker) {
        if (root.batchQueue.length === 0) {
            checkAllBatchesComplete()
            return
        }

        var batchInfo = root.batchQueue.shift()
        var batch = root.userBatches[batchInfo.index]

        worker.batchIndex = batchInfo.index
        worker.retryCount = batchInfo.retryCount
        worker.command = buildBatchCommand(batch)
        worker.running = true
    }

    function buildBatchCommand(batch) {
        var query = "query {"

        for (var i = 0; i < batch.length; i++) {
            var user = batch[i]
            query += " u" + i + ": user(login: \"" + user + "\") {"
            query += " login avatarUrl"
            query += " starredRepositories(first: " + root.maxStarsPerUser + ", orderBy: {field: STARRED_AT, direction: DESC}) {"
            query += " nodes { nameWithOwner description }"
            query += " edges { starredAt }"
            query += " }"
            query += " repositories(first: " + root.maxReposPerUser + ", orderBy: {field: CREATED_AT, direction: DESC}, isFork: false, privacy: PUBLIC) {"
            query += " nodes { nameWithOwner createdAt description }"
            query += " }"
            query += " forkedRepos: repositories(first: " + root.maxForksPerUser + ", orderBy: {field: CREATED_AT, direction: DESC}, isFork: true, privacy: PUBLIC) {"
            query += " nodes { nameWithOwner createdAt description parent { nameWithOwner } }"
            query += " }"
            query += " pullRequests(first: " + root.maxPRsPerUser + ", orderBy: {field: CREATED_AT, direction: DESC}, states: [OPEN, MERGED]) {"
            query += " nodes { title createdAt state repository { nameWithOwner } }"
            query += " }"
            query += " }"
        }

        query += " rateLimit { cost remaining } }"

        var payload = JSON.stringify({ query: query })

        return [
            "curl", "-s", "--max-time", "20",
            "-X", "POST",
            "https://api.github.com/graphql",
            "-H", "Authorization: Bearer " + root.token,
            "-H", "Content-Type: application/json",
            "-d", payload
        ]
    }

    function handleWorkerResponse(worker, responseText) {
        var batchIndex = worker.batchIndex
        var retryCount = worker.retryCount

        var success = false
        var shouldRetry = false

        try {
            if (!responseText || responseText.trim() === "") {
                Logger.w("GitHubFeed", "Batch " + (batchIndex + 1) + " empty response")
                shouldRetry = true
            } else if (!responseText.trim().startsWith("{")) {
                Logger.w("GitHubFeed", "Batch " + (batchIndex + 1) + " non-JSON response")
                shouldRetry = true
            } else {
                var result = JSON.parse(responseText)

                if (result.data && result.data.rateLimit) {
                    root.totalGraphQLCost += result.data.rateLimit.cost || 0
                }

                if (!result.data) {
                    Logger.w("GitHubFeed", "Batch " + (batchIndex + 1) + " no data field")
                    shouldRetry = true
                } else {
                    processBatchData(result.data)
                    success = true
                    root.completedBatches++

                    var progress = Math.min(root.completedBatches * root.batchSize, root.followingList.length)
                    logDebug("Batch " + (batchIndex + 1) + "/" + root.totalBatches +
                        " done: " + progress + "/" + root.followingList.length + " users, events=" + root.collectedEvents.length)
                }
            }
        } catch (e) {
            Logger.e("GitHubFeed", "Batch " + (batchIndex + 1) + " parse error: " + e)
            shouldRetry = true
        }

        if (shouldRetry && retryCount < root.maxRetries) {
            logDebug("Batch " + (batchIndex + 1) + " retry " + (retryCount + 1) + "/" + root.maxRetries)
            root.batchQueue.push({ index: batchIndex, retryCount: retryCount + 1 })
        } else if (!success) {
            Logger.e("GitHubFeed", "Batch " + (batchIndex + 1) + " failed after " + retryCount + " retries")
            root.completedBatches++
        }

        assignNextBatch(worker)
    }

    function processBatchData(data) {
        var keys = Object.keys(data).filter(function(k) { return k.startsWith("u") })

        keys.forEach(function(key) {
            var userData = data[key]
            if (!userData || !userData.login) return

            var login = userData.login
            var avatarUrl = userData.avatarUrl || ""

            if (userData.starredRepositories && userData.starredRepositories.nodes && userData.starredRepositories.edges) {
                var nodes = userData.starredRepositories.nodes
                var edges = userData.starredRepositories.edges

                for (var i = 0; i < nodes.length && i < edges.length; i++) {
                    if (!nodes[i] || !edges[i] || !edges[i].starredAt) continue

                    root.collectedEvents.push({
                        id: "star_" + login + "_" + nodes[i].nameWithOwner + "_" + edges[i].starredAt,
                        type: "WatchEvent",
                        created_at: edges[i].starredAt,
                        actor: { login: login, avatar_url: avatarUrl },
                        repo: { name: nodes[i].nameWithOwner },
                        isFollowedUserEvent: true,
                        payload: { action: "started" },
                        description: nodes[i].description || ""
                    })
                }
            }

            if (userData.repositories && userData.repositories.nodes) {
                userData.repositories.nodes.forEach(function(repo) {
                    if (!repo || !repo.createdAt || !repo.nameWithOwner) return

                    root.collectedEvents.push({
                        id: "repo_" + login + "_" + repo.nameWithOwner,
                        type: "CreateEvent",
                        created_at: repo.createdAt,
                        actor: { login: login, avatar_url: avatarUrl },
                        repo: { name: repo.nameWithOwner },
                        isFollowedUserEvent: true,
                        payload: { ref_type: "repository" },
                        description: repo.description || ""
                    })
                })
            }

            if (userData.forkedRepos && userData.forkedRepos.nodes) {
                userData.forkedRepos.nodes.forEach(function(repo) {
                    if (!repo || !repo.createdAt || !repo.nameWithOwner) return

                    var parentRepo = repo.parent ? repo.parent.nameWithOwner : ""
                    root.collectedEvents.push({
                        id: "fork_" + login + "_" + repo.nameWithOwner,
                        type: "ForkEvent",
                        created_at: repo.createdAt,
                        actor: { login: login, avatar_url: avatarUrl },
                        repo: { name: parentRepo || repo.nameWithOwner },
                        isFollowedUserEvent: true,
                        payload: { forkee: { full_name: repo.nameWithOwner } },
                        description: repo.description || ""
                    })
                })
            }

            if (userData.pullRequests && userData.pullRequests.nodes) {
                userData.pullRequests.nodes.forEach(function(pr) {
                    if (!pr || !pr.createdAt || !pr.repository) return

                    root.collectedEvents.push({
                        id: "pr_" + login + "_" + pr.repository.nameWithOwner + "_" + pr.createdAt,
                        type: "PullRequestEvent",
                        created_at: pr.createdAt,
                        actor: { login: login, avatar_url: avatarUrl },
                        repo: { name: pr.repository.nameWithOwner },
                        isFollowedUserEvent: true,
                        payload: { action: pr.state === "MERGED" ? "merged" : "opened", pull_request: { title: pr.title } },
                        description: pr.title || ""
                    })
                })
            }
        })
    }

    function checkAllBatchesComplete() {
        if (root.completedBatches >= root.totalBatches && root.batchQueue.length === 0) {
            fetchMyRepoEvents()
        }
    }

    Process {
        id: worker0
        property int batchIndex: -1
        property int retryCount: 0
        stdout: StdioCollector {
            onStreamFinished: { handleWorkerResponse(worker0, this.text) }
        }
        stderr: StdioCollector {}
    }

    Process {
        id: worker1
        property int batchIndex: -1
        property int retryCount: 0
        stdout: StdioCollector {
            onStreamFinished: { handleWorkerResponse(worker1, this.text) }
        }
        stderr: StdioCollector {}
    }

    Process {
        id: worker2
        property int batchIndex: -1
        property int retryCount: 0
        stdout: StdioCollector {
            onStreamFinished: { handleWorkerResponse(worker2, this.text) }
        }
        stderr: StdioCollector {}
    }

    Process {
        id: worker3
        property int batchIndex: -1
        property int retryCount: 0
        stdout: StdioCollector {
            onStreamFinished: { handleWorkerResponse(worker3, this.text) }
        }
        stderr: StdioCollector {}
    }

    Process {
        id: worker4
        property int batchIndex: -1
        property int retryCount: 0
        stdout: StdioCollector {
            onStreamFinished: { handleWorkerResponse(worker4, this.text) }
        }
        stderr: StdioCollector {}
    }

    Process {
        id: worker5
        property int batchIndex: -1
        property int retryCount: 0
        stdout: StdioCollector {
            onStreamFinished: { handleWorkerResponse(worker5, this.text) }
        }
        stderr: StdioCollector {}
    }

    Process {
        id: myReposProcess

        stdout: StdioCollector {
            onStreamFinished: {
                handleMyReposResponse(this.text)
            }
        }

        stderr: StdioCollector {}

        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0) {
                finalizeFetch()
            }
        }
    }

    function fetchMyRepoEvents() {
        if (!root.showMyRepoStars && !root.showMyRepoForks) {
            finalizeFetch()
            return
        }

        logDebug("Fetching stars/forks on your repos")

        var query = "query {"
        query += " user(login: \"" + root.username + "\") {"
        query += " repositories(first: 10, orderBy: {field: STARGAZERS, direction: DESC}, privacy: PUBLIC) {"
        query += " nodes {"
        query += " nameWithOwner"
        query += " stargazers(first: 5, orderBy: {field: STARRED_AT, direction: DESC}) {"
        query += " edges { starredAt node { login avatarUrl } }"
        query += " }"
        query += " forks(first: 5, orderBy: {field: CREATED_AT, direction: DESC}) {"
        query += " nodes { owner { login avatarUrl } createdAt }"
        query += " }"
        query += " }"
        query += " }"
        query += " }"
        query += " rateLimit { cost remaining }"
        query += " }"

        var payload = JSON.stringify({ query: query })

        myReposProcess.command = [
            "curl", "-s", "--max-time", "20",
            "-X", "POST",
            "https://api.github.com/graphql",
            "-H", "Authorization: Bearer " + root.token,
            "-H", "Content-Type: application/json",
            "-d", payload
        ]

        myReposProcess.running = true
    }

    function handleMyReposResponse(responseText) {
        try {
            if (!responseText || responseText.trim() === "" || !responseText.trim().startsWith("{")) {
                Logger.w("GitHubFeed", "My repos response invalid")
                finalizeFetch()
                return
            }

            var result = JSON.parse(responseText)

            if (result.data && result.data.rateLimit) {
                root.totalGraphQLCost += result.data.rateLimit.cost || 0
            }

            if (!result.data || !result.data.user || !result.data.user.repositories) {
                Logger.w("GitHubFeed", "No data for your repos")
                finalizeFetch()
                return
            }

            var repos = result.data.user.repositories.nodes || []

            repos.forEach(function(repo) {
                if (!repo || !repo.nameWithOwner) return

                if (repo.stargazers && repo.stargazers.edges) {
                    repo.stargazers.edges.forEach(function(edge) {
                        if (!edge || !edge.node || !edge.starredAt) return
                        if (edge.node.login === root.username) return

                        root.collectedEvents.push({
                            id: "myrepo_star_" + edge.node.login + "_" + repo.nameWithOwner + "_" + edge.starredAt,
                            type: "WatchEvent",
                            created_at: edge.starredAt,
                            actor: { login: edge.node.login, avatar_url: edge.node.avatarUrl || "" },
                            repo: { name: repo.nameWithOwner },
                            isMyRepoEvent: true,
                            payload: { action: "started" },
                            description: ""
                        })
                    })
                }

                if (repo.forks && repo.forks.nodes) {
                    repo.forks.nodes.forEach(function(fork) {
                        if (!fork || !fork.owner || !fork.createdAt) return
                        if (fork.owner.login === root.username) return

                        root.collectedEvents.push({
                            id: "myrepo_fork_" + fork.owner.login + "_" + repo.nameWithOwner + "_" + fork.createdAt,
                            type: "ForkEvent",
                            created_at: fork.createdAt,
                            actor: { login: fork.owner.login, avatar_url: fork.owner.avatarUrl || "" },
                            repo: { name: repo.nameWithOwner },
                            isMyRepoEvent: true,
                            payload: {},
                            description: ""
                        })
                    })
                }
            })

            logDebug("Processed stars/forks on your repos, total events: " + root.collectedEvents.length)

        } catch (e) {
            Logger.e("GitHubFeed", "Failed to parse my repos response: " + e)
        }

        finalizeFetch()
    }

    function fetchFromGitHub() {
        if (!root.username || root.username.trim() === "") {
            Logger.w("GitHubFeed", "No username configured")
            root.hasError = true
            root.errorMessage = "Please configure your GitHub username in settings"
            return
        }

        if (!root.token || root.token.trim() === "") {
            Logger.w("GitHubFeed", "No token configured")
            root.hasError = true
            root.errorMessage = "Please add a GitHub Personal Access Token in settings"
            return
        }

        if (root.isLoading) {
            logDebug("Already fetching, skipping")
            return
        }

        Logger.i("GitHubFeed", "Fetching feed for user: " + root.username)
        root.isLoading = true
        root.hasError = false
        root.errorMessage = ""
        root.collectedEvents = []
        root.allFollowingUsers = []
        root.userBatches = []
        root.batchQueue = []
        root.completedBatches = 0
        root.totalBatches = 0
        root.totalGraphQLCost = 0

        followingProcess.page = 1
        followingProcess.running = true
    }

    function finalizeFetch() {
        root.collectedEvents.sort(function(a, b) {
            var dateA = new Date(a.created_at)
            var dateB = new Date(b.created_at)
            return dateB - dateA
        })

        var seen = {}
        var uniqueEvents = []
        for (var i = 0; i < root.collectedEvents.length; i++) {
            var event = root.collectedEvents[i]
            if (!seen[event.id]) {
                seen[event.id] = true
                uniqueEvents.push(event)
            }
        }

        root.rawEvents = uniqueEvents
        root.lastFetchTimestamp = Math.floor(Date.now() / 1000)
        root.isLoading = false
        root.hasError = false

        var byType = {}
        uniqueEvents.forEach(function(e) {
            var key = e.isMyRepoEvent ? "MyRepo:" + e.type : e.type
            byType[key] = (byType[key] || 0) + 1
        })

        var totalTime = ((Date.now() - root.fetchStartTime) / 1000).toFixed(1)
        Logger.i("GitHubFeed", "Fetch complete: " + uniqueEvents.length + " events from " +
            root.followingList.length + " users in " + totalTime + "s, GraphQL cost: " + root.totalGraphQLCost)
        logDebug("Events by type: " + JSON.stringify(byType))

        saveToCache()
        downloadAvatars(root.events)
    }

    property var pendingAvatars: []
    property bool isDownloadingAvatar: false

    Process {
        id: avatarDownloadProcess

        property string currentUserId: ""
        property string currentUrl: ""

        stdout: StdioCollector {}
        stderr: StdioCollector {}

        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0) {
                var newAvatars = root.availableAvatars
                newAvatars[currentUserId] = true
                root.availableAvatars = newAvatars
            }
            root.isDownloadingAvatar = false
            downloadNextAvatar()
        }
    }

    function downloadAvatars(events) {
        var seenUsers = {}

        for (var i = 0; i < events.length; i++) {
            var event = events[i]
            if (event.actor && event.actor.login && event.actor.avatar_url) {
                var oderId = event.actor.login
                if (!seenUsers[oderId]) {
                    seenUsers[oderId] = true
                    root.pendingAvatars.push({
                        id: event.actor.login,
                        url: event.actor.avatar_url
                    })
                }
            }
        }

        if (!root.isDownloadingAvatar && root.pendingAvatars.length > 0) {
            downloadNextAvatar()
        }
    }

    function downloadNextAvatar() {
        if (root.pendingAvatars.length === 0) {
            return
        }

        var avatar = root.pendingAvatars.shift()
        var avatarPath = root.avatarsDir + "/" + avatar.id + ".png"

        avatarCheckProcess.avatarId = avatar.id
        avatarCheckProcess.avatarUrl = avatar.url
        avatarCheckProcess.avatarPath = avatarPath
        avatarCheckProcess.command = ["test", "-f", avatarPath]
        avatarCheckProcess.running = true
    }

    Process {
        id: avatarCheckProcess

        property string avatarId: ""
        property string avatarUrl: ""
        property string avatarPath: ""

        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0) {
                var newAvatars = root.availableAvatars
                newAvatars[avatarId] = true
                root.availableAvatars = newAvatars
                downloadNextAvatar()
            } else {
                root.isDownloadingAvatar = true
                avatarDownloadProcess.currentUserId = avatarId
                avatarDownloadProcess.currentUrl = avatarUrl
                avatarDownloadProcess.command = [
                    "curl", "-s", "-L", "--max-time", "10",
                    "-o", avatarPath,
                    avatarUrl + "&s=80"
                ]
                avatarDownloadProcess.running = true
            }
        }
    }

    function getAvatarPath(actorLogin) {
        if (!actorLogin) return ""
        if (!root.availableAvatars[actorLogin]) return ""
        return "file://" + root.avatarsDir + "/" + actorLogin + ".png"
    }

    Timer {
        id: refreshTimer
        interval: root.refreshInterval * 1000
        running: root.username !== "" && root.token !== ""
        repeat: true
        triggeredOnStart: false

        onTriggered: {
            logDebug("Timer triggered, checking if refresh needed")
            var now = Math.floor(Date.now() / 1000)
            var age = now - root.lastFetchTimestamp

            if (age >= root.refreshInterval) {
                fetchFromGitHub()
            }
        }
    }

    IpcHandler {
        target: "plugin:github-feed"

        function refresh() {
            Logger.i("GitHubFeed", "Manual refresh triggered via IPC")
            root.lastFetchTimestamp = 0
            fetchFromGitHub()
            ToastService.showNotice("Refreshing GitHub feed...")
        }

        function toggle() {
            if (pluginApi) {
                pluginApi.withCurrentScreen(function(screen) {
                    pluginApi.openPanel(screen)
                })
            }
        }

        function setUsername(newUsername: string) {
            if (pluginApi && newUsername) {
                pluginApi.pluginSettings.username = newUsername
                pluginApi.saveSettings()
                root.rawEvents = []
                root.followingList = []
                root.lastFetchTimestamp = 0
                fetchFromGitHub()
                ToastService.showNotice("GitHub username updated: " + newUsername)
            }
        }
    }

    Component.onCompleted: {
        Logger.i("GitHubFeed", "Plugin initialized (parallel GraphQL fetching)")

        if (!root.username) {
            Logger.w("GitHubFeed", "No username configured")
            return
        }

        if (!root.token) {
            Logger.w("GitHubFeed", "No token configured")
            return
        }

        ensureCacheDir.running = true
    }

    Process {
        id: ensureCacheDir
        command: ["mkdir", "-p", root.avatarsDir]

        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0) {
                scanAvatarsProcess.running = true
            }
        }
    }

    Process {
        id: scanAvatarsProcess
        command: ["ls", "-1", root.avatarsDir]

        stdout: StdioCollector {
            onStreamFinished: {
                var files = this.text.trim().split("\n")
                var avatars = {}
                for (var i = 0; i < files.length; i++) {
                    var file = files[i]
                    if (file.endsWith(".png")) {
                        var id = file.replace(".png", "")
                        avatars[id] = true
                    }
                }
                root.availableAvatars = avatars
                logDebug("Scanned " + Object.keys(avatars).length + " existing avatars")
                cacheExistsCheck.running = true
            }
        }

        stderr: StdioCollector {}

        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0) {
                cacheExistsCheck.running = true
            }
        }
    }

    Process {
        id: cacheExistsCheck
        command: ["test", "-f", root.eventsCachePath]

        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0) {
                eventsCacheFile.reload()
            } else {
                logDebug("No cache file, fetching fresh data")
                if (root.username && root.token) {
                    fetchFromGitHub()
                }
            }
        }
    }

    onUsernameChanged: {
        if (root.username && root.token) {
            Logger.i("GitHubFeed", "Username changed, fetching new data")
            root.rawEvents = []
            root.followingList = []
            root.lastFetchTimestamp = 0
            fetchFromGitHub()
        }
    }
}
