CREATE OR REPLACE FUNCTION public.crm_report_get_total_lottery_return_in_month_v2(p_month character varying, p_sale_point_id integer)
 RETURNS TABLE("SalePointId" integer, "SalePointName" character varying, "DateReturn" date, "TotalReturn" bigint)
 LANGUAGE plpgsql
AS $function$

BEGIN
	RETURN QUERY
	SELECT 
		T."FromSalePointId",
		SP."SalePointName", 
		T."LotteryDate", 
		SUM(T."TotalTrans") AS "TotalTrans"
	FROM "Transition" T
		LEFT JOIN "SalePoint" SP ON SP."SalePointId" = T."FromSalePointId"
	WHERE TO_CHAR(T."LotteryDate", 'YYYY-MM') = p_month 
		AND T."TransitionTypeId" = 3
		AND (COALESCE(p_sale_point_id, 0) = 0 OR SP."SalePointId" = p_sale_point_id)
	GROUP BY T."FromSalePointId", T."LotteryDate", SP."SalePointName";
END;
$function$
