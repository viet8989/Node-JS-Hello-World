
DROP TABLE IF EXISTS public."Rule";
DROP SEQUENCE IF EXISTS public."Rule_RuleId_seq";

CREATE SEQUENCE IF NOT EXISTS public."Rule_RuleId_seq"
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

ALTER SEQUENCE public."Rule_RuleId_seq"
    OWNER TO postgres;

-- Table: public.Rule

CREATE TABLE IF NOT EXISTS public."Rule"
(
    "RuleId" integer NOT NULL DEFAULT nextval('"Rule_RuleId_seq"'::regclass),
    "Name" character varying(255) COLLATE pg_catalog."default",
    "PathFile" character varying(500) COLLATE pg_catalog."default",
    "IsDeleted" boolean DEFAULT false,
    "CreatedBy" integer,
    "CreatedByName" character varying(255) COLLATE pg_catalog."default",
    "CreateTime" date DEFAULT now(),
    "ModifyBy" integer,
    "ModifyByName" character varying(255) COLLATE pg_catalog."default",
    "ModifyTime" date DEFAULT now(),
    CONSTRAINT "Rule_pkey" PRIMARY KEY ("RuleId")
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."Rule" OWNER to postgres;

COMMENT ON COLUMN public."Rule"."RuleId" IS 'Rule id tự động tăng';