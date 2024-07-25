DROP FUNCTION IF EXISTS public.crm_user_create_or_update_rule(integer, character varying, integer, integer, character varying, character varying);

CREATE OR REPLACE FUNCTION public.crm_user_create_or_update_rule(
    p_action_by INTEGER,
    p_action_by_name CHARACTER VARYING,
    p_action_type INTEGER,
    p_rule_id INTEGER,
    p_rule_name CHARACTER VARYING,
    p_rule_path_file CHARACTER VARYING
)
RETURNS TABLE("Id" INTEGER, "Message" TEXT)
LANGUAGE 'plpgsql'
COST 100
VOLATILE PARALLEL UNSAFE
ROWS 1000
AS $BODY$
DECLARE
    v_id INT := NULL;
    v_mess TEXT := '';
BEGIN
    -- Add
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
        
        v_mess := 'Thêm thành công';  -- Added successfully
    
    -- Update
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
        v_id := p_rule_id;
        v_mess := 'Cập nhật thành công';  -- Updated successfully
    
    -- Delete
    ELSEIF p_action_type = 3 THEN
        UPDATE "Rule"
        SET
            "IsDeleted" = TRUE,
            "ModifyBy" = p_action_by,
            "ModifyByName" = p_action_by_name,
            "ModifyTime" = NOW()
        WHERE 
            "RuleId" = p_rule_id;
        v_id := p_rule_id;
        v_mess := 'Xóa thành công';  -- Deleted successfully
    END IF;

    RETURN QUERY
    SELECT v_id, v_mess;

EXCEPTION WHEN OTHERS THEN
    v_id := -1;
    v_mess := SQLERRM;
    RETURN QUERY
    SELECT v_id, v_mess;
END;
$BODY$;

ALTER FUNCTION public.crm_user_create_or_update_rule(
    INTEGER, 
    CHARACTER VARYING, 
    INTEGER, 
    INTEGER, 
    CHARACTER VARYING, 
    CHARACTER VARYING
)
OWNER TO postgres;
