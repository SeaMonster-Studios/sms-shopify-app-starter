require("dotenv").config({path: "../.env"})
const { exec } = require('child_process');

let header = "'x-hasura-admin-secret=" + process.env.HASURA_ADMIN_SECRET + "'";

exec(`npx get-graphql-schema https:${process.env.GRAPHQL_ENDPOINT} -j -h ${header} > ../graphql_schema.json`, (err, stdout, stderr) => {
  if (err) {
    //some err occurred
    console.error(err)
  }

  console.log(stdout)
  console.log(stderr)
});
