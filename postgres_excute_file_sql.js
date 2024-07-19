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
    // database: "tanphat_crm_prod"
    // database: "tanphat_crm"
};

// Path to your SQL file
// const sqlFilePath = path.join(__dirname, 'Postgres_TanPhat/table_Rule_viet_create.sql');
const sqlFilePath = path.join(__dirname, 'Postgres_TanPhat/crm_user_get_list_rule.sql');

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
      console.log('Connected to the database');

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
