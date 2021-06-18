alias ${_ZSH_FILE_OPENER_CMD:-f}='_file_opener'

# If this env var is set, file_opener will not look suggest these files in the autocomplete menu
[[ $_ZSH_FILE_OPENER_EXCLUDE_SUFFIXES ]] &&\
zstyle ':completion:*:*:_file_opener:*' file-patterns "^*.(${_ZSH_FILE_OPENER_EXCLUDE_SUFFIXES//,/|}):source-files" '*:all-files'

_file_opener() {
    typeset -aU arcs movs pdfs pics urls docs

    [[ -d "$@" ]] && cd "${@:--}" > /dev/null 2>&1 && return 0
    [[ -e "$1" ]] && [[ ! -r "$1" ]] && print "Permission denied: $1" && return 1

    for file in "$@"
    do
        [[ -d ${file} ]] && continue
        case "${file:e:l}" in
            (gz|tgz|bz2|tbz|tbz2|xz|txz|zma|tlz|zst|tzst|tar|lz|gz|bz2|xz|lzma|z|zip|war|jar|sublime-package|ipsw|xpi|apk|aar|whl|rar|rpm|7z|deb|zs)
                arcs+=(${file:a})
                [[ "${#@}" -eq 2 ]] && [[ ! -e "$2" ]] && { local extract_dir="$2"; break } ;;
            (mkv|mp4|movs|mp3|avi|mpg|m4v|oga|m4a|m4b|opus)
                swaymsg -q '[app_id=mpv] focus' || movs+=("${file:a:q}") ;;
            (pdf|epub|djvu)
                swaymsg -q "[app_id=\"^org.pwmt.zathura$\" title=\"^${(q)file##*/}\ \[\"] focus" || pdfs+=("${file:a:q}") ;;
            (jpeg|jpg|png|webp|svg|gif|bmp|tif|tiff|psd)
                pics+=("${file:a:q}") ;;
            (otf|ttf|iso|mobi|dll)
                print "Cannot open \x1B[36m${file##*/}\033[0m" && local ret=1 ;;
            (html|mhtml)
                urls+=("${file:a:q}") ;;
            (*)
                docs+=("${file:a:q}") ;;
        esac
    done

    [[ ${arcs} ]] && {
        local pwd="$PWD"
        typeset -aU extract_msg

        for arc in ${arcs[@]}; do
            if [[ "${#arcs}" -ne 1 ]] || [[ -z $extract_dir ]]; then
                local extract_dir="${pwd}/${${arc:t}%%.*}"
            fi
            [[ -e "$extract_dir" ]] && { extract_msg+="\n\x1B[34m\x1B[3m${${extract_dir}/${HOME}/~}\033[0m already exists"; local ret=1; continue }
            mkdir -p "$extract_dir"
            cd "$extract_dir"
            case "${arc:l}" in
                (*.tar.gz|*.tgz) (( $+commands[pigz] )) && { pigz -dc "$arc" | tar xv } || tar zxvf "$arc" ;;
                (*.tar.bz2|*.tbz|*.tbz2) tar xvjf "$arc" ;;
                (*.tar.xz|*.txz)
                    tar --xz --help &> /dev/null \
                    && tar --xz -xvf "$arc" \
                    || xzcat "$arc" | tar xvf - ;;
                (*.tar.zma|*.tlz)
                    tar --lzma --help &> /dev/null \
                    && tar --lzma -xvf "$arc" \
                    || lzcat "$arc" | tar xvf - ;;
                (*.tar.zst|*.tzst)
                    tar --zstd --help &> /dev/null \
                    && tar --zstd -xvf "$arc" \
                    || zstdcat "$arc" | tar xvf - ;;
                (*.tar) tar xvf "$arc" ;;
                (tar.lz) (( $+commands[lzip] )) && tar xvf "$arc" ;;
                (*.gz) (( $+commands[pigz] )) && pigz -dk "$arc" || gunzip -k "$arc" ;;
                (*.bz2) bunzip2 "$arc" ;;
                (*.xz) unxz "$arc" ;;
                (*.lzma) unlzma "$arc" ;;
                (*.z) uncompress "$arc" ;;
                (*.zip|*.war|*.jar|*.sublime-package|*.ipsw|*.xpi|*.apk|*.aar|*.whl) unzip "$arc" ;;
                (*.rar) unrar x -ad "$arc" ;;
                (*.rpm) rpm2cpio "../$arc" | cpio --quiet -id ;;
                (*.7z) 7za x "$arc" ;;
                (*.deb)
                    mkdir -p "control"
                    mkdir -p "data"
                    ar vx "../${arc}" > /dev/null
                    cd control; tar xzvf ../control.tar.gz
                    cd ../data; extract ../data.tar.*
                    cd ..; rm *.tar.* debian-binary
                    cd ..
                ;;
                (*.zst) unzstd "$arc" ;;
                (*)
                    print "Wrong file type: '$arc' "
                    local ret=1
                    rmdir -p --ignore-fail-on-non-empty "$extract_dir"
                    cd "$pwd"
                    continue
                ;;
            esac
            all_files=(*(ND))
            # move extracted archive if it only contains 1 dir
            if [[ ${#all_files[@]} -eq 1 ]] && [[ -d "${all_files}" ]]; then
                mv "${all_files}/"*(D) . && rmdir "${all_files}"
            fi
            extract_msg+=("\nExtracted \x1B[33m${arc/${HOME}/~}\033[0m -> \x1B[34m\033[3m${extract_dir/${HOME}/~}\033[0m")
        done

        if [[ "${#arcs}" -gt 1 ]] || [[ $ret -eq 1 ]]; then
            cd "$pwd"
            print ${extract_msg}
        fi
    } < $TTY || [[ ${ret} ]] || swaymsg -q -- [app_id=^PopUp$] move scratchpad


    [[ ${movs} ]] && {
        grep -q 'enabled' /sys/class/drm/{card0-DP-1,card0-DP-2,card0-HDMI-A-1}/enabled\
        && grep -q 'Discharging' /sys/class/power_supply/BAT0/status\
        && swaymsg -q output eDP-1 dpms off
        swaymsg -q -- exec \'/usr/bin/mpv --player-operation-mode=pseudo-gui ${movs} \; swaymsg output eDP-1 dpms on\'
    }

    [[ ${pdfs} ]] && swaymsg -q -- exec \'/usr/bin/zathura ${pdfs}\'

    [[ ${pics} ]] && {
        [[ ${#pics} -eq 1 ]] && swaymsg -q -- exec \'/usr/bin/imv-wayland ${pics%/*} -n "${pics}"\' ||\
        swaymsg -q -- exec \'/usr/bin/imv-wayland ${pics}\'
    }

    [[ ${docs} ]] && swaymsg -q -- exec \'/opt/sublime_text/sublime_text ${docs}\' \; [app_id=^sublime_text$] focus\; [app_id="^sublime_text$" workspace="^2$"] fullscreen enable

    [[ ${urls} ]] && {
        pkill -CONT $FIREFOXPROCESSES
        swaymsg -q -- exec \'/usr/bin/firefox ${urls[@]/#/--new-tab }\' \; [app_id=^firefox$] focus\; [app_id="^firefox$" workspace="^3$"] fullscreen enable
    } || grep -q 1 /sys/class/power_supply/AC0/online || pkill -STOP $FIREFOXPROCESSES

    return ${ret:-0}

}
