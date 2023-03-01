#!/usr/bin/env bash

#---------------------------------------------------------------------------|
# AUTOR             : Matheus Martins <3mhenrique@gmail.com>
# HOMEPAGE          : https://github.com/mateuscomh/pomodoro
# DATE/VER.         : 28/02/2023 1.0
# LICENCE           : GPL3
# SHORT DESC        : Pomodoro notify-send GNU/LINUX
# DEPS              : notify-send
#---------------------------------------------------------------------------|

# Duration of each Pomodoro session (in seconds)
P_DURATION=1500   # 25 minutes

# Duration of the short break (in seconds)
SHORT_BREAK_DURATION=300  # 5 minutes

# Duration of the long break (in seconds)
LONG_BREAK_DURATION=900   # 15 minutes

# Number of Pomodoro sessions before a long break
P_TOTAL=4

# Initialize the Pomodoro counter
P_COUNT=0

# Define a function to display a notification with the remaining time
function show_notification() {
    local remaining_minutes=$(($1 / 60))
    local remaining_seconds=$(($1 % 60))
    notify-send -e -r 10 --urgency=$P_NOTIFY "$P_MODE Pomodoro Timer: Session $P_COUNT" "$(printf "%02d:%02d" $remaining_minutes $remaining_seconds) remaining"
}

# Start the timer loop
while true; do
    # Display the start notification
    notify-send -e -t 5000 --urgency=critical "Pomodoro Timer: Session $P_COUNT" "Starting $(($session_duration / 60)) minute session"

    # Increment the Pomodoro counter
    P_COUNT=$(($P_COUNT + 1))

    # Duration of the current session
    if [[ $(($P_COUNT % $P_TOTAL)) -eq 0 ]]; then
        session_duration=$LONG_BREAK_DURATION
        P_NOTIFY="critical"
        P_MODE="Long Break"
    else
        session_duration=$P_DURATION
        P_NOTIFY="low"
        P_MODE=""
    fi

    # Start the timer
    remaining_time=$session_duration
    while [[ $remaining_time -gt 0 ]]; do
        show_notification $remaining_time
        sleep 1
        remaining_time=$(($remaining_time - 1))
    done

    # Display the end notification
    notify-send "Pomodoro Timer" "$(($session_duration)) minute session $(($P_COUNT)) complete"

    # Take a short break if necessary
        remaining_time=$SHORT_BREAK_DURATION
        P_NOTIFY="normal"
        P_MODE="Short Break"
        while [[ $remaining_time -gt 0 ]]; do
            show_notification $remaining_time
            sleep 1
            remaining_time=$(($remaining_time - 1))
        done
done
