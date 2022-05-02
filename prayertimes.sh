#!/usr/bin/env bash

BINARY_LOCATION=/usr/local/bin/prayertimes

if [[ ! -e $BINARY_LOCATION ]]; then
  echo "Downloading script.."
  sudo wget -O $BINARY_LOCATION https://raw.githubusercontent.com/hllvc/Vaktija.ba-Unix-Notifications/develop/prayertimes.sh
  echo "Setting permission.."
  sudo chmod 755 $BINARY_LOCATION
  exit 2
fi

OS="$(uname)"

CONFIG="$HOME/.prayerconfig"

API_URL="https://api.vaktija.ba/vaktija/v1"

__usage() {
  cat << EOF
    Usage:
      $(basename $0) OPTION <ARG>

    Where OPTIONs are:

      --clean                 Remove $HOME/.prayerconfig file (resets settings) and setup new config
      --view-config <ARG>     Show config file in stdout (default is cat, can use any other like vi, less, head, tail ...)
      --LANGUAGE <ARG>,
      -l <ARG>                Change output language (en or ba)

      --uninstall <ARG>       Unisntall binary file from $BINARY_LOCATION (pass argument all to also clean config data)

      --help, -h              Show this help menu
EOF
  exit 2
}

__get_town() {
  (( $LANGUAGE == 0 )) && printf "\nFetching list of towns..\n"
  (( $LANGUAGE == 1 )) && printf "\nDobavljamo listu gradova..\n"

  ## Explained nested/piped command below
  ## curl gets array of all locations from Vaktija.ba
  ## array is parsed with tr (translate characters) where we remove all occurences of [,",] characters
  ## again what is left are locations separated by comma (,), we parse again with tr and replace comma (,) with new line (\n)
  ## we then pipe list of locations with new line to nl (line numbering filter) where we say to start counting from 0, and to align left
  ## after that we pipe everything to fzf (fuzzy finder), now we have list of locations indexed with number from 0
  ## when we find desired location, we pipe it to cut (cutout selected portion) where we say to cut(out) first part, which is location number
  ## finally we tr left spaces so we get just number of location
  local LOCATION=`curl -fsSL "$API_URL/lokacije" | tr -d '["]' | tr ',' '\n' | nl -v 0 -n ln | fzf | cut -f 1 | tr -d [:space:]`

  sed -i '' -e "s/LOCATION=.*/LOCATION=$LOCATION/" $CONFIG
}

__initial_setup() {
  cat > $CONFIG <<EOF
  LANGUAGE=
  LOCATION=
EOF

  local LANGUAGES="English Bosanski"
  LANGUAGE=`echo $LANGUAGES | tr ' ' '\n' | nl -v 0 -n ln | fzf | cut -f 1 | tr -d [:space:]`

  (( $LANGUAGE == 0 )) && printf "\nSaving language choice to $CONFIG"
  (( $LANGUAGE == 1 )) && printf "\nSpremanje jezika u $CONFIG"
  sed -i '' -e "s/LANGUAGE=.*/LANGUAGE=$LANGUAGE/" $CONFIG

  __get_town
  __usage
}

__load_config() {
  [[ ! -e $CONFIG ]] && return 1

  LANGUAGE=`grep 'LANGUAGE=[0-1]' $CONFIG | cut -d"=" -f 2`
  LOCATION=`grep 'LOCATION=[0-90-90-9]' $CONFIG | cut -d"=" -f 2`
  # (( $LANGUAGE == 0 )) && echo $'\nContinuing setup..'
  # (( $LANGUAGE == 1 )) && echo $'\nNastavka konfiguracije..'

}

__load_config
(( $? == 1 )) && __initial_setup

for arg; do
  case ${arg} in
    "--clean")
      shift
      rm -r $CONFIG
      __initial_setup
      ;;
    "--view-config")
      shift
      if [[ -z $1 ]]; then
        cat $CONFIG
      else
        $* $CONFIG
      fi
      exit 0
      ;;
    "--lang" | "-l")
      shift
      if (( $# == 0 )); then
        LANGUAGES="English Bosanski"
        LANGUAGE=`echo $LANGUAGES | tr ' ' '\n' | nl -v 0 -n ln | fzf | cut -f 1 | tr -d [:space:]`
      elif [[ $1 == "en" ]]; then
        LANGUAGE=0
      elif [[ $1 == "ba" ]]; then
        LANGUAGE=1
      else
        __usage
      fi
      sed -i '' -e "s/LANGUAGE=[0-1]/LANGUAGE=$LANGUAGE/" $CONFIG
      break
      ;;
    "--uninstall")
      shift
      [[ $1 == all ]] && rm -r $CONFIG
      # sudo rm -rf $BINARY_LOCATION
      echo "sudo rm -rf $BINARY_LOCATION"
      exit 0
      ;;
    "--help" | "-h")
      __usage && exit 2
      ;;
      *)
        break
  esac
done

current_time="$(date +"%H:%M:%S")"
prayer_times=($(curl -fsSL "$API_URL/$LOCATION" | jq -r ".vakat[]"))

__check_if_passed_Darwin() {
  if ([[ $(date -j -f "%H:%M" "$1" +"%H") < $(date -j -f "%H:%M:%S" "$current_time" +"%H") ]] || \
    ( [[ $(date -j -f "%H:%M" "$1" +"%H") == $(date -j -f "%H:%M:%S" "$current_time" +"%H") ]] && [[ $(date -j -f "%H:%M" "$1" +"%M") < $(date -j -f "%H:%M:%S" "$current_time" +"%M") ]] )) && \
    [[ $1 == ${prayer_times[0]} ]] && [[ $(date -j -f "%H:%M" "${prayer_times[5]}" +"%H") < $(date -j -f "%H:%M:%S" "$current_time" +"%H") ]]; then
    return 2
  elif [[ $(date -j -f "%H:%M" "$1" +"%H") < $(date -j -f "%H:%M:%S" "$current_time" +"%H") ]] || \
    ( [[ $(date -j -f "%H:%M" "$1" +"%H") == $(date -j -f "%H:%M:%S" "$current_time" +"%H") ]] && [[ $(date -j -f "%H:%M" "$1" +"%M") < $(date -j -f "%H:%M:%S" "$current_time" +"%M") ]] ); then
    return 1
  fi
  return 0
}

__check_if_passed_Linux () {
	if ([[ $(date -d "$1" +"%H") < $(date -d "$current_time" +"%H") ]] || \
		( [[ $(date -d "$1" +"%H") == $(date -d "$current_time" +"%H") ]] && [[ $(date -d "$1" +"%M") < $(date -d "$current_time" +"%M") ]] )) && \
		[[ $1 == ${prayer_times[0]} ]] && [[ $(date -d "${prayer_times[5]}" +"%H") < $(date -d "$current_time" +"%H") ]]; then
		return 2
	elif [[ $(date -d "$1" +"%H") < $(date -d "$current_time" +"%H") ]] || \
		( [[ $(date -d "$1" +"%H") == $(date -d "$current_time" +"%H") ]] && [[ $(date -d "$1" +"%M") < $(date -d "$current_time" +"%M") ]] ); then
		return 1
	fi
	return 0
}

__Darwin () {
	for time in ${prayer_times[@]}; do
		__check_if_passed_$OS $time
		exit_code=$?

		curr_hours="$(date -j -f "%H:%M:%S" "$current_time" +"%_H")"
		curr_minutes="$(date -j -f "%H:%M:%S" "$current_time" +"%_M")"
		curr_seconds="$(date -j -f "%H:%M:%S" "$current_time" +"%_S")"

		if [[ $exit_code == 0 ]]; then
			prayer_hours="$(date -j -f "%H:%M" "$time" +"%_H")"
			prayer_minutes="$(date -j -f "%H:%M" "$time" +"%_M")"
			hours=$(($prayer_hours-$curr_hours))
			minutes=$(($prayer_minutes-$curr_minutes))
			while [[ $minutes < 0 ]]; do
				minutes=$((60+$minutes))
				hours=$(($hours-1))
			done
      if (( $minutes == 1 )) && (( $curr_seconds != 0 )); then
        seconds=$((60-$curr_seconds))
        minutes=$(($minutes-1))
      fi
			break
		elif [[ $exit_code == 2 ]]; then
			prayer_hours="$(date -j -f "%H:%M" "$time" +"%_H")"
			prayer_minutes="$(date -j -f "%H:%M" "$time" +"%_M")"
			hours=$((24-$curr_hours+$prayer_hours))
			minutes=$((60-$curr_minutes+$prayer_minutes))
      if (( $minutes > 59 )); then
        minutes=$(($minutes-60))
      fi
      break
		fi
	done
}

__Linux () {
	for time in ${prayer_times[@]}; do
		__check_if_passed_$OS $time
		exit_code=$?

		curr_hours="$(date -d "$current_time" +"%_H")"
		curr_minutes="$(date -d "$current_time" +"%_M")"
		curr_seconds="$(date -d "$current_time" +"%_S")"

		if [[ $exit_code == 0 ]]; then
			prayer_hours="$(date -d "$time" +"%_H")"
			prayer_minutes="$(date -d "$time" +"%_M")"
			hours=$(($prayer_hours-$curr_hours))
			minutes=$(($prayer_minutes-$curr_minutes))
			while [[ $minutes < 0 ]]; do
				minutes=$((60+$minutes))
				hours=$(($hours-1))
			done
      if (( $minutes == 1 )) && (( $curr_seconds != 0 )); then
        seconds=$((60-$curr_seconds))
        minutes=$(($minutes-1))
      fi
			break
		elif [[ $exit_code == 2 ]]; then
			prayer_hours="$(date -d "$time" +"%_H")"
			prayer_minutes="$(date -d "$time" +"%_M")"
			hours=$((24-$curr_hours+$prayer_hours))
			minutes=$((60-$curr_minutes+$prayer_minutes))
      if (( $minutes > 59 )); then
        minutes=$(($minutes-60))
      fi
			break
		fi
	done
}

__$OS

[[ $LANGUAGE == 0 ]] && echo -e "\nNext prayer at $time$(([[ $hours > 0 ]] || [[ $minutes > 0 ]] || [[ $seconds > 0 ]]) && echo ", in ")$([[ $hours > 0 ]] && echo "$hours hours ")$([[ $minutes > 0 ]] && echo "$minutes minutes ")$([[ $seconds > 0 ]] && echo "$seconds seconds")"
[[ $LANGUAGE == 1 ]] && echo -e "\nSljedeci vakat u $time$(([[ $hours > 0 ]] || [[ $minutes > 0 ]] || [[ $seconds > 0 ]]) && echo ", za ")$([[ $hours > 0 ]] && echo "$hours sati ")$([[ $minutes > 0 ]] && echo "$minutes minuta ")$([[ $seconds > 0 ]] && echo "$seconds sekundi")"
