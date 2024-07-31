DROP FUNCTION IF EXISTS public.crm_activity_get_history_debt(integer, integer);

CREATE OR REPLACE FUNCTION public.crm_activity_get_history_debt(
    p_user_id integer, 
    p_action_type integer
)
RETURNS TABLE( 
    "Money" numeric, 
    "Date" timestamp without time zone, 
    "ApprovedBy" character varying
)
LANGUAGE 'plpgsql'
COST 100
VOLATILE PARALLEL UNSAFE
ROWS 1000
AS $BODY$
BEGIN
    IF p_action_type = 1 THEN 
        -- Get history debt
        RETURN QUERY
        SELECT 
            "Price" AS "Money",
            COALESCE("ModifyDate", "ActionDate") AS "Date",
            COALESCE("ModifyByName", "ActionByName") AS "ApprovedBy"
        FROM 
            "Transaction"
        WHERE 
            COALESCE("IsDeleted", FALSE) IS FALSE
            AND "TransactionTypeId" = 14
            AND COALESCE("Price", 0) != 0
            AND "UserId" = p_user_id
        ORDER BY "ModifyDate" DESC;
    ELSE 
        -- Get history pay
        RETURN QUERY
        SELECT 
            "Refunds" AS "Money",
            COALESCE("ModifyDate", "ActionDate") AS "Date",
            COALESCE("ModifyByName", "ActionByName") AS "ApprovedBy"
        FROM 
            "Transaction"
        WHERE 
            COALESCE("IsDeleted", FALSE) IS FALSE
            AND "TransactionTypeId" = 14
            AND COALESCE("Refunds", 0) != 0
            AND "UserId" = p_user_id
        ORDER BY "ModifyDate" DESC;
    END IF;
END;
$BODY$;

ALTER FUNCTION public.crm_activity_get_history_debt(integer, integer)
    OWNER TO postgres;
