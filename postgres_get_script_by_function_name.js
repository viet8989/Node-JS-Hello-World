
// require("Postgres_TanPhat/postgres_db_TanPhat.js");

const {Client} = require('pg');
const fs = require('fs');

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
// const functionName = "crm_get_salary_of_user_by_month_v10";
// const functionName = "crm_activity_sell_get_data_v10";
// const functionName = "crm_activity_confirm_transition_v3";
const functionName = "crm_report_get_total_lottery_return_in_month_v2";
const isSave = true;

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
        sql_text = res.rows[0].function_definition;
        if (isSave == true)
        {
          fs.writeFileSync('Postgres_TanPhat/'+functionName+'.sql', sql_text);
          console.log('Saved to '+functionName+'.sql');
        }
        console.log(`Function definition for ${functionName}:\n`, sql_text);
    } else {
        console.log(`No function found with the name: ${functionName}`);
    }
  })
  .catch(err => console.error('Error executing query', err.stack))
  .finally(() => client.end());
