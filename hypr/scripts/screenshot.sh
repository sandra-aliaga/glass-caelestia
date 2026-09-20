#!/usr/bin/env bash
# Screenshot utility using grim, slurp, and wl-copy for Hyprland

set -euo pipefail

get_save_path() {
    local pictures_dir
    pictures_dir="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/imagenes")"
    local screenshots_dir="${pictures_dir}/screenshots"
    mkdir -p "${screenshots_dir}"
    local timestamp
    timestamp="$(date +'%Y-%m-%d_%H-%M-%S')"
    echo "${screenshots_dir}/screenshot_${timestamp}.png"
}

copy_and_notify() {
    local file_path="$1"
    local title="$2"
    local filename
    filename="$(basename "${file_path}")"

    if [[ ! -f "${file_path}" ]]; then
        notify-send -a "Screenshot" -u critical "Screenshot Failed" "Could not capture image."
        exit 1
    fi

    # Copy image to clipboard
    if wl-copy --type image/png < "${file_path}"; then
        notify-send -a "Screenshot" -i "${file_path}" "${title}" "Saved to ${filename} and copied to clipboard."
    else
        notify-send -a "Screenshot" -u normal "Screenshot Saved" "Saved to ${filename}, but failed to copy to clipboard."
    fi
}

capture_full() {
    local output_file
    output_file="$(get_save_path)"
    local focused_monitor
    focused_monitor="$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused == true) | .name' 2>/dev/null || true)"

    if [[ -n "${focused_monitor}" ]]; then
        grim -l 1 -o "${focused_monitor}" "${output_file}"
    else
        grim -l 1 "${output_file}"
    fi

    copy_and_notify "${output_file}" "Fullscreen Captured"
}

capture_region() {
    local geometry
    geometry="$(slurp -d 2>/dev/null || true)"

    # Exit silently if selection was cancelled
    if [[ -z "${geometry}" ]]; then
        exit 0
    fi

    local output_file
    output_file="$(get_save_path)"
    grim -l 1 -g "${geometry}" "${output_file}"

    copy_and_notify "${output_file}" "Region Captured"
}

capture_window() {
    local geometry
    geometry="$(hyprctl activewindow -j 2>/dev/null | jq -r 'select(.at != null and .size != null) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' 2>/dev/null || true)"

    if [[ -z "${geometry}" || "${geometry}" == "null,null nullxnull" ]]; then
        notify-send -a "Screenshot" -u normal "Screenshot Warning" "No active window detected."
        exit 1
    fi

    local output_file
    output_file="$(get_save_path)"
    grim -l 1 -g "${geometry}" "${output_file}"

    copy_and_notify "${output_file}" "Window Captured"
}

capture_edit() {
    local geometry
    geometry="$(slurp -d 2>/dev/null || true)"

    if [[ -z "${geometry}" ]]; then
        exit 0
    fi

    local output_file
    output_file="$(get_save_path)"
    grim -l 1 -g "${geometry}" "${output_file}"

    # Copy to clipboard immediately
    wl-copy --type image/png < "${output_file}" || true

    # Open in swappy for annotation/editing if installed
    if command -v swappy >/dev/null 2>&1; then
        swappy -f "${output_file}"
    fi
}

main() {
    local mode="${1:-full}"

    case "${mode}" in
        full|fullscreen)
            capture_full
            ;;
        region|area)
            capture_region
            ;;
        window)
            capture_window
            ;;
        edit)
            capture_edit
            ;;
        *)
            echo "Usage: $0 {full|region|window|edit}" >&2
            exit 1
            ;;
    esac
}

main "$@"
