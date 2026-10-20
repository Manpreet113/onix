pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

// Centralized High-Performance Media Coordinator (Ambxst / Material 3 Architecture)
Singleton {
    id: root

    property var activePlayer: null
    property bool hasMedia: false
    property bool isPlaying: false

    property string trackTitle: ""
    property string trackArtist: ""
    property string trackAlbum: ""
    property string trackArtUrl: ""
    property string playerIdentity: "Media Player"

    property real trackLength: 0.0 // in seconds
    property real position: 0.0    // in seconds
    readonly property real progress: (trackLength > 0) ? Math.max(0.0, Math.min(1.0, position / trackLength)) : 0.0

    // Friendly reactive aliases
    readonly property bool hasTrack: hasMedia && (trackTitle.length > 0 || isPlaying)
    readonly property string title: trackTitle
    readonly property string artist: trackArtist
    readonly property string album: trackAlbum
    readonly property string artUrl: trackArtUrl
    readonly property string identity: playerIdentity

    property real volume: activePlayer?.volume ?? 1.0

    // Shuffle & Loop properties
    readonly property bool shuffleSupported: activePlayer?.shuffleSupported ?? false
    readonly property bool isShuffle: activePlayer?.shuffle ?? false
    readonly property bool loopSupported: activePlayer?.loopSupported ?? false
    readonly property var loopState: activePlayer?.loopState ?? MprisLoopState.None

    // Available players list for quick switching
    readonly property var availablePlayers: Mpris.players.values

    // Interpolation state
    property real _anchorPos: 0.0
    property real _anchorTime: 0.0

    function formatTime(s: real): string {
        if (!s || isNaN(s) || s < 0) return "0:00";
        const total = Math.floor(s);
        const m = Math.floor(total / 60);
        const sec = total % 60;
        return m + ":" + (sec < 10 ? "0" : "") + sec;
    }

    function cleanPlayerIdentity(p): string {
        if (!p) return "Media Player";
        let ident = (p.identity && p.identity.trim().length > 0) ? p.identity.trim() : "";
        if (!ident || ident === "Media Player") {
            if (p.desktopEntry && p.desktopEntry.trim().length > 0) {
                ident = p.desktopEntry.trim();
            } else if (p.dbusName) {
                const parts = p.dbusName.split(".");
                ident = parts[parts.length - 1];
            }
        }
        if (!ident) return "Media Player";
        const lower = ident.toLowerCase();
        if (lower === "bitchord") return "BitChord";
        if (lower === "spotify") return "Spotify";
        if (lower === "firefox") return "Firefox";
        if (lower === "chromium") return "Chromium";
        if (lower === "nuvio") return "Nuvio";
        return ident.charAt(0).toUpperCase() + ident.slice(1);
    }

    function selectPlayer(player): void {
        if (!player) return;
        root.activePlayer = player;
        syncPlayerState();
    }

    function updateActivePlayer(): void {
        const list = Mpris.players.values;
        if (!list || list.length === 0) {
            root.activePlayer = null;
            root.hasMedia = false;
            root.isPlaying = false;
            root.trackTitle = "";
            root.trackArtist = "";
            root.trackAlbum = "";
            root.trackArtUrl = "";
            root.trackLength = 0;
            root.position = 0;
            root._anchorPos = 0;
            root._anchorTime = 0;
            return;
        }

        // If current activePlayer is still valid and playing, keep it
        if (root.activePlayer && list.indexOf(root.activePlayer) !== -1) {
            if (root.activePlayer.playbackState === MprisPlaybackState.Playing) {
                syncPlayerState();
                return;
            }
        }

        let chosen = null;
        // Priority 1: Any player currently playing
        for (let i = 0; i < list.length; i++) {
            if (list[i].playbackState === MprisPlaybackState.Playing) {
                chosen = list[i];
                break;
            }
        }
        // Priority 2: Any player with valid track title
        if (!chosen) {
            for (let j = 0; j < list.length; j++) {
                if (list[j].trackTitle && list[j].trackTitle.length > 0) {
                    chosen = list[j];
                    break;
                }
            }
        }
        // Priority 3: First available player
        if (!chosen) chosen = list[0];

        root.activePlayer = chosen;
        syncPlayerState();
    }

    function syncPlayerState(): void {
        const p = root.activePlayer;
        if (!p) {
            root.hasMedia = false;
            root.isPlaying = false;
            return;
        }

        const playing = (p.playbackState === MprisPlaybackState.Playing);
        const title = p.trackTitle || "";
        const artist = p.trackArtist || "";
        const album = p.trackAlbum || "";
        const art = p.trackArtUrl || "";
        const ident = cleanPlayerIdentity(p);

        const trackChanged = (title !== root.trackTitle || artist !== root.trackArtist);
        if (trackChanged) {
            root.trackTitle = title;
            root.trackArtist = artist;
            root.trackAlbum = album;
            root.trackArtUrl = art;
            root.playerIdentity = ident;

            const initialPos = (p.position >= 0) ? p.position : 0.0;
            root.position = initialPos;
            root._anchorPos = initialPos;
            root._anchorTime = Date.now();
            fetchFallbacks();
        } else {
            root.trackAlbum = album;
            root.trackArtUrl = art;
            root.playerIdentity = ident;
        }

        if (playing !== root.isPlaying) {
            root.isPlaying = playing;
            const curPos = (p.position >= 0) ? p.position : root.position;
            root._anchorPos = curPos;
            root._anchorTime = Date.now();
            root.position = curPos;
        }

        root.hasMedia = (title.length > 0 || playing);

        if (p.lengthSupported && p.length > 0 && p.length !== p.position) {
            root.trackLength = p.length;
        }

        if (p.volumeSupported && !isNaN(p.volume)) {
            root.volume = p.volume;
        }
    }

    // Process fallback for players that don't export length directly over Mpris properties
    Process {
        id: lengthProc
        command: ["playerctl", "metadata", "mpris:length"]
        stdout: SplitParser {
            onRead: raw => {
                const val = parseFloat(raw.trim());
                if (!isNaN(val) && val > 0) {
                    root.trackLength = val / 1000000.0;
                }
            }
        }
    }

    // Fallback position poller for players whose DBus position isn't updating continuously
    Process {
        id: posProc
        command: ["playerctl", "position"]
        stdout: SplitParser {
            onRead: raw => {
                const val = parseFloat(raw.trim());
                if (!isNaN(val) && val >= 0) {
                    if (Math.abs(val - root.position) > 1.2) {
                        root.position = val;
                        root._anchorPos = val;
                        root._anchorTime = Date.now();
                    }
                }
            }
        }
    }

    // Fallback art url retriever for players with non-standard Mpris metadata exposure
    Process {
        id: artProc
        command: ["playerctl", "metadata", "mpris:artUrl"]
        stdout: SplitParser {
            onRead: raw => {
                const url = raw.trim();
                if (url.length > 0 && (!root.trackArtUrl || root.trackArtUrl.length === 0)) {
                    root.trackArtUrl = url;
                }
            }
        }
    }

    // Fallback player identity retriever
    Process {
        id: identProc
        command: ["playerctl", "metadata", "--format", "{{playerName}}"]
        stdout: SplitParser {
            onRead: raw => {
                const name = raw.trim();
                if (name.length > 0 && (!root.playerIdentity || root.playerIdentity === "Media Player")) {
                    root.playerIdentity = cleanPlayerIdentity({ identity: name });
                }
            }
        }
    }

    function fetchTrackLength(): void {
        if (root.activePlayer?.lengthSupported && root.activePlayer.length > 0 && root.activePlayer.length !== root.activePlayer.position) {
            root.trackLength = root.activePlayer.length;
            return;
        }
        if (!lengthProc.running) {
            lengthProc.running = true;
        }
    }

    function fetchFallbacks(): void {
        fetchTrackLength();
        if ((!root.trackArtUrl || root.trackArtUrl.length === 0) && !artProc.running) {
            artProc.running = true;
        }
        if ((!root.playerIdentity || root.playerIdentity === "Media Player") && !identProc.running) {
            identProc.running = true;
        }
    }

    // React to all player events reactively
    Instantiator {
        model: Mpris.players
        delegate: Connections {
            target: modelData
            function onPlaybackStateChanged(): void {
                root.updateActivePlayer();
            }
            function onTrackChanged(): void {
                root.updateActivePlayer();
            }
            function onMetadataChanged(): void {
                root.updateActivePlayer();
                root.fetchTrackLength();
            }
            function onPositionChanged(): void {
                if (modelData === root.activePlayer) {
                    const p = modelData.position;
                    // Detect discrete seeks or loops (drift greater than 1.0s)
                    if (p >= 0 && Math.abs(p - root.position) > 1.0) {
                        root._anchorPos = p;
                        root._anchorTime = Date.now();
                        root.position = p;
                    }
                }
            }
            function onVolumeChanged(): void {
                if (modelData === root.activePlayer && modelData.volumeSupported) {
                    root.volume = modelData.volume;
                }
            }
        }
    }

    // Smooth continuous position interpolator (ticks every 100ms when playing)
    Timer {
        id: posTimer
        interval: 100
        repeat: true
        running: root.isPlaying && root.hasMedia
        onTriggered: {
            if (!root.activePlayer) return;
            const now = Date.now();
            const rate = root.activePlayer.rate || 1.0;
            const elapsed = ((now - root._anchorTime) / 1000.0) * rate;
            const newPos = root._anchorPos + elapsed;
            root.position = (root.trackLength > 0) ? Math.min(root.trackLength, newPos) : newPos;
        }
    }

    // Heartbeat sync (every 1.5s) to guard against drift or external player changes
    Timer {
        interval: 1500
        repeat: true
        running: true
        onTriggered: {
            root.updateActivePlayer();
            if (root.isPlaying && !posProc.running) {
                posProc.running = true;
            }
        }
    }

    Timer {
        id: syncTimer
        interval: 200
        repeat: false
        onTriggered: {
            root.updateActivePlayer();
            root.fetchFallbacks();
            if (!posProc.running) {
                posProc.running = true;
            }
        }
    }

    function togglePlay(): void {
        if (root.activePlayer?.canTogglePlaying) {
            root.activePlayer.togglePlaying();
        } else if (root.activePlayer?.canPlay && !root.isPlaying) {
            root.activePlayer.play();
        } else if (root.activePlayer?.canPause && root.isPlaying) {
            root.activePlayer.pause();
        } else {
            Quickshell.execDetached(["playerctl", "play-pause"]);
        }

        root.isPlaying = !root.isPlaying;
        if (root.isPlaying) {
            root._anchorTime = Date.now();
            root._anchorPos = root.position;
        } else {
            root._anchorPos = root.position;
        }
        syncTimer.restart();
    }

    function next(): void {
        root.position = 0.0;
        root._anchorPos = 0.0;
        root._anchorTime = Date.now();

        if (root.activePlayer?.canGoNext) {
            root.activePlayer.next();
        } else {
            Quickshell.execDetached(["playerctl", "next"]);
        }
        syncTimer.restart();
    }

    function previous(): void {
        // If track has progressed more than 3s, or cannot go to previous track: restart current song from 0
        if (root.position > 3.0 || (root.activePlayer && !root.activePlayer.canGoPrevious)) {
            seek(0.0);
            if (root.isPlaying) {
                if (root.activePlayer?.canPlay) root.activePlayer.play();
                else Quickshell.execDetached(["playerctl", "play"]);
            }
            return;
        }

        // Within first 3 seconds and player can go previous:
        root.position = 0.0;
        root._anchorPos = 0.0;
        root._anchorTime = Date.now();

        if (root.activePlayer?.canGoPrevious) {
            root.activePlayer.previous();
        } else {
            Quickshell.execDetached(["playerctl", "previous"]);
        }
        syncTimer.restart();
    }

    function seek(targetSec: real): void {
        const s = Math.max(0.0, Math.min(root.trackLength > 0 ? root.trackLength : targetSec, targetSec));
        root.position = s;
        root._anchorPos = s;
        root._anchorTime = Date.now();

        if (root.activePlayer?.canSeek) {
            root.activePlayer.position = s;
        } else {
            Quickshell.execDetached(["playerctl", "position", s.toFixed(2)]);
        }
    }

    function seekRelative(offsetSec: real): void {
        seek(root.position + offsetSec);
    }

    function setVolume(vol: real): void {
        const v = Math.max(0.0, Math.min(1.0, vol));
        root.volume = v;
        if (root.activePlayer?.volumeSupported) {
            root.activePlayer.volume = v;
        } else {
            Quickshell.execDetached(["playerctl", "volume", v.toFixed(2)]);
        }
    }

    function toggleShuffle(): void {
        if (root.activePlayer?.shuffleSupported) {
            root.activePlayer.shuffle = !root.activePlayer.shuffle;
        } else {
            Quickshell.execDetached(["playerctl", "shuffle", "toggle"]);
        }
    }

    function cycleLoop(): void {
        if (!root.activePlayer?.loopSupported) return;
        const cur = root.activePlayer.loopState;
        if (cur === MprisLoopState.None) {
            root.activePlayer.loopState = MprisLoopState.Playlist;
        } else if (cur === MprisLoopState.Playlist) {
            root.activePlayer.loopState = MprisLoopState.Track;
        } else {
            root.activePlayer.loopState = MprisLoopState.None;
        }
    }

    Component.onCompleted: {
        updateActivePlayer();
        fetchTrackLength();
    }
}
