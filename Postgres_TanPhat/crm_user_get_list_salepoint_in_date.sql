CREATE OR REPLACE FUNCTION public.crm_user_get_list_salepoint_in_date(p_user_id integer, p_date timestamp without time zone DEFAULT now())
 RETURNS TABLE("ShiftDistributeId" integer, "ShiftId" integer, "SalePointId" integer, "SalePointName" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN QUERY
	SELECT
		SD."ShiftDistributeId",
		SD."ShiftId",
		SD."SalePointId",
		SP."SalePointName"
	FROM "ShiftDistribute" SD 
		JOIN "SalePoint" SP ON SD."SalePointId" = SP."SalePointId"
	WHERE SD."UserId" = p_user_id
		AND SD."DistributeDate" = p_date::DATE
	ORDER BY SD."ShiftId";
END;
$function$