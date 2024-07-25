DROP FUNCTION IF EXISTS public.crm_activity_get_salary_advance_debt(integer);

CREATE OR REPLACE FUNCTION public.crm_activity_get_history_debt(p_user_id integer, p_user_title_id integer)
 RETURNS TABLE("Price" numeric, "SalePointName" character varying, "Date" date, "ActionByName" character varying, "ActionDate" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN QUERY
	SELECT 
		T."UserId",
		U."FullName",
		SP."SalePointName",
		SUM(COALESCE(T."Price", 0)),
		SUM(COALESCE(T."Refunds", 0)),
		T."ModifyDate"
	FROM "Transaction" T
		LEFT JOIN "User" U ON U."UserId" = T."UserId"
		LEFT JOIN "SalePoint" SP ON SP."SalePointId" = T."SalePointId"
	WHERE T."IsDeleted" IS FALSE
		AND T."TransactionTypeId" = 14
		AND T."UserId" = p_user_id
	ORDER BY T."ModifyDate" DESC
	GROUP BY T."UserId";
END;
$function$
