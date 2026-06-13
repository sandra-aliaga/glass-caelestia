pragma Singleton

import qs.utils
import Quickshell
import Quickshell.Io
import QtQuick

// Parses the user's Hyprland keybinds.conf into categorised, human
// readable entries for the cheatsheet. Categories come from the
// "# --- Name ---" section headers; descriptions from inline comments.
Singleton {
    id: root

    readonly property string keybindsPath: `${Paths.home}/.config/hypr/hyprland/keybinds.conf`
    readonly property string variablesPath: `${Paths.home}/.config/hypr/variables.conf`

    // [{ name, binds: [{ combo, description }] }]
    property var categories: []

    property var vars: ({})
    property bool varsReady: false
    property bool bindsReady: false

    function parse(): void {
        if (!varsReady || !bindsReady)
            return;

        const lines = binds.text().split("\n");
        const cats = [];
        let current = null;
        // Tracks digit-key runs so workspace 1-0 spam collapses to one row
        const digitGroups = {};

        for (const raw of lines) {
            const line = raw.trim();

            const header = line.match(/^#\s*---\s*(.+?)\s*---/);
            if (header) {
                current = { name: header[1], binds: [] };
                cats.push(current);
                continue;
            }

            if (!current || !/^bind/.test(line))
                continue;

            const eq = line.indexOf("=");
            if (eq < 0)
                continue;

            // Split inline comment (the human description) from the bind body
            let body = line.slice(eq + 1);
            let description = "";
            const hash = body.indexOf("#");
            if (hash >= 0) {
                description = body.slice(hash + 1).trim();
                body = body.slice(0, hash);
            }
            if (!description)
                continue;

            // Resolve $variables before splitting on commas
            body = body.replace(/\$\w+/g, m => root.vars[m] ?? m);
            const fields = body.split(",").map(f => f.trim());
            const mods = fields[0] ?? "";
            const key = fields[1] ?? "";

            const combo = root.formatCombo(mods, key);
            if (!combo)
                continue;

            // Collapse runs of single-digit keys (workspaces 1..0)
            if (/^[0-9]$/.test(key)) {
                const base = description.replace(/\s*\d+$/, "").trim();
                const groupKey = `${current.name}|${mods}|${base}`;
                if (digitGroups[groupKey]) {
                    digitGroups[groupKey].combo = root.formatCombo(mods, "1-0");
                    digitGroups[groupKey].description = base;
                    continue;
                }
                const entry = { combo: root.formatCombo(mods, "1-0"), description: base };
                digitGroups[groupKey] = entry;
                current.binds.push(entry);
                continue;
            }

            current.binds.push({ combo, description });
        }

        root.categories = cats.filter(c => c.binds.length > 0);
    }

    function formatCombo(mods: string, key: string): string {
        const parts = [];
        if (mods)
            parts.push(...mods.split("+").map(m => root.prettyMod(m.trim())).filter(m => m));
        if (key)
            parts.push(root.prettyKey(key));
        return parts.join(" + ");
    }

    function prettyMod(mod: string): string {
        const map = {
            "Super": "Super",
            "Ctrl": "Ctrl",
            "Control": "Ctrl",
            "Shift": "Shift",
            "Alt": "Alt"
        };
        return map[mod] ?? mod;
    }

    function prettyKey(key: string): string {
        const map = {
            "Return": "Enter",
            "Comma": ",",
            "comma": ",",
            "period": ".",
            "Backslash": "\\",
            "Space": "Space",
            "slash": "/",
            "Page_Up": "Pg↑",
            "Page_Down": "Pg↓",
            "left": "←",
            "right": "→",
            "up": "↑",
            "down": "↓",
            "mouse_up": "Scroll↑",
            "mouse_down": "Scroll↓",
            "Escape": "Esc",
            "Delete": "Del"
        };
        return map[key] ?? (key.length === 1 ? key.toUpperCase() : key);
    }

    FileView {
        id: variables

        path: root.variablesPath
        watchChanges: true
        onFileChanged: reload()

        onLoaded: {
            const map = {};
            for (const raw of text().split("\n")) {
                const m = raw.match(/^\s*(\$\w+)\s*=\s*(.+?)\s*(?:#.*)?$/);
                if (m)
                    map[m[1]] = m[2].trim();
            }
            root.vars = map;
            root.varsReady = true;
            root.parse();
        }
    }

    FileView {
        id: binds

        path: root.keybindsPath
        watchChanges: true
        onFileChanged: reload()

        onLoaded: {
            root.bindsReady = true;
            root.parse();
        }
    }
}
