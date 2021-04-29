const fetch = require("node-fetch");
const fs = require("fs");
const path = require("path");
const os = require("os");
require("dotenv").config();

var times = [];
const dirpath = path.join(os.homedir(), process.env.DIR_PATH);
const reminderspath = path.join(dirpath, "/data/reminders.json");

const rawdata = fs.readFileSync(reminderspath);
const data = JSON.parse(rawdata);
times = data.vakat.at;
let date = new Date();
let newdata = {
  ...data,
  vakat: {
    until: times.map(texttime => {
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
  },
};
jsondata = JSON.stringify(newdata);
fs.writeFileSync(reminderspath, jsondata);
