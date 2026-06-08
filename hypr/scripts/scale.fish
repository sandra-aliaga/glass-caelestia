#!/usr/bin/env fish
# Script para cambiar la escala del monitor dinámicamente
# Valores válidos: 1.0, 1.2, 1.4, 1.6, 1.8, 2.0

set scales 10 12 14 16 18 20
set scale_labels 1.0 1.2 1.4 1.6 1.8 2.0

# Obtener la escala actual y convertir a entero (x10) para comparar sin decimales
set current (hyprctl monitors -j | jq -r '.[0].scale')
set current_int (math "round($current * 10)")

switch $argv[1]
    case up
        for i in (seq (count $scales))
            if test $scales[$i] -gt $current_int
                set idx $i
                break
            end
        end
        if not set -q idx
            set idx (count $scales)
        end
    case down
        set idx 1
        for i in (seq (count $scales))
            if test $scales[$i] -ge $current_int
                if test $i -gt 1
                    set idx (math "$i - 1")
                end
                break
            end
        end
    case '*'
        echo "Uso: scale.fish [up|down]"
        exit 1
end

set new_scale $scale_labels[$idx]
set monitor_name (hyprctl monitors -j | jq -r '.[0].name')
set monitor_res (hyprctl monitors -j | jq -r '.[0] | "\(.width)x\(.height)@\(.refreshRate)"')
set monitor_pos (hyprctl monitors -j | jq -r '.[0] | "\(.x)x\(.y)"')
hyprctl keyword monitor $monitor_name,$monitor_res,$monitor_pos,$new_scale
notify-send -u low -i display "Escala: $new_scale" "Monitor ajustado a $new_scale" -a "Hyprland"
