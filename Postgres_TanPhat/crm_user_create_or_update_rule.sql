DROP FUNCTION IF EXISTS public.crm_user_create_or_update_rule(integer, character, integer, text);
CREATE OR REPLACE FUNCTION public.crm_user_create_or_update_rule(p_action_by integer, p_action_by_name character varying, p_action_type integer, p_data text)
 RETURNS TABLE("Id" integer, "Message" text)
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_id INT;
	v_mess TEXT;
BEGIN
	
	-- THÊM
	IF p_action_type = 1 THEN 
		ele := p_data::JSON;
		INSERT INTO "Rule"(
				"Name",
				"PathFile",
				"CreatedBy",
				"CreatedByName",
				"CreatedByTime"
			)
			VALUES(
				(ele->>'Name')::VARCHAR,
				(ele->>'PathFile')::VARCHAR,
				p_action_by,
				p_action_by_name,
				NOW()
			) RETURNING "RuleId" INTO v_id;
		
		v_mess := 'Thêm thành công';
	-- Sửa
	ELSEIF p_action_type = 2 THEN
		ele := p_data::JSON;
		UPDATE "Rule"
		SET
			"Name" = COALESCE((ele ->> 'Name')::VARCHAR, "Name"),
			"PathFile" = COALESCE((ele ->> 'PathFile')::VARCHAR, "PathFile"),
			"ModifyBy" = p_action_by,
			"ModifyByName" = p_action_by_name,
			"ModifyDate" = NOW()
		WHERE 
			"RuleId" = (ele ->> 'RuleId')::INT;
		v_id := 1;
		v_mess := 'Cập nhật thành công';
	-- Xóa
	ELSEIF p_action_type = 3 THEN
		ele := p_data::JSON;
		UPDATE "Rule"
		SET
			"IsDeleted" = TRUE,
			"ModifyBy" = p_action_by,
			"ModifyByName" = p_action_by_name,
			"ModifyDate" = NOW()
		WHERE 
			"RuleId" = (ele ->> 'RuleId')::INT;
		v_id := 1;
		v_mess := 'Xóa thành công';
	END IF;

	RETURN QUERY
	SELECT v_id, v_mess;

	EXCEPTION WHEN OTHERS THEN
	BEGIN
	v_id := -1;
	v_mess := sqlerrm;

	RETURN QUERY
	SELECT v_id, v_mess;
	END;

END;
$function$