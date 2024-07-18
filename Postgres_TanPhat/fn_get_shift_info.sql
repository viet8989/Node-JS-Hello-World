CREATE OR REPLACE FUNCTION public.fn_get_shift_info(p_user_role_id integer, p_date timestamp without time zone DEFAULT now())
 RETURNS TABLE("UserId" integer, "IsSuperAdmin" boolean, "IsLeader" boolean, "IsManager" boolean, "IsStaff" boolean, "SalePointId" integer, "ShiftDistributeId" integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_sale_point_id INT;
	v_user_id INT;
	v_shift_dis_id INT;
	--
	v_is_super_admin BOOL;
	v_is_manager BOOL;
	v_is_staff BOOL;
	v_is_leader BOOL;
BEGIN
	
	SELECT
		UT."IsSuperAdmin",
		UT."IsLeader",
		UT."IsManager",
		UT."IsStaff",
		UR."UserId"
	INTO 
		v_is_super_admin,
		v_is_leader,
		v_is_manager,
		v_is_staff,
		v_user_id
	FROM "UserRole" UR
		JOIN "UserTitle" UT ON UR."UserTitleId" = UT."UserTitleId"
	WHERE UR."UserRoleId" = p_user_role_id;
	
	IF v_is_super_admin IS TRUE OR v_is_manager IS TRUE OR v_is_leader IS TRUE THEN
		
		RETURN QUERY 
		SELECT v_user_id, v_is_super_admin, v_is_leader, v_is_manager, v_is_staff, NULL::INT, NULL::INT;
	
	ELSE
	
		SELECT 
			SD."SalePointId", SD."ShiftDistributeId" INTO v_sale_point_id, v_shift_dis_id
		FROM "ShiftDistribute" SD 
		WHERE p_date::DATE = SD."DistributeDate" AND SD."UserId" = v_user_id
		ORDER BY EXISTS(SELECT 1 FROM "ShiftTransfer" T WHERE T."ShiftDistributeId" = SD."ShiftDistributeId" AND T."SalePointid" = SD."SalePointId" AND T."ShiftId" = 1), SD."ShiftId"
		LIMIT 1;
		
		RETURN QUERY 
		SELECT v_user_id, v_is_super_admin, v_is_leader, v_is_manager, v_is_staff, v_sale_point_id, v_shift_dis_id;
	
	END IF;

END;
$function$