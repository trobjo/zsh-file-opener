
alias ${_ZSH_FILE_OPENER_CMD:-u}='_file_opener'

if [[ $SSH_TTY ]]; then

    if ! command -v rmate &> /dev/null; then
        print -P "%F{5}Installing %F{33}rmate%F{5} helper for Sublime Text…%f"
        curl --silent -o $HOME/.local/bin/rmate https://raw.githubusercontent.com/aurora/rmate/master/rmate &&\
        chmod +x $HOME/.local/bin/rmate &&\
        print -P "%F{2}%{\e[3m%}rmate Installed.%f%b"
    fi

    _file_opener() {
        cd "$@" > /dev/null 2>&1 && return 0
        touch "$@" > /dev/null 2>&1 && $HOME/.local/bin/rmate "$@" || sudo $HOME/.local/bin/rmate "$@"
    }
else

if [[ $HOST == "MateBookXPro" ]] ; then
    STOPFIREFOX="grep -q 1 /sys/class/power_supply/AC0/online || pkill -STOP \$FIREFOXPROCESSES"
    CONTFIREFOX="pkill -CONT \$FIREFOXPROCESSES"
    SUBLFOCUS='[app_id=^subl$] focus; [app_id=^subl$ workspace="^2λ$"] fullscreen enable'
else
    swaycmd=""
    SUBLFOCUS='[app_id=^subl$] focus'
fi

__mov() {
    if [[ $HOST == "MateBookXPro" ]] ; then
        if grep -q 'enabled' /sys/class/drm/card0-DP-1/enabled
        then
            if grep -q 'Discharging' /sys/class/power_supply/BAT0/status
            then
                swaymsg "output eDP-1 disable"
                /usr/bin/mpv --fullscreen --audio-device=alsa/hdmi:CARD=PCH,DEV=0 ${mov} ; swaymsg "output eDP-1 enable"
            else
                /usr/bin/mpv --fullscreen --audio-device=alsa/hdmi:CARD=PCH,DEV=0 ${mov}
            fi
        return 0
        fi
    fi
    # (grep -q 'enabled' /sys/class/drm/card0-DP-1/enabled && output="--audio-device=alsa/iec958:CARD=Audio,DEV=0"
     readlink /sys/bus/hid/devices/0003:047F:02F7* && output="--audio-device=alsa/iec958:CARD=BT600,DEV=0"
     /usr/bin/mpv --fullscreen $output ${mov}
}

__pic() {
    if [ ${#pic[@]} -eq 1 ]
    then
        setopt local_options dotglob
        dirname=$(dirname "${pic}")
        imagearray=("$dirname"/*.(jpeg|jpg|png|webp|svg|gif|bmp|tif|tiff|psd))
        cd "$dirname"
        /usr/bin/imv-wayland $(sort --ignore-case --sort=version <<< "${imagearray[@]##*/}") -n "${pic##*/}"
    else
        /usr/bin/imv-wayland $(sort --ignore-case --sort=version <<< "${pic[@]}")
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
    eval ${CONTFIREFOX}
    firefox-nightly --new-tab "$@"
    swaymsg '[app_id=^firefox$] focus'
}

_file_opener() {
    local IFS=$'\n'
    cd "$@" > /dev/null 2>&1 && return 0


    for file in "$@"
    do
        [ -d ${file} ] && continue
        case "${(L)file##*.}" in
            zip|war|jar|sublime-package|ipsw|xpi|apk|aar|whl|gz|bz2|xz|lzma|z|7z|xz|bz2|tbz|gz|tgz)
                arc+=($file)
                ;;
            mkv|mp4|mov|mp3|avi|mpg|m4v|oga|m4a)
                swaymsg '[app_id=mpv] focus' > /dev/null 2>&1 || mov+=($file)
                ;;
            pdf|epub|djvu)
                swaymsg "[app_id=\"^org.pwmt.zathura$\" title=\"^${(q)file##*/}\ \[\"] focus" > /dev/null 2>&1 || pdf+=($file)
                ;;
            jpeg|jpg|png|webp|svg|gif|bmp|tif|tiff|psd)
                pic+=($file)
                ;;
            otf|ttf|iso)
                err+=($file)
                ;;
            html|mhtml)
                url+=($file)
                ;;
            *)
                doc+=($file)
                ;;
        esac
    done
    [[ ${#arc} -eq 1 && "${#@}" -eq 1 ]] && __arc
    [ -z ${err} ] && [[ ${#arc} -ne 1 ]] && swaymsg '[app_id=^PopUp$] move scratchpad'
    [ ${#mov} -gt 0 ] && (__mov &) > /dev/null 2>&1
    [ ${#err} -gt 0 ] && print "Cannot open" ${err}
    [ ${#pdf} -gt 0 ] && (/usr/bin/zathura $pdf &) > /dev/null 2>&1
    [ ${#pic} -gt 0 ] && (__pic &) > /dev/null 2>&1
    [ ${#doc} -gt 0 ] && /opt/sublime_text/sublime_text ${doc} && swaymsg "$SUBLFOCUS" > /dev/null 2>&1
    [ ${#url} -gt 0 ] && (__browser ${url} & ) > /dev/null 2>&1 || eval ${STOPFIREFOX}
    unset arc mov err pdf pic url doc
}

fi
