const fetch = require("node-fetch");
const fs = require("fs");
const path = require("path");
const os = require("os");
require("dotenv").config();

const fetchdata = async () => {
  const data = await fetch(`${URL}${id}`).then(res => res.json());
  let rawdata = {
    ...data,
    vakat: ["Zora", "Izlazak sunca", "Podne", "Ikindija", "Akšam", "Jacija"],
  };
  let jsondata = JSON.stringify(rawdata);
  fs.writeFileSync(tdatapath, jsondata);
  let date = new Date();
  rawdata = {
    vakat: {
      until: data.vakat.map(texttime => {
        const splittime = texttime.split(":");
        date.setHours(splittime[0]);
        date.setMinutes(splittime[1]);
        date.setSeconds("00");
        const time = date.getTime() - Date.now();
        let reminder = new Date(time);
        reminder.setHours(reminder.getHours() - 1);
        if (time < 0) return null;
        return reminder.toTimeString().split(" ")[0];
      }),
      at: [
        data.vakat[0],
        data.vakat[1],
        data.vakat[2],
        data.vakat[3],
        data.vakat[4],
        data.vakat[5],
      ],
    },
  };
  jsondata = JSON.stringify(rawdata);
  fs.writeFileSync(reminderspath, jsondata);
};

var id;
const URL = process.env.URL;
const dirpath = path.join(os.homedir(), process.env.DIR_PATH);
const tdatapath = path.join(dirpath, "/data/town-data.json");
const reminderspath = path.join(dirpath, "/data/reminders.json");

try {
  const rawdata = fs.readFileSync(tdatapath);
  const data = JSON.parse(rawdata);
  id = data.id;
  console.log("\nFetching town preferences ...");
  fetchdata();
} catch (err) {
  console.log(err);
}
