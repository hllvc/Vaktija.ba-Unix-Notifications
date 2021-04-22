const fetch = require("node-fetch");
const fs = require("fs");
const path = require("path");

const fetchTownInfo = async () => {
  const data = await fetch(`${URL}${id}`).then((res) => res.json());
  let jsondata = JSON.stringify(data);
  fs.writeFileSync(path.join(__dirname, "/data/town-data.json"), jsondata);
};

var id;
var URL = "https://api.vaktija.ba/vaktija/v1/";

try {
  const rawdata = fs.readFileSync(path.join(__dirname, "/data/town-data.json"));
  const data = JSON.parse(rawdata);
  id = data.id;
  fetchTownInfo();
} catch (err) {
  console.log(err);
}
