CREATE OR REPLACE FUNCTION public.crm_activity_confirm_transition_v3(
    p_user_role_id INTEGER,
    p_note CHARACTER VARYING,
    p_list_item TEXT,
    p_is_confirm BOOLEAN,
    p_trans_type_id INTEGER,
    p_sale_point_id INTEGER
) 
RETURNS TABLE ("Id" INTEGER, "Message" TEXT) 
LANGUAGE plpgsql 
AS $function$
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
BEGIN
    -- Get the user's role and name
    SELECT UT."IsStaff", U."UserId" INTO v_is_staff, v_user_id
    FROM "UserRole" U 
    JOIN "UserTitle" UT ON U."UserTitleId" = UT."UserTitleId"
    WHERE U."UserRoleId" = p_user_role_id;

    SELECT U."FullName" INTO v_name
    FROM "User" U
    WHERE U."UserId" = v_user_id;

    -- Process the confirmation
    IF p_is_confirm THEN
        IF p_trans_type_id = 1 THEN
            FOR ele IN SELECT * FROM json_array_elements(p_list_item::JSON) LOOP
                -- Check and validate inventory or scratchcard
                IF NOT ((ele ->> 'IsScratchcard')::BOOL) THEN
                    -- Inventory case
                    SELECT I."TotalRemaining", I."TotalDupRemaining"
                    INTO v_total_check, v_total_dup_check
                    FROM "Inventory" I
                    WHERE I."SalePointId" = p_sale_point_id
                        AND I."LotteryChannelId" = (ele ->> 'LotteryChannelId')::INT
                        AND I."LotteryDate" = (ele ->> 'LotteryDate')::DATE;

                    -- Validate transition status and inventory
                    IF NOT EXISTS (SELECT 1 FROM "Transition" T 
                                   WHERE T."TransitionId" = (ele ->> 'TransitionId')::INT 
                                     AND T."ConfirmStatusId" = 1) THEN
                        RAISE EXCEPTION 'Yêu cầu đã được xác nhận trước';
                    END IF;

                    IF v_total_check < COALESCE((ele ->> 'TotalTrans')::INT) 
                        OR v_total_dup_check < COALESCE((ele ->> 'TotalTransDup')::INT) THEN
                        RAISE EXCEPTION 'Không đủ vé trong kho hàng1';
                    END IF;
                ELSE
                    -- Scratchcard case
                    SELECT I."TotalRemaining"
                    INTO v_total_check
                    FROM "Scratchcard" I
                    WHERE I."SalePointId" = p_sale_point_id
                        AND I."LotteryChannelId" = (ele ->> 'LotteryChannelId')::INT;

                    -- Validate transition status and scratchcard
                    IF NOT EXISTS (SELECT 1 FROM "Transition" T 
                                   WHERE T."TransitionId" = (ele ->> 'TransitionId')::INT 
                                     AND T."ConfirmStatusId" = 1) THEN
                        RAISE EXCEPTION 'Yêu cầu đã được xác nhận trước';
                    END IF;

                    IF v_total_check < COALESCE((ele ->> 'TotalTrans')::INT) THEN
                        RAISE EXCEPTION 'Không đủ vé trong kho hàng2';
                    END IF;
                END IF;
            END LOOP;
        END IF;

        IF p_trans_type_id = 2 THEN
            FOR ele IN SELECT * FROM json_array_elements(p_list_item::JSON) LOOP
                IF EXISTS (SELECT 1 FROM "Transition" T 
                           WHERE T."TransitionId" = (ele ->> 'TransitionId')::INT 
                             AND T."ShiftDistributeId" = -1 
                             AND T."ConfirmStatusId" = 1) THEN
                    IF NOT ((ele ->> 'IsScratchcard')::BOOL) THEN
                        -- Inventory update
                        IF NOT EXISTS (SELECT 1 FROM "Inventory" 
                                       WHERE "LotteryDate" = (ele ->> 'LotteryDate')::DATE
                                         AND "LotteryChannelId" = (ele ->> 'LotteryChannelId')::INT
                                         AND "SalePointId" = p_sale_point_id) THEN
                            INSERT INTO "Inventory"
                            SELECT *
                            FROM "InventoryConfirm"
                            WHERE "LotteryDate" = (ele ->> 'LotteryDate')::DATE
                              AND "LotteryChannelId" = (ele ->> 'LotteryChannelId')::INT
                              AND "SalePointId" = p_sale_point_id;
                        ELSE
                            UPDATE "Inventory"
                            SET "TotalReceived" = IC."TotalReceived",
                                "TotalRemaining" = IC."TotalRemaining",
                                "TotalDupReceived" = IC."TotalDupReceived",
                                "TotalDupRemaining" = IC."TotalDupRemaining"
                            FROM "InventoryConfirm" IC
                            WHERE IC."LotteryDate" = (ele ->> 'LotteryDate')::DATE
                              AND IC."LotteryChannelId" = (ele ->> 'LotteryChannelId')::INT
                              AND IC."SalePointId" = p_sale_point_id
                              AND "Inventory"."LotteryDate" = IC."LotteryDate"
                              AND "Inventory"."LotteryChannelId" = IC."LotteryChannelId"
                              AND "Inventory"."SalePointId" = IC."SalePointId";
                        END IF;
                        -- Start Viet Edit
                        UPDATE "Inventory"
                        SET "TotalRemaining" = "TotalReceived" - (SELECT SUM("Quantity") 
                                                                    FROM "SalePointLog" 
                                                                    WHERE "LotteryDate"=(ele ->> 'LotteryDate')::DATE
                                                                    AND "LotteryChannelId" = (ele ->> 'LotteryChannelId')::INT
                                                                    AND "SalePointId" = p_sale_point_id)
                        WHERE "LotteryDate" = (ele ->> 'LotteryDate')::DATE
                            AND "LotteryChannelId" = (ele ->> 'LotteryChannelId')::INT
                            AND "SalePointId" = p_sale_point_id;
                        -- End Viet Edit
                    ELSE
                        -- Scratchcard update
                        IF NOT EXISTS (SELECT 1 FROM "Scratchcard" 
                                       WHERE "LotteryChannelId" = (ele ->> 'LotteryChannelId')::INT
                                         AND "SalePointId" = p_sale_point_id) THEN
                            INSERT INTO "Scratchcard"
                            ("LotteryChannelId", "TotalReceived", "TotalRemaining", "SalePointId")
                            VALUES ((ele ->> 'LotteryChannelId')::INT,
                                    (ele ->> 'TotalTrans')::INT,
                                    (ele ->> 'TotalTrans')::INT,
                                    p_sale_point_id);
                        ELSE
                            UPDATE "Scratchcard"
                            SET "TotalRemaining" = "TotalRemaining" + COALESCE((ele ->> 'TotalTrans')::INT, 0)
                            WHERE "SalePointId" = p_sale_point_id
                              AND "LotteryChannelId" = (ele ->> 'LotteryChannelId')::INT;
                        END IF;
                    END IF;

                    -- Update the transition
                    UPDATE "Transition"
                    SET "ConfirmTrans" = (ele ->> 'TotalTrans')::INT,
                        "ConfirmTransDup" = (ele ->> 'TotalTransDup')::INT,
                        "ConfirmBy" = v_user_id,
                        "ConfirmByName" = v_name,
                        "ConfirmDate" = NOW(),
                        "ConfirmStatusId" = 2,
                        "Note" = p_note
                    WHERE "TransitionId" = (ele ->> 'TransitionId')::INT
                      AND "ConfirmStatusId" = 1;
                ELSE
                    -- Handle scratchcard if not found
                    IF NOT EXISTS (SELECT 1 FROM "Scratchcard" 
                                   WHERE "LotteryChannelId" = (ele ->> 'LotteryChannelId')::INT
                                     AND "SalePointId" = p_sale_point_id) THEN
                        INSERT INTO "Scratchcard"
                        ("LotteryChannelId", "TotalReceived", "TotalRemaining", "SalePointId")
                        VALUES ((ele ->> 'LotteryChannelId')::INT,
                                (ele ->> 'TotalTrans')::INT,
                                (ele ->> 'TotalTrans')::INT,
                                p_sale_point_id);
                    ELSE
                        UPDATE "Scratchcard"
                        SET "TotalRemaining" = "TotalRemaining" + COALESCE((ele ->> 'TotalTrans')::INT, 0)
                        WHERE "SalePointId" = p_sale_point_id
                          AND "LotteryChannelId" = (ele ->> 'LotteryChannelId')::INT;
                    END IF;

                    -- Update the transition
                    UPDATE "Transition"
                    SET "ConfirmTrans" = (ele ->> 'TotalTrans')::INT,
                        "ConfirmTransDup" = (ele ->> 'TotalTransDup')::INT,
                        "ConfirmBy" = v_user_id,
                        "ConfirmByName" = v_name,
                        "ConfirmDate" = NOW(),
                        "ConfirmStatusId" = 2,
                        "Note" = p_note
                    WHERE "TransitionId" = (ele ->> 'TransitionId')::INT
                      AND "ConfirmStatusId" = 1;
                END IF;
            END LOOP;
        END IF;

        -- Additional handling for p_trans_type_id = 3 or others can be added similarly

        v_id := 1;
        v_mess := 'Xác nhận thành công';
    ELSE
        -- Handle non-confirm case
        FOR ele IN SELECT * FROM json_array_elements(p_list_item::JSON) LOOP
            IF NOT ((ele ->> 'IsScratchcard')::BOOL) THEN
                IF EXISTS (SELECT 1 FROM "Transition" 
                           WHERE "TransitionId" = (ele ->> 'TransitionId')::INT 
                             AND "ShiftDistributeId" = -1 
                             AND "ConfirmStatusId" = 1 
                             AND "ToSalePointId