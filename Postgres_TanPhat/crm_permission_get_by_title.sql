CREATE OR REPLACE FUNCTION public.crm_permission_get_by_title(p_title integer)
 RETURNS TABLE("RoleId" integer, "RoleName" character varying, "PermissionId" integer, "PermissionName" character varying, "ControllerName" character varying, "IsCheck" boolean)
 LANGUAGE plpgsql
AS $function$
BEGIN 
	
	RETURN QUERY
	SELECT 
		PR."PermissionRoleId",
		COALESCE(PR."RoleDisplayName", PR."RoleName"),
		P."PermissionId",
		P."PermissionName",
		P."ControllerName",
		(CASE WHEN PTR."PermissionRoleId" IS NULL THEN FALSE ELSE TRUE END)
	FROM "PermissionRole" PR
		JOIN "Permission" P ON P."PermissionId" = PR."PermissionId"
		LEFT JOIN "PermissionRoleTitles" PTR ON PR."PermissionRoleId" = PTR."PermissionRoleId" AND PTR."UserTitleId" = p_title
		JOIN "UserTitle" UT ON UT."UserTitleId" = p_title
	WHERE PR."IsDelete" IS FALSE
		AND PR."IsActive" IS TRUE
	ORDER BY 
		P."Sort" ASC, 
		P."PermissionId" ASC, 
		PR."Sort" ASC, 
		PR."PermissionRoleId" ASC; 
			
END; 
$function$