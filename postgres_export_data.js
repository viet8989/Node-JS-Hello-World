const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');

// PostgreSQL database credentials
const dbConfig = {
  user: 'postgres',
  host: '45.119.82.190',
  database: 'tanphat_test_v3',
  password: 'Vesotanphat686879###',
  port: 5432, // Default PostgreSQL port
};

// Path to save the SQL dump file
const outputFile = path.join(__dirname, 'tanphat_test_v3.sql');

// Absolute path to pg_dump
const pgDumpPath = '"C:/Users/Vietnhq/AppData/Local/Programs/pgAdmin 4/runtime/pg_dump"'; // Replace with actual path

// Construct the pg_dump command
const dumpCommand = `${pgDumpPath} -U ${dbConfig.user} -h ${dbConfig.host} -d ${dbConfig.database} -F p -f ${outputFile}`;

// Set the environment variable for the password
const env = { ...process.env, PGPASSWORD: dbConfig.password };

// Execute the pg_dump command
exec(dumpCommand, { env }, (error, stdout, stderr) => {
  if (error) {
    console.error(`Error executing pg_dump: ${error.message}`);
    return;
  }

  if (stderr) {
    console.error(`pg_dump stderr: ${stderr}`);
    return;
  }

  console.log(`Database successfully exported to ${outputFile}`);
});