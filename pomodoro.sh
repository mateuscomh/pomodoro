#!/usr/bin/env bash

#---------------------------------------------------------------------------|
# AUTOR             : Matheus Martins <3mhenrique@gmail.com>
# HOMEPAGE          : https://github.com/mateuscomh/pomodoro
# DATE/VER.         : 28/02/2023 2.2
# LICENCE           : GPL3
# SHORT DESC        : Pomodoro notify-send GNU/LINUX
# DEPS              : notify-send >= 0.7.9
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
P_COUNT=0

#PRINT ASCII ART
function show_help {
  cat <<EOF

Running Options:

  h) Display help usage.
  p) Pause/continue Pomodoro timer.
  c) Continue Pomodoro timer.
  s) Skip current session
  q) Exit Pomodoro timer.

Description:
A pomodoro timer that alternates work sessions and break sessions.
Here used a notify-send on GNU/Linux to keep look on timer always

┏┓        ┓
┃┃┏┓┏┳┓┏┓┏┫┏┓┏┓┏┓
┣┛┗┛┛┗┗┗┛┗┻┗┛┛ ┗┛

EOF
}

show_help

function show_notification() {
  local remaining_minutes=$(($1 / 60))
  local remaining_seconds=$(($1 % 60))
  notify-send -t 1006 -h int:transient:1 --urgency=$P_NOTIFY "$P_MODE Pomodoro Timer: Session $P_COUNT/$P_TOTAL" \
    \ "$(printf "%02d:%02d" $remaining_minutes $remaining_seconds) remaining"
}

function play_pause() {
  read -r -s -n 1 -t 0.0001 key
  case $key in
  [Pp])
    paused=true
    notify-send --urgency=critical -t 5000 "Pomodoro Paused"
    P_NOTIFY="critical"
    while $paused; do
      show_notification $remaining_time
      read -r -n 1 -s -t 0.0001 key
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
    show_notification $remaining_time
    play_pause
    remaining_time=$(($remaining_time - 1))
  done
}

function wait_key {
  trap 'echo "Pomodoro interrupted by user"; notify-send "Pomodoro interrupted by user"; exit 1' INT
  echo "Press 'C' to continue or 'Q' to interrupt Session: $P_COUNT/$P_TOTAL $P_MODE"
  notify-send --urgency=critical "Press 'C' to continue or 'Q' to interrupt \
  Session: $P_COUNT/$P_TOTAL $P_MODE"
  read -r -n 1 -s -r -p "" input
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

while true; do
  P_COUNT=$(($P_COUNT + 1))
  session_duration=$P_DURATION
  P_NOTIFY="low"
  P_MODE="Work Mode"
  remaining_time=$session_duration
  paused=false
  main_timer
  wait_key

  notify-send -t 5000 --urgency=critical "Pomodoro Timer: Session $P_COUNT/$P_TOTAL ""\
Starting $(($session_duration / 60)) minute session"

  if [[ $(($P_COUNT % $P_TOTAL)) -eq 0 ]]; then
    remaining_time=$LONG_BREAK_DURATION
    P_NOTIFY="critical"
    P_MODE="Long Break"
    while [[ $remaining_time -gt 0 ]]; do
      show_notification $remaining_time
      play_pause
      remaining_time=$(($remaining_time - 1))
    done
  fi

  notify-send "Pomodoro Timer" "$(($session_duration / 60)) minute session $(($P_COUNT)) complete"

  if [[ "$P_COUNT" != "$P_TOTAL" ]]; then
    remaining_time=$SHORT_BREAK_DURATION
    P_NOTIFY="normal"
    P_MODE="Short Break"
  fi

  main_timer
  wait_key

  if [[ $P_COUNT -eq $P_TOTAL ]]; then
    notify-send --urgency=critical "ALL $P_COUNT/$P_TOTAL CICLE POMODORO OVER"
    exit 0
  fi
done
