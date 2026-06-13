import qs.components.misc
import Quickshell
import QtQuick

// Owns the cheatsheet overlay and its Super+? toggle
Item {
    id: root

    CustomShortcut {
        name: "cheatsheet"
        description: "Toggle keybind cheatsheet"
        onPressed: {
            const c = loader.item;
            if (c)
                c.open = !c.open;
        }
    }

    LazyLoader {
        id: loader

        loading: true

        Cheatsheet {}
    }
}
