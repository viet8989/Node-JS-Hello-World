DROP FUNCTION IF EXISTS public.crm_activity_get_salary_advance_debt(integer);

CREATE OR REPLACE FUNCTION public.crm_activity_get_salary_advance_debt(p_user_id integer)
 RETURNS TABLE("Price" numeric, "SalePointName" character varying, "Date" date, "ActionByName" character varying, "ActionDate" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN QUERY
	SELECT 
		T."Price",
		SP."SalePointName",
		T."Date",
		T."ActionByName",
		T."ActionDate"
	FROM "Transaction" T
		LEFT JOIN "SalePoint" SP ON SP."SalePointId" = T."SalePointId"
	WHERE T."IsDeleted" IS FALSE
		AND T."TransactionTypeId" = 14
		AND T."UserId" = p_user_id
	ORDER BY T."Date" DESC;
END;
$function$
