alias ${_ZSH_FILE_OPENER_CMD:-u}='_file_opener'
alias ${_ZSH_FILE_OPENER_CMD:-u}${_ZSH_FILE_OPENER_CMD:-u}='cd - 1> /dev/null'

# makes sure .subtitles are not part of the tab completion
zstyle ':completion:*:*:_file_opener:*' file-patterns '^*.(srt|part|ytdl|vtt|log):source-files' '*:all-files'

__mov() {
    if [[ $HOST == "MateBookXPro" ]] ; then
        if grep -q 'enabled' /sys/class/drm/card0-DP-1/enabled
        then
            if grep -q 'Discharging' /sys/class/power_supply/BAT0/status
            then
                swaymsg "output eDP-1 disable"
                swaymsg -q -- exec /usr/bin/mpv --fullscreen --audio-device=alsa/hdmi:CARD=PCH,DEV=0 ${@} ; swaymsg "output eDP-1 enable"
            else
                swaymsg -q -- exec /usr/bin/mpv --fullscreen --audio-device=alsa/hdmi:CARD=PCH,DEV=0 ${@}
            fi
        return 0
        fi
    fi
    # (grep -q 'enabled' /sys/class/drm/card0-DP-1/enabled && output="--audio-device=alsa/iec958:CARD=Audio,DEV=0"
     readlink /sys/bus/hid/devices/0003:047F:02F7* && output="--audio-device=alsa/iec958:CARD=BT600,DEV=0"
     swaymsg -q -- exec /usr/bin/mpv --fullscreen $output ${@}
}

__pic() {
    if [ ${#@} -eq 1 ]
    then
        setopt local_options dotglob
        dirname=$(dirname "${1}")
        imagearray=("$dirname"/*.(jpeg|jpg|png|webp|svg|gif|bmp|tif|tiff|psd))
        swaymsg -- exec /usr/bin/imv-wayland $(sort --ignore-case --sort=version <<< "${imagearray[@]}") -n "${1}"
    else
        swaymsg -- exec /usr/bin/imv-wayland $(sort --ignore-case --sort=version <<< "${@}")
    fi
}

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

__browser() {
    pkill -CONT $FIREFOXPROCESSES
    swaymsg -q -- [app_id=^firefox$] focus, exec /usr/bin/firefox --new-tab "$@"
}

_file_opener() {
    local IFS=$'\n' arc mov err pdf pic url doc

    cd "$@" > /dev/null 2>&1 && return 0
    [[ -d "$1" ]] && [[ ! -r "$1" ]] && echo "Permission denied: $1" && return 1

    for file in "$@"
    do
        [ -d ${file} ] && continue
        case "${file:e:l}" in
            zip|war|jar|sublime-package|ipsw|xpi|apk|aar|whl|gz|bz2|xz|lzma|z|7z|xz|bz2|tbz|gz|tgz)
                arc+=(${file:a:q})
                ;;
            mkv|mp4|mov|mp3|avi|mpg|m4v|oga|m4a)
                swaymsg '[app_id=mpv] focus' > /dev/null 2>&1 || mov+=("${file:a:q}")
                ;;
            pdf|epub|djvu)
                swaymsg "[app_id=\"^org.pwmt.zathura$\" title=\"^${(q)file##*/}\ \[\"] focus" > /dev/null 2>&1 || pdf+=("${file:a:q}")
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
    [ ${#mov} -gt 0 ] && __mov ${mov}
    [ ${#err} -gt 0 ] && print "Cannot open" ${err}
    [ ${#pdf} -gt 0 ] && swaymsg -q -- exec /usr/bin/zathura ${pdf}
    [ ${#pic} -gt 0 ] && __pic ${pic}
    [ ${#doc} -gt 0 ] && swaymsg -q --  exec /opt/sublime_text/sublime_text ${doc} \; [app_id=^(subl|sublime_text)$] focus\; [app_id=^(subl|sublime_text)$ workspace="^2λ$"] fullscreen enable
    [ ${#url} -gt 0 ] && __browser ${url} || grep -q 1 /sys/class/power_supply/AC0/online || pkill -STOP $FIREFOXPROCESSES
}

