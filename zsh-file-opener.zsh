alias ${_ZSH_FILE_OPENER_CMD:-f}='_file_opener'

# makes sure .subtitles are not part of the tab completion
zstyle ':completion:*:*:_file_opener:*' file-patterns '^*.(srt|part|ytdl|vtt|log):source-files' '*:all-files'

_file_opener() {
    typeset -aU arc mov pdf pic url doc

    cd "${@:--}" > /dev/null 2>&1 && return 0
    [[ ! -r "$1" ]] && print "Permission denied: $1" && return 1

    for file in "$@"
    do
        [ -d ${file} ] && continue
        case "${file:e:l}" in
            (zip|war|jar|sublime-package|ipsw|xpi|apk|aar|whl|gz|bz2|xz|lzma|z|7z|xz|bz2|tbz|gz|tgz|tar)
                arc+=(${file:a}) ;;
            (mkv|mp4|mov|mp3|avi|mpg|m4v|oga|m4a)
                swaymsg -q '[app_id=mpv] focus' || mov+=("${file:a:q}") ;;
            (pdf|epub|djvu)
                swaymsg -q "[app_id=\"^org.pwmt.zathura$\" title=\"^${(q)file##*/}\ \[\"] focus" || pdf+=("${file:a:q}") ;;
            (jpeg|jpg|png|webp|svg|gif|bmp|tif|tiff|psd)
                pic+=("${file:a:q}") ;;
            (otf|ttf|iso|mobi|dll)
                print "Cannot open \x1B[36m${file##*/}\033[0m" && local ret=1 ;;
            (html|mhtml)
                url+=("${file:a:q}") ;;
            (*)
                doc+=("${file:a:q}") ;;
        esac
    done

    [[ ${ret} ]] || [[ ${arc} ]] || swaymsg -q -- [app_id=^PopUp$] move scratchpad

    [[ ${mov} ]] && {
        grep -q 'enabled' /sys/class/drm/{card0-DP-1,card0-DP-2,card0-HDMI-A-1}/enabled\
        && grep -q 'Discharging' /sys/class/power_supply/BAT0/status\
        && swaymsg -q output eDP-1 dpms off
        swaymsg -q -- exec \'/usr/bin/mpv --player-operation-mode=pseudo-gui ${mov} \; swaymsg output eDP-1 dpms on\'
    }

    [[ ${pdf} ]] && swaymsg -q -- exec \'/usr/bin/zathura ${pdf}\'

    [[ ${pic} ]] && {
        [ ${#pic} -eq 1 ] && swaymsg -q -- exec \'/usr/bin/imv-wayland ${pic%/*} -n "${pic}"\' ||\
        swaymsg -q -- exec \'/usr/bin/imv-wayland ${pic}\'
    }

    [[ ${doc} ]] && swaymsg -q -- exec \'/opt/sublime_text/sublime_text ${doc}\' \; [app_id=^sublime_text$] focus\; [app_id="^sublime_text$" workspace="^2λ$"] fullscreen enable

    [[ ${url} ]] && {
        pkill -CONT $FIREFOXPROCESSES
        swaymsg -q -- exec \'/usr/bin/firefox ${url[@]/#/--new-tab }\' \; [app_id=^firefox$] focus\; [app_id="^firefox$" workspace="^3$"] fullscreen enable
    } || grep -q 1 /sys/class/power_supply/AC0/online || pkill -STOP $FIREFOXPROCESSES

    [[ ${arc} ]] && extract ${arc} < $TTY

    return ${ret:-0}

}
