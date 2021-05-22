alias ${_ZSH_FILE_OPENER_CMD:-u}='_file_opener'

if [[ $SSH_TTY ]]; then
    if ! command -v $HOME/.local/bin/rmate &> /dev/null; then
        printf "\rInstalling \x1B[35m\033[3mrmate\033[0m helper for \x1B[33m\033[3mSublime Text\033[0m           … " &&\
        command mkdir -p "${HOME}/.local/bin"
        curl --silent -o $HOME/.local/bin/rmate https://raw.githubusercontent.com/aurora/rmate/master/rmate &&\
        chmod +x $HOME/.local/bin/rmate &&\
        printf "\x1B[32m\033[3mSucces\033[0m!\n" ||\
        printf "\r\x1B[31mFailed to install \x1B[35m\033[3mrmate\033[0m\n"
    fi

    _file_opener() {
        cd "$@" > /dev/null 2>&1 && return 0
        touch "$@" > /dev/null 2>&1 && $HOME/.local/bin/rmate "$@" || sudo $HOME/.local/bin/rmate "$@"
    }

    return 0
fi

# makes sure .subtitles are not part of the tab completion
zstyle ':completion:*:*:_file_opener:*' file-patterns '^*.(srt|part|ytdl|vtt|log):source-files' '*:all-files'

__mov() {
    if [[ $HOST == "MateBookXPro" ]] ; then
        if grep -q 'enabled' /sys/class/drm/card0-DP-1/enabled
        then
            if grep -q 'Discharging' /sys/class/power_supply/BAT0/status
            then
                swaymsg "output eDP-1 disable"
                swaymsg -q -- exec /usr/bin/mpv --fullscreen --audio-device=alsa/hdmi:CARD=PCH,DEV=0 ${mov} ; swaymsg "output eDP-1 enable"
            else
                swaymsg -q -- exec /usr/bin/mpv --fullscreen --audio-device=alsa/hdmi:CARD=PCH,DEV=0 ${mov}
            fi
        return 0
        fi
    fi
    # (grep -q 'enabled' /sys/class/drm/card0-DP-1/enabled && output="--audio-device=alsa/iec958:CARD=Audio,DEV=0"
     readlink /sys/bus/hid/devices/0003:047F:02F7* && output="--audio-device=alsa/iec958:CARD=BT600,DEV=0"
     swaymsg -q -- exec /usr/bin/mpv --fullscreen $output ${mov}
}

__pic() {
    if [ ${#pic[@]} -eq 1 ]
    then
        setopt local_options dotglob
        dirname=$(dirname "${pic}")
        imagearray=("$dirname"/*.(jpeg|jpg|png|webp|svg|gif|bmp|tif|tiff|psd))
        swaymsg -- exec /usr/bin/imv-wayland $(sort --ignore-case --sort=version <<< "${imagearray[@]}") -n "${pic}"
    else
        swaymsg -- exec /usr/bin/imv-wayland $(sort --ignore-case --sort=version <<< "${pic[@]}")
    fi
}

__arc() {
    unset ISFILE
    cd $(dirname "${arc}")
    baseNameArc=$(basename "${arc}")
    if [ ${arc##*.} == "zip" ] ; then
        BUFFER="extract \"${baseNameArc}\""
    else
        mkdir "${${arc%%.*}##*/}" &&\
        cd "${${arc%%.*}##*/}" &&\
        BUFFER="extract ../\"${baseNameArc}\""
    fi
        zle .accept-line
}

__browser() {
    pkill -CONT $FIREFOXPROCESSES
    swaymsg -q -- [app_id=^firefox$] focus, exec /usr/bin/firefox --new-tab "$@"
}

_file_opener() {
    local IFS=$'\n'
    if [ -d "$1" ]; then
        cd "$1" > /dev/null 2>&1 && return 0
        echo "Permission denied"
        return 1
    fi

    for file in "$@"
    do
        [ -d ${file} ] && continue
        case "${(L)file##*.}" in
            zip|war|jar|sublime-package|ipsw|xpi|apk|aar|whl|gz|bz2|xz|lzma|z|7z|xz|bz2|tbz|gz|tgz)
                arc+=($file)
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
    [ ${#mov} -gt 0 ] && __mov
    [ ${#err} -gt 0 ] && print "Cannot open" ${err}
    [ ${#pdf} -gt 0 ] && swaymsg -q -- exec /usr/bin/zathura ${(q)pdf}
    [ ${#pic} -gt 0 ] && __pic
    [ ${#doc} -gt 0 ] && swaymsg -q --  exec /opt/sublime_text/sublime_text ${doc} \; [app_id=^(subl|sublime_text)$] focus\; [app_id=^(subl|sublime_text)$ workspace="^2λ$"] fullscreen enable
    [ ${#url} -gt 0 ] && __browser ${url} || grep -q 1 /sys/class/power_supply/AC0/online || pkill -STOP $FIREFOXPROCESSES
    unset arc mov err pdf pic url doc
}

