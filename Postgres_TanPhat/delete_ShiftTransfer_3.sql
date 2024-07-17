CREATE OR REPLACE FUNCTION public.script_huy_ket_ca(p_shift_dis_id bigint)
 RETURNS TABLE("Id" integer, "Message" text)
 LANGUAGE plpgsql
AS $function$
BEGIN
	
	DELETE FROM "ShiftTransfer" WHERE "ShiftDistributeId" = p_shift_dis_id;
	
	RETURN QUERY 
	SELECT 1, 'Ok';
	
END;