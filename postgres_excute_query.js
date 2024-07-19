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

client.connect();

// const sql = 'Select * From "Rule"';
const sql = 'Select * From "Guest"';
// const sql = "Select * From crm_report_delete_shift_transfer(41, 'Test', 99999)";
// const sql = 'SELECT * FROM "ShiftTransfer" WHERE "ShiftDistributeId"= 34740';
// const sql = 'SELECT * FROM "ShiftTransfer" ORDER BY "ActionDate" DESC LIMIT 2';
// const sql = 'SELECT st."ShiftDistributeId" FROM "ShiftTransfer" st WHERE (SELECT COUNT(*) FROM "ShiftTransfer" st2 WHERE st2."ShiftDistributeId" = st."ShiftDistributeId") > 1';
// const sql = 'SELECT SD."SalePointId", SD."UserId", U."FullName" FROM "ShiftDistribute" SD JOIN "User" U ON U."UserId" = Sd."UserId" WHERE SD."ShiftDistributeId" = 37100';
// const sql = 'Select * From "ShiftDistribute" WHERE "UserId" = 185 Order By "DistributeDate" DESC Limit 10';
// const sql = 'Select * From "ShiftDistribute" WHERE "SalePointId" = 1 AND "ShiftId"=2 Order By "DistributeDate" DESC Limit 10';
console.log("")
console.log(sql)
console.log("")
client.query(sql, (err, res)=>{
    if(!err){
        console.log(res.rows);
    } else {
        console.log(err.message);
    }
    client.end;
    console.log("")
    console.log("Completed !!!")
});
