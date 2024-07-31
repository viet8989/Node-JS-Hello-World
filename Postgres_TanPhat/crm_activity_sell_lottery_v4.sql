CREATE OR REPLACE FUNCTION public.crm_activity_sell_lottery_v4(p_shift_dis_id integer, p_user_role_id integer, p_action_by integer, p_action_by_name character varying, p_data text, p_guest_id integer DEFAULT NULL::integer, p_order_id integer DEFAULT NULL::integer)
 RETURNS TABLE("Id" integer, "Message" text, "OrderId" integer, "PromotionCode" text)
 LANGUAGE plpgsql
AS $function$
DECLARE 
	v_id INT;
	v_mess TEXT;
	v_data JSON := p_data::JSON;
	v_sale_point_id INT;
	v_user_id INT;
	ele JSON;
	v_shift_dis_id INT;
	v_is_super_admin BOOL;
	v_is_manager BOOL;
	v_is_staff BOOL;
	v_check INT := 0;
	v_time TIMESTAMP DEFAULT NOW();
	v_array INT[] := '{}'::INT[];
	v_tmp INT;
	v_step INT;
	v_quantity INT;
	v_promotioncode TEXT;
	v_data_promotion TEXT;
	v_data_promotion_id TEXT;
	v_regionId TEXT;
BEGIN	
	SELECT 
		f."IsSuperAdmin",
		f."IsManager",
		f."IsStaff",
		f."SalePointId",
		f."ShiftDistributeId"
	INTO v_is_super_admin, v_is_manager, v_is_staff, v_sale_point_id, v_shift_dis_id
	FROM fn_get_shift_info(p_user_role_id) f;
	
		--Tạo hoá đơn khi chưa có
	IF p_order_id IS NULL THEN
		
		INSERT INTO "HistoryOfOrder" (
			"SalePointId",
			"CreatedBy",
			"CreatedByName",
			"CreatedDate",
			"IsDeleted",
			"ShiftDistributeId"
		)
		VALUES (
			v_sale_point_id,
			p_action_by,
			p_action_by_name,
			v_time,
			FALSE,
			v_shift_dis_id
		) RETURNING "HistoryOfOrderId" INTO p_order_id;
		
	END IF;
	
	--Lấy danh sách id bán hàng
	SELECT "SalePointLogIds" INTO v_array FROM "HistoryOfOrder" WHERE "HistoryOfOrderId" = p_order_id;
	IF v_array IS NULL THEN 
		v_array := '{}'::INT[];
	END IF;
	
	
	
	IF COALESCE(v_sale_point_id, 0) > 0 THEN
		FOR ele IN SELECT * FROM json_array_elements(v_data) LOOP
			IF COALESCE(p_guest_id,NULL) IS NOT NULL
			THEN
				v_quantity:=0;
			ELSEIF (ele ->> 'LotteryChannelId')::INT < 1000
			THEN
				v_quantity= COALESCE(v_quantity,0) + (ele ->> 'Quantity')::INT;
			END IF;
		END LOOP;
		
		v_step := (SELECT (v_quantity::INT / P."Step") FROM "Promotion" P LIMIT 1);
		v_regionId:=(select "RegionId" from "LotteryChannel" where "LotteryChannelId"=(ele ->> 'LotteryChannelId')::INT);
		IF(v_step > 0 and  v_regionId::INT =7)
		THEN
			v_data_promotion := (with tmp AS(SELECT P."PromotionCodeId",P."PromotionCode" FROM "PromotionCode" P WHERE P."Date" = NOW()::DATE AND P."IsUsed" IS FALSE LIMIT v_step) SELECT array_agg(T."PromotionCode") FROM tmp T )::TEXT;
			v_data_promotion_id := (with tmp AS(SELECT P."PromotionCodeId",P."PromotionCode" FROM "PromotionCode" P WHERE P."Date" = NOW()::DATE AND P."IsUsed" = FALSE  LIMIT v_step) SELECT array_agg(T."PromotionCodeId") FROM tmp T )::TEXT;
		END IF;
		
		raise notice 'v_data_promotion, %', v_data_promotion;
		
		FOR ele IN SELECT * FROM json_array_elements(v_data) LOOP
	
			INSERT INTO "SalePointLog"(
				"SalePointId",
				"LotteryDate",
				"LotteryChannelId",
				"Quantity",
				"LotteryTypeId",
				"LotteryPriceId",
				"TotalValue",
				"ActionBy",
				"ActionByName",
				"ShiftDistributeId",
				"GuestId",
				"HistoryOfOrderId",
				"FourLastNumber"
			) VALUES(
				v_sale_point_id,
				(CASE WHEN (ele ->> 'LotteryTypeId')::INT = 3 THEN NULL::DATE ELSE (ele ->> 'LotteryDate')::DATE END),
				(ele ->> 'LotteryChannelId')::INT,
				(ele ->> 'Quantity')::INT,
				(ele ->> 'LotteryTypeId')::INT,
				(ele ->> 'LotteryPriceId')::INT,
				(SELECT (CASE WHEN (ele ->> 'Quantity')::INT >= 110 AND (ele ->> 'LotteryPriceId')::INT = 6 THEN  CEIL((ele ->> 'Quantity')::INT * LP."Price") + ((ele ->> 'Quantity')::INT /100) ELSE CEIL((ele ->> 'Quantity')::INT * LP."Price") END) FROM "LotteryPrice" LP WHERE LP."LotteryPriceId" = (ele ->> 'LotteryPriceId')::INT),
				p_action_by,
				p_action_by_name,
				v_shift_dis_id,
				COALESCE(p_guest_id,NULL),
				p_order_id,
				(ele->>'FourLastNumber')::VARCHAR
			) RETURNING "SalePointLogId" INTO v_tmp;
			IF (ele ->> 'LotteryChannelId')::INT < 1000
			THEN
				SELECT * INTO v_mess FROM crm_update_reward_lottery(NOW()::DATE,v_tmp, v_data_promotion, v_data_promotion_id);
			END IF;

			
			v_array := array_append(v_array, v_tmp);
			
			IF (ele ->> 'LotteryTypeId')::INT = 1 THEN 
			
				UPDATE "Inventory"
				SET
					"TotalRemaining" = "TotalRemaining" - (ele ->> 'Quantity')::INT
				WHERE "SalePointId" = v_sale_point_id
					AND "LotteryDate" = (ele ->> 'LotteryDate')::DATE
					AND "LotteryChannelId" = (ele ->> 'LotteryChannelId')::INT
				RETURNING "TotalRemaining" INTO v_check;
				
				IF v_check < 0 THEN
					RAISE 'Số lượng vé đã thay đổi không đủ vé để bán';
				END IF;
			
			ELSEIF (ele ->> 'LotteryTypeId')::INT = 2 THEN
			
				UPDATE "Inventory"
				SET
					"TotalDupRemaining" = "TotalDupRemaining" - (ele ->> 'Quantity')::INT
				WHERE "SalePointId" = v_sale_point_id
					AND "LotteryDate" = (ele ->> 'LotteryDate')::DATE
					AND "LotteryChannelId" = (ele ->> 'LotteryChannelId')::INT
				RETURNING "TotalDupRemaining" INTO v_check;
				
				IF v_check < 0 THEN
					RAISE 'Số lượng vé đã thay đổi không đủ vé để bán';
				END IF;
			
			ELSE
			
				UPDATE "Scratchcard"
				SET
					"TotalRemaining" = "TotalRemaining" - (ele ->> 'Quantity')::INT
				WHERE "SalePointId" = v_sale_point_id
					AND "LotteryChannelId" = (ele ->> 'LotteryChannelId')::INT
				RETURNING "TotalRemaining" INTO v_check;
				
				IF v_check < 0 THEN
					RAISE 'Số lượng vé đã thay đổi không đủ vé để bán';
				END IF;
					
			
			END IF;
			
	
		END LOOP;
		
		UPDATE "HistoryOfOrder" 
		SET 
			"SalePointLogIds" = v_array
		WHERE "HistoryOfOrderId" = p_order_id;
		v_id := v_sale_point_id;
		v_mess := 'Lưu thành công';
	
	ELSE 
 
		v_id := 0;
		v_mess := 'Nhân viên không trong ca làm việc';
 
	END IF;
	
	RETURN QUERY 
	SELECT 	v_id, v_mess, p_order_id, v_data_promotion;

	EXCEPTION WHEN OTHERS THEN
	BEGIN				
		v_id := -1;
		v_mess := sqlerrm;
		
		RETURN QUERY 
		SELECT 	v_id, v_mess, p_order_id;
	END;

END;
$function$
