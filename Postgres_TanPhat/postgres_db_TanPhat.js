const {Client} = require('pg');

const client = new Client({
    host: "45.119.82.190",
    user: "postgres",
    port: 5432,
    password: "Vesotanphat686879###",
    // database: "tanphat_test_v3"
    database: "tanphat_crm_prod"
    // database: "tanphat_crm"
})