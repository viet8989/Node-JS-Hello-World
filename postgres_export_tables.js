const { Client } = require('pg');
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

const query = `
  SELECT
    table_name,
    table_schema
  FROM
    information_schema.tables
  WHERE
    table_type = 'BASE TABLE'
    AND table_schema NOT IN ('pg_catalog', 'information_schema')
  ORDER BY
    table_schema,
    table_name;
`;

client.connect()
  .then(() => client.query(query))
  .then(async res => {
    let tableDefinitions = '';
    for (const row of res.rows) {
      const createTableQuery = `SELECT pg_get_tabledef('${row.table_schema}.${row.table_name}'::regclass) as table_definition;`;
      const result = await client.query(createTableQuery);
      tableDefinitions += result.rows[0].table_definition + '\n\n';
    }
    fs.writeFileSync('tanphat_tables.sql', tableDefinitions);
    console.log('Tables exported to tables.sql');
  })
  .catch(err => console.error('Error executing query', err.stack))
  .finally(() => client.end());