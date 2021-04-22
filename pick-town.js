const fetch = require("node-fetch");
const fs = require("fs");
const path = require("path");

const readline = require("readline").createInterface({
  input: process.stdin,
  output: process.stdout,
});

const fetchdata = async () => {
  data = await fetch(`${URL}lokacije`).then((res) => res.json());
  picktown();
};

const picktown = () => {
  data.map((town, index) => console.log(`[ ${index} ] ${town}`));
  readline.question("\nChoose town?\n> ", (id) => {
    town = data[id];
    console.log(`\nYou picked ${town}.`);
    readline.close();
    let towndata = {
      id: id,
      lokacija: "",
      datum: [],
      vakat: [],
    };
    try {
      if (!fs.existsSync(dirpath)) {
        fs.mkdirSync(dirpath);
        console.log("\nCreating data folder ...");
      }
    } catch (err) {
      console.log(err);
    }
    let jsondata = JSON.stringify(towndata);
    try {
      fs.writeFileSync(filepath, jsondata);
      console.log("\nSaving data ...");
    } catch (err) {
      console.log(err);
    }
  });
};

const URL = "https://api.vaktija.ba/vaktija/v1/";
const dirpath = path.join(__dirname, "/data");
const filepath = path.join(dirpath, "/town-data.json");
var data = {};

console.log("Fetching data ...\n");
fetchdata();
