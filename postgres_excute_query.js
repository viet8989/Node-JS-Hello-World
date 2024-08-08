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

// const sql = "Select * From crm_activity_get_summary_debt(3, 1)";
// const sql = "Select * From crm_activity_get_history_debt(213, 1)";
// const sql = "Select * From crm_user_get_list_rule(1)";
// const sql = "Select * From crm_report_delete_shift_transfer(41, 'Test', 99999)";
// const sql = "Select * From crm_salepoint_get_list_transaction('2024-07', 0, 1) A WHERE A.\"TransactionTypeId\" = 14";

// const sql = "Select * From crm_activity_sell_get_data_v10(34875, 27, '2024-07-15')";

// const sql = 'SELECT * FROM "Transaction" WHERE "UserId"=21 ORDER BY "ActionDate" DESC LIMIT 10';
// const sql = 'SELECT * FROM "Transaction" WHERE "TransactionTypeId"=14 AND "UserId"=17 ORDER BY "ActionDate" DESC LIMIT 1';
// const sql = 'SELECT * FROM "Type" ORDER BY "ActionDate" DESC LIMIT 10';
// const sql = 'SELECT * FROM "Debt"';
// const sql = 'SELECT * FROM "ShiftDistribute" WHERE "ShiftDistributeId"= 34875';
// const sql = 'SELECT * FROM "ShiftTransfer" ORDER BY "ActionDate" DESC LIMIT 2';
// const sql = 'SELECT * FROM "Transaction" ORDER BY "ModifyDate" DESC LIMIT 1';
// const sql = 'SELECT * FROM "PermissionRole"';

// const sql = 'INSERT INTO public."PermissionRole"("PermissionRoleId", "RoleName", "PermissionId", "ActionName", "Sort", "IsShowMenu", "IsSubMenu", "RoleDisplayName") VALUES(102,\'rule\', 3, \'rule\', 102, true, true, \'Nội quy\');';

const sql = 'SELECT * FROM "PermissionRole" WHERE "RoleName"=\'rule\'';
// const sql = 'SELECT st."ShiftDistributeId" FROM "ShiftTransfer" st WHERE (SELECT COUNT(*) FROM "ShiftTransfer" st2 WHERE st2."ShiftDistributeId" = st."ShiftDistributeId") > 1';
// const sql = 'SELECT SD."SalePointId", SD."UserId", U."FullName" FROM "ShiftDistribute" SD JOIN "User" U ON U."UserId" = Sd."UserId" WHERE SD."ShiftDistributeId" = 37100';
// const sql = 'Select * From "ShiftDistribute" WHERE "UserId" = 185 Order By "DistributeDate" DESC Limit 10';
// const sql = 'Select * From "ShiftDistribute" WHERE "SalePointId" = 1 AND "ShiftId"=2 Order By "DistributeDate" DESC Limit 10';
// const sql = 'Select * From "ShiftDistribute" WHERE "ShiftDistributeId" = 34875';
// const sql = 'Select * From "User" WHERE "UserId" = 27';
// const sql = 'Select * From "LotteryChannel"';
// const sql = 'Select * From "LotteryType"';
// const sql = 'Select * From "UserRole" WHERE "UserId" = 27';
// const sql = 'Select * From "SalePointLog" ORDER BY "ActionDate" DESC LIMIT 1';
// const sql = 'Select * From "HistoryOfOrder" WHERE "HistoryOfOrderId" = 3983943';
// const sql = 'Select * From "InventoryConfirm" ORDER BY "LotteryDate" DESC LIMIT 1';
// const sql = 'Select * From "Inventory" ORDER BY "InventoryId" DESC LIMIT 2';


// const sql = 'Delete From public."TargetData" WHERE "TargetDataId" = 81;';

// const sql = 'Select * From "TargetData" WHERE "TargetDataTypeId" = 5 ORDER BY "CreatedDate" DESC LIMIT 3;';

// const sql = 'Select * From "Transition" WHERE "TransitionTypeId" = 3 ORDER BY "LotteryDate" DESC LIMIT 2';

// const sql = 'INSERT INTO public."TargetData"("TargetDataTypeId", "FromValue", "ToValue", "Value") VALUES(4,-200, -101, 0.6)';
// const sql = 'INSERT INTO public."TargetData"("TargetDataTypeId", "FromValue", "ToValue", "Value") VALUES(4,-300, -201, 0.5)';
// const sql = 'INSERT INTO public."TargetData"("TargetDataTypeId", "FromValue", "ToValue", "Value") VALUES(5,-200, -101, 0.6)';
// const sql = 'INSERT INTO public."TargetData"("TargetDataTypeId", "FromValue", "ToValue", "Value") VALUES(5,-300, -201, 0.5)';


console.log("")
console.log(sql)
console.log("")
client.query(sql, (err, res)=>{
    if(!err){
        // console.table(res.rows);
        console.log(res.rows);
    } else {
        console.log(err.message);
    }
    client.end();
    console.log("")
    console.log("Completed !!!")
});
