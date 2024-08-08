const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

// Database connection configuration
const config = {
    host: "45.119.82.190",
    user: "postgres",
    port: 5432,
    password: "Vesotanphat686879###",
    database: "tanphat_test_v3"
    // database: "tanphat_crm"
    // database: "tanphat_crm_prod"
};

// Path to your SQL file

// const sqlFilePath = path.join(__dirname, 'Postgres_TanPhat/table_Rule_viet_create.sql');
// const sqlFilePath = path.join(__dirname, 'Postgres_TanPhat/crm_user_get_list_rule.sql');
// const sqlFilePath = path.join(__dirname, 'Postgres_TanPhat/crm_user_create_or_update_rule.sql');

// const sqlFilePath = path.join(__dirname, 'Postgres_TanPhat/crm_activity_update_debt.sql');

// const sqlFilePath = path.join(__dirname, 'Postgres_TanPhat/crm_activity_get_summary_debt.sql');
// const sqlFilePath = path.join(__dirname, 'Postgres_TanPhat/crm_activity_get_history_debt.sql');

const sqlFilePath = path.join(__dirname, 'Postgres_TanPhat/TargetData_insert.sql');

// Read the SQL file
fs.readFile(sqlFilePath, 'utf8', (err, sql) => {
  if (err) {
    console.error('Error reading SQL file:', err);
    process.exit(1);
  }

  // Create a new PostgreSQL client
  const client = new Client(config);

  // Connect to the database
  client.connect()
    .then(() => {
      console.log('Connected to the database ', client.database);
      // Execute the SQL file content
      return client.query(sql);
    })
    .then(() => {
      console.log('SQL file executed successfully');
    })
    .catch(err => {
      console.error('Error executing SQL file:', err);
    })
    .finally(() => {
      // Close the database connection
      client.end()
        .then(() => {
          console.log('Database connection closed');
        })
        .catch(err => {
          console.error('Error closing the database connection:', err);
        });
    });
});
