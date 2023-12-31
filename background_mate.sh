#!/bin/sh

function change_bg(){
    img="$1";
    time_sleep="$2";
    config="$3";
    time_sleep_sec="$(echo "$time_sleep" | sed 's/\([0-9]\+\)h/\1*3600\+/g;s/\([0-9]\+\)m/\1*60\+/g;s/s//g;s/+$//' | bc)";
    for (( c=1; c<=$time_sleep_sec; c++ )) do
        [[ ! -z "$config" ]] && conf_md5="$(md5sum "$config" | awk '{print $1}')";
        sleep 1;
        [[ ! -z "$config" ]] && conf_md5_now="$(md5sum "$config" | awk '{print $1}')";
        if [[ "$conf_md5_now" != "$conf_md5" ]]; then break 2; fi
    done
    if xdotool getwindowfocus getwindowname | grep -Pq '^Рабочий\ стол$'; then
        dconf write /org/mate/desktop/background/picture-filename "'$img'";
    fi
}

function sequentially(){
    time_sleep="$1";
    config="$2";
    file ~/Изображения/* | grep -Pv "directory" |
                           awk -F: '{print $1}' | sort -R | while read img; do
        [[ ! -z "$config" ]] && conf_md5="$(md5sum "$config" | awk '{print $1}')";
        change_bg "$img" $time_sleep "$config";
        [[ ! -z "$config" ]] && conf_md5_now="$(md5sum "$config" | awk '{print $1}')";
        if [[ "$conf_md5_now" != "$conf_md5" ]]; then break; fi
    done
}

function random_image(){
    prev_img_regexp="$1";
    time_sleep=$2;
    config="$3";
    img="$(file ~/Изображения/* | grep -Pv "directory$prev_img_regexp" |
                                   awk -F: '{print $1}' | sort -R | tail -n1)";
    change_bg "$img" $time_sleep "$config";
}

while true; do
    time_sleep=""; random="";
    if [[ -e "$HOME/background_mate.conf" ]] &&
       grep -Pq '[a-zA-Z_]+=[a-zA-Z0-9\.]+' "$HOME/background_mate.conf"; then
        export config="$HOME/background_mate.conf";
    elif [[ -e "/etc/background_mate/background_mate.conf" ]] &&
       grep -Pq '[a-zA-Z_]+=[a-zA-Z0-9\.]+' "/etc/background_mate/background_mate.conf"; then
        export config="/etc/background_mate/background_mate.conf";
    fi

    if [[ ! -z "$config" ]] && [[ -e "$config" ]]; then source "$config"; fi
    if [[ ! -z "$1" ]] && grep -Pq '^[0-9\.]+$' <<< "$1"; then
        time_sleep="$1";
    elif [[ ! -z "$2" ]] && grep -Pq '^[0-9\.]+$' <<< "$2"; then
        time_sleep="$2";
    elif grep -Pq '^[0-9\.]+$' <<< "$time_sleep"; then # from background_mate.conf
        time_sleep="$time_sleep";
    else
        time_sleep="15";
    fi
    if grep -Piq '\-\-random=false|\-r *no|\-r *false' <<< "$*"; then
        sequentially "$time_sleep" "$config";
    elif grep -Piq '\-\-random|\-r' <<< "$*"; then
        prev_img="$img";
        if ! grep -Pq '^$' <<< $prev_img; then prev_img_regexp="|$prev_img";
        else prev_img_regexp="";
        fi
        random_image "$prev_img_regexp" $time_sleep "$config";
    elif grep -Piq 'true' <<< "$random"; then
        prev_img="$img";
        if ! grep -Pq '^$' <<< $prev_img; then prev_img_regexp="|$prev_img";
        else prev_img_regexp="";
        fi
        random_image "$prev_img_regexp" $time_sleep "$config";
    else
        sequentially "$time_sleep" "$config";
    fi
done
