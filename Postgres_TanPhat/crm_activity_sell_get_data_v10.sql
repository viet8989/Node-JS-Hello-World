CREATE OR REPLACE FUNCTION public.crm_activity_sell_get_data_v10(p_shift_distribute_id integer, p_user_role_id integer, p_date timestamp without time zone)
 RETURNS TABLE("ManagerId" integer, "ManagerName" character varying, "UserId" integer, "SalePointId" integer, "SalePointName" character varying, "ShiftDistributeId" integer, "Flag" boolean, "TodayData" text, "TomorrowData" text, "ScratchcardData" text, "SoldData" text, "SoldLoto" text, "LCNameTd" text, "LCNameTm" text, "SalePointAddress" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE 
	v_sale_point_id INT;
	v_sale_point_name VARCHAR;
	v_shift_dis_id INT;
	v_is_super_admin BOOL;
	v_is_manager BOOL;
	v_is_staff BOOL;
	v_user_id INT;
	v_user_check INT;
	v_shift_id INT;
	v_shift_bef_dis_id INT;
	v_flag BOOL;
	v_sale_point_address VARCHAR;
	v_temp INT;
	v_total_leader INT;
	v_dayids int[];
BEGIN

	
	with tmp AS(
	SELECT COUNT(U."UserId") AS "Leaders" FROM "User" U LEFT JOIN "UserRole" UR ON UR."UserId" = U."UserId" WHERE U."IsActive" = TRUE AND UR."UserTitleId" = 4 
	) SELECT T."Leaders" * (T."Leaders" + 1) INTO v_total_leader FROM tmp T;
	SELECT UR."UserId" INTO v_user_check
	FROM "UserRole" UR 
	WHERE UR."UserRoleId" = p_user_role_id;

	SELECT SD."ShiftDistributeId", SD."ShiftId" , SD."SalePointId" INTO v_shift_dis_id, v_shift_id ,v_sale_point_id
	FROM "ShiftDistribute" SD
	WHERE SD."ShiftDistributeId" = p_shift_distribute_id
		AND SD."DistributeDate" = p_date;
	
	IF v_shift_id IS NULL THEN
		SELECT 
			SD."SalePointId", 
			SD."UserId", 
			FALSE
			INTO v_sale_point_id, v_user_id, v_flag
		FROM "ShiftDistribute" SD
		WHERE SD."ShiftDistributeId" = p_shift_distribute_id;
	
	ELSEIF v_shift_id = 1 THEN 
	
		SELECT 
			SD."SalePointId", 
			SD."UserId", 
			(CASE WHEN EXISTS (SELECT 1 FROM "ShiftTransfer" SF WHERE SF."ShiftDistributeId" = v_shift_dis_id) THEN FALSE ELSE TRUE END)
			INTO v_sale_point_id, v_user_id, v_flag
		FROM "ShiftDistribute" SD
		WHERE SD."ShiftDistributeId" = v_shift_dis_id;
		
	ELSE
	
		SELECT SD."ShiftDistributeId" INTO v_shift_bef_dis_id 
		FROM "ShiftDistribute" SD 
		WHERE SD."DistributeDate" = p_date
			AND SD."ShiftId" =  1
			AND SD."SalePointId" =  v_sale_point_id;
			
		IF(EXISTS (SELECT 1 FROM "ShiftTransfer" SF WHERE SF."ShiftDistributeId" = v_shift_bef_dis_id) OR v_shift_bef_dis_id IS NULL) THEN
		
			SELECT 
				SD."SalePointId", 
				SD."UserId" , 
				(CASE WHEN EXISTS (SELECT 1 FROM "ShiftTransfer" SF WHERE SF."ShiftDistributeId" = v_shift_dis_id) THEN FALSE ELSE TRUE END)
				INTO v_sale_point_id, v_user_id, v_flag
			FROM "ShiftDistribute" SD
			WHERE SD."ShiftDistributeId" = p_shift_distribute_id;
			
		END IF;

	END IF;
	
	SELECT SP."SalePointName", SP."FullAddress" INTO v_sale_point_name, v_sale_point_address FROM "SalePoint" SP WHERE SP."SalePointId" = v_sale_point_id;
	IF(v_user_id IS NOT NULL AND v_user_id = v_user_check) THEN
		
			IF (EXISTS (SELECT 1  FROM "LeaderOffLog" LOL WHERE LOL."WorkingDate" = p_date::DATE) ) THEN
		
			RETURN QUERY 
	SELECT 
		(
			with tmp AS(
				SELECT SD."UserId", SD."SalePointId",SD."ShiftId" 
					FROM "ShiftDistribute" SD 
				WHERE SD."DistributeDate"::DATE =p_date::DATE AND SD."UserId" = v_user_id AND SD."ShiftDistributeId" = p_shift_distribute_id
					GROUP BY SD."SalePointId", SD."UserId",SD."ShiftId"
			),tmp1 AS (SELECT * FROM "GroupSalePoint" GSP  ORDER BY GSP."GroupSalePointId" DESC LIMIT v_total_leader)
			,tmp2 AS(
			SELECT GSP."UserId" FROM "tmp1" GSP
				LEFT JOIN tmp T ON T."SalePointId" = ANY (GSP."SalePointIds")
				LEFT JOIN "UserRole" UR ON UR."UserId" = GSP."UserId"
				LEFT JOIN "ShiftDistribute" SD ON SD."SalePointId" = T."SalePointId"
			WHERE UR."UserTitleId" = 4  AND SD."DistributeDate"::DATE =  p_date::DATE AND GSP."UserId" <> (SELECT LOL."UserId"  FROM "LeaderOffLog" LOL WHERE LOL."WorkingDate" =   p_date::DATE GROUP BY LOL."UserId" LIMIT 1)
					GROUP BY GSP."UserId",
					GSP."GroupSalePointId",
					GSP."Option" 
				ORDER BY GSP."Option" ASC ,GSP."GroupSalePointId" DESC
					LIMIT 1
				)
				SELECT T."UserId" FROM tmp2 T GROUP BY T."UserId"
		)
		 As "ManagerId",
			(
			with tmp AS(
						SELECT SD."UserId", SD."SalePointId",SD."ShiftId" 
					FROM "ShiftDistribute" SD 
				WHERE SD."DistributeDate"::DATE = p_date::DATE AND SD."UserId" = v_user_id AND SD."ShiftDistributeId" = p_shift_distribute_id
					GROUP BY SD."SalePointId", SD."UserId",SD."ShiftId"
				), tmp1 AS (SELECT * FROM "GroupSalePoint" GSP  ORDER BY GSP."GroupSalePointId" DESC LIMIT v_total_leader)
				,tmp2 AS (SELECT U."FullName",GSP."GroupSalePointId" FROM "tmp1" GSP
						LEFT JOIN tmp T ON T."SalePointId" = ANY (GSP."SalePointIds")
						LEFT JOIN "UserRole" UR ON UR."UserId" = GSP."UserId"
						LEFT JOIN "User" U ON U."UserId" = UR."UserId"
						LEFT JOIN "ShiftDistribute" SD ON SD."SalePointId" = T."SalePointId" WHERE UR."UserTitleId" = 4  AND SD."DistributeDate"::DATE =  p_date::DATE AND GSP."UserId" <> (SELECT LOL."UserId"  FROM "LeaderOffLog" LOL WHERE LOL."WorkingDate" =  p_date::DATE GROUP BY LOL."UserId" LIMIT 1)
						GROUP BY 
							GSP."UserId",
							U."FullName",
							GSP."GroupSalePointId",
							GSP."Option" 
					ORDER BY GSP."Option" ASC ,GSP."GroupSalePointId" DESC
					LIMIT 1
					)
					SELECT T."FullName" FROM tmp2 T GROUP BY T."FullName"
			) As "ManagerName",
			v_user_id,
			v_sale_point_id,
			v_sale_point_name,
			p_shift_distribute_id,
			v_flag,
			(
				SELECT array_to_json(
					ARRAY_AGG (r))
				FROM
				(
					SELECT
						ROW_NUMBER() OVER(ORDER BY LCT."LotteryChannelTypeId") AS "RowNumber",
						I."LotteryDate",
						I."LotteryChannelId",
						IC."LotteryChannelName",
						IC."RetailPrice",
						I."TotalRemaining",
						I."TotalDupRemaining",
						IC."ShortName",
						LCT."ShortName" AS "ChannelTypeShortName",
					IC."RegionId"
					FROM "Inventory" I
						JOIN "LotteryChannel" IC ON IC."LotteryChannelId" = I."LotteryChannelId"
						LEFT JOIN "LotteryChannelType" LCT ON LCT."LotteryChannelTypeId" = IC."LotteryChannelTypeId"
					WHERE I."LotteryDate" = p_date::DATE AND I."SalePointId" = v_sale_point_id
					ORDER BY I."LotteryDate", IC."LotteryChannelTypeId"
				) r
			)::TEXT AS "TodayData",
			(
				SELECT array_to_json(
					ARRAY_AGG (r))
				FROM
				(
					SELECT
						ROW_NUMBER() OVER(ORDER BY LCT."LotteryChannelTypeId") AS "RowNumber",
						I."LotteryDate",
						I."LotteryChannelId",
						IC."LotteryChannelName",
						IC."RetailPrice",
						I."TotalRemaining",
						I."TotalDupRemaining",
						IC."ShortName",
						LCT."ShortName" AS "ChannelTypeShortName",
					IC."RegionId"
					FROM "Inventory" I
						JOIN "LotteryChannel" IC ON IC."LotteryChannelId" = I."LotteryChannelId"
						LEFT JOIN "LotteryChannelType" LCT ON LCT."LotteryChannelTypeId" = IC."LotteryChannelTypeId"
					WHERE I."LotteryDate" = (p_date + '1 day'::INTERVAL)::DATE AND I."SalePointId" = v_sale_point_id
					ORDER BY I."LotteryDate", IC."LotteryChannelTypeId"
				) r
			)::TEXT AS "TomorrowData",
			(
				SELECT array_to_json(
					ARRAY_AGG (r))
				FROM
				(
					SELECT
						ROW_NUMBER() OVER() AS "RowNumber",
						S."TotalRemaining",
						S."LotteryChannelId",
						LC."ShortName",
						LC."LotteryChannelName",
						LC."RetailPrice"
					FROM "Scratchcard" S
						JOIN "LotteryChannel" LC ON LC."LotteryChannelId" = S."LotteryChannelId"
					WHERE S."SalePointId" = v_sale_point_id
					ORDER BY LC."LotteryChannelTypeId"
				) r
			)::TEXT AS "ScratchcardData",
			(
				SELECT array_to_json(
					ARRAY_AGG (r))
				FROM
				(
					SELECT
						SUM(SL."Quantity") FILTER(WHERE SL."LotteryPriceId" NOT IN(1,6)) AS "TotalWholesaleQuantity",
						SUM(SL."TotalValue") FILTER(WHERE SL."LotteryPriceId" NOT IN(1,6)) AS "TotalWholesalePrice",
						SUM(SL."Quantity") FILTER(WHERE SL."LotteryPriceId" IN(1,6)) AS "TotalRetailQuantity",
						SUM(SL."TotalValue") FILTER(WHERE SL."LotteryPriceId" IN(1,6)) AS "TotalRetailPrice"
					FROM "SalePointLog" SL
					WHERE SL."ShiftDistributeId" = v_shift_dis_id AND SL."IsDeleted" IS FALSE
				) r
			)::TEXT AS "SoldData",
			(
				SELECT array_to_json(
					ARRAY_AGG (r))
				FROM
				(
					SELECT
					LT."TransactionCode",
						LT."LotoType",
						LT."Type",
						LC."LotteryChannelName",
					LT."Seri",
					LT."IntoMoney",
					LT."ShiftId",
					TO_CHAR(LT."Time", 'DD/MM/YYYY HH24:MI:SS') AS Time
						
					FROM "LotoNew" LT inner join "LotteryChannel" LC on LT."LotteryChannelId"=LC."LotteryChannelId"
					WHERE LT."SalePointId" = v_sale_point_id and  LT."Time"::date = p_date::date  and LT."IsDelete"=true and LT."ShiftId"=v_shift_id  
					order by LT."Time" DESC
				) r
			)::TEXT AS "SoldLoto",
			(
				SELECT array_to_json(
					ARRAY_AGG (r))
				FROM
				(
					SELECT LT."LotteryChannelId",LT."LotteryChannelName" FROM "LotteryChannel" LT WHERE "DayIds" in (Select LT."DayIds" from "LotteryChannel" LT 
			JOIN "Inventory" I
				on  LT."LotteryChannelId" = I."LotteryChannelId"
			where 
				I."LotteryDate"::date=p_date::DATE ) and LT."RegionId"=2
-- 					ORDER BY CASE LT."RegionId"
-- 				WHEN 2 THEN 1
-- 				WHEN 3 THEN 2
-- 				WHEN 1 THEN 3

-- 			END
				) r
			)::TEXT AS "LCNameTd",
			(
				SELECT array_to_json(
					ARRAY_AGG (r))
				FROM
				(
					SELECT LT."LotteryChannelId",LT."LotteryChannelName" FROM "LotteryChannel" LT WHERE "DayIds" in (Select LT."DayIds" from "LotteryChannel" LT 
			JOIN "Inventory" I
				on  LT."LotteryChannelId" = I."LotteryChannelId"
			where 
				I."LotteryDate"::date=(p_date::date + '1 day'::INTERVAL)::DATE ) and LT."RegionId"=2
-- 					ORDER BY CASE LT."RegionId"
-- 					WHEN 2 THEN 1
-- 					WHEN 3 THEN 2
-- 					WHEN 1 THEN 3

-- 				END
				) r
			)::TEXT AS "LCNameTm",
			v_sale_point_address;
		ELSE
		RETURN QUERY 
			SELECT 
		(
			with tmp AS(
				SELECT SD."UserId", SD."SalePointId",SD."ShiftId" 
					FROM "ShiftDistribute" SD 
				WHERE SD."DistributeDate"::DATE =p_date::DATE AND SD."UserId" = v_user_id AND SD."ShiftDistributeId" = p_shift_distribute_id
					GROUP BY SD."SalePointId", SD."UserId",SD."ShiftId"
			),tmp1 AS (SELECT * FROM "GroupSalePoint" GSP  ORDER BY GSP."GroupSalePointId" DESC LIMIT v_total_leader)
			,tmp2 AS(
			SELECT GSP."UserId" FROM "tmp1" GSP
				LEFT JOIN tmp T ON T."SalePointId" = ANY (GSP."SalePointIds")
				LEFT JOIN "UserRole" UR ON UR."UserId" = GSP."UserId"
				LEFT JOIN "ShiftDistribute" SD ON SD."SalePointId" = T."SalePointId"
			WHERE UR."UserTitleId" = 4  AND SD."DistributeDate"::DATE =  p_date::DATE
					GROUP BY GSP."UserId",
					GSP."GroupSalePointId",
					GSP."Option" 
				ORDER BY GSP."Option" ASC ,GSP."GroupSalePointId" DESC
					LIMIT 1
				)
				SELECT T."UserId" FROM tmp2 T GROUP BY T."UserId"
		)
		 As "ManagerId",
			(
			with tmp AS(
						SELECT SD."UserId", SD."SalePointId",SD."ShiftId" 
					FROM "ShiftDistribute" SD 
				WHERE SD."DistributeDate"::DATE = p_date::DATE AND SD."UserId" = v_user_id AND SD."ShiftDistributeId" = p_shift_distribute_id
					GROUP BY SD."SalePointId", SD."UserId",SD."ShiftId"
				), tmp1 AS (SELECT * FROM "GroupSalePoint" GSP  ORDER BY GSP."GroupSalePointId" DESC LIMIT v_total_leader)
				,tmp2 AS (SELECT U."FullName",GSP."GroupSalePointId" FROM "tmp1" GSP
						LEFT JOIN tmp T ON T."SalePointId" = ANY (GSP."SalePointIds")
						LEFT JOIN "UserRole" UR ON UR."UserId" = GSP."UserId"
						LEFT JOIN "User" U ON U."UserId" = UR."UserId"
						LEFT JOIN "ShiftDistribute" SD ON SD."SalePointId" = T."SalePointId" WHERE UR."UserTitleId" = 4  AND SD."DistributeDate"::DATE =  p_date::DATE 
						GROUP BY 
							GSP."UserId",
							U."FullName",
							GSP."GroupSalePointId",
							GSP."Option" 
					ORDER BY GSP."Option" ASC , GSP."GroupSalePointId" DESC
					LIMIT 1
					)
					SELECT T."FullName" FROM tmp2 T GROUP BY T."FullName"
			) As "ManagerName",
			v_user_id,
			v_sale_point_id,
			v_sale_point_name,
			p_shift_distribute_id,
			v_flag,
			(
				SELECT array_to_json(
					ARRAY_AGG (r))
				FROM
				(
					SELECT
						ROW_NUMBER() OVER(ORDER BY LCT."LotteryChannelTypeId") AS "RowNumber",
						I."LotteryDate",
						I."LotteryChannelId",
						IC."LotteryChannelName",
						IC."RetailPrice",
						I."TotalRemaining",
						I."TotalDupRemaining",
						IC."ShortName",
						LCT."ShortName" AS "ChannelTypeShortName",
					IC."RegionId"
					FROM "Inventory" I
						JOIN "LotteryChannel" IC ON IC."LotteryChannelId" = I."LotteryChannelId"
						LEFT JOIN "LotteryChannelType" LCT ON LCT."LotteryChannelTypeId" = IC."LotteryChannelTypeId"
					WHERE I."LotteryDate" = p_date::DATE AND I."SalePointId" = v_sale_point_id
					ORDER BY I."LotteryDate", IC."LotteryChannelTypeId"
				) r
			)::TEXT AS "TodayData",
			(
				SELECT array_to_json(
					ARRAY_AGG (r))
				FROM
				(
					SELECT
						ROW_NUMBER() OVER(ORDER BY LCT."LotteryChannelTypeId") AS "RowNumber",
						I."LotteryDate",
						I."LotteryChannelId",
						IC."LotteryChannelName",
						IC."RetailPrice",
						I."TotalRemaining",
						I."TotalDupRemaining",
						IC."ShortName",
						LCT."ShortName" AS "ChannelTypeShortName",
					IC."RegionId"
					FROM "Inventory" I
						JOIN "LotteryChannel" IC ON IC."LotteryChannelId" = I."LotteryChannelId"
						LEFT JOIN "LotteryChannelType" LCT ON LCT."LotteryChannelTypeId" = IC."LotteryChannelTypeId"
					WHERE I."LotteryDate" = (p_date + '1 day'::INTERVAL)::DATE AND I."SalePointId" = v_sale_point_id
					ORDER BY I."LotteryDate", IC."LotteryChannelTypeId"
				) r
			)::TEXT AS "TomorrowData",
			
			(
				SELECT array_to_json(
					ARRAY_AGG (r))
				FROM
				(
					SELECT
						ROW_NUMBER() OVER() AS "RowNumber",
						S."TotalRemaining",
						S."LotteryChannelId",
						LC."ShortName",
						LC."LotteryChannelName",
						LC."RetailPrice"
					FROM "Scratchcard" S
						JOIN "LotteryChannel" LC ON LC."LotteryChannelId" = S."LotteryChannelId"
					WHERE S."SalePointId" = v_sale_point_id
					ORDER BY LC."LotteryChannelTypeId"
				) r
			)::TEXT AS "ScratchcardData",
			(
				SELECT array_to_json(
					ARRAY_AGG (r))
				FROM
				(
					SELECT
						SUM(SL."Quantity") FILTER(WHERE SL."LotteryPriceId" NOT IN(1,6)) AS "TotalWholesaleQuantity",
						SUM(SL."TotalValue") FILTER(WHERE SL."LotteryPriceId" NOT IN(1,6)) AS "TotalWholesalePrice",
						SUM(SL."Quantity") FILTER(WHERE SL."LotteryPriceId" IN(1,6)) AS "TotalRetailQuantity",
						SUM(SL."TotalValue") FILTER(WHERE SL."LotteryPriceId" IN(1,6)) AS "TotalRetailPrice"
					FROM "SalePointLog" SL
					WHERE SL."ShiftDistributeId" = v_shift_dis_id AND SL."IsDeleted" IS FALSE
				) r
			)::TEXT AS "SoldData",
				(
				SELECT array_to_json(
					ARRAY_AGG (r))
				FROM
				(
					SELECT
					LT."TransactionCode",
						LT."LotoType",
						LT."Type",
						LC."LotteryChannelName",
					LT."Seri",
					LT."IntoMoney",
					LT."ShiftId",
					TO_CHAR(LT."Time", 'DD/MM/YYYY HH24:MI:SS') AS Time
						
					FROM "LotoNew" LT inner join "LotteryChannel" LC on LT."LotteryChannelId"=LC."LotteryChannelId"
					WHERE LT."SalePointId" = v_sale_point_id and  LT."Time"::date = p_date::date and LT."ShiftId"=v_shift_id  and LT."IsDelete"=true
					order by LT."Time" DESC
				) r
			)::TEXT AS "SoldLoto",
			(
				SELECT array_to_json(
					ARRAY_AGG (r))
				FROM
				(
					SELECT LT."LotteryChannelId",LT."LotteryChannelName" FROM "LotteryChannel" LT WHERE "DayIds" in (Select LT."DayIds" from "LotteryChannel" LT 
			JOIN "Inventory" I
				on  LT."LotteryChannelId" = I."LotteryChannelId"
			where 
				I."LotteryDate"::date=p_date::DATE ) and LT."RegionId"=2
-- 					ORDER BY CASE LT."RegionId"
-- 				WHEN 2 THEN 1
-- 				WHEN 3 THEN 2
-- 				WHEN 1 THEN 3

-- 			END
				) r
			)::TEXT AS "LCNameTd",
			(
				SELECT array_to_json(
					ARRAY_AGG (r))
				FROM
				(
					SELECT LT."LotteryChannelId",LT."LotteryChannelName" FROM "LotteryChannel" LT WHERE "DayIds" in (Select LT."DayIds" from "LotteryChannel" LT 
			JOIN "Inventory" I
				on  LT."LotteryChannelId" = I."LotteryChannelId"
			where 
				I."LotteryDate"::date=(p_date::date + '1 day'::INTERVAL)::DATE ) and LT."RegionId"=2
-- 					ORDER BY CASE LT."RegionId"
-- 					WHEN 2 THEN 1
-- 					WHEN 3 THEN 2
-- 					WHEN 1 THEN 3

-- 				END
				) r
			)::TEXT AS "LCNameTm",
			v_sale_point_address;
			END IF;
		END IF;
END;

-- DECLARE 
-- 	v_sale_point_id INT;
-- 	v_sale_point_name VARCHAR;
-- 	v_shift_dis_id INT;
-- 	v_is_super_admin BOOL;
-- 	v_is_manager BOOL;
-- 	v_is_staff BOOL;
-- 	v_user_id INT;
-- 	v_user_check INT;
-- 	v_shift_id INT;
-- 	v_shift_bef_dis_id INT;
-- 	v_flag BOOL;
-- 	v_sale_point_address VARCHAR;
-- 	v_temp INT;
-- 	v_total_leader INT;
-- 	v_dayids int[];
-- BEGIN

	
-- 	with tmp AS(
-- 	SELECT COUNT(U."UserId") AS "Leaders" FROM "User" U LEFT JOIN "UserRole" UR ON UR."UserId" = U."UserId" WHERE U."IsActive" = TRUE AND UR."UserTitleId" = 4 
-- 	) SELECT T."Leaders" * (T."Leaders" + 1) INTO v_total_leader FROM tmp T;
-- 	SELECT UR."UserId" INTO v_user_check
-- 	FROM "UserRole" UR 
-- 	WHERE UR."UserRoleId" = p_user_role_id;

-- 	SELECT SD."ShiftDistributeId", SD."ShiftId" , SD."SalePointId" INTO v_shift_dis_id, v_shift_id ,v_sale_point_id
-- 	FROM "ShiftDistribute" SD
-- 	WHERE SD."ShiftDistributeId" = p_shift_distribute_id
-- 		AND SD."DistributeDate" = p_date;
	
-- 	IF v_shift_id IS NULL THEN
-- 		SELECT 
-- 			SD."SalePointId", 
-- 			SD."UserId", 
-- 			FALSE
-- 			INTO v_sale_point_id, v_user_id, v_flag
-- 		FROM "ShiftDistribute" SD
-- 		WHERE SD."ShiftDistributeId" = p_shift_distribute_id;
	
-- 	ELSEIF v_shift_id = 1 THEN 
	
-- 		SELECT 
-- 			SD."SalePointId", 
-- 			SD."UserId", 
-- 			(CASE WHEN EXISTS (SELECT 1 FROM "ShiftTransfer" SF WHERE SF."ShiftDistributeId" = v_shift_dis_id) THEN FALSE ELSE TRUE END)
-- 			INTO v_sale_point_id, v_user_id, v_flag
-- 		FROM "ShiftDistribute" SD
-- 		WHERE SD."ShiftDistributeId" = v_shift_dis_id;
		
-- 	ELSE
	
-- 		SELECT SD."ShiftDistributeId" INTO v_shift_bef_dis_id 
-- 		FROM "ShiftDistribute" SD 
-- 		WHERE SD."DistributeDate" = p_date
-- 			AND SD."ShiftId" =  1
-- 			AND SD."SalePointId" =  v_sale_point_id;
			
-- 		IF(EXISTS (SELECT 1 FROM "ShiftTransfer" SF WHERE SF."ShiftDistributeId" = v_shift_bef_dis_id) OR v_shift_bef_dis_id IS NULL) THEN
		
-- 			SELECT 
-- 				SD."SalePointId", 
-- 				SD."UserId" , 
-- 				(CASE WHEN EXISTS (SELECT 1 FROM "ShiftTransfer" SF WHERE SF."ShiftDistributeId" = v_shift_dis_id) THEN FALSE ELSE TRUE END)
-- 				INTO v_sale_point_id, v_user_id, v_flag
-- 			FROM "ShiftDistribute" SD
-- 			WHERE SD."ShiftDistributeId" = p_shift_distribute_id;
			
-- 		END IF;

-- 	END IF;
	
-- 	SELECT SP."SalePointName", SP."FullAddress" INTO v_sale_point_name, v_sale_point_address FROM "SalePoint" SP WHERE SP."SalePointId" = v_sale_point_id;
-- 	IF(v_user_id IS NOT NULL AND v_user_id = v_user_check) THEN
		
-- 			IF (EXISTS (SELECT 1  FROM "LeaderOffLog" LOL WHERE LOL."WorkingDate" = p_date::DATE) ) THEN
		
-- 			RETURN QUERY 
-- 	SELECT 
-- 		(
-- 			with tmp AS(
-- 				SELECT SD."UserId", SD."SalePointId",SD."ShiftId" 
-- 					FROM "ShiftDistribute" SD 
-- 				WHERE SD."DistributeDate"::DATE =p_date::DATE AND SD."UserId" = v_user_id AND SD."ShiftDistributeId" = p_shift_distribute_id
-- 					GROUP BY SD."SalePointId", SD."UserId",SD."ShiftId"
-- 			),tmp1 AS (SELECT * FROM "GroupSalePoint" GSP  ORDER BY GSP."GroupSalePointId" DESC LIMIT v_total_leader)
-- 			,tmp2 AS(
-- 			SELECT GSP."UserId" FROM "tmp1" GSP
-- 				LEFT JOIN tmp T ON T."SalePointId" = ANY (GSP."SalePointIds")
-- 				LEFT JOIN "UserRole" UR ON UR."UserId" = GSP."UserId"
-- 				LEFT JOIN "ShiftDistribute" SD ON SD."SalePointId" = T."SalePointId"
-- 			WHERE UR."UserTitleId" = 4  AND SD."DistributeDate"::DATE =  p_date::DATE AND GSP."UserId" <> (SELECT LOL."UserId"  FROM "LeaderOffLog" LOL WHERE LOL."WorkingDate" =   p_date::DATE GROUP BY LOL."UserId" LIMIT 1)
-- 					GROUP BY GSP."UserId",
-- 					GSP."GroupSalePointId",
-- 					GSP."Option" 
-- 				ORDER BY GSP."Option" ASC ,GSP."GroupSalePointId" DESC
-- 					LIMIT 1
-- 				)
-- 				SELECT T."UserId" FROM tmp2 T GROUP BY T."UserId"
-- 		)
-- 		 As "ManagerId",
-- 			(
-- 			with tmp AS(
-- 						SELECT SD."UserId", SD."SalePointId",SD."ShiftId" 
-- 					FROM "ShiftDistribute" SD 
-- 				WHERE SD."DistributeDate"::DATE = p_date::DATE AND SD."UserId" = v_user_id AND SD."ShiftDistributeId" = p_shift_distribute_id
-- 					GROUP BY SD."SalePointId", SD."UserId",SD."ShiftId"
-- 				), tmp1 AS (SELECT * FROM "GroupSalePoint" GSP  ORDER BY GSP."GroupSalePointId" DESC LIMIT v_total_leader)
-- 				,tmp2 AS (SELECT U."FullName",GSP."GroupSalePointId" FROM "tmp1" GSP
-- 						LEFT JOIN tmp T ON T."SalePointId" = ANY (GSP."SalePointIds")
-- 						LEFT JOIN "UserRole" UR ON UR."UserId" = GSP."UserId"
-- 						LEFT JOIN "User" U ON U."UserId" = UR."UserId"
-- 						LEFT JOIN "ShiftDistribute" SD ON SD."SalePointId" = T."SalePointId" WHERE UR."UserTitleId" = 4  AND SD."DistributeDate"::DATE =  p_date::DATE AND GSP."UserId" <> (SELECT LOL."UserId"  FROM "LeaderOffLog" LOL WHERE LOL."WorkingDate" =  p_date::DATE GROUP BY LOL."UserId" LIMIT 1)
-- 						GROUP BY 
-- 							GSP."UserId",
-- 							U."FullName",
-- 							GSP."GroupSalePointId",
-- 							GSP."Option" 
-- 					ORDER BY GSP."Option" ASC ,GSP."GroupSalePointId" DESC
-- 					LIMIT 1
-- 					)
-- 					SELECT T."FullName" FROM tmp2 T GROUP BY T."FullName"
-- 			) As "ManagerName",
-- 			v_user_id,
-- 			v_sale_point_id,
-- 			v_sale_point_name,
-- 			p_shift_distribute_id,
-- 			v_flag,
-- 			(
-- 				SELECT array_to_json(
-- 					ARRAY_AGG (r))
-- 				FROM
-- 				(
-- 					SELECT
-- 						ROW_NUMBER() OVER(ORDER BY LCT."LotteryChannelTypeId") AS "RowNumber",
-- 						I."LotteryDate",
-- 						I."LotteryChannelId",
-- 						IC."LotteryChannelName",
-- 						IC."RetailPrice",
-- 						I."TotalRemaining",
-- 						I."TotalDupRemaining",
-- 						IC."ShortName",
-- 						LCT."ShortName" AS "ChannelTypeShortName"
-- 					FROM "Inventory" I
-- 						JOIN "LotteryChannel" IC ON IC."LotteryChannelId" = I."LotteryChannelId"
-- 						LEFT JOIN "LotteryChannelType" LCT ON LCT."LotteryChannelTypeId" = IC."LotteryChannelTypeId"
-- 					WHERE I."LotteryDate" = p_date::DATE AND I."SalePointId" = v_sale_point_id
-- 					ORDER BY I."LotteryDate", IC."LotteryChannelTypeId"
-- 				) r
-- 			)::TEXT AS "TodayData",
-- 			(
-- 				SELECT array_to_json(
-- 					ARRAY_AGG (r))
-- 				FROM
-- 				(
-- 					SELECT
-- 						ROW_NUMBER() OVER(ORDER BY LCT."LotteryChannelTypeId") AS "RowNumber",
-- 						I."LotteryDate",
-- 						I."LotteryChannelId",
-- 						IC."LotteryChannelName",
-- 						IC."RetailPrice",
-- 						I."TotalRemaining",
-- 						I."TotalDupRemaining",
-- 						IC."ShortName",
-- 						LCT."ShortName" AS "ChannelTypeShortName"
-- 					FROM "Inventory" I
-- 						JOIN "LotteryChannel" IC ON IC."LotteryChannelId" = I."LotteryChannelId"
-- 						LEFT JOIN "LotteryChannelType" LCT ON LCT."LotteryChannelTypeId" = IC."LotteryChannelTypeId"
-- 					WHERE I."LotteryDate" = (p_date + '1 day'::INTERVAL)::DATE AND I."SalePointId" = v_sale_point_id
-- 					ORDER BY I."LotteryDate", IC."LotteryChannelTypeId"
-- 				) r
-- 			)::TEXT AS "TomorrowData",
-- 			(
-- 				SELECT array_to_json(
-- 					ARRAY_AGG (r))
-- 				FROM
-- 				(
-- 					SELECT
-- 						ROW_NUMBER() OVER() AS "RowNumber",
-- 						S."TotalRemaining",
-- 						S."LotteryChannelId",
-- 						LC."ShortName",
-- 						LC."LotteryChannelName",
-- 						LC."RetailPrice"
-- 					FROM "Scratchcard" S
-- 						JOIN "LotteryChannel" LC ON LC."LotteryChannelId" = S."LotteryChannelId"
-- 					WHERE S."SalePointId" = v_sale_point_id
-- 					ORDER BY LC."LotteryChannelTypeId"
-- 				) r
-- 			)::TEXT AS "ScratchcardData",
-- 			(
-- 				SELECT array_to_json(
-- 					ARRAY_AGG (r))
-- 				FROM
-- 				(
-- 					SELECT
-- 						SUM(SL."Quantity") FILTER(WHERE SL."LotteryPriceId" NOT IN(1,6)) AS "TotalWholesaleQuantity",
-- 						SUM(SL."TotalValue") FILTER(WHERE SL."LotteryPriceId" NOT IN(1,6)) AS "TotalWholesalePrice",
-- 						SUM(SL."Quantity") FILTER(WHERE SL."LotteryPriceId" IN(1,6)) AS "TotalRetailQuantity",
-- 						SUM(SL."TotalValue") FILTER(WHERE SL."LotteryPriceId" IN(1,6)) AS "TotalRetailPrice"
-- 					FROM "SalePointLog" SL
-- 					WHERE SL."ShiftDistributeId" = v_shift_dis_id AND SL."IsDeleted" IS FALSE
-- 				) r
-- 			)::TEXT AS "SoldData",
-- 			(
-- 				SELECT array_to_json(
-- 					ARRAY_AGG (r))
-- 				FROM
-- 				(
-- 					SELECT
-- 					LT."TransactionCode",
-- 						LT."LotoType",
-- 						LT."Type",
-- 						LC."LotteryChannelName",
-- 					LT."Seri",
-- 					LT."IntoMoney",
-- 					LT."ShiftId",
-- 					TO_CHAR(LT."Time", 'DD/MM/YYYY HH24:MI:SS') AS Time
						
-- 					FROM "LotoNew" LT inner join "LotteryChannel" LC on LT."LotteryChannelId"=LC."LotteryChannelId"
-- 					WHERE LT."SalePointId" = v_sale_point_id and  LT."Time"::date = p_date::date  and LT."IsDelete"=true and LT."ShiftId"=v_shift_id  
-- 					order by LT."Time" DESC
-- 				) r
-- 			)::TEXT AS "SoldLoto",
-- 			(
-- 				SELECT array_to_json(
-- 					ARRAY_AGG (r))
-- 				FROM
-- 				(
-- 					SELECT LT."LotteryChannelId",LT."LotteryChannelName" FROM "LotteryChannel" LT WHERE "DayIds" @> (Select LT."DayIds" from "LotteryChannel" LT 
-- 			JOIN "Inventory" I
-- 				on  LT."LotteryChannelId" = I."LotteryChannelId"
-- 			where 
-- 				I."LotteryDate"::date=p_date::DATE Limit 1) and LT."RegionId"=2
-- -- 					ORDER BY CASE LT."RegionId"
-- -- 				WHEN 2 THEN 1
-- -- 				WHEN 3 THEN 2
-- -- 				WHEN 1 THEN 3

-- -- 			END
-- 				) r
-- 			)::TEXT AS "LCNameTd",
-- 			(
-- 				SELECT array_to_json(
-- 					ARRAY_AGG (r))
-- 				FROM
-- 				(
-- 					SELECT LT."LotteryChannelId",LT."LotteryChannelName" FROM "LotteryChannel" LT WHERE "DayIds" @> (Select LT."DayIds" from "LotteryChannel" LT 
-- 			JOIN "Inventory" I
-- 				on  LT."LotteryChannelId" = I."LotteryChannelId"
-- 			where 
-- 				I."LotteryDate"::date=(p_date::date + '1 day'::INTERVAL)::DATE Limit 1) and LT."RegionId"=2
-- -- 					ORDER BY CASE LT."RegionId"
-- -- 					WHEN 2 THEN 1
-- -- 					WHEN 3 THEN 2
-- -- 					WHEN 1 THEN 3

-- -- 				END
-- 				) r
-- 			)::TEXT AS "LCNameTm",
-- 			v_sale_point_address;
-- 		ELSE
-- 		RETURN QUERY 
-- 			SELECT 
-- 		(
-- 			with tmp AS(
-- 				SELECT SD."UserId", SD."SalePointId",SD."ShiftId" 
-- 					FROM "ShiftDistribute" SD 
-- 				WHERE SD."DistributeDate"::DATE =p_date::DATE AND SD."UserId" = v_user_id AND SD."ShiftDistributeId" = p_shift_distribute_id
-- 					GROUP BY SD."SalePointId", SD."UserId",SD."ShiftId"
-- 			),tmp1 AS (SELECT * FROM "GroupSalePoint" GSP  ORDER BY GSP."GroupSalePointId" DESC LIMIT v_total_leader)
-- 			,tmp2 AS(
-- 			SELECT GSP."UserId" FROM "tmp1" GSP
-- 				LEFT JOIN tmp T ON T."SalePointId" = ANY (GSP."SalePointIds")
-- 				LEFT JOIN "UserRole" UR ON UR."UserId" = GSP."UserId"
-- 				LEFT JOIN "ShiftDistribute" SD ON SD."SalePointId" = T."SalePointId"
-- 			WHERE UR."UserTitleId" = 4  AND SD."DistributeDate"::DATE =  p_date::DATE
-- 					GROUP BY GSP."UserId",
-- 					GSP."GroupSalePointId",
-- 					GSP."Option" 
-- 				ORDER BY GSP."Option" ASC ,GSP."GroupSalePointId" DESC
-- 					LIMIT 1
-- 				)
-- 				SELECT T."UserId" FROM tmp2 T GROUP BY T."UserId"
-- 		)
-- 		 As "ManagerId",
-- 			(
-- 			with tmp AS(
-- 						SELECT SD."UserId", SD."SalePointId",SD."ShiftId" 
-- 					FROM "ShiftDistribute" SD 
-- 				WHERE SD."DistributeDate"::DATE = p_date::DATE AND SD."UserId" = v_user_id AND SD."ShiftDistributeId" = p_shift_distribute_id
-- 					GROUP BY SD."SalePointId", SD."UserId",SD."ShiftId"
-- 				), tmp1 AS (SELECT * FROM "GroupSalePoint" GSP  ORDER BY GSP."GroupSalePointId" DESC LIMIT v_total_leader)
-- 				,tmp2 AS (SELECT U."FullName",GSP."GroupSalePointId" FROM "tmp1" GSP
-- 						LEFT JOIN tmp T ON T."SalePointId" = ANY (GSP."SalePointIds")
-- 						LEFT JOIN "UserRole" UR ON UR."UserId" = GSP."UserId"
-- 						LEFT JOIN "User" U ON U."UserId" = UR."UserId"
-- 						LEFT JOIN "ShiftDistribute" SD ON SD."SalePointId" = T."SalePointId" WHERE UR."UserTitleId" = 4  AND SD."DistributeDate"::DATE =  p_date::DATE 
-- 						GROUP BY 
-- 							GSP."UserId",
-- 							U."FullName",
-- 							GSP."GroupSalePointId",
-- 							GSP."Option" 
-- 					ORDER BY GSP."Option" ASC , GSP."GroupSalePointId" DESC
-- 					LIMIT 1
-- 					)
-- 					SELECT T."FullName" FROM tmp2 T GROUP BY T."FullName"
-- 			) As "ManagerName",
-- 			v_user_id,
-- 			v_sale_point_id,
-- 			v_sale_point_name,
-- 			p_shift_distribute_id,
-- 			v_flag,
-- 			(
-- 				SELECT array_to_json(
-- 					ARRAY_AGG (r))
-- 				FROM
-- 				(
-- 					SELECT
-- 						ROW_NUMBER() OVER(ORDER BY LCT."LotteryChannelTypeId") AS "RowNumber",
-- 						I."LotteryDate",
-- 						I."LotteryChannelId",
-- 						IC."LotteryChannelName",
-- 						IC."RetailPrice",
-- 						I."TotalRemaining",
-- 						I."TotalDupRemaining",
-- 						IC."ShortName",
-- 						LCT."ShortName" AS "ChannelTypeShortName"
-- 					FROM "Inventory" I
-- 						JOIN "LotteryChannel" IC ON IC."LotteryChannelId" = I."LotteryChannelId"
-- 						LEFT JOIN "LotteryChannelType" LCT ON LCT."LotteryChannelTypeId" = IC."LotteryChannelTypeId"
-- 					WHERE I."LotteryDate" = p_date::DATE AND I."SalePointId" = v_sale_point_id
-- 					ORDER BY I."LotteryDate", IC."LotteryChannelTypeId"
-- 				) r
-- 			)::TEXT AS "TodayData",
-- 			(
-- 				SELECT array_to_json(
-- 					ARRAY_AGG (r))
-- 				FROM
-- 				(
-- 					SELECT
-- 						ROW_NUMBER() OVER(ORDER BY LCT."LotteryChannelTypeId") AS "RowNumber",
-- 						I."LotteryDate",
-- 						I."LotteryChannelId",
-- 						IC."LotteryChannelName",
-- 						IC."RetailPrice",
-- 						I."TotalRemaining",
-- 						I."TotalDupRemaining",
-- 						IC."ShortName",
-- 						LCT."ShortName" AS "ChannelTypeShortName"
-- 					FROM "Inventory" I
-- 						JOIN "LotteryChannel" IC ON IC."LotteryChannelId" = I."LotteryChannelId"
-- 						LEFT JOIN "LotteryChannelType" LCT ON LCT."LotteryChannelTypeId" = IC."LotteryChannelTypeId"
-- 					WHERE I."LotteryDate" = (p_date + '1 day'::INTERVAL)::DATE AND I."SalePointId" = v_sale_point_id
-- 					ORDER BY I."LotteryDate", IC."LotteryChannelTypeId"
-- 				) r
-- 			)::TEXT AS "TomorrowData",
			
-- 			(
-- 				SELECT array_to_json(
-- 					ARRAY_AGG (r))
-- 				FROM
-- 				(
-- 					SELECT
-- 						ROW_NUMBER() OVER() AS "RowNumber",
-- 						S."TotalRemaining",
-- 						S."LotteryChannelId",
-- 						LC."ShortName",
-- 						LC."LotteryChannelName",
-- 						LC."RetailPrice"
-- 					FROM "Scratchcard" S
-- 						JOIN "LotteryChannel" LC ON LC."LotteryChannelId" = S."LotteryChannelId"
-- 					WHERE S."SalePointId" = v_sale_point_id
-- 					ORDER BY LC."LotteryChannelTypeId"
-- 				) r
-- 			)::TEXT AS "ScratchcardData",
-- 			(
-- 				SELECT array_to_json(
-- 					ARRAY_AGG (r))
-- 				FROM
-- 				(
-- 					SELECT
-- 						SUM(SL."Quantity") FILTER(WHERE SL."LotteryPriceId" NOT IN(1,6)) AS "TotalWholesaleQuantity",
-- 						SUM(SL."TotalValue") FILTER(WHERE SL."LotteryPriceId" NOT IN(1,6)) AS "TotalWholesalePrice",
-- 						SUM(SL."Quantity") FILTER(WHERE SL."LotteryPriceId" IN(1,6)) AS "TotalRetailQuantity",
-- 						SUM(SL."TotalValue") FILTER(WHERE SL."LotteryPriceId" IN(1,6)) AS "TotalRetailPrice"
-- 					FROM "SalePointLog" SL
-- 					WHERE SL."ShiftDistributeId" = v_shift_dis_id AND SL."IsDeleted" IS FALSE
-- 				) r
-- 			)::TEXT AS "SoldData",
-- 				(
-- 				SELECT array_to_json(
-- 					ARRAY_AGG (r))
-- 				FROM
-- 				(
-- 					SELECT
-- 					LT."TransactionCode",
-- 						LT."LotoType",
-- 						LT."Type",
-- 						LC."LotteryChannelName",
-- 					LT."Seri",
-- 					LT."IntoMoney",
-- 					LT."ShiftId",
-- 					TO_CHAR(LT."Time", 'DD/MM/YYYY HH24:MI:SS') AS Time
						
-- 					FROM "LotoNew" LT inner join "LotteryChannel" LC on LT."LotteryChannelId"=LC."LotteryChannelId"
-- 					WHERE LT."SalePointId" = v_sale_point_id and  LT."Time"::date = p_date::date and LT."ShiftId"=v_shift_id  and LT."IsDelete"=true
-- 					order by LT."Time" DESC
-- 				) r
-- 			)::TEXT AS "SoldLoto",
-- 			(
-- 				SELECT array_to_json(
-- 					ARRAY_AGG (r))
-- 				FROM
-- 				(
-- 					SELECT LT."LotteryChannelId",LT."LotteryChannelName" FROM "LotteryChannel" LT WHERE "DayIds" @> (Select LT."DayIds" from "LotteryChannel" LT 
-- 			JOIN "Inventory" I
-- 				on  LT."LotteryChannelId" = I."LotteryChannelId"
-- 			where 
-- 				I."LotteryDate"::date=p_date::DATE Limit 1) and LT."RegionId"=2
-- -- 					ORDER BY CASE LT."RegionId"
-- -- 				WHEN 2 THEN 1
-- -- 				WHEN 3 THEN 2
-- -- 				WHEN 1 THEN 3

-- -- 			END
-- 				) r
-- 			)::TEXT AS "LCNameTd",
-- 			(
-- 				SELECT array_to_json(
-- 					ARRAY_AGG (r))
-- 				FROM
-- 				(
-- 					SELECT LT."LotteryChannelId",LT."LotteryChannelName" FROM "LotteryChannel" LT WHERE "DayIds" @> (Select LT."DayIds" from "LotteryChannel" LT 
-- 			JOIN "Inventory" I
-- 				on  LT."LotteryChannelId" = I."LotteryChannelId"
-- 			where 
-- 				I."LotteryDate"::date=(p_date::date + '1 day'::INTERVAL)::DATE Limit 1) and LT."RegionId"=2
-- -- 					ORDER BY CASE LT."RegionId"
-- -- 					WHEN 2 THEN 1
-- -- 					WHEN 3 THEN 2
-- -- 					WHEN 1 THEN 3

-- -- 				END
-- 				) r
-- 			)::TEXT AS "LCNameTm",
-- 			v_sale_point_address;
-- 			END IF;
-- 		END IF;
-- END;

-- -- DECLARE 
-- -- 	v_sale_point_id INT;
-- -- 	v_sale_point_name VARCHAR;
-- -- 	v_shift_dis_id INT;
-- -- 	v_is_super_admin BOOL;
-- -- 	v_is_manager BOOL;
-- -- 	v_is_staff BOOL;
-- -- 	v_user_id INT;
-- -- 	v_user_check INT;
-- -- 	v_shift_id INT;
-- -- 	v_shift_bef_dis_id INT;
-- -- 	v_flag BOOL;
-- -- 	v_sale_point_address VARCHAR;
-- -- 	v_temp INT;
-- -- 	v_total_leader INT;
-- -- 	v_dayids int[];
-- -- BEGIN

	
-- -- 	with tmp AS(
-- -- 	SELECT COUNT(U."UserId") AS "Leaders" FROM "User" U LEFT JOIN "UserRole" UR ON UR."UserId" = U."UserId" WHERE U."IsActive" = TRUE AND UR."UserTitleId" = 4 
-- -- 	) SELECT T."Leaders" * (T."Leaders" + 1) INTO v_total_leader FROM tmp T;
-- -- 	SELECT UR."UserId" INTO v_user_check
-- -- 	FROM "UserRole" UR 
-- -- 	WHERE UR."UserRoleId" = p_user_role_id;

-- -- 	SELECT SD."ShiftDistributeId", SD."ShiftId" , SD."SalePointId" INTO v_shift_dis_id, v_shift_id ,v_sale_point_id
-- -- 	FROM "ShiftDistribute" SD
-- -- 	WHERE SD."ShiftDistributeId" = p_shift_distribute_id
-- -- 		AND SD."DistributeDate" = p_date;
	
-- -- 	IF v_shift_id IS NULL THEN
-- -- 		SELECT 
-- -- 			SD."SalePointId", 
-- -- 			SD."UserId", 
-- -- 			FALSE
-- -- 			INTO v_sale_point_id, v_user_id, v_flag
-- -- 		FROM "ShiftDistribute" SD
-- -- 		WHERE SD."ShiftDistributeId" = p_shift_distribute_id;
	
-- -- 	ELSEIF v_shift_id = 1 THEN 
	
-- -- 		SELECT 
-- -- 			SD."SalePointId", 
-- -- 			SD."UserId", 
-- -- 			(CASE WHEN EXISTS (SELECT 1 FROM "ShiftTransfer" SF WHERE SF."ShiftDistributeId" = v_shift_dis_id) THEN FALSE ELSE TRUE END)
-- -- 			INTO v_sale_point_id, v_user_id, v_flag
-- -- 		FROM "ShiftDistribute" SD
-- -- 		WHERE SD."ShiftDistributeId" = v_shift_dis_id;
		
-- -- 	ELSE
	
-- -- 		SELECT SD."ShiftDistributeId" INTO v_shift_bef_dis_id 
-- -- 		FROM "ShiftDistribute" SD 
-- -- 		WHERE SD."DistributeDate" = p_date
-- -- 			AND SD."ShiftId" =  1
-- -- 			AND SD."SalePointId" =  v_sale_point_id;
			
-- -- 		IF(EXISTS (SELECT 1 FROM "ShiftTransfer" SF WHERE SF."ShiftDistributeId" = v_shift_bef_dis_id) OR v_shift_bef_dis_id IS NULL) THEN
		
-- -- 			SELECT 
-- -- 				SD."SalePointId", 
-- -- 				SD."UserId" , 
-- -- 				(CASE WHEN EXISTS (SELECT 1 FROM "ShiftTransfer" SF WHERE SF."ShiftDistributeId" = v_shift_dis_id) THEN FALSE ELSE TRUE END)
-- -- 				INTO v_sale_point_id, v_user_id, v_flag
-- -- 			FROM "ShiftDistribute" SD
-- -- 			WHERE SD."ShiftDistributeId" = p_shift_distribute_id;
			
-- -- 		END IF;

-- -- 	END IF;
	
-- -- 	SELECT SP."SalePointName", SP."FullAddress" INTO v_sale_point_name, v_sale_point_address FROM "SalePoint" SP WHERE SP."SalePointId" = v_sale_point_id;
-- -- 	IF(v_user_id IS NOT NULL AND v_user_id = v_user_check) THEN
		
-- -- 			IF (EXISTS (SELECT 1  FROM "LeaderOffLog" LOL WHERE LOL."WorkingDate" = p_date::DATE) ) THEN
		
-- -- 			RETURN QUERY 
-- -- 	SELECT 
-- -- 		(
-- -- 			with tmp AS(
-- -- 				SELECT SD."UserId", SD."SalePointId",SD."ShiftId" 
-- -- 					FROM "ShiftDistribute" SD 
-- -- 				WHERE SD."DistributeDate"::DATE =p_date::DATE AND SD."UserId" = v_user_id AND SD."ShiftDistributeId" = p_shift_distribute_id
-- -- 					GROUP BY SD."SalePointId", SD."UserId",SD."ShiftId"
-- -- 			),tmp1 AS (SELECT * FROM "GroupSalePoint" GSP  ORDER BY GSP."GroupSalePointId" DESC LIMIT v_total_leader)
-- -- 			,tmp2 AS(
-- -- 			SELECT GSP."UserId" FROM "tmp1" GSP
-- -- 				LEFT JOIN tmp T ON T."SalePointId" = ANY (GSP."SalePointIds")
-- -- 				LEFT JOIN "UserRole" UR ON UR."UserId" = GSP."UserId"
-- -- 				LEFT JOIN "ShiftDistribute" SD ON SD."SalePointId" = T."SalePointId"
-- -- 			WHERE UR."UserTitleId" = 4  AND SD."DistributeDate"::DATE =  p_date::DATE AND GSP."UserId" <> (SELECT LOL."UserId"  FROM "LeaderOffLog" LOL WHERE LOL."WorkingDate" =   p_date::DATE GROUP BY LOL."UserId" LIMIT 1)
-- -- 					GROUP BY GSP."UserId",
-- -- 					GSP."GroupSalePointId",
-- -- 					GSP."Option" 
-- -- 				ORDER BY GSP."Option" ASC ,GSP."GroupSalePointId" DESC
-- -- 					LIMIT 1
-- -- 				)
-- -- 				SELECT T."UserId" FROM tmp2 T GROUP BY T."UserId"
-- -- 		)
-- -- 		 As "ManagerId",
-- -- 			(
-- -- 			with tmp AS(
-- -- 						SELECT SD."UserId", SD."SalePointId",SD."ShiftId" 
-- -- 					FROM "ShiftDistribute" SD 
-- -- 				WHERE SD."DistributeDate"::DATE = p_date::DATE AND SD."UserId" = v_user_id AND SD."ShiftDistributeId" = p_shift_distribute_id
-- -- 					GROUP BY SD."SalePointId", SD."UserId",SD."ShiftId"
-- -- 				), tmp1 AS (SELECT * FROM "GroupSalePoint" GSP  ORDER BY GSP."GroupSalePointId" DESC LIMIT v_total_leader)
-- -- 				,tmp2 AS (SELECT U."FullName",GSP."GroupSalePointId" FROM "tmp1" GSP
-- -- 						LEFT JOIN tmp T ON T."SalePointId" = ANY (GSP."SalePointIds")
-- -- 						LEFT JOIN "UserRole" UR ON UR."UserId" = GSP."UserId"
-- -- 						LEFT JOIN "User" U ON U."UserId" = UR."UserId"
-- -- 						LEFT JOIN "ShiftDistribute" SD ON SD."SalePointId" = T."SalePointId" WHERE UR."UserTitleId" = 4  AND SD."DistributeDate"::DATE =  p_date::DATE AND GSP."UserId" <> (SELECT LOL."UserId"  FROM "LeaderOffLog" LOL WHERE LOL."WorkingDate" =  p_date::DATE GROUP BY LOL."UserId" LIMIT 1)
-- -- 						GROUP BY 
-- -- 							GSP."UserId",
-- -- 							U."FullName",
-- -- 							GSP."GroupSalePointId",
-- -- 							GSP."Option" 
-- -- 					ORDER BY GSP."Option" ASC ,GSP."GroupSalePointId" DESC
-- -- 					LIMIT 1
-- -- 					)
-- -- 					SELECT T."FullName" FROM tmp2 T GROUP BY T."FullName"
-- -- 			) As "ManagerName",
-- -- 			v_user_id,
-- -- 			v_sale_point_id,
-- -- 			v_sale_point_name,
-- -- 			p_shift_distribute_id,
-- -- 			v_flag,
-- -- 			(
-- -- 				SELECT array_to_json(
-- -- 					ARRAY_AGG (r))
-- -- 				FROM
-- -- 				(
-- -- 					SELECT
-- -- 						ROW_NUMBER() OVER(ORDER BY LCT."LotteryChannelTypeId") AS "RowNumber",
-- -- 						I."LotteryDate",
-- -- 						I."LotteryChannelId",
-- -- 						IC."LotteryChannelName",
-- -- 						IC."RetailPrice",
-- -- 						I."TotalRemaining",
-- -- 						I."TotalDupRemaining",
-- -- 						IC."ShortName",
-- -- 						LCT."ShortName" AS "ChannelTypeShortName"
-- -- 					FROM "Inventory" I
-- -- 						JOIN "LotteryChannel" IC ON IC."LotteryChannelId" = I."LotteryChannelId"
-- -- 						LEFT JOIN "LotteryChannelType" LCT ON LCT."LotteryChannelTypeId" = IC."LotteryChannelTypeId"
-- -- 					WHERE I."LotteryDate" = p_date::DATE AND I."SalePointId" = v_sale_point_id
-- -- 					ORDER BY I."LotteryDate", IC."LotteryChannelTypeId"
-- -- 				) r
-- -- 			)::TEXT AS "TodayData",
-- -- 			(
-- -- 				SELECT array_to_json(
-- -- 					ARRAY_AGG (r))
-- -- 				FROM
-- -- 				(
-- -- 					SELECT
-- -- 						ROW_NUMBER() OVER(ORDER BY LCT."LotteryChannelTypeId") AS "RowNumber",
-- -- 						I."LotteryDate",
-- -- 						I."LotteryChannelId",
-- -- 						IC."LotteryChannelName",
-- -- 						IC."RetailPrice",
-- -- 						I."TotalRemaining",
-- -- 						I."TotalDupRemaining",
-- -- 						IC."ShortName",
-- -- 						LCT."ShortName" AS "ChannelTypeShortName"
-- -- 					FROM "Inventory" I
-- -- 						JOIN "LotteryChannel" IC ON IC."LotteryChannelId" = I."LotteryChannelId"
-- -- 						LEFT JOIN "LotteryChannelType" LCT ON LCT."LotteryChannelTypeId" = IC."LotteryChannelTypeId"
-- -- 					WHERE I."LotteryDate" = (p_date + '1 day'::INTERVAL)::DATE AND I."SalePointId" = v_sale_point_id
-- -- 					ORDER BY I."LotteryDate", IC."LotteryChannelTypeId"
-- -- 				) r
-- -- 			)::TEXT AS "TomorrowData",
-- -- 			(
-- -- 				SELECT array_to_json(
-- -- 					ARRAY_AGG (r))
-- -- 				FROM
-- -- 				(
-- -- 					SELECT
-- -- 						ROW_NUMBER() OVER() AS "RowNumber",
-- -- 						S."TotalRemaining",
-- -- 						S."LotteryChannelId",
-- -- 						LC."ShortName",
-- -- 						LC."LotteryChannelName",
-- -- 						LC."RetailPrice"
-- -- 					FROM "Scratchcard" S
-- -- 						JOIN "LotteryChannel" LC ON LC."LotteryChannelId" = S."LotteryChannelId"
-- -- 					WHERE S."SalePointId" = v_sale_point_id
-- -- 					ORDER BY LC."LotteryChannelTypeId"
-- -- 				) r
-- -- 			)::TEXT AS "ScratchcardData",
-- -- 			(
-- -- 				SELECT array_to_json(
-- -- 					ARRAY_AGG (r))
-- -- 				FROM
-- -- 				(
-- -- 					SELECT
-- -- 						SUM(SL."Quantity") FILTER(WHERE SL."LotteryPriceId" NOT IN(1,6)) AS "TotalWholesaleQuantity",
-- -- 						SUM(SL."TotalValue") FILTER(WHERE SL."LotteryPriceId" NOT IN(1,6)) AS "TotalWholesalePrice",
-- -- 						SUM(SL."Quantity") FILTER(WHERE SL."LotteryPriceId" IN(1,6)) AS "TotalRetailQuantity",
-- -- 						SUM(SL."TotalValue") FILTER(WHERE SL."LotteryPriceId" IN(1,6)) AS "TotalRetailPrice"
-- -- 					FROM "SalePointLog" SL
-- -- 					WHERE SL."ShiftDistributeId" = v_shift_dis_id AND SL."IsDeleted" IS FALSE
-- -- 				) r
-- -- 			)::TEXT AS "SoldData",
-- -- 			(
-- -- 				SELECT array_to_json(
-- -- 					ARRAY_AGG (r))
-- -- 				FROM
-- -- 				(
-- -- 					SELECT
-- -- 					LT."TransactionCode",
-- -- 						LT."LotoType",
-- -- 						LT."Type",
-- -- 						LC."LotteryChannelName",
-- -- 					LT."Seri",
-- -- 					LT."IntoMoney",
-- -- 					LT."ShiftId",
-- -- 					TO_CHAR(LT."Time", 'DD/MM/YYYY HH24:MI:SS') AS Time
						
-- -- 					FROM "LotoNew" LT inner join "LotteryChannel" LC on LT."LotteryChannelId"=LC."LotteryChannelId"
-- -- 					WHERE LT."SalePointId" = v_sale_point_id and  LT."Time"::date = p_date::date  and LT."IsDelete"=true and LT."ShiftId"=v_shift_id  
-- -- 					order by LT."Time" DESC
-- -- 				) r
-- -- 			)::TEXT AS "SoldLoto",
-- -- 			(
-- -- 				SELECT array_to_json(
-- -- 					ARRAY_AGG (r))
-- -- 				FROM
-- -- 				(
-- -- 					SELECT LT."LotteryChannelId",LT."LotteryChannelName" FROM "LotteryChannel" LT WHERE "DayIds" @> (Select LT."DayIds" from "LotteryChannel" LT 
-- -- 			JOIN "Inventory" I
-- -- 				on  LT."LotteryChannelId" = I."LotteryChannelId"
-- -- 			where LT."RegionId"=2 and
-- -- 				I."LotteryDate"::date=p_date::DATE Limit 1)
-- -- -- 					ORDER BY CASE LT."RegionId"
-- -- -- 				WHEN 2 THEN 1
-- -- -- 				WHEN 3 THEN 2
-- -- -- 				WHEN 1 THEN 3

-- -- -- 			END
-- -- 				) r
-- -- 			)::TEXT AS "LCNameTd",
-- -- 			(
-- -- 				SELECT array_to_json(
-- -- 					ARRAY_AGG (r))
-- -- 				FROM
-- -- 				(
-- -- 					SELECT LT."LotteryChannelId",LT."LotteryChannelName" FROM "LotteryChannel" LT WHERE "DayIds" @> (Select LT."DayIds" from "LotteryChannel" LT 
-- -- 			JOIN "Inventory" I
-- -- 				on  LT."LotteryChannelId" = I."LotteryChannelId"
-- -- 			where LT."RegionId"=2 and
-- -- 				I."LotteryDate"::date=(p_date::date + '1 day'::INTERVAL)::DATE Limit 1)
-- -- -- 					ORDER BY CASE LT."RegionId"
-- -- -- 					WHEN 2 THEN 1
-- -- -- 					WHEN 3 THEN 2
-- -- -- 					WHEN 1 THEN 3

-- -- -- 				END
-- -- 				) r
-- -- 			)::TEXT AS "LCNameTm",
-- -- 			v_sale_point_address;
-- -- 		ELSE
-- -- 		RETURN QUERY 
-- -- 			SELECT 
-- -- 		(
-- -- 			with tmp AS(
-- -- 				SELECT SD."UserId", SD."SalePointId",SD."ShiftId" 
-- -- 					FROM "ShiftDistribute" SD 
-- -- 				WHERE SD."DistributeDate"::DATE =p_date::DATE AND SD."UserId" = v_user_id AND SD."ShiftDistributeId" = p_shift_distribute_id
-- -- 					GROUP BY SD."SalePointId", SD."UserId",SD."ShiftId"
-- -- 			),tmp1 AS (SELECT * FROM "GroupSalePoint" GSP  ORDER BY GSP."GroupSalePointId" DESC LIMIT v_total_leader)
-- -- 			,tmp2 AS(
-- -- 			SELECT GSP."UserId" FROM "tmp1" GSP
-- -- 				LEFT JOIN tmp T ON T."SalePointId" = ANY (GSP."SalePointIds")
-- -- 				LEFT JOIN "UserRole" UR ON UR."UserId" = GSP."UserId"
-- -- 				LEFT JOIN "ShiftDistribute" SD ON SD."SalePointId" = T."SalePointId"
-- -- 			WHERE UR."UserTitleId" = 4  AND SD."DistributeDate"::DATE =  p_date::DATE
-- -- 					GROUP BY GSP."UserId",
-- -- 					GSP."GroupSalePointId",
-- -- 					GSP."Option" 
-- -- 				ORDER BY GSP."Option" ASC ,GSP."GroupSalePointId" DESC
-- -- 					LIMIT 1
-- -- 				)
-- -- 				SELECT T."UserId" FROM tmp2 T GROUP BY T."UserId"
-- -- 		)
-- -- 		 As "ManagerId",
-- -- 			(
-- -- 			with tmp AS(
-- -- 						SELECT SD."UserId", SD."SalePointId",SD."ShiftId" 
-- -- 					FROM "ShiftDistribute" SD 
-- -- 				WHERE SD."DistributeDate"::DATE = p_date::DATE AND SD."UserId" = v_user_id AND SD."ShiftDistributeId" = p_shift_distribute_id
-- -- 					GROUP BY SD."SalePointId", SD."UserId",SD."ShiftId"
-- -- 				), tmp1 AS (SELECT * FROM "GroupSalePoint" GSP  ORDER BY GSP."GroupSalePointId" DESC LIMIT v_total_leader)
-- -- 				,tmp2 AS (SELECT U."FullName",GSP."GroupSalePointId" FROM "tmp1" GSP
-- -- 						LEFT JOIN tmp T ON T."SalePointId" = ANY (GSP."SalePointIds")
-- -- 						LEFT JOIN "UserRole" UR ON UR."UserId" = GSP."UserId"
-- -- 						LEFT JOIN "User" U ON U."UserId" = UR."UserId"
-- -- 						LEFT JOIN "ShiftDistribute" SD ON SD."SalePointId" = T."SalePointId" WHERE UR."UserTitleId" = 4  AND SD."DistributeDate"::DATE =  p_date::DATE 
-- -- 						GROUP BY 
-- -- 							GSP."UserId",
-- -- 							U."FullName",
-- -- 							GSP."GroupSalePointId",
-- -- 							GSP."Option" 
-- -- 					ORDER BY GSP."Option" ASC , GSP."GroupSalePointId" DESC
-- -- 					LIMIT 1
-- -- 					)
-- -- 					SELECT T."FullName" FROM tmp2 T GROUP BY T."FullName"
-- -- 			) As "ManagerName",
-- -- 			v_user_id,
-- -- 			v_sale_point_id,
-- -- 			v_sale_point_name,
-- -- 			p_shift_distribute_id,
-- -- 			v_flag,
-- -- 			(
-- -- 				SELECT array_to_json(
-- -- 					ARRAY_AGG (r))
-- -- 				FROM
-- -- 				(
-- -- 					SELECT
-- -- 						ROW_NUMBER() OVER(ORDER BY LCT."LotteryChannelTypeId") AS "RowNumber",
-- -- 						I."LotteryDate",
-- -- 						I."LotteryChannelId",
-- -- 						IC."LotteryChannelName",
-- -- 						IC."RetailPrice",
-- -- 						I."TotalRemaining",
-- -- 						I."TotalDupRemaining",
-- -- 						IC."ShortName",
-- -- 						LCT."ShortName" AS "ChannelTypeShortName"
-- -- 					FROM "Inventory" I
-- -- 						JOIN "LotteryChannel" IC ON IC."LotteryChannelId" = I."LotteryChannelId"
-- -- 						LEFT JOIN "LotteryChannelType" LCT ON LCT."LotteryChannelTypeId" = IC."LotteryChannelTypeId"
-- -- 					WHERE I."LotteryDate" = p_date::DATE AND I."SalePointId" = v_sale_point_id
-- -- 					ORDER BY I."LotteryDate", IC."LotteryChannelTypeId"
-- -- 				) r
-- -- 			)::TEXT AS "TodayData",
-- -- 			(
-- -- 				SELECT array_to_json(
-- -- 					ARRAY_AGG (r))
-- -- 				FROM
-- -- 				(
-- -- 					SELECT
-- -- 						ROW_NUMBER() OVER(ORDER BY LCT."LotteryChannelTypeId") AS "RowNumber",
-- -- 						I."LotteryDate",
-- -- 						I."LotteryChannelId",
-- -- 						IC."LotteryChannelName",
-- -- 						IC."RetailPrice",
-- -- 						I."TotalRemaining",
-- -- 						I."TotalDupRemaining",
-- -- 						IC."ShortName",
-- -- 						LCT."ShortName" AS "ChannelTypeShortName"
-- -- 					FROM "Inventory" I
-- -- 						JOIN "LotteryChannel" IC ON IC."LotteryChannelId" = I."LotteryChannelId"
-- -- 						LEFT JOIN "LotteryChannelType" LCT ON LCT."LotteryChannelTypeId" = IC."LotteryChannelTypeId"
-- -- 					WHERE I."LotteryDate" = (p_date + '1 day'::INTERVAL)::DATE AND I."SalePointId" = v_sale_point_id
-- -- 					ORDER BY I."LotteryDate", IC."LotteryChannelTypeId"
-- -- 				) r
-- -- 			)::TEXT AS "TomorrowData",
			
-- -- 			(
-- -- 				SELECT array_to_json(
-- -- 					ARRAY_AGG (r))
-- -- 				FROM
-- -- 				(
-- -- 					SELECT
-- -- 						ROW_NUMBER() OVER() AS "RowNumber",
-- -- 						S."TotalRemaining",
-- -- 						S."LotteryChannelId",
-- -- 						LC."ShortName",
-- -- 						LC."LotteryChannelName",
-- -- 						LC."RetailPrice"
-- -- 					FROM "Scratchcard" S
-- -- 						JOIN "LotteryChannel" LC ON LC."LotteryChannelId" = S."LotteryChannelId"
-- -- 					WHERE S."SalePointId" = v_sale_point_id
-- -- 					ORDER BY LC."LotteryChannelTypeId"
-- -- 				) r
-- -- 			)::TEXT AS "ScratchcardData",
-- -- 			(
-- -- 				SELECT array_to_json(
-- -- 					ARRAY_AGG (r))
-- -- 				FROM
-- -- 				(
-- -- 					SELECT
-- -- 						SUM(SL."Quantity") FILTER(WHERE SL."LotteryPriceId" NOT IN(1,6)) AS "TotalWholesaleQuantity",
-- -- 						SUM(SL."TotalValue") FILTER(WHERE SL."LotteryPriceId" NOT IN(1,6)) AS "TotalWholesalePrice",
-- -- 						SUM(SL."Quantity") FILTER(WHERE SL."LotteryPriceId" IN(1,6)) AS "TotalRetailQuantity",
-- -- 						SUM(SL."TotalValue") FILTER(WHERE SL."LotteryPriceId" IN(1,6)) AS "TotalRetailPrice"
-- -- 					FROM "SalePointLog" SL
-- -- 					WHERE SL."ShiftDistributeId" = v_shift_dis_id AND SL."IsDeleted" IS FALSE
-- -- 				) r
-- -- 			)::TEXT AS "SoldData",
-- -- 				(
-- -- 				SELECT array_to_json(
-- -- 					ARRAY_AGG (r))
-- -- 				FROM
-- -- 				(
-- -- 					SELECT
-- -- 					LT."TransactionCode",
-- -- 						LT."LotoType",
-- -- 						LT."Type",
-- -- 						LC."LotteryChannelName",
-- -- 					LT."Seri",
-- -- 					LT."IntoMoney",
-- -- 					LT."ShiftId",
-- -- 					TO_CHAR(LT."Time", 'DD/MM/YYYY HH24:MI:SS') AS Time
						
-- -- 					FROM "LotoNew" LT inner join "LotteryChannel" LC on LT."LotteryChannelId"=LC."LotteryChannelId"
-- -- 					WHERE LT."SalePointId" = v_sale_point_id and  LT."Time"::date = p_date::date and LT."ShiftId"=v_shift_id  and LT."IsDelete"=true
-- -- 					order by LT."Time" DESC
-- -- 				) r
-- -- 			)::TEXT AS "SoldLoto",
-- -- 			(
-- -- 				SELECT array_to_json(
-- -- 					ARRAY_AGG (r))
-- -- 				FROM
-- -- 				(
-- -- 					SELECT LT."LotteryChannelId",LT."LotteryChannelName" FROM "LotteryChannel" LT WHERE "DayIds" @> (Select LT."DayIds" from "LotteryChannel" LT 
-- -- 			JOIN "Inventory" I
-- -- 				on  LT."LotteryChannelId" = I."LotteryChannelId"
-- -- 			where LT."RegionId"=2 and
-- -- 				I."LotteryDate"::date=p_date::DATE Limit 1)
-- -- -- 					ORDER BY CASE LT."RegionId"
-- -- -- 				WHEN 2 THEN 1
-- -- -- 				WHEN 3 THEN 2
-- -- -- 				WHEN 1 THEN 3

-- -- -- 			END
-- -- 				) r
-- -- 			)::TEXT AS "LCNameTd",
-- -- 			(
-- -- 				SELECT array_to_json(
-- -- 					ARRAY_AGG (r))
-- -- 				FROM
-- -- 				(
-- -- 					SELECT LT."LotteryChannelId",LT."LotteryChannelName" FROM "LotteryChannel" LT WHERE "DayIds" @> (Select LT."DayIds" from "LotteryChannel" LT 
-- -- 			JOIN "Inventory" I
-- -- 				on  LT."LotteryChannelId" = I."LotteryChannelId"
-- -- 			where LT."RegionId"=2 and
-- -- 				I."LotteryDate"::date=(p_date::date + '1 day'::INTERVAL)::DATE Limit 1)
-- -- -- 					ORDER BY CASE LT."RegionId"
-- -- -- 					WHEN 2 THEN 1
-- -- -- 					WHEN 3 THEN 2
-- -- -- 					WHEN 1 THEN 3

-- -- -- 				END
-- -- 				) r
-- -- 			)::TEXT AS "LCNameTm",
-- -- 			v_sale_point_address;
-- -- 			END IF;
-- -- 		END IF;
-- -- END;
$function$
