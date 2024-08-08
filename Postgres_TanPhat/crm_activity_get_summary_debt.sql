DROP FUNCTION IF EXISTS public.crm_activity_get_summary_debt(integer, integer);

CREATE OR REPLACE FUNCTION public.crm_activity_get_summary_debt(p_user_id integer, p_user_title_id integer)
RETURNS TABLE(
    "UserId" integer,
    "FullName" character varying,
    "SalePointId" integer, 
    "SalePointName" character varying, 
    "TotalDebt" numeric, 
    "TotalPay" numeric,
    "ModifyDate" timestamp without time zone
)
LANGUAGE 'plpgsql'
COST 100
VOLATILE PARALLEL UNSAFE
ROWS 1000
AS $BODY$
BEGIN
    RETURN QUERY
    SELECT 
        T."UserId",
        U."FullName",
        SP."SalePointId",
        SP."SalePointName",
        COALESCE(SUM(T."Price"), 0) AS "TotalDebt",
        COALESCE(SUM(T."Refunds"), 0) AS "TotalPay",
        MAX(T."ModifyDate") AS "ModifyDate"
    FROM 
        "Transaction" T
        LEFT JOIN "User" U ON U."UserId" = T."UserId"
        LEFT JOIN "SalePoint" SP ON SP."SalePointId" = T."SalePointId"
    WHERE 
        COALESCE(T."IsDeleted", FALSE) IS FALSE
        AND T."TransactionTypeId" = 14
        AND (p_user_title_id = 1 OR p_user_title_id = 6 OR T."UserId" = p_user_id)
    GROUP BY 
        T."UserId", 
        U."FullName", 
        SP."SalePointId",
        SP."SalePointName";
END;
$BODY$;

ALTER FUNCTION public.crm_activity_get_summary_debt(integer, integer)
    OWNER TO postgres;
