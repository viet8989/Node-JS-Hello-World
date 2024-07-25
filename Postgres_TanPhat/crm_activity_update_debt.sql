CREATE OR REPLACE FUNCTION public.crm_activity_update_debt(p_user_id integer, p_money_pay numeric, p_salepoint_id integer, p_shift_distribute_id integer, p_action_by integer, p_action_by_name character varying)
 RETURNS TABLE("Id" integer, "Message" text)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_id INT;
    v_mess TEXT;
    v_time TIMESTAMP := NOW();
    v_total_debt DECIMAL;
    v_total_pay DECIMAL;
BEGIN
    v_total_debt := (SELECT COALESCE(SUM("Price"), 0) FROM "Transaction" WHERE "IsDeleted" = false AND "TransactionTypeId" = 14 AND "UserId" = p_user_id);
    v_total_pay := (SELECT COALESCE(SUM("Price"), 0) FROM "Transaction" WHERE "IsDeleted" = false AND "TransactionTypeId" = 14 AND "UserId" = p_user_id);
    
    IF((v_total_pay + p_money_pay) > 0 v_total_debt) THEN 
        v_mess := 'Trả quá số nợ cần trả, vui lòng nhập lại';
        v_id := 0;
    ELSE
        INSERT INTO "Transaction"(
                    "TransactionTypeId",
                    "Quantity",
                    "Price",
                    "TotalPrice",
                    "SalePointId",
                    "ShiftDistributeId",
                    "IsDeleted",
                    "UserId",
                    "TypeNameId",
                    "ActionBy",
                    "ActionByName",
                    "ActionDate",
                    "Date"
                )
                VALUES(
                    15, -- Nhan vien tra no
                    1,
                    p_money_pay,
                    p_money_pay,
                    p_salepoint_id,
                    p_shift_distribute_id,
                    FALSE,
                    p_user_id,
                    15,
                    p_action_by,
                    p_action_by_name,
                    v_time,
                    v_time::DATE
                );
	END IF;

    RETURN QUERY
    SELECT v_id, v_mess;

    EXCEPTION WHEN OTHERS THEN
    BEGIN
        v_id := -1;
        v_mess := sqlerrm;
        RETURN QUERY
        SELECT v_id, v_mess;
    END;

END;
$function$