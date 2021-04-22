const fetch = require("node-fetch");
const fs = require("fs");
const path = require("path");

const readline = require("readline").createInterface({
  input: process.stdin,
  output: process.stdout,
});

const getTown = async () => {
  const data = await fetch(`${URL}lokacije`).then((res) => res.json());
  data.forEach((town, index) => {
    console.log(`[${index}] ${town}`);
  });
  readline.question("\nChoose town?\n> ", (id) => {
    town = data[id];
    console.log(`\nYou picked ${town}.\n`);
    readline.close();
    let towndata = {
      id: id,
      lokacija: "",
      datum: [],
      vakat: [],
    };
    try {
      if (!fs.existsSync(path.join(__dirname, "/data"))) {
        fs.mkdirSync(path.join(__dirname, "/data"));
      }
    } catch (err) {
      console.log(err);
    }
    let jsondata = JSON.stringify(towndata);
    try {
      fs.writeFileSync(path.join(__dirname, "/data/town-data.json"), jsondata);
    } catch (err) {
      console.log(err);
    }
    console.log("Saving data ...");
  });
};

var URL = "https://api.vaktija.ba/vaktija/v1/";
getTown();
