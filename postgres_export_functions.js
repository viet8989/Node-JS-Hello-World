const { Client } = require('pg');
const fs = require('fs');

const client = new Client({
    host: "45.119.82.190",
    user: "postgres",
    port: 5432,
    password: "Vesotanphat686879###",
    // database: "tanphat_test_v3"
    // database: "tanphat_crm_prod"
    database: "tanphat_crm"
})

const query = `
  SELECT
    pg_get_functiondef(p.oid) as function_definition
  FROM
    pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE
    n.nspname NOT IN ('pg_catalog', 'information_schema')
  ORDER BY
    p.proname;
`;

client.connect()
  .then(() => client.query(query))
  .then(res => {
    const functions = res.rows.map(row => row.function_definition).join('\n\n');
    fs.writeFileSync('tanphat_functions.sql', functions);
    console.log('Functions exported to functions.sql');
  })
  .catch(err => console.error('Error executing query', err.stack))
  .finally(() => client.end());