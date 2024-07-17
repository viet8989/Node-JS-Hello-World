CREATE TABLE public."ShiftDistribute" (
    "ShiftDistributeId" integer NOT NULL,
    "DistributeDate" date NOT NULL,
    "SalePointId" integer NOT NULL,
    "ShiftId" integer NOT NULL,
    "UserId" integer,
    "ActionBy" integer,
    "ActionByName" character varying(100),
    "ActionDate" timestamp(6) without time zone DEFAULT now(),
    "ShiftTypeId" integer NOT NULL,
    "IsActive" boolean DEFAULT true,
    "Note" text,
    "ShiftMainId" integer
);


ALTER TABLE public."ShiftDistribute" OWNER TO postgres;