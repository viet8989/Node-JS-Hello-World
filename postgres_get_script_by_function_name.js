
// require("Postgres_TanPhat/postgres_db_TanPhat.js");

const {Client} = require('pg');

const client = new Client({
    host: "45.119.82.190",
    user: "postgres",
    port: 5432,
    password: "Vesotanphat686879###",
    database: "tanphat_test_v3"
    // database: "tanphat_crm_prod"
    // database: "tanphat_crm"
})

// const functionName = "crm_report_delete_shift_transfer";
const functionName = "crm_user_create_or_update_rule";

const query = `
      SELECT
        pg_get_functiondef(p.oid) AS function_definition
      FROM
        pg_proc p
      JOIN
        pg_namespace n ON p.pronamespace = n.oid
      WHERE
        p.proname = $1;
    `;

client.connect()
  .then(() => client.query(query, [functionName]))
  .then(async res => {
    // Check if any function was found
    if (res.rows.length > 0) {
        console.log(`Function definition for ${functionName}:\n`, res.rows[0].function_definition);
    } else {
        console.log(`No function found with the name: ${functionName}`);
    }
  })
  .catch(err => console.error('Error executing query', err.stack))
  .finally(() => client.end());
