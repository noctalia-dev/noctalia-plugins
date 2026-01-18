// LRC Lyric Parser
// Parses LRC format lyrics and finds current line based on position

.pragma library

// Parse LRC format lyrics into an array of {time, text} objects
// time is in microseconds (MPRIS position unit)
function parseLyric(lrcText) {
    if (!lrcText || typeof lrcText !== 'string') {
        return [];
    }

    var lines = lrcText.split('\n');
    var result = [];
    // Regex: [mm:ss.xx] or [mm:ss:xx]
    var timeRegex = /\[(\d{1,2}):(\d{1,2})[.:](\d{1,3})\]/g;

    for (var i = 0; i < lines.length; i++) {
        var line = lines[i].trim();
        if (!line) continue;

        var match;
        var times = [];
        var lastIndex = 0;

        // Find all time tags in this line
        while ((match = timeRegex.exec(line)) !== null) {
            var mm = parseInt(match[1], 10);
            var ss = parseInt(match[2], 10);
            var xx = parseInt(match[3], 10);

            // Normalize centiseconds (handle both .xx and .xxx formats)
            if (match[3].length === 3) {
                // milliseconds
                xx = Math.floor(xx / 10);
            }

            // Convert to microseconds (MPRIS uses microseconds)
            var timeUs = ((mm * 60 + ss) * 100 + xx) * 10000;
            times.push(timeUs);
            lastIndex = match.index + match[0].length;
        }

        // Get the lyric text (everything after time tags)
        var text = line.substring(lastIndex).trim();

        // Add entry for each time tag
        for (var j = 0; j < times.length; j++) {
            if (text) {
                result.push({
                    time: times[j],
                    text: text
                });
            }
        }
    }

    // Sort by time
    result.sort(function(a, b) {
        return a.time - b.time;
    });

    return result;
}

// Find current lyric line based on position (in microseconds)
function getCurrentLyric(lyrics, positionUs) {
    if (!lyrics || lyrics.length === 0) {
        return null;
    }

    var current = null;
    for (var i = 0; i < lyrics.length; i++) {
        if (lyrics[i].time <= positionUs) {
            current = lyrics[i];
        } else {
            break;
        }
    }

    return current;
}

// Get current lyric with context (prev, current, next)
function getLyricInfo(lyrics, positionUs) {
    if (!lyrics || lyrics.length === 0) {
        return {
            prev: null,
            current: null,
            next: null,
            progress: 0
        };
    }

    var currentIndex = -1;
    for (var i = 0; i < lyrics.length; i++) {
        if (lyrics[i].time <= positionUs) {
            currentIndex = i;
        } else {
            break;
        }
    }

    var prev = currentIndex > 0 ? lyrics[currentIndex - 1] : null;
    var current = currentIndex >= 0 ? lyrics[currentIndex] : null;
    var next = currentIndex < lyrics.length - 1 ? lyrics[currentIndex + 1] : null;

    // Calculate progress within current line (0-1)
    var progress = 0;
    if (current && next) {
        var duration = next.time - current.time;
        if (duration > 0) {
            progress = (positionUs - current.time) / duration;
            progress = Math.max(0, Math.min(1, progress));
        }
    }

    return {
        prev: prev,
        current: current,
        next: next,
        progress: progress
    };
}

// Split translation from main lyric (if exists)
// Common formats: "main lyric\ntranslation" or "main lyric / translation"
function splitTranslation(text) {
    if (!text) {
        return { main: "", translation: "" };
    }

    // Check for newline separator
    var newlineIndex = text.indexOf('\n');
    if (newlineIndex !== -1) {
        return {
            main: text.substring(0, newlineIndex).trim(),
            translation: text.substring(newlineIndex + 1).trim()
        };
    }

    return {
        main: text.trim(),
        translation: ""
    };
}
