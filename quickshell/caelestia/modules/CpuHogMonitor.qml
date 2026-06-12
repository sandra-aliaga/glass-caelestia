import Caelestia
import Quickshell
import Quickshell.Io
import QtQuick

// Warns when a process sustains high CPU. Uses the second frame of
// `top -bn2` since ps/top first frames only report lifetime averages.
Scope {
    id: root

    readonly property real threshold: 80 // % of one core
    readonly property int samplesNeeded: 3 // consecutive polls above threshold
    readonly property int cooldownMs: 300000

    property var streaks: ({})
    property var cooldowns: ({})

    function handleSample(lines: list<string>): void {
        const now = Date.now();
        const next = {};

        for (const line of lines) {
            const [pid, cpu, name] = line.trim().split(/\s+/);
            if (!pid || parseFloat(cpu) < threshold)
                continue;

            const count = (streaks[pid] ?? 0) + 1;
            next[pid] = count;

            if (count < samplesNeeded)
                continue;
            if (cooldowns[pid] && now - cooldowns[pid] < cooldownMs)
                continue;

            cooldowns[pid] = now;
            next[pid] = 0;
            console.info(`[CpuHogMonitor] ${name} (${pid}) at ${cpu}%`);
            Toaster.toast(qsTr("High CPU usage"), qsTr("%1 at %2% (PID %3)").arg(name).arg(Math.round(cpu)).arg(pid), "local_fire_department", Toast.Warning);
        }

        streaks = next;
    }

    Timer {
        running: true
        triggeredOnStart: true
        interval: 10000
        repeat: true
        onTriggered: proc.running = true
    }

    Process {
        id: proc

        // LC_ALL=C so %CPU uses dot decimals regardless of locale
        command: ["sh", "-c", "LC_ALL=C top -bn2 -d1 -w 200 -o %CPU | awk '/^top -/{b++} b==2 && $1 ~ /^[0-9]+$/ && $9+0 >= 50 {print $1, $9, $12}'"]

        stdout: StdioCollector {
            onStreamFinished: root.handleSample(text.split("\n").filter(l => l.length > 0))
        }
    }
}
