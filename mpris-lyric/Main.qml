import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import "LyricParser.js" as LyricParser

Item {
  id: root

  property var pluginApi: null

  // Lyric state - exposed to BarWidget
  property string currentLyric: ""
  property string currentTranslation: ""
  property double lyricProgress: 0

  // Player state
  property bool isPlaying: false
  property string trackTitle: ""
  property string trackArtist: ""

  // Internal state
  property var parsedLyrics: []
  property string rawLyricText: ""
  property string lastTrackKey: ""

  // Settings
  readonly property string playerName: pluginApi?.pluginSettings?.playerName ||
      pluginApi?.manifest?.metadata?.defaultSettings?.playerName || "musicfox"
  readonly property int updateInterval: pluginApi?.pluginSettings?.updateInterval ||
      pluginApi?.manifest?.metadata?.defaultSettings?.updateInterval || 200

  // Find player by name
  readonly property var targetPlayer: {
    if (!Mpris.players || !Mpris.players.values) return null;
    var players = Mpris.players.values;
    for (var i = 0; i < players.length; i++) {
      var p = players[i];
      var identity = String(p.identity || "").toLowerCase();
      var name = String(p.name || "").toLowerCase();
      if (identity.includes(playerName.toLowerCase()) || name.includes(playerName.toLowerCase())) {
        return p;
      }
    }
    return null;
  }

  // Watch player state
  onTargetPlayerChanged: {
    updatePlayerState();
    updateLyrics();
  }

  // Watch for track changes via Connections
  Connections {
    target: root.targetPlayer
    enabled: root.targetPlayer !== null

    function onTrackTitleChanged() {
      root.forceRefreshLyrics();
    }

    function onTrackArtistChanged() {
      root.forceRefreshLyrics();
    }

    function onPlaybackStateChanged() {
      root.updatePlayerState();
      // Update lyrics when playback state changes (e.g., after seeking)
      root.updateCurrentLyric();
    }

    function onPositionChanged() {
      // Always update on position change (including when seeking/paused)
      root.updateCurrentLyric();
    }

    function onMetadataChanged() {
      // Metadata includes lyrics, force refresh when it changes
      root.forceRefreshLyrics();
    }
  }

  // Delay timer for track change - wait for position to stabilize
  Timer {
    id: trackChangeTimer
    interval: 100
    repeat: false
    onTriggered: {
      root.updateCurrentLyric();
    }
  }

  // Update timer for lyric sync
  Timer {
    id: updateTimer
    interval: root.updateInterval
    repeat: true
    running: root.isPlaying && root.parsedLyrics.length > 0

    onTriggered: {
      updateCurrentLyric();
    }
  }

  // Playback control
  readonly property bool canPlay: targetPlayer ? targetPlayer.canPlay : false
  readonly property bool canPause: targetPlayer ? targetPlayer.canPause : false
  readonly property bool canGoNext: targetPlayer ? targetPlayer.canGoNext : false
  readonly property bool canGoPrevious: targetPlayer ? targetPlayer.canGoPrevious : false

  function playPause() {
    if (!targetPlayer) return;
    if (targetPlayer.playbackState === MprisPlaybackState.Playing) {
      targetPlayer.pause();
    } else {
      targetPlayer.play();
    }
  }

  function next() {
    if (targetPlayer && targetPlayer.canGoNext) {
      targetPlayer.next();
    }
  }

  function previous() {
    if (targetPlayer && targetPlayer.canGoPrevious) {
      targetPlayer.previous();
    }
  }

  // IPC handler
  IpcHandler {
    target: "plugin:mpris-lyric"

    function refresh() {
      root.updateLyrics();
    }

    function setPlayer(name: string) {
      if (pluginApi && name) {
        pluginApi.pluginSettings.playerName = name;
        pluginApi.saveSettings();
      }
    }
  }

  function updatePlayerState() {
    if (!targetPlayer) {
      isPlaying = false;
      trackTitle = "";
      trackArtist = "";
      return;
    }

    isPlaying = targetPlayer.playbackState === MprisPlaybackState.Playing;
    trackTitle = targetPlayer.trackTitle || "";
    trackArtist = targetPlayer.trackArtist || "";
  }

  // Force refresh lyrics - clear cache and reload
  function forceRefreshLyrics() {
    updatePlayerState();

    // Clear the cache to force reload
    lastTrackKey = "";
    rawLyricText = "";
    parsedLyrics = [];
    currentLyric = "";
    currentTranslation = "";

    // Reload lyrics
    updateLyrics();

    // Wait a bit for position to stabilize, then update again
    trackChangeTimer.restart();
  }

  function updateLyrics() {
    if (!targetPlayer) {
      parsedLyrics = [];
      rawLyricText = "";
      currentLyric = "";
      currentTranslation = "";
      return;
    }

    var trackKey = trackTitle + "|" + trackArtist;
    if (trackKey === lastTrackKey && parsedLyrics.length > 0) {
      return; // Same track, already have lyrics
    }

    lastTrackKey = trackKey;

    // Get lyrics from metadata
    var metadata = targetPlayer.metadata;
    var lyricText = "";
    if (metadata && metadata["xesam:asText"]) {
      lyricText = String(metadata["xesam:asText"]);
    }

    if (lyricText !== rawLyricText) {
      rawLyricText = lyricText;
      parsedLyrics = LyricParser.parseLyric(lyricText);
      currentLyric = "";
      currentTranslation = "";
    }

    updateCurrentLyric();
  }

  function updateCurrentLyric() {
    if (!targetPlayer || parsedLyrics.length === 0) {
      currentLyric = "";
      currentTranslation = "";
      lyricProgress = 0;
      return;
    }

    // Position is in seconds, convert to microseconds
    var positionUs = Math.floor(targetPlayer.position * 1000000);
    var info = LyricParser.getLyricInfo(parsedLyrics, positionUs);

    if (info.current) {
      var split = LyricParser.splitTranslation(info.current.text);
      currentLyric = split.main;
      currentTranslation = split.translation;
    } else {
      currentLyric = "";
      currentTranslation = "";
    }

    lyricProgress = info.progress;
  }

  Component.onCompleted: {
    updatePlayerState();
    updateLyrics();
  }
}
