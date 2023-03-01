#!/bin/bash

# Set the duration of each Pomodoro session (in seconds)
P_DURATION=1500   # 25 minutes

# Set the duration of the short break (in seconds)
SHORT_BREAK_DURATION=300  # 5 minutes

# Set the duration of the long break (in seconds)
LONG_BREAK_DURATION=900   # 15 minutes

# Set the number of Pomodoro sessions before a long break
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
    # Increment the Pomodoro counter
    P_COUNT=$(($P_COUNT + 1))

    # Determine the duration of the current session
    if [[ $(($P_COUNT % $P_TOTAL)) -eq 0 ]]; then
        session_duration=$LONG_BREAK_DURATION
        P_NOTIFY="critical"
        P_MODE="Long Break"
    else
        session_duration=$P_DURATION
        P_NOTIFY="low"
        P_MODE=""
    fi

    # Display the start notification
    notify-send -e -t 5000 --urgency=critical "Pomodoro Timer: Session $P_COUNT" "Starting $(($session_duration)) minute session"

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
#            notify-send -e -t 1013  "Pomodoro Timer" "Taking a $(($SHORT_BREAK_DURATION / 60)) minute break"
            show_notification $remaining_time
            sleep 1
            remaining_time=$(($remaining_time - 1))
        done
done
