import json,requests,sys

username=sys.argv[1]

content = requests.get("https://api.vaktija.ba/vaktija/v1/14")
prayer_times = json.loads(content.content)

with open("/home/" + username + "/.config/PrayerTimes/data/prayer-location", "w+") as the_file:
    the_file.write(prayer_times["lokacija"])
    
with open("/home/" + username + "/.config/PrayerTimes/data/prayer-date", "w+") as the_file:
    the_file.write(prayer_times["datum"][0])

with open("/home/" + username + "/.config/PrayerTimes/data/prayer-gdate", "w+") as the_file:
    the_file.write(prayer_times["datum"][1])

with open("/home/" + username + "/.config/PrayerTimes/data/prayer-dawn", "w+") as the_file:
    the_file.write(prayer_times["vakat"][0])

with open("/home/" + username + "/.config/PrayerTimes/data/prayer-fajr", "w+") as the_file:
    the_file.write(prayer_times["vakat"][1])

with open("/home/" + username + "/.config/PrayerTimes/data/prayer-zuhr", "w+") as the_file:
    the_file.write(prayer_times["vakat"][2])

with open("/home/" + username + "/.config/PrayerTimes/data/prayer-asr", "w+") as the_file:
    the_file.write(prayer_times["vakat"][3])

with open("/home/" + username + "/.config/PrayerTimes/data/prayer-maghrib", "w+") as the_file:
    the_file.write(prayer_times["vakat"][4])

with open("/home/" + username + "/.config/PrayerTimes/data/prayer-isha", "w+") as the_file:
    the_file.write(prayer_times["vakat"][5])