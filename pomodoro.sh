#!/usr/bin/env bash

#---------------------------------------------------------------------------|
# AUTOR         : Matheus Martins <3mhenrique@gmail.com>
# HOMEPAGE      : https://github.com/mateuscomh/pomodoro
# DATE/VER.     : 28/02/2023 4.0
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

NOTIFY_ID="$BASHPID"
# ------------------------------------------------------------------------------

read_int_default_minutes() {
  local prompt="$1"
  local default_min="$2"
  local input
  while true; do
    read -r -p "$prompt [padrão ${default_min}]: " input
    if [[ -z "$input" ]]; then
      echo "$default_min"
      return 0
    fi
    if [[ "$input" =~ ^[0-9]+$ ]] && (( input > 0 )); then
      echo "$input"
      return 0
    fi
    echo "Input Error: Insert the number integer greather than zero or press enter for defaul"
  done
}

interactive_config() {
  echo
  echo "Set Pomodoro timer (Insert values in minutes) Enter set default:"
  local cur_work_min=$((P_DURATION / 60))
  local cur_short_min=$((SHORT_BREAK_DURATION / 60))
  local cur_long_min=$((LONG_BREAK_DURATION / 60))
  local cur_cycles=$((P_TOTAL))

  local work_min
  local short_min
  local long_min
  local cycles

  work_min=$(read_int_default_minutes "Focus time: (min)" "${cur_work_min}")
  short_min=$(read_int_default_minutes "Short pause (min)" "${cur_short_min}")
  long_min=$(read_int_default_minutes "Long pause (min)" "${cur_long_min}")

  while true; do
    read -r -p "Cicle before long pause [default: ${cur_cycles}]: " cycles
    if [[ -z "$cycles" ]]; then
      cycles=${cur_cycles}
      break
    fi
    if [[ "$cycles" =~ ^[0-9]+$ ]] && (( cycles > 0 )); then
      break
    fi
    echo "Input Error: Insert the number integer greather than zero or press enter for defaul"
  done

  P_DURATION=$((work_min * 60))
  SHORT_BREAK_DURATION=$((short_min * 60))
  LONG_BREAK_DURATION=$((long_min * 60))
  P_TOTAL=$((cycles))

  echo
  echo "Configuration temporaly updated:"
  echo "  Focus: ${work_min} minute(s)"
  echo "  Short Pause: ${short_min} minute(s)"
  echo "  Long Pause: ${long_min} minute(s)"
  echo "  Cicles until the Long Pause: ${P_TOTAL}"
  echo

  # Opcional: salvar em arquivo para persistir entre execuções:
  # CONFIG_FILE="${HOME}/.pomodororc"
  # read -r -p "Deseja salvar estas preferências em ${CONFIG_FILE}? (s/N): " __save
  # if [[ "$__save" =~ ^[Ss]$ ]]; then
  #   cat > "$CONFIG_FILE" <<EOF
  # WORK=${work_min}
  # SHORT=${short_min}
  # LONG=${long_min}
  # CYCLES=${cycles}
  # EOF
  #   echo "Preferências salvas em ${CONFIG_FILE}."
  # fi
}
# ----------------------------------------------------------------------------------------------

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

format_mmss() {
  local total=$1
  local mm=$(( total / 60 ))
  local ss=$(( total % 60 ))
  printf "%02d:%02d" "$mm" "$ss"
}

function show_notification() {
	local remaining_minutes=$(($1 / 60))
	local remaining_seconds=$(($1 % 60))
	local time_str
	time_str=$(format_mmss "$1")
	notification_id="${NOTIFY_ID}"

	notify-send -r "$notification_id" -t 2000 --urgency="$P_NOTIFY" \
		"$P_MODE Pomodoro Timer: Session $P_COUNT/$P_TOTAL" \
		"$(printf "%02d:%02d" "$remaining_minutes" "$remaining_seconds") remaining"

	printf "\r%s Pomodoro Timer: Session %s/%s — %s remaining" "$P_MODE" "$P_COUNT" "$P_TOTAL" "$time_str"
	# força flush (alguns terminais precisam)
	printf ""
}

function play_pause() {
	read -r -s -n 1 -t 0.0001 key >/dev/null
	case $key in
	[Pp])
		paused=true
		notify-send -r "$NOTIFY_ID" --urgency=critical -t 5000 "Pomodoro Paused"
		P_NOTIFY="critical"
		while $paused; do
			show_notification "$remaining_time"
			read -r -s -n 1 -t 0.0001 key
			case $key in
			[CcPp])
				paused=false
				notify-send -r "$NOTIFY_ID" -t 3000 "Pomodoro Resumed"
				P_NOTIFY="low"
				;;
			[Qq])
				notify-send -r "$NOTIFY_ID" -t 3000 --urgency=critical "Pomodoro Quit"
				echo "bye.."
				exit 0
				;;
			esac
			sleep 1
		done
		;;
	[Ss])
		notify-send -r "$NOTIFY_ID" --urgency=critical -t 1999 "Skiped session $P_COUNT/$P_TOTAL $P_MODE"
		remaining_time=0
		;;
	[Qq])
		notify-send -r "$NOTIFY_ID" --urgency=critical -t 5000 "Pomodoro Quit"
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
	trap 'echo "Pomodoro interrupted by user"; notify-send -r "$NOTIFY_ID" "Pomodoro interrupted by user"; exit 1' INT
	while [[ $remaining_time -gt 0 ]]; do
		show_notification "$remaining_time"
		play_pause
		remaining_time=$((remaining_time - 1))
	done
	printf "\n"
}

function wait_key {
	trap 'echo "Pomodoro interrupted by user"; notify-send -r "$NOTIFY_ID" "Pomodoro interrupted by user"; exit 1' INT
	echo "Press 'C' to continue or 'Q' to interrupt Session: $P_COUNT/$P_TOTAL $P_MODE"

	notify-send -r "$NOTIFY_ID" --urgency=critical -t 0 "Press 'C' to continue or 'Q' to interrupt" \
	  "Session: $P_COUNT/$P_TOTAL $P_MODE"

	read -r -n 1 -s -p "" input
	case $input in
	[cC])
		echo "Continuing Pomodoro cycle execution..."
		notify-send -r "$NOTIFY_ID" -t 3000 --urgency=low "Continuing Pomodoro cycle execution"
		;;
	[qQ])
		echo "Exiting Pomodoro..."
		notify-send -r "$NOTIFY_ID" -t 3000 "Pomodoro terminated by user"
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

read -r -p "Edit default timer before start? (y/N): " __resp_edit
if [[ "$__resp_edit" =~ ^[Yy]$ ]]; then
  interactive_config
fi

show_help

while [[ $P_COUNT -le $P_TOTAL ]]; do
	# --- Inicia a sessão de TRABALHO ---
	P_MODE="Work Mode"
	P_NOTIFY="low"
	remaining_time=$P_DURATION
	paused=false

	# Notificação de início (curta)
	notify-send -r "$NOTIFY_ID" -t 5000 --urgency=normal "Pomodoro ShellTimer: Starting Work Session $P_COUNT/$P_TOTAL"
	main_timer
	wait_key

	if [[ $P_COUNT -eq $P_TOTAL ]]; then
		P_MODE="Long Break"
		P_NOTIFY="critical"
		remaining_time=$LONG_BREAK_DURATION
		notify-send -r "$NOTIFY_ID" --urgency=critical -t 0 "Work Session Finished! Starting Long Pause."
		main_timer
	else
		P_MODE="Short Break"
		P_NOTIFY="normal"
		remaining_time=$SHORT_BREAK_DURATION
		notify-send -r "$NOTIFY_ID" --urgency=normal -t 0 "Work Session Finished! Starting Short Pause."
		main_timer
	fi

	if [[ $P_COUNT -lt $P_TOTAL ]]; then
		wait_key
	fi

	P_COUNT=$((P_COUNT + 1))
done

notify-send -r "$NOTIFY_ID" --urgency=critical -t 0 "ALL POMODORO  $P_TOTAL CICLE HAS BEEN FINISHED!"
notify-send -r "$NOTIFY_ID" -t 3000 --urgency=low "Cicle Finished. Well Done!!"
echo "All Pomodo Cicle Finished! Well done!!!"
exit 0
