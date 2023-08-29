#!/bin/sh
config="/etc/background_mate/background_mate.conf";
config_home="$HOME/background_mate.conf";

function change_bg(){
    if [[ ! -z "$2" ]] && grep -Pq '^[0-9\.]+$' <<< "$2"; then
        time_sleep="$2";
    else
        time_sleep="15";
    fi
    if xdotool getwindowfocus getwindowname | grep -Pq '^Рабочий\ стол$'; then
        dconf write /org/mate/desktop/background/picture-filename "'$1'";
        sleep $time_sleep;
    else
        sleep 1;
    fi
}

function sequentially(){
    config="/etc/background_mate/background_mate.conf";
    time_sleep="$1";
    file ~/Изображения/* | grep -Pv "directory" |
                           awk -F: '{print $1}' | sort -R | while read file; do
        conf_md5="$(md5sum "$config" | awk '{print $1}')";
        change_bg "$file" $time_sleep;
        conf_md5_now="$(md5sum "$config" | awk '{print $1}')";
        if [[ "$conf_md5_now" != "$conf_md5" ]]; then break; fi
    done
}

function random_image(){
    prev_file_regexp="$1";
    time_sleep=$2;
    file="$(file ~/Изображения/* | grep -Pv "directory$prev_file_regexp" |
                                   awk -F: '{print $1}' | sort -R | tail -n1)";
    change_bg "$file" $time_sleep;
}

while true; do
    time_sleep=""; random="";
    if [[ -e "$config_home" ]]; then source "$config_home";
    elif [[ -e "$config" ]]; then source "$config";
    fi
    if [[ ! -z "$1" ]] && grep -Pq '^[0-9\.]+$' <<< "$1"; then
        time_sleep="$1";
    elif [[ ! -z "$2" ]] && grep -Pq '^[0-9\.]+$' <<< "$2"; then
        time_sleep="$2";
    elif grep -Pq '^[0-9\.]+$' <<< "$time_sleep"; then
        time_sleep="$time_sleep";
    else
        time_sleep="15";
    fi
    if grep -Piq '\-\-random=false|\-r *no|\-r *false' <<< "$*"; then
        sequentially "$time_sleep";
    elif grep -Piq '\-\-random|\-r' <<< "$*"; then
        prev_file="$file";
        if ! grep -Pq '^$' <<< $prev_file; then prev_file_regexp="|$prev_file";
        else prev_file_regexp="";
        fi
        random_image "$prev_file_regexp" $time_sleep;
    elif grep -Piq 'true' <<< "$random"; then
        prev_file="$file";
        if ! grep -Pq '^$' <<< $prev_file; then prev_file_regexp="|$prev_file";
        else prev_file_regexp="";
        fi
        random_image "$prev_file_regexp" $time_sleep;
    else
        sequentially "$time_sleep";
    fi
done