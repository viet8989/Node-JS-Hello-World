DROP FUNCTION IF EXISTS public.crm_activity_update_debt(integer, numeric, character varying, integer, integer, integer, integer, character varying);

CREATE OR REPLACE FUNCTION public.crm_activity_update_debt(
    p_user_id INTEGER, 
    p_money_pay NUMERIC, 
    p_month CHARACTER VARYING, 
    p_salepoint_id INTEGER, 
    p_type_name_id INTEGER, 
    p_action_type INTEGER, 
    p_action_by INTEGER, 
    p_action_by_name CHARACTER VARYING
)
RETURNS TABLE("Id" INTEGER, "Message" TEXT)
LANGUAGE 'plpgsql'
COST 100
VOLATILE PARALLEL UNSAFE
ROWS 1000
AS $BODY$
DECLARE
    v_id INT;
    v_mess TEXT;
    v_time TIMESTAMP := NOW();
    v_total_debt NUMERIC := 0;
    v_total_pay NUMERIC := 0;
BEGIN
    -- Calculate total debt
    SELECT COALESCE(SUM("Price"), 0)  
    INTO v_total_debt
    FROM "Transaction" 
    WHERE COALESCE("IsDeleted", FALSE) = FALSE AND "TransactionTypeId" = 14 AND "UserId" = p_user_id;
    
    -- Calculate total pay
    SELECT COALESCE(SUM("Refunds"), 0)  
    INTO v_total_pay
    FROM "Transaction" 
    WHERE COALESCE("IsDeleted", FALSE) = FALSE AND "TransactionTypeId" = 14 AND "UserId" = p_user_id;
    
    -- Conditional check
    IF (v_total_pay + p_money_pay) > v_total_debt THEN 
        v_mess := 'Trả quá số nợ cần trả, vui lòng nhập lại';
        v_id := 0;
    ELSE
        -- Insert new transaction
        INSERT INTO "Transaction"(
            "TransactionTypeId",
            "TypeNameId",
            "Note",
            "SalePointId",
            "Quantity",
            "Price",
            "TotalPrice",
            "Refunds",
            "UserId",
            "IsDeleted",
            "ActionBy",
            "ActionByName",
            "ActionDate",
            "ModifyBy",
            "ModifyByName",
            "ModifyDate",
            "Date"
        )
        VALUES(
            14,
            p_type_name_id,
            'Trả nợ',
            p_salepoint_id,
            1,
            0,
            0,
            p_money_pay,
            p_user_id,
            FALSE,
            p_action_by,
            p_action_by_name,
            v_time,
            p_action_by,
            p_action_by_name,
            v_time,
            v_time::DATE
        );
        
        v_id := 1;
        v_mess := 'Thao tác thành công';
    END IF;

    RETURN QUERY
    SELECT v_id, v_mess;

EXCEPTION WHEN OTHERS THEN
    v_id := -1;
    v_mess := sqlerrm;
    RETURN QUERY
    SELECT v_id, v_mess;
END;
$BODY$;

ALTER FUNCTION public.crm_activity_update_debt(
    INTEGER, 
    NUMERIC, 
    CHARACTER VARYING, 
    INTEGER, 
    INTEGER, 
    INTEGER, 
    INTEGER, 
    CHARACTER VARYING
)
OWNER TO postgres;
