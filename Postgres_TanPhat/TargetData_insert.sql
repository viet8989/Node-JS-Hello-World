IF NOT EXISTS(SELECT 1 FROM public."TargetData" WHERE "TargetDataTypeId" = 4 AND "Value" = 0.6) THEN
	INSERT INTO public."TargetData"("TargetDataTypeId", "FromValue", "ToValue", "Value") VALUES(4,-200, -101, 0.6);
END IF;

IF NOT EXISTS(SELECT 1 FROM public."TargetData" WHERE "TargetDataTypeId" = 4 AND "Value" = 0.5) THEN
	INSERT INTO public."TargetData"("TargetDataTypeId", "FromValue", "ToValue", "Value") VALUES(4,-300, -201, 0.5);
END IF;

IF NOT EXISTS(SELECT 1 FROM public."TargetData" WHERE "TargetDataTypeId" = 5 AND "Value" = 0.6) THEN
	INSERT INTO public."TargetData"("TargetDataTypeId", "FromValue", "ToValue", "Value") VALUES(5,-200, -101, 0.6);
END IF;

IF NOT EXISTS(SELECT 1 FROM public."TargetData" WHERE "TargetDataTypeId" = 5 AND "Value" = 0.6) THEN
	INSERT INTO public."TargetData"("TargetDataTypeId", "FromValue", "ToValue", "Value") VALUES(5,-300, -201, 0.5);
END IF;