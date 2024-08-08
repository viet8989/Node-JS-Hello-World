-- FUNCTION: public.crm_activity_confirm_transition_v3(integer, character varying, text, boolean, integer, integer)

-- DROP FUNCTION IF EXISTS public.crm_activity_confirm_transition_v3(integer, character varying, text, boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.crm_activity_confirm_transition_v3(
	p_user_role_id integer,
	p_note character varying,
	p_list_item text,
	p_is_confirm boolean,
	p_trans_type_id integer,
	p_sale_point_id integer)
    RETURNS TABLE("Id" integer, "Message" text) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$

DECLARE
	v_id INT;
	v_mess TEXT;
	v_is_staff BOOL;
	v_name VARCHAR;
	v_user_id INT;
	ele JSON;
	v_inventory_id INT;
	v_total INT;
	v_total_dup INT;
	v_total_check INT := 0;
	v_total_dup_check INT := 0;
	v_shift_dis_id INT;
BEGIN	

	SELECT UT."IsStaff", U."UserId" INTO v_is_staff, v_user_id
	FROM "UserRole" U JOIN "UserTitle" UT ON U."UserTitleId" = UT."UserTitleId" 
	WHERE U."UserRoleId" = p_user_role_id;
	
	SELECT U."FullName" INTO v_name
	FROM "User" U 
	WHERE U."UserId" = v_user_id;
	
		IF p_is_confirm IS TRUE THEN
			IF p_trans_type_id = 1 THEN
				FOR ele IN SELECT * FROM json_array_elements(p_list_item::JSON) LOOP 		
					IF ((ele ->> 'IsScratchcard')::BOOL) IS FALSE THEN
				
						SELECT 
							I."TotalRemaining",
							I."TotalDupRemaining"
						INTO 
							v_total_check,
							v_total_dup_check
						FROM "Inventory" I 
						WHERE I."SalePointId" = p_sale_point_id
							AND I."LotteryChannelId" = (ele ->> 'LotteryChannelId')::INT
							AND I."LotteryDate" = (ele ->> 'LotteryDate')::DATE;
						
						IF(NOT EXISTS (SELECT 1 FROM "Transition" T WHERE T."TransitionId" = (ele ->> 'TransitionId')::INT AND T."ConfirmStatusId" = 1)) THEN
							RAISE 'Yêu cầu đã được xác nhận trước';
						END IF;
						
						IF v_total_check < COALESCE((ele ->> 'TotalTrans')::INT) OR v_total_dup_check < (ele ->> 'TotalTransDup')::INT THEN
							RAISE 'Không đủ vé trong kho hàng1';
						END IF;			
					ELSE 
						SELECT 
							I."TotalRemaining"
						INTO 
							v_total_check
						FROM "Scratchcard" I
						WHERE I."SalePointId" = p_sale_point_id
							AND I."LotteryChannelId" = (ele ->> 'LotteryChannelId')::INT;
							
						IF(NOT EXISTS (SELECT 1 FROM "Transition" T WHERE T."TransitionId" = (ele ->> 'TransitionId')::INT AND T."ConfirmStatusId" = 1)) THEN
							RAISE 'Yêu cầu đã được xác nhận trước';
						END IF;
						
						IF v_total_check < COALESCE((ele ->> 'TotalTrans')::INT) THEN
							RAISE 'Không đủ vé trong kho hàng2';
						END IF;	
						
					END IF;
				END LOOP;
			END IF;
			
			IF p_trans_type_id = 2 THEN
    		FOR ele IN SELECT * FROM json_array_elements(p_list_item::JSON) LOOP 	
			 IF (EXISTS (SELECT 1 FROM "Transition" T WHERE T."TransitionId" = (ele ->> 'TransitionId')::INT and T."ShiftDistributeId"= -1 AND T."ConfirmStatusId" = 1)) THEN
       	 IF ((ele ->> 'IsScratchcard')::BOOL) IS FALSE THEN
				if(NOT EXISTS (select 1 from "Inventory" where "LotteryDate"= (ele ->> 'LotteryDate')::DATE  AND "LotteryChannelId" = (ele ->> 'LotteryChannelId')::INT and  "SalePointId" = p_sale_point_id) ) Then 
				INSERT INTO "Inventory"
					SELECT *
					FROM "InventoryConfirm"
					 where "InventoryConfirm"."LotteryDate"= (ele ->> 'LotteryDate')::DATE  AND "InventoryConfirm"."LotteryChannelId" = (ele ->> 'LotteryChannelId')::INT and  "SalePointId" = p_sale_point_id ; 
					
						UPDATE "Transition"
							SET 
							"ConfirmBy" = v_user_id,
							"ConfirmByName" = v_name,
							"ConfirmDate" = NOW(),
							"ConfirmStatusId" = 2,
							"Note" = p_note
						WHERE "TransitionId" = (ele ->> 'TransitionId')::INT
							AND "ConfirmStatusId" = 1 and "ToSalePointId" = p_sale_point_id;
				ELSE
				UPDATE "Inventory"
							set "TotalReceived"=IC."TotalReceived",
								"TotalRemaining"=IC."TotalRemaining",
								"TotalDupReceived"=IC."TotalDupReceived",
								"TotalDupRemaining"=IC."TotalDupRemaining"
							from "InventoryConfirm" AS IC
							where  IC."LotteryDate"=(ele ->> 'LotteryDate')::DATE  and IC."LotteryChannelId"=(ele ->> 'LotteryChannelId')::INT and IC."SalePointId"=p_sale_point_id and "Inventory"."LotteryDate"= IC."LotteryDate" and "Inventory"."LotteryChannelId"=IC."LotteryChannelId"
							and "Inventory"."SalePointId"=IC."SalePointId";
							UPDATE "Transition"
							SET 
							"ConfirmBy" = v_user_id,
							"ConfirmByName" = v_name,
							"ConfirmDate" = NOW(),
							"ConfirmStatusId" = 2,
							"Note" = p_note
						WHERE "TransitionId" = (ele ->> 'TransitionId')::INT
							AND "ConfirmStatusId" = 1 and "ToSalePointId" = p_sale_point_id;
				END IF;
				-- Start Viet Edit
				UPDATE "Inventory"
				SET "TotalRemaining" = "TotalReceived" - COALESCE((SELECT SUM("Quantity") 
															FROM "SalePointLog" 
															WHERE "LotteryDate"=(ele ->> 'LotteryDate')::DATE
															AND "LotteryChannelId" = (ele ->> 'LotteryChannelId')::INT
															AND "SalePointId" = p_sale_point_id),0)
				WHERE "LotteryDate" = (ele ->> 'LotteryDate')::DATE
					AND "LotteryChannelId" = (ele ->> 'LotteryChannelId')::INT
					AND "SalePointId" = p_sale_point_id;
				-- End Viet Edit
            ELSE
					if NOT  EXISTS(SELECT 1 FROM "Scratchcard" WHERE "LotteryChannelId" = (ele ->> 'LotteryChannelId')::INT and "SalePointId" = p_sale_point_id)   then
						INSERT INTO "Scratchcard"(
								"LotteryChannelId",
								"TotalReceived",
								"TotalRemaining",
								"SalePointId"
							) VALUES (
								(ele ->> 'LotteryChannelId')::INT,
								(ele ->> 'TotalTrans')::INT,
								(ele ->> 'TotalTrans')::INT,
								p_sale_point_id
							);
							 
						else
					
				
						UPDATE "Scratchcard"
						SET "TotalRemaining" = "TotalRemaining" + COALESCE((ele ->> 'TotalTrans')::INT, 0)
						WHERE "SalePointId" = p_sale_point_id 
							AND "LotteryChannelId" = (ele ->> 'LotteryChannelId')::INT;
							end if;
								UPDATE "Transition"
				SET 
					"ConfirmTrans" = (ele ->> 'TotalTrans')::INT,
					"ConfirmTransDup" = (ele ->> 'TotalTransDup')::INT,
					"ConfirmBy" = v_user_id,
					"ConfirmByName" = v_name,
					"ConfirmDate" = NOW(),
					"ConfirmStatusId" = 2,
					"Note" = p_note
				WHERE "TransitionId" = (ele ->> 'TransitionId')::INT
					AND "ConfirmStatusId" = 1;
             
            END IF;
     ELSE 
	 	   SELECT 
                    I."TotalRemaining",
                    I."TotalDupRemaining"
                INTO 
                    v_total_check,
                    v_total_dup_check
                FROM "Inventory" I 
                WHERE I."SalePointId" = 0
                    AND I."LotteryChannelId" = (ele ->> 'LotteryChannelId')::INT
                    AND I."LotteryDate" = (ele ->> 'LotteryDate')::DATE;
                
                IF(NOT EXISTS (SELECT 1 FROM "Transition" T WHERE T."TransitionId" = (ele ->> 'TransitionId')::INT AND T."ConfirmStatusId" = 1)) THEN
                    RAISE 'Yêu cầu đã được xác nhận trước';
                END IF;
                
                IF v_total_check < COALESCE((ele ->> 'TotalTrans')::INT) OR v_total_dup_check < (ele ->> 'TotalTransDup')::INT THEN
                    RAISE 'Không đủ vé trong kho hàng3';
                END IF;
					
				
		END IF;	
    END LOOP;
END IF;

		
			FOR ele IN SELECT * FROM json_array_elements(p_list_item::JSON) LOOP 		
				   IF ( NOT EXISTS (SELECT 1 FROM "Transition" T WHERE T."TransitionId" = (ele ->> 'TransitionId')::INT and T."ShiftDistributeId"= -1  )) THEN
				UPDATE "Transition"
				SET 
					"ConfirmTrans" = (ele ->> 'TotalTrans')::INT,
					"ConfirmTransDup" = (ele ->> 'TotalTransDup')::INT,
					"ConfirmBy" = v_user_id,
					"ConfirmByName" = v_name,
					"ConfirmDate" = NOW(),
					"ConfirmStatusId" = 2,
					"Note" = p_note
				WHERE "TransitionId" = (ele ->> 'TransitionId')::INT
					AND "ConfirmStatusId" = 1;
				
				IF p_trans_type_id = 1 THEN
					IF ((ele ->> 'IsScratchcard')::BOOL) IS FALSE THEN		
						IF COALESCE((ele ->> 'TotalTrans')::INT, 0) > 0 THEN
					
							UPDATE "Inventory"
							SET
								"TotalRemaining" = "TotalRemaining" - (ele ->> 'TotalTrans')::INT
							WHERE "SalePointId" = p_sale_point_id
								AND "LotteryDate" = (ele ->> 'LotteryDate')::DATE
								AND "LotteryChannelId" = (ele ->> 'LotteryChannelId')::INT;
							
						END IF;
					
						IF COALESCE((ele ->> 'TotalTransDup')::INT, 0) > 0 THEN
						
							UPDATE "Inventory"
							SET
								"TotalDupRemaining" = "TotalDupRemaining" - (ele ->> 'TotalTransDup')::INT
							WHERE "SalePointId" = p_sale_point_id
								AND "LotteryDate" = (ele ->> 'LotteryDate')::DATE
								AND "LotteryChannelId" = (ele ->> 'LotteryChannelId')::INT;
								
						END IF;
						
						IF NOT EXISTS (SELECT 1 FROM "Inventory" WHERE "SalePointId" = 0 
							AND "LotteryDate" = (ele ->> 'LotteryDate')::DATE
							AND "LotteryChannelId" = (ele ->> 'LotteryChannelId')::INT) THEN
							
							INSERT INTO "Inventory"(
								"LotteryDate",
								"LotteryChannelId",
								"TotalReceived",
								"TotalRemaining",
								"TotalDupReceived",
								"TotalDupRemaining",
								"SalePointId"
							) VALUES (
								(ele ->> 'LotteryDate')::DATE,
								(ele ->> 'LotteryChannelId')::INT,
								(ele ->> 'TotalTrans')::INT,
								(ele ->> 'TotalTrans')::INT,
								(ele ->> 'TotalTransDup')::INT,
								(ele ->> 'TotalTransDup')::INT,
								0
							);
							
						ELSE 
						
							UPDATE "Inventory" I
							SET
								"TotalReceived" = I."TotalReceived" + (ele ->> 'TotalTrans')::INT,
								"TotalRemaining" = I."TotalRemaining" + (ele ->> 'TotalTrans')::INT,
								"TotalDupReceived" = I."TotalDupReceived" + (ele ->> 'TotalTransDup')::INT,
								"TotalDupRemaining" = I."TotalDupRemaining" + (ele ->> 'TotalTransDup')::INT
							WHERE I."LotteryDate" = (ele ->> 'LotteryDate')::DATE
								AND I."LotteryChannelId" = (ele ->> 'LotteryChannelId')::INT
								AND I."SalePointId" = 0;
						
						END IF;
					ELSE
						UPDATE "Scratchcard"
						SET "TotalRemaining" = "TotalRemaining" - COALESCE((ele ->> 'TotalTrans')::INT, 0)
						WHERE "SalePointId" = p_sale_point_id 
							AND "LotteryChannelId" = (ele ->> 'LotteryChannelId')::INT;
							
						IF NOT EXISTS (SELECT 1 FROM "Scratchcard" WHERE "SalePointId" = 0 
							AND "LotteryChannelId" = (ele ->> 'LotteryChannelId')::INT) THEN
							
							INSERT INTO "Scratchcard"(
								"LotteryChannelId",
								"TotalReceived",
								"TotalRemaining",
								"SalePointId"
							) VALUES (
								(ele ->> 'LotteryChannelId')::INT,
								(ele ->> 'TotalTrans')::INT,
								(ele ->> 'TotalTrans')::INT,
								0
							);
							
						ELSE 
						
							UPDATE "Scratchcard" I
							SET
								"TotalReceived" = I."TotalReceived" + (ele ->> 'TotalTrans')::INT,
								"TotalRemaining" = I."TotalRemaining" + (ele ->> 'TotalTrans')::INT							
							WHERE I."LotteryChannelId" = (ele ->> 'LotteryChannelId')::INT
								AND I."SalePointId" = 0;
								
						END IF;
					END IF;
					

				
				ELSEIF p_trans_type_id = 2 THEN 
					IF ((ele ->> 'IsScratchcard')::BOOL) IS FALSE THEN	
						IF COALESCE((ele ->> 'TotalTrans')::INT, 0) > 0 THEN
							
							IF NOT EXISTS (SELECT I."InventoryId" 
												FROM "Inventory" I 
												WHERE I."LotteryChannelId" =  (ele ->> 'LotteryChannelId')::INT
												AND I."SalePointId" = p_sale_point_id
												AND I."LotteryDate" = (ele ->> 'LotteryDate')::DATE)
							THEN
									
										INSERT INTO "Inventory"(
										"LotteryDate",
										"LotteryChannelId",
										"TotalReceived",
										"TotalRemaining",
										"TotalDupReceived",
										"TotalDupRemaining",
										"SalePointId"
									) VALUES (
										(ele ->> 'LotteryDate')::DATE,
										(ele ->> 'LotteryChannelId')::INT,
										0,
										(ele ->> 'TotalTrans')::INT,
										0,
										(ele ->> 'TotalTransDup')::INT,
										p_sale_point_id
									);
										
							ELSE
									
									UPDATE "Inventory"
									SET
										"TotalRemaining" = "TotalRemaining" + (ele ->> 'TotalTrans')::INT
									WHERE "SalePointId" = p_sale_point_id
										AND "LotteryDate" = (ele ->> 'LotteryDate')::DATE
										AND "LotteryChannelId" = (ele ->> 'LotteryChannelId')::INT;
							END IF;
								
						
						END IF;
					
						IF COALESCE((ele ->> 'TotalTransDup')::INT, 0) > 0 THEN
							IF EXISTS (SELECT I."InventoryId" 
												FROM "Inventory" I 
												WHERE I."LotteryChannelId" =  (ele ->> 'LotteryChannelId')::INT
												AND I."SalePointId" = p_sale_point_id
												AND I."LotteryDate" = (ele ->> 'LotteryDate')::DATE)
							THEN
								UPDATE "Inventory"
								SET
									"TotalDupRemaining" = "TotalDupRemaining" + (ele ->> 'TotalTransDup')::INT
								WHERE "SalePointId" = p_sale_point_id
									AND "LotteryDate" = (ele ->> 'LotteryDate')::DATE
									AND "LotteryChannelId" = (ele ->> 'LotteryChannelId')::INT;
							ELSE
								INSERT INTO "Inventory"(
										"LotteryDate",
										"LotteryChannelId",
										"TotalReceived",
										"TotalRemaining",
										"TotalDupReceived",
										"TotalDupRemaining",
										"SalePointId"
									) VALUES (
										(ele ->> 'LotteryDate')::DATE,
										(ele ->> 'LotteryChannelId')::INT,
										0,
										(ele ->> 'TotalTrans')::INT,
										0,
										(ele ->> 'TotalTransDup')::INT,
										p_sale_point_id
									);
									END IF;
								
						END IF;
					
						SELECT "InventoryId", "TotalRemaining", "TotalDupRemaining"
						INTO  v_inventory_id, v_total, v_total_dup
						FROM "Inventory" I
						WHERE I."LotteryDate" = (ele ->> 'LotteryDate')::DATE
							AND I."LotteryChannelId" = (ele ->> 'LotteryChannelId')::INT
							AND I."SalePointId" = 0;
						
						IF v_total >= (ele ->> 'TotalTrans')::INT THEN 
						
							UPDATE "Inventory" I
							SET
								"TotalRemaining" = I."TotalRemaining" -  (ele ->> 'TotalTrans')::INT
							WHERE I."InventoryId" = v_inventory_id;
						
						END IF;
						
						IF v_total_dup >= (ele ->> 'TotalTransDup')::INT THEN 
						
							UPDATE "Inventory" I
							SET
								"TotalDupRemaining" = I."TotalDupRemaining" - (ele ->> 'TotalTransDup')::INT
							WHERE I."InventoryId" = v_inventory_id;
						
						END IF;
					ELSE
					if NOT  EXISTS(SELECT 1 FROM "Scratchcard" WHERE "LotteryChannelId" = (ele ->> 'LotteryChannelId')::INT and "SalePointId" = p_sale_point_id)   then
						INSERT INTO "Scratchcard"(
								"LotteryChannelId",
								"TotalReceived",
								"TotalRemaining",
								"SalePointId"
							) VALUES (
								(ele ->> 'LotteryChannelId')::INT,
								(ele ->> 'TotalTrans')::INT,
								(ele ->> 'TotalTrans')::INT,
								p_sale_point_id
							);
							 
						else
					
						UPDATE "Scratchcard"
						SET "TotalRemaining" = "TotalRemaining" + COALESCE((ele ->> 'TotalTrans')::INT, 0)
						WHERE "SalePointId" = p_sale_point_id 
							AND "LotteryChannelId" = (ele ->> 'LotteryChannelId')::INT;
						END IF;
						IF EXISTS (SELECT 1 FROM "Scratchcard" WHERE "SalePointId" = 0 
							AND "LotteryChannelId" = (ele ->> 'LotteryChannelId')::INT) THEN

							UPDATE "Scratchcard" I
							SET
								"TotalReceived" = I."TotalReceived" - (ele ->> 'TotalTrans')::INT,
								"TotalRemaining" = I."TotalRemaining" - (ele ->> 'TotalTrans')::INT							
							WHERE I."LotteryChannelId" = (ele ->> 'LotteryChannelId')::INT
								AND I."SalePointId" = 0;
								
						END IF;
							
					END IF;
				
				ELSEIF p_trans_type_id = 3 THEN
				
					IF COALESCE((ele ->> 'TotalTrans')::INT, 0) > 0 THEN
				
						UPDATE "Inventory"
						SET
							"TotalRemaining" = "TotalRemaining" - (ele ->> 'TotalTrans')::INT
						WHERE "SalePointId" = p_sale_point_id
							AND "LotteryDate" = (ele ->> 'LotteryDate')::DATE
							AND "LotteryChannelId" = (ele ->> 'LotteryChannelId')::INT;
					
					END IF;
				
					IF COALESCE((ele ->> 'TotalTransDup')::INT, 0) > 0 THEN
					
						UPDATE "Inventory"
						SET
							"TotalDupRemaining" = "TotalDupRemaining" - (ele ->> 'TotalTransDup')::INT
						WHERE "SalePointId" = p_sale_point_id
							AND "LotteryDate" = (ele ->> 'LotteryDate')::DATE
							AND "LotteryChannelId" = (ele ->> 'LotteryChannelId')::INT;
					
					END IF;
					
					IF NOT EXISTS (SELECT 1 FROM "Inventory" WHERE "SalePointId" = 0 
						AND "LotteryDate" = (ele ->> 'LotteryDate')::DATE
						AND "LotteryChannelId" = (ele ->> 'LotteryChannelId')::INT) THEN
						
						INSERT INTO "Inventory"(
							"LotteryDate",
							"LotteryChannelId",
							"TotalReceived",
							"TotalRemaining",
							"TotalDupReceived",
							"TotalDupRemaining",
							"SalePointId"
						) VALUES (
							(ele ->> 'LotteryDate')::DATE,
							(ele ->> 'LotteryChannelId')::INT,
							(ele ->> 'TotalTrans')::INT,
							(ele ->> 'TotalTrans')::INT,
							(ele ->> 'TotalTransDup')::INT,
							(ele ->> 'TotalTransDup')::INT,
							p_sale_point_id
						);
						
					ELSE 
					
						UPDATE "Inventory" I
						SET
							"TotalReceived" = I."TotalReceived" + (ele ->> 'TotalTrans')::INT,
							"TotalRemaining" = I."TotalRemaining" + (ele ->> 'TotalTrans')::INT,
							"TotalDupReceived" = I."TotalDupReceived" + (ele ->> 'TotalTransDup')::INT,
							"TotalDupRemaining" = I."TotalDupRemaining" + (ele ->> 'TotalTransDup')::INT
						WHERE I."LotteryDate" = (ele ->> 'LotteryDate')::DATE
							AND I."LotteryChannelId" = (ele ->> 'LotteryChannelId')::INT
							AND I."SalePointId" = 0;
					
					END IF;
				
				ELSE
					
					v_id := -1;
					v_mess := 'Có lỗi xảy ra';
					
				END IF;
			END IF;
			END LOOP;
		
		ELSE 
		
			FOR ele IN SELECT * FROM json_array_elements(p_list_item::JSON) LOOP 	
				IF ((ele ->> 'IsScratchcard')::BOOL) IS FALSE THEN	
					if EXISTS (select 1 from "Transition" where "TransitionId" = (ele ->> 'TransitionId')::INT and "ShiftDistributeId"= -1  AND "ConfirmStatusId" = 1 and "ToSalePointId"=p_sale_point_id) then
					UPDATE "InventoryFull"  set "TotalRemaining"="TotalRemaining" +(select "TotalTrans" from "Transition" where "TransitionId" = (ele ->> 'TransitionId')::INT and "ShiftDistributeId"= -1  AND "ConfirmStatusId" = 1 and "ToSalePointId"=p_sale_point_id)
					where "LotteryChannelId" = (ele ->> 'LotteryChannelId')::INT and "LotteryDate" = (ele ->> 'LotteryDate')::DATE ;
					UPDATE "InventoryLog" set "TotalReceived"="TotalReceived"-(select "TotalTrans" from "Transition" where "TransitionId" = (ele ->> 'TransitionId')::INT and "ShiftDistributeId"= -1 AND "ConfirmStatusId" = 1 )
					where "LotteryChannelId" = (ele ->> 'LotteryChannelId')::INT and "LotteryDate" = (ele ->> 'LotteryDate')::DATE and "SalePointId"=p_sale_point_id;
					End if;
				ELSE
					
						UPDATE "ScratchcardFull"
						SET "TotalRemaining" = "TotalRemaining" + COALESCE((ele ->> 'TotalTrans')::INT, 0)
						WHERE 
							 "LotteryChannelId" = (ele ->> 'LotteryChannelId')::INT;
							
				END IF;
				
				UPDATE "Transition"
				SET
					"ConfirmBy" = v_user_id,
					"ConfirmByName" = v_name,
					"ConfirmDate" = NOW(),
					"ConfirmStatusId" = 3,
					"Note" = p_note
				WHERE "TransitionId" = (ele ->> 'TransitionId')::INT;
-- 					AND "ConfirmStatusId" = 1 and "ToSalePointId" = p_sale_point_id;
					
					
			END LOOP;	
		
		END IF;
	
		v_id := 1;
		v_mess := 'Xác nhận thành công';

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

ALTER FUNCTION public.crm_activity_confirm_transition_v3(integer, character varying, text, boolean, integer, integer)
    OWNER TO postgres;
