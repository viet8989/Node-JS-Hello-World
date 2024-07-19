DROP FUNCTION IF EXISTS public.crm_user_get_list_rule(integer);
CREATE OR REPLACE FUNCTION public.crm_user_get_list_rule(p_user_title_id integer)
 RETURNS TABLE("RuleId" integer, "Name" character varying, "PathFile" character varying, "CreateByName" character varying, "CreateTime" date)
 LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN QUERY
	SELECT 
		"RuleId", 
		"Name", 
		"PathFile", 
		"CreateByName", 
		"CreateTime"
	FROM public."Regulation"
	WHERE "IsDeleted" = false
	ORDER BY "CreateTime" DESC;
END;
$function$