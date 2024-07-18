CREATE TABLE public."PermissionRole" (
    "PermissionRoleId" integer DEFAULT nextval('public."PermissionRole_PermissionRoleId_seq"'::regclass) NOT NULL,
    "RoleName" character varying(255) NOT NULL,
    "PermissionId" integer NOT NULL,
    "ActionName" character varying(255) NOT NULL,
    "Sort" integer,
    "IsShowMenu" boolean DEFAULT true,
    "IsSubMenu" boolean DEFAULT true,
    "IsActive" boolean DEFAULT true,
    "IsDelete" boolean DEFAULT false,
    "RoleDisplayName" character varying(255),
    "CreatedDate" timestamp(6) without time zone DEFAULT now()
);
ALTER TABLE public."PermissionRole" OWNER TO postgres;

INSERT INTO public."PermissionRole"(
	"RoleName", "PermissionId", "ActionName", "Sort", "IsShowMenu", "IsSubMenu", "IsActive", "IsDelete", "RoleDisplayName", "CreatedDate")
	VALUES ('Rules', '3', 'Rules', 101, false, true, true, false, 'Nội quy', now());
-- PermissionId = 3 : menu Nhân sự

INSERT INTO public."PermissionRole"(
	"RoleName", "PermissionId", "ActionName", "Sort", "IsShowMenu", "IsSubMenu", "IsActive", "IsDelete", "RoleDisplayName", "CreatedDate")
	VALUES ('Rules', '3', 'Rules', 101, false, true, true, false, 'Xem nợ', now());
-- PermissionId = 3 : menu Nhân sự