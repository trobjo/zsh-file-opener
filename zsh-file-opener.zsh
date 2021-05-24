alias ${_ZSH_FILE_OPENER_CMD:-u}='_file_opener'

# makes sure .subtitles are not part of the tab completion
zstyle ':completion:*:*:_file_opener:*' file-patterns '^*.(srt|part|ytdl|vtt|log):source-files' '*:all-files'

__arc() {
    unset ISFILE
    cd $(dirname "${@}")
    baseNameArc=$(basename "${@}")
    if [ ${@##*.} == "zip" ] ; then
        BUFFER="extract \"${baseNameArc}\""
    else
        mkdir "${${@%%.*}##*/}" &&\
        cd "${${@%%.*}##*/}" &&\
        BUFFER="extract ../\"${baseNameArc}\""
    fi
    zle .accept-line
}

_file_opener() {
    local IFS=$'\n' arc=() mov=() err=() pdf=() pic=() url=() doc=()

    cd "$@" > /dev/null 2>&1 && return 0
    [[ -d "$1" ]] && [[ ! -r "$1" ]] && echo "Permission denied: $1" && return 1
    cd "${@:--}" > /dev/null 2>&1 && return 0

    for file in "$@"
    do
        [ -d ${file} ] && continue
        case "${file:e:l}" in
            zip|war|jar|sublime-package|ipsw|xpi|apk|aar|whl|gz|bz2|xz|lzma|z|7z|xz|bz2|tbz|gz|tgz)
                arc+=(${file:a:q})
                ;;
            mkv|mp4|mov|mp3|avi|mpg|m4v|oga|m4a)
                swaymsg -q '[app_id=mpv] focus' || mov+=("${file:a:q}")
                ;;
            pdf|epub|djvu)
                swaymsg -q "[app_id=\"^org.pwmt.zathura$\" title=\"^${(q)file##*/}\ \[\"] focus" || pdf+=("${file:a:q}")
                ;;
            jpeg|jpg|png|webp|svg|gif|bmp|tif|tiff|psd)
                pic+=("${file:a:q}")
                ;;
            otf|ttf|iso|mobi)
                err+=($file)
                ;;
            html|mhtml)
                url+=("${file:a:q}")
                ;;
            *)
                doc+=("${file:a:q}")
                ;;
        esac
    done

    [[ ${#arc} -eq 1 && "${#@}" -eq 1 ]] && __arc
    [ -z ${err} ] && [[ ${#arc} -ne 1 ]] && swaymsg -q -- [app_id=^PopUp$] move scratchpad

    [ ${#mov} -gt 0 ] && {
        grep -q 'enabled' /sys/class/drm/{card0-DP-1,card0-DP-2,card0-HDMI-A-1}/enabled\
        && grep -q 'Discharging' /sys/class/power_supply/BAT0/status\
        && swaymsg "output eDP-1 dpms off"
        swaymsg -q -- exec \'/usr/bin/mpv ${mov} \; swaymsg output eDP-1 dpms on\'
    }

    [ ${#err} -gt 0 ] && print "Cannot open" ${err}
    [ ${#pdf} -gt 0 ] && swaymsg -q -- exec \'/usr/bin/zathura ${pdf}\'

    [ ${#pic} -gt 0 ] && {
        [ ${#pic} -eq 1 ] && swaymsg -q -- exec \'/usr/bin/imv-wayland ${pic%/*} -n "${pic}"\' ||\
        swaymsg -q -- exec \'/usr/bin/imv-wayland $(sort --ignore-case --sort=version <<< "${pic}")\'
    }

    [ ${#doc} -gt 0 ] && swaymsg -q -- [app_id=^PopUp$] move scratchpad, exec \'/opt/sublime_text/sublime_text ${doc}\' \; [app_id=^sublime_text$] focus\; [app_id=^sublime_text$ workspace="^2λ$"] fullscreen enable

    [ ${#url} -gt 0 ] && {
        pkill -CONT $FIREFOXPROCESSES
        swaymsg -q -- [app_id=^firefox$] focus, exec \'/usr/bin/firefox --new-tab "${url}"\'
    } || grep -q 1 /sys/class/power_supply/AC0/online || pkill -STOP $FIREFOXPROCESSES
    return 0
}
