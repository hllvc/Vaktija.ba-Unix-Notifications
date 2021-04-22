const fetch = require("node-fetch");
const fs = require("fs");
const path = require("path");

const fetchTownInfo = async () => {
  const data = await fetch(`${URL}${id}`).then((res) => res.json());
  let jsondata = JSON.stringify(data);
  fs.writeFileSync(path.join(__dirname, "/data/town-data.json"), jsondata);
};

var id;
const URL = "https://api.vaktija.ba/vaktija/v1/";
const filepath = path.join(__dirname, "/data/town-data.json");

try {
  const rawdata = fs.readFileSync(filepath);
  const data = JSON.parse(rawdata);
  id = data.id;
  console.log("\nFetching town preferences ...");
  fetchTownInfo();
} catch (err) {
  console.log(err);
}
