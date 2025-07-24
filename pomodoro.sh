#!/usr/bin/env bash

#---------------------------------------------------------------------------|
# AUTOR         : Matheus Martins <3mhenrique@gmail.com>
# HOMEPAGE      : https://github.com/mateuscomh/pomodoro
# DATE/VER.     : 28/02/2023 2.3
# LICENCE       : GPL3
# SHORT DESC    : Pomodoro notify-send GNU/LINUX
# DEPS          : notify-send >= 0.7.9
#---------------------------------------------------------------------------|
if ! command -v notify-send &>/dev/null; then
    echo "The 'notify-send' ver. >= 0.7.9 command is not installed. Please install it and try again."
    exit 1
fi

# Duration of each Pomodoro session (in seconds)
P_DURATION=1500 # 25 minutes

# Duration of the short break (in seconds)
SHORT_BREAK_DURATION=300 # 5 minutes

# Duration of the long break (in seconds)
LONG_BREAK_DURATION=900 # 15 minutes

# Number of Pomodoro sessions before a long break
P_TOTAL=4

# Initialize the Pomodoro counter
P_COUNT=1

#PRINT ASCII ART
function show_help {
    cat <<EOF
┏┓      ┓
┃┃┏┓┏┳┓┏┓┏┫┏┓┏┓┏┓
┣┛┗┛┛┗┗┗┛┗┻┗┛┛ ┗┛

Running Options:
  p) Pause/continue Pomodoro timer.
  c) Continue Pomodoro timer.
  s) Skip current session
  q) Exit Pomodoro timer.
EOF
}

function show_notification() {
    local remaining_minutes=$(($1 / 60))
    local remaining_seconds=$(($1 % 60))
    notification_id="$BASHPID"
    notify-send -r "$notification_id" -t 2000 --urgency="$P_NOTIFY" \
    "$P_MODE Pomodoro Timer: Session $P_COUNT/$P_TOTAL" \
    "$(printf "%02d:%02d" "$remaining_minutes" "$remaining_seconds") remaining"
}

function play_pause() {
    read -r -s -n 1 -t 0.0001 key > /dev/null
    case $key in
    [Pp])
        paused=true
        notify-send --urgency=critical -t 5000 "Pomodoro Paused"
        P_NOTIFY="critical"
        while $paused; do
            show_notification "$remaining_time"
            read -r -s -n 1 -t 0.0001 key
            case $key in
            [CcPp])
                paused=false
                notify-send "Pomodoro Resumed"
                P_NOTIFY="low"
                ;;
            [Qq])
                notify-send --urgency=critical -t 5000 "Pomodoro Quit"
                echo "bye.."
                exit 0
                ;;
            esac
            sleep 1
        done
        ;;
    [Ss])
        notify-send --urgency=critical -t 1999 "Skiped session $P_COUNT/$P_TOTAL $P_MODE"
        remaining_time=0
        ;;
    [Qq])
        notify-send --urgency=critical -t 5000 "Pomodoro Quit"
        echo "bye.."
        exit 0
        ;;
    [Hh?*])
        show_help
        ;;
    esac
    sleep 1
}

function main_timer() {
    trap 'echo "Pomodoro interrupted by user"; notify-send "Pomodoro interrupted by user"; exit 1' INT
    while [[ $remaining_time -gt 0 ]]; do
        show_notification "$remaining_time"
        play_pause
        remaining_time=$((remaining_time - 1))
    done
}

function wait_key {
    trap 'echo "Pomodoro interrupted by user"; notify-send "Pomodoro interrupted by user"; exit 1' INT
    echo "Press 'C' to continue or 'Q' to interrupt Session: $P_COUNT/$P_TOTAL $P_MODE"
    notify-send --urgency=critical "Press 'C' to continue or 'Q' to interrupt \
  Session: $P_COUNT/$P_TOTAL $P_MODE"
    read -r -n 1 -s -p "" input
    case $input in
    [cC])
        echo "Continuing Pomodoro cycle execution..."
        notify-send "Continuing Pomodoro cycle execution"
        ;;
    [qQ])
        echo "Exiting Pomodoro..."
        notify-send "Pomodoro terminated by user"
        exit 0
        ;;
    *)
        wait_key
        ;;
    esac
}

# Main
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi

show_help

while [[ $P_COUNT -le $P_TOTAL ]]; do
    # --- Inicia a sessão de TRABALHO ---
    P_MODE="Work Mode"
    P_NOTIFY="low"
    remaining_time=$P_DURATION
    paused=false
    
    notify-send -t 5000 --urgency=normal "Pomodoro Timer: Iniciando Sessão de Trabalho $P_COUNT/$P_TOTAL"
    main_timer
    wait_key

    if [[ $P_COUNT -eq $P_TOTAL ]]; then
        P_MODE="Long Break"
        P_NOTIFY="critical"
        remaining_time=$LONG_BREAK_DURATION
        notify-send --urgency=critical "Sessão de trabalho finalizada! Iniciando Pausa Longa."
        main_timer
    else
        P_MODE="Short Break"
        P_NOTIFY="normal"
        remaining_time=$SHORT_BREAK_DURATION
        notify-send --urgency=normal "Sessão de trabalho finalizada! Iniciando Pausa Curta."
        main_timer
    fi
    
    if [[ $P_COUNT -lt $P_TOTAL ]]; then
      wait_key
    fi

    P_COUNT=$((P_COUNT + 1))
done

notify-send --urgency=critical "TODOS OS $P_TOTAL CICLOS POMODORO FORAM CONCLUÍDOS!"
echo "Ciclos Pomodoro finalizados. Parabéns!"
exit 0
