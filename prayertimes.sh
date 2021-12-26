#!/bin/bash

os="$(uname)"

if [[ $os == Darwin ]]; then
  homedir="/Users"
elif [[ $os == Linux ]]; then
  homedir="/home"
fi

config="$homedir/$USER/.prayerconfig"
url="https://api.vaktija.ba/vaktija/v1"

usage () {
  echo -e "\nUsage: $(basename "$0") [OPTIONS] <ARG>

  Where OPTIONS are:

      -h)        Show this help
      -c)        Remove config
      -u)        Update town and data
      -e)        Edit config file
      -s)        Show config file
      -l ARG)    Change language (where ARG is [en] or [ba])"
  exit 2
}

load_config () {
  [[ ! -e $config ]] && return 1
  old_ifs=$IFS
  IFS="="
  town=($(grep 'town=[0-90-90-9]' $config))
  town=${town[1]}
  lang=($(grep 'lang=[0-1]' $config))
  lang=${lang[1]}
  IFS=$old_ifs
}

initital_config () {
  while [[ $lang > 1 ]] || [[ $lang < 0 ]]; do
    read -p $'\nLanguages (Jezici):\n\n[0] English\n[1] Bosanski\n\nChoose language (Odaberite jezik)\n> ' lang
  done
  [[ $lang == 0 ]] && echo -e "\nCreating config file at $config"
  [[ $lang == 1 ]] && echo -e "\nKreiranje konfiguracija u $config"
  echo 'lang='"$lang"'' > $config

  [[ $lang == 0 ]] && echo -e "\nFetching list of towns...\n"
  [[ $lang == 1 ]] && echo -e "\nDobavljamo listu gradova...\n"
  old_ifs=$IFS
  IFS=$'\n'
  locations=($(curl -fsSL "$url/lokacije" | jq -r ".[]"))
  IFS=$old_ifs

  for i in ${!locations[@]}; do
    echo "[$i] ${locations[$i]}"
  done

  town=-1
  while [[ $town -lt 0 ]] || [[ $town -gt $((${#locations[@]}-1)) ]]; do
    [[ $lang == 0 ]] && read -p $'\nChoose town\n> ' town
    [[ $lang == 1 ]] && read -p $'\nOdaberite grad\n> ' town
  done
  echo 'town='"$town"'' >> $config
  usage

}

update_town () {
  [[ $lang == 0 ]] && echo -e "\nFetching list of towns...\n"
  [[ $lang == 1 ]] && echo -e "\nDobavljamo listu gradova...\n"
  old_ifs=$IFS
  IFS=$'\n'
  locations=($(curl -fsSL "$url/lokacije" | jq -r ".[]"))
  IFS=$old_ifs

  for i in ${!locations[@]}; do
    echo "[$i] ${locations[$i]}"
  done

  town=-1
  echo $town
  while [[ $town -lt 0 ]] || [[ $town -gt $((${#locations[@]}-1)) ]]; do
    [[ $lang == 0 ]] && read -p $'\nChoose town\n> ' town
    [[ $lang == 1 ]] && read -p $'\nOdaberite grad\n> ' town
    echo $town
    echo $((${#locations[@]}-1))
  done
  sed -i'' -e 's/town=.*/town='$town'/' $config
}

load_config
[[ $? == 1 ]] && initital_config

while getopts 'hcuesl:' arg; do
  case "$arg" in
    h)
      usage
      ;;
    c)
      rm $config
      exit 2
      ;;
    u)
      update_town
      exit 2
      ;;
    e)
      $EDITOR $config
      exit 2
      ;;
    s)
      cat $config
      exit 2
      ;;
    l)
      if [[ $OPTARG == "en" ]]; then
        lang=0
      elif [[ $OPTARG == "ba" ]]; then
        lang=1
      else
        usage
      fi
      sed -i'' -e 's/lang=[0-1]/lang='"$lang"'/' $config
      ;;
    *)
      usage
      ;;
  esac
done

current_time="$(date +"%H:%M:%S")"
prayer_times=($(curl -fsSL "$url/$town" | jq -r ".vakat[]"))

check_if_passed_Darwin () {
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

check_if_passed_Linux () {
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

Darwin () {
	for time in $prayer_times; do
		check_if_passed_$os $time
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
				minutes=$((60$minutes))
				hours=$(($hours-1))
			done
			if [[ $minutes == 1 ]] && [[ $hours == 0 ]]; then
				seconds=$((60-$curr_seconds))
			fi
			break
		elif [[ $exit_code == 2 ]]; then
			prayer_hours="$(date -j -f "%H:%M" "$time" +"%_H")"
			prayer_minutes="$(date -j -f "%H:%M" "$time" +"%_M")"
			hours=$((24-$curr_hours+$prayer_hours))
			minutes=$((60-$curr_minutes+$prayer_minutes))
		fi
	done
}

Linux () {
	for time in ${prayer_times[@]}; do
		check_if_passed_$os $time
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
				minutes=$((60$minutes))
				hours=$(($hours-1))
			done
			if [[ $minutes == 1 ]] && [[ $hours == 0 ]]; then
				seconds=$((60-$curr_seconds))
			fi
			break
		elif [[ $exit_code == 2 ]]; then
			prayer_hours="$(date -d "$time" +"%_H")"
			prayer_minutes="$(date -d "$time" +"%_M")"
			hours=$((24-$curr_hours+$prayer_hours))
			minutes=$((60-$curr_minutes+$prayer_minutes))
		fi
	done
}

$os

[[ $lang == 0 ]] && echo -e "\nPrayer at $time, in $([[ $hours > 0 ]] && echo "$hours hours ")$([[ $minutes > 1 ]] && echo "$minutes minutes")$([[ $seconds > 0 ]] && echo "$seconds seconds")"
[[ $lang == 1 ]] && echo -e "\nVakat u $time, za $([[ $hours > 0 ]] && echo "$hours sati ")$([[ $minutes > 1 ]] && echo "$minutes minuta")$([[ $seconds > 0 ]] && echo "$seconds sekundi")"
