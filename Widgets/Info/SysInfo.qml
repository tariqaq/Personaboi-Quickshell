pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property bool active: false

    readonly property real cpuUsage: _cpuUsage
    property real _cpuUsage: 0
    property real _lastCpuIdle: 0
    property real _lastCpuTotal: 0

    property real _memUsed: 0
    property real _memTotal: 1
    readonly property real memUsage: _memTotal > 0 ? _memUsed / _memTotal : 0
    readonly property string memText: (_memUsed / 1073741824).toFixed(1) + " / " + (_memTotal / 1073741824).toFixed(1) + " GB"

    property real _diskUsed: 0
    property real _diskTotal: 1
    readonly property real diskUsage: _diskTotal > 0 ? _diskUsed / _diskTotal : 0
    readonly property string diskText: (_diskUsed / 1073741824).toFixed(1) + " / " + (_diskTotal / 1073741824).toFixed(1) + " GB"

    property string osName: ""
    property string loggedInUsers: ""
    property string hostname: ""
    property string kernel: ""
    property string uptime: ""
    property string loadAverage: ""
    property string cpuModel: ""
    property string cpuCores: ""
    property string processCount: ""
    property string gpuName: ""
    property string gpuUtil: "N/A"
    property string gpuMemory: "N/A"
    property string gpuTemp: "N/A"

    FileView {
        id: cpuFile
        path: "/proc/stat"
        onLoaded: {
            const line = text().match(/^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/);
            if (!line)
                return;
            const s = line.slice(1).map(Number);
            const idle = s[3] + s[4];
            const total = s[0] + s[1] + s[2] + s[3] + s[4] + s[5] + s[6];
            if (root._lastCpuTotal > 0) {
                const dt = total - root._lastCpuTotal;
                const di = idle - root._lastCpuIdle;
                if (dt > 0)
                    root._cpuUsage = 1 - di / dt;
            }
            root._lastCpuIdle = idle;
            root._lastCpuTotal = total;
        }
    }

    FileView {
        id: memFile
        path: "/proc/meminfo"
        onLoaded: {
            const t = text();
            const total = parseInt(t.match(/MemTotal:\s+(\d+)/)?.[1] ?? 0);
            const avail = parseInt(t.match(/MemAvailable:\s+(\d+)/)?.[1] ?? 0);
            if (total > 0) {
                root._memTotal = total * 1024;
                root._memUsed = (total - avail) * 1024;
            }
        }
    }

    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        onLoaded: {
            const seconds = Math.floor(parseFloat(text().split(/\s+/)[0] || "0"));
            const days = Math.floor(seconds / 86400);
            const hours = Math.floor((seconds % 86400) / 3600);
            const mins = Math.floor((seconds % 3600) / 60);
            root.uptime = (days > 0 ? days + "d " : "") + hours + "h " + mins + "m";
        }
    }

    FileView {
        id: loadFile
        path: "/proc/loadavg"
        onLoaded: {
            const p = text().trim().split(/\s+/);
            root.loadAverage = p.length >= 3 ? p.slice(0, 3).join(" / ") : "N/A";
        }
    }

    Process {
        id: dfShell
        command: ["sh"]
        stdinEnabled: true
        running: root.active
        onRunningChanged: {
            if (running)
                diskTimer.triggered();
        }
        stdout: SplitParser {
            splitMarker: "@@END@@"
            onRead: data => {
                const parts = data.trim().split(/\s+/);
                if (parts.length >= 3) {
                    root._diskTotal = parseInt(parts[1]);
                    root._diskUsed = parseInt(parts[2]);
                }
            }
        }
    }

    Process {
        id: osProc
        command: ["sh", "-c", ". /etc/os-release && echo $PRETTY_NAME"]
        running: true
        stdout: SplitParser { onRead: data => root.osName = data.trim() }
    }
    Process {
        id: usersProc
        command: ["sh", "-c", "who | wc -l"]
        stdout: SplitParser { onRead: data => root.loggedInUsers = data.trim() }
    }
    Process {
        id: hostProc
        command: ["hostname"]
        running: true
        stdout: SplitParser { onRead: data => root.hostname = data.trim() }
    }
    Process {
        id: kernelProc
        command: ["uname", "-r"]
        running: true
        stdout: SplitParser { onRead: data => root.kernel = data.trim() }
    }
    Process {
        id: cpuModelProc
        command: ["sh", "-c", "awk -F': ' '/model name/{print $2; exit}' /proc/cpuinfo | sed -E 's/^.*(Intel\\(R\\) )?Core\\(TM\\) //; s/^.*AMD //; s/ CPU.*$//' "]
        running: true
        stdout: SplitParser { onRead: data => root.cpuModel = data.trim() }
    }
    Process {
        id: coresProc
        command: ["nproc"]
        running: true
        stdout: SplitParser { onRead: data => root.cpuCores = data.trim() }
    }
    Process {
        id: processProc
        command: ["sh", "-c", "find /proc -maxdepth 1 -type d -name '[0-9]*' 2>/dev/null | wc -l"]
        stdout: SplitParser { onRead: data => root.processCount = data.trim() }
    }
    Process {
        id: gpuProc
        command: ["sh", "-c", "if command -v nvidia-smi >/dev/null 2>&1; then nvidia-smi --query-gpu=name,utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv,noheader,nounits | head -n1; elif command -v lspci >/dev/null 2>&1; then lspci | grep -Ei 'VGA|3D' | head -n1 | sed -E 's/^.*: //'; else echo 'Unknown GPU'; fi"]
        stdout: SplitParser {
            onRead: data => {
                const line = data.trim();
                if (line.indexOf(",") >= 0) {
                    const p = line.split(",").map(s => s.trim());
                    root.gpuName = p[0] || "NVIDIA GPU";
                    root.gpuUtil = (p[1] || "0") + "%";
                    root.gpuMemory = (p[2] || "0") + " / " + (p[3] || "0") + " MiB";
                    root.gpuTemp = (p[4] || "0") + "°C";
                } else {
                    root.gpuName = line || "Unknown GPU";
                    root.gpuUtil = "N/A";
                    root.gpuMemory = "N/A";
                    root.gpuTemp = "N/A";
                }
            }
        }
    }

    Timer {
        interval: 2000
        repeat: true
        running: root.active
        triggeredOnStart: true
        onTriggered: {
            cpuFile.reload();
            memFile.reload();
            uptimeFile.reload();
            loadFile.reload();
        }
    }

    Timer {
        id: diskTimer
        interval: 30000
        repeat: true
        running: root.active
        onTriggered: {
            if (dfShell.running)
                dfShell.write("df -B1 / | awk 'NR==2{print $1\" \"$2\" \"$3}'; echo '@@END@@'\n");
        }
    }

    Timer {
        interval: 10000
        repeat: true
        running: root.active
        triggeredOnStart: true
        onTriggered: {
            if (!processProc.running)
                processProc.running = true;
            if (!gpuProc.running)
                gpuProc.running = true;
        }
    }

    Timer {
        interval: 60000
        repeat: true
        running: root.active
        triggeredOnStart: true
        onTriggered: {
            if (!usersProc.running)
                usersProc.running = true;
        }
    }
}
