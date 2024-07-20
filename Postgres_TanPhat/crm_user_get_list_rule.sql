DROP FUNCTION IF EXISTS public.crm_user_get_list_rule(integer);
CREATE OR REPLACE FUNCTION public.crm_user_get_list_rule(p_user_title_id integer)
 RETURNS TABLE("RuleId" integer, "Name" character varying, "PathFile" character varying, "CreatedByName" character varying, "CreatedTime" date)
 LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN QUERY
	SELECT 
		R."RuleId", 
		R."Name", 
		R."PathFile", 
		R."CreatedByName", 
		R."CreatedTime"
	FROM public."Rule" R
	WHERE "IsDeleted" = false
	ORDER BY "CreatedTime" DESC;
END;
$function$