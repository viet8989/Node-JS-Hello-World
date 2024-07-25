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
console.log("Connected to database ", client.database);

// const sql = 'Select * From "User"'; // UserId=21 - kieu
// const sql = "Select * From crm_activity_get_salary_advance_debt(213)";
// const sql = "Select * From crm_user_get_list_rule(1)";
// const sql = "Select * From crm_report_delete_shift_transfer(41, 'Test', 99999)";
// const sql = "Select * From crm_salepoint_get_list_transaction('2024-07', 0, 1) A WHERE A.\"TransactionTypeId\" = 14";
// const sql = 'SELECT * FROM "Transaction" WHERE "UserId"=21 ORDER BY "ActionDate" DESC LIMIT 10';
const sql = 'SELECT * FROM "Transaction" WHERE "TransactionTypeId"=14 AND "UserId"=17 ORDER BY "ActionDate" DESC LIMIT 1';
// const sql = 'SELECT * FROM "Type" ORDER BY "ActionDate" DESC LIMIT 10';
// const sql = 'SELECT * FROM "Debt"';
// const sql = 'SELECT * FROM "ShiftTransfer" WHERE "ShiftDistributeId"= 34740';
// const sql = 'SELECT * FROM "ShiftTransfer" ORDER BY "ActionDate" DESC LIMIT 2';
// const sql = 'SELECT * FROM "Rule"';
// const sql = 'SELECT * FROM "PermissionRole"';
// const sql = 'INSERT INTO public."PermissionRole"("PermissionRoleId", "RoleName", "PermissionId", "ActionName", "Sort", "IsShowMenu", "IsSubMenu", "RoleDisplayName") VALUES(101,\'Rule\', 3, \'Rule\', 101, false, true, \'Nội quy\');';
// const sql = 'INSERT INTO public."TransactionType"("TransactionTypeId", "TransactionTypeName", "IsSum", "IsActive", "Description", "IsCountForUser") VALUES(15, \'Nhân Viên Trả Nợ\', true, true, \'\', true)';
// const sql = 'SELECT * FROM "PermissionRole" A WHERE A."RoleDisplayName"=\'QL trưởng nhóm\'';
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
