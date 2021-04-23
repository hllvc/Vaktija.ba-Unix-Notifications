const fetch = require("node-fetch");
const fs = require("fs");
const path = require("path");
const os = require("os");
require("dotenv").config();

const fetchdata = async () => {
  const data = await fetch(`${URL}${id}`).then(res => res.json());
  // let detaildata = {
  //   ...data,
  //   datum: {
  //     hijr: data.datum[0],
  //     greg: data.datum[1],
  //   },
  //   vakat: {
  //     zora: data.vakat[0],
  //     izlazak: data.vakat[1],
  //     podne: data.vakat[2],
  //     ikindija: data.vakat[3],
  //     aksam: data.vakat[4],
  //     jacija: data.vakat[5],
  //   },
  // };
  let jsondata = JSON.stringify(data);
  fs.writeFileSync(filepath, jsondata);
};

var id;
const URL = process.env.URL;
const dirpath = path.join(os.homedir(), process.env.DIR_PATH);
const filepath = path.join(dirpath, "/data/town-data.json");

try {
  const rawdata = fs.readFileSync(filepath);
  const data = JSON.parse(rawdata);
  id = data.id;
  console.log("\nFetching town preferences ...");
  fetchdata();
} catch (err) {
  console.log(err);
}
