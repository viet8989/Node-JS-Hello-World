DROP FUNCTION IF EXISTS public.crm_user_get_list_rule(integer);
CREATE OR REPLACE FUNCTION public.crm_user_get_list_rule(p_user_title_id integer)
 RETURNS TABLE("RuleId" integer, "Name" character varying, "PathFile" character varying, "CreatedByName" character varying, "CreateTime" date)
 LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN QUERY
	SELECT 
		R."RuleId", 
		R."Name", 
		R."PathFile", 
		R."CreatedByName", 
		R."CreateTime"
	FROM public."Rule" R
	WHERE R."IsDeleted" = false
	ORDER BY R."CreateTime" DESC;
END;
$function$