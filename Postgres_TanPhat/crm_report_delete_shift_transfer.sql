CREATE OR REPLACE FUNCTION public.crm_report_delete_shift_transfer(p_action_by integer, p_action_by_name character varying, p_shift_distribute_id integer)
 RETURNS TABLE("Id" integer, "Message" text)
 LANGUAGE plpgsql
AS $function$
DECLARE 
	v_id INT;
	v_mess TEXT;
	v_check INT;
	v_user_id INT;
	v_user_name VARCHAR;
	v_salepoint_id INT;
BEGIN
	SELECT "ShiftDistributeId"
		INTO v_check
		FROM "ShiftTransfer" WHERE "ShiftDistributeId"= p_shift_distribute_id LIMIT 1;
	
	IF(COALESCE(v_check, 0)=0) THEN
		v_id := -1;
		v_mess := 'Ca làm việc chưa kết thúc HOẶC đã được huỷ kết ca';
	ELSE
		--GET DATA
		SELECT
			SD."SalePointId",
			SD."UserId",
			U."FullName"
		INTO
			v_salepoint_id,
			v_user_id,
			v_user_name
		FROM "ShiftDistribute" SD 
			JOIN "User" U ON U."UserId" = Sd."UserId"
			WHERE SD."ShiftDistributeId"  = v_check;
		--DELETE
		DELETE FROM "ShiftTransfer" 
			WHERE "ShiftDistributeId" = v_check AND "SalePointId" = v_salepoint_id;
		--INSERT LOG
		INSERT INTO "ShiftTransferLog" (
			"ActionBy",
			"ActionByName",
			"ActionDate",
			"ShiftDistributeId",
			"SalePointId",
			"UserId",
			"UserName"
		)VALUES(
			p_action_by,
			p_action_by_name,
			NOW(),
			v_check,
			v_salepoint_id,
			v_user_id,
			v_user_name
		);
		 
		v_id := 1;
		v_mess := 'Thao tác thành công';
	END IF;
	

	RETURN QUERY 
	SELECT 	v_id, v_mess;

	EXCEPTION WHEN OTHERS THEN
	BEGIN				
		v_id := -1;
		v_mess := sqlerrm;
		
		RETURN QUERY 
		SELECT 	v_id, v_mess;
	END;

END;