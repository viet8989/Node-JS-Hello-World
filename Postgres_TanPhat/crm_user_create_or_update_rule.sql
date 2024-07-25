-- FUNCTION: public.crm_user_create_or_update_rule(integer, character varying, integer, integer, character varying, character varying)

DROP FUNCTION IF EXISTS public.crm_user_create_or_update_rule(integer, character varying, integer, integer, character varying, character varying);

CREATE OR REPLACE FUNCTION public.crm_user_create_or_update_rule(
	p_action_by integer,
	p_action_by_name character varying,
	p_action_type integer,
	p_rule_id integer,
	p_rule_name character varying,
	p_rule_path_file character varying)
    RETURNS TABLE("Id" integer, "Message" text) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$

DECLARE
	v_id INT;
	v_mess TEXT;
BEGIN
	
	-- THÊM
	IF p_action_type = 1 THEN 
		INSERT INTO "Rule"(
				"Name",
				"PathFile",
				"CreatedBy",
				"CreatedByName",
				"CreateTime"
			)
			VALUES(
				p_rule_name,
				p_rule_path_file,
				p_action_by,
				p_action_by_name,
				NOW()
			) RETURNING "RuleId" INTO v_id;
		
		v_mess := 'Thêm thành công';
	-- Sửa
	ELSEIF p_action_type = 2 THEN
		UPDATE "Rule"
		SET
			"Name" = p_rule_name,
			"PathFile" = p_rule_path_file,
			"ModifyBy" = p_action_by,
			"ModifyByName" = p_action_by_name,
			"ModifyTime" = NOW()
		WHERE 
			"RuleId" = p_rule_id;
		v_id := 1;
		v_mess := 'Cập nhật thành công';
	-- Xóa
	ELSEIF p_action_type = 3 THEN
		UPDATE "Rule"
		SET
			"IsDeleted" = TRUE,
			"ModifyBy" = p_action_by,
			"ModifyByName" = p_action_by_name,
			"ModifyTime" = NOW()
		WHERE 
			"RuleId" = p_rule_id;
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
$BODY$;

ALTER FUNCTION public.crm_user_create_or_update_rule(integer, character varying, integer, integer, character varying, character varying)
    OWNER TO postgres;
