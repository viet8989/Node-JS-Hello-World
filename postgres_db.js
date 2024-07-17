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

client.connect();

client.query('Select * From "ShiftDistribute" Order By "ActionDate" DESC Limit 1', (err, res)=>{
    if(!err){
        console.log(res.rows);
    } else {
        console.log(err.message);
    }
    client.end;
});

client.query('Select * From "ShiftTransfer" Order By "ActionDate" DESC Limit 1', (err, res)=>{
    if(!err){
        console.log(res.rows);
    } else {
        console.log(err.message);
    }
    client.end;
});