const fetch = require("node-fetch");
const fs = require("fs");
const path = require("path");
const os = require("os");
require("dotenv").config();

const readline = require("readline").createInterface({
  input: process.stdin,
  output: process.stdout,
});

const fetchdata = async () => {
  data = await fetch(`${URL}lokacije`).then(res => res.json());
  picktown();
};

const picktown = () => {
  data.map((town, index) => console.log(`[ ${index} ] ${town}`));
  readline.question("\nChoose town?\n> ", id => {
    town = data[id];
    console.log(`\nYou picked ${town}.`);
    readline.close();
    try {
      if (!fs.existsSync(datapath)) {
        fs.mkdirSync(datapath);
        console.log("\nCreating data folder ...");
      }
    } catch (err) {
      console.log(err);
    }
    let towndata = {
      id: id,
    };
    let jsondata = JSON.stringify(towndata);
    try {
      fs.writeFileSync(filepath, jsondata);
      console.log("\nSaving data ...");
    } catch (err) {
      console.log(err);
    }
  });
};

const URL = process.env.URL;
const dirpath = path.join(__dirname, "../");
const datapath = path.join(dirpath, "/data");
const filepath = path.join(datapath, "/town-data.json");
var data = {};

console.log("Fetching data ...\n");
fetchdata();
