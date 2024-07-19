CREATE OR REPLACE FUNCTION public.crm_user_get_list(p_page_size integer, p_page_number integer, p_usertitle_id integer)
 RETURNS TABLE("RowNumber" bigint, "TotalCount" bigint, "UserId" integer, "Account" character varying, "Phone" character varying, "FullName" character varying, "Email" character varying, "IsActive" boolean, "IsDeleted" boolean, "StartDate" date, "EndDate" date, "UserTitleId" integer, "UserTitleName" character varying, "SalePointId" integer, "BasicSalary" bigint, "Address" character varying, "BankAccount" character varying, "NumberIdentity" character varying, "IsIntern" boolean)
 LANGUAGE plpgsql
AS $function$
DECLARE 
	v_offset_row INT8 := p_page_size * (p_page_number - 1);
BEGIN
	
	RETURN QUERY 
	WITH tmp AS(
		SELECT
			ROW_NUMBER() OVER(PARTITION BY BS."UserId" ORDER BY BS."CreatedDate" DESC) AS "Id",
			BS."UserId",
			BS."Salary"
		FROM "BasicSalary" BS
	),
	tmp2 AS (
		SELECT * 
		FROM tmp 
		WHERE tmp."Id" = 1
	)
	SELECT 
		ROW_NUMBER() OVER (ORDER BY U."UserId") "RowNumber",
		COUNT(1) OVER() AS "TotalCount",
		U."UserId",
		U."Account",
		U."Phone",
		U."FullName",
		U."Email",
		U."IsActive",
		U."IsDeleted",
		U."StartDate",
		U."EndDate",
		UT."UserTitleId",
		UT."UserTitleName",
		U."SalePointId",
		COALESCE(T."Salary", 0) AS "BasicSalary",
		U."Address",
		U."BankAccount",
		U."NumberIdentity",
		U."IsIntern"
	FROM "User" U
		JOIN "UserRole" UR ON UR."UserId" = U."UserId"
		JOIN "UserTitle" UT ON UT."UserTitleId" = UR."UserTitleId"
		LEFT JOIN tmp2 T ON T."UserId" = U."UserId"
	WHERE (COALESCE(p_usertitle_id, 0) = 0 OR UT."UserTitleId" = p_usertitle_id)
		AND UT."UserTitleId" <> 1
-- 		AND U."IsActive" IS TRUE
-- 		AND U."IsIntern" IS FALSE
	ORDER BY 
		U."IsActive" DESC,
		UR."UserTitleId",
		U."SalePointId",
		U."UserId"
	OFFSET v_offset_row LIMIT 100000;
	
END;
$function$