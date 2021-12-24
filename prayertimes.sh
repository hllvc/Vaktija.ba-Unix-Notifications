#!/bin/bash

os="$(uname)"

if [[ $os == Darwin ]]; then
  homedir="/Users"
elif [[ $os == Linux ]]; then
  homedir="/home"
fi
echo -e "\nRecognized $os as your OS.\n"

config="$homedir/$USER/.prayerconfig"
url="https://api.vaktija.ba/vaktija/v1"

initital_config () {
  echo -e "\nFetching list of towns...\n"
  old_ifs=$IFS
  IFS=$'\n'
  locations=($(curl -fsSL "$url/lokacije" | jq -r ".[]"))
  IFS=$old_ifs

  for i in ${!locations[@]}; do
    echo "[$i] ${locations[$i]}"
  done

  read -p $'\nChoose town\n> ' town
  echo -e "\nCreating config file at $config"
  echo 'town='"$town"'' >> $config
}

check_config () {
  [[ ! -e $config ]] && return 1
  old_ifs=$IFS
  IFS="="
  town=($(grep 'town=[0-90-90-9]' $config))
  town=${town[1]}
  IFS=$old_ifs
}

check_config
[[ $? == 1 ]] && initital_config

current_time="$(date +"%H:%M:%S")"
prayer_times=($(curl -fsSL "$url/$town" | jq -r ".vakat[]"))

check_if_passed () {
  if ([[ $(date -j -f "%H:%M" "$1" +"%H") < $(date -j -f "%H:%M:%S" "$current_time" +"%H") ]] || \
    ( [[ $(date -j -f "%H:%M" "$1" +"%H") == $(date -j -f "%H:%M:%S" "$current_time" +"%H") ]] && [[ $(date -j -f "%H:%M" "$1" +"%M") < $(date -j -f "%H:%M:%S" "$current_time" +"%M") ]] )) && \
    [[ $1 == ${prayer_times[0]} ]]; then
    return 2
  elif [[ $(date -j -f "%H:%M" "$1" +"%H") < $(date -j -f "%H:%M:%S" "$current_time" +"%H") ]] || \
    ( [[ $(date -j -f "%H:%M" "$1" +"%H") == $(date -j -f "%H:%M:%S" "$current_time" +"%H") ]] && [[ $(date -j -f "%H:%M" "$1" +"%M") < $(date -j -f "%H:%M:%S" "$current_time" +"%M") ]] ); then
    return 1
  fi
  return 0
}

curr_hours="$(date -j -f "%H:%M:%S" "$current_time" +"%H")"
curr_minutes="$(date -j -f "%H:%M:%S" "$current_time" +"%M")"
curr_seconds="$(date -j -f "%H:%M:%S" "$current_time" +"%S")"

for time in $prayer_times; do
  check_if_passed $time
  exit_code=$?
  if [[ $exit_code == 0 ]]; then
    prayer_hours="$(date -j -f "%H:%M" "$time" +"%H")"
    prayer_minutes="$(date -j -f "%H:%M" "$time" +"%M")"
    hours=$(($prayer_hours-$curr_hours))
    minutes=$(($prayer_minutes-$curr_minutes))
    while [[ $minutes < 0 ]]; do
      minutes=$((60$minutes))
      hours=$(($hours-1))
    done
    if [[ $minutes == 1 ]]; then
     seconds=$((60-$curr_seconds))
    fi
    break
  elif [[ $exit_code == 2 ]]; then
    prayer_hours="$(date -j -f "%H:%M" "$time" +"%H")"
    prayer_minutes="$(date -j -f "%H:%M" "$time" +"%M")"
    hours=$((24-$curr_hours+$prayer_hours))
    minutes=$((60-$curr_minutes+$prayer_minutes))
  fi
done

echo "Prajer at $time, in $([[ $hours > 0 ]] && echo "$hours hours and ")$([[ $minutes > 1 ]] && echo "$minutes minutes")$([[ $seconds > 0 ]] && echo "$seconds seconds")"
