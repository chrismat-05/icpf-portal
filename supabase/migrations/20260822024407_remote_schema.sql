set local check_function_bodies = off;

alter default privileges for role "postgres" in schema "public" revoke all on sequences from "anon";

alter default privileges for role "postgres" in schema "public" revoke all on sequences from "authenticated";

alter default privileges for role "postgres" in schema "public" revoke all on sequences from "service_role";

alter default privileges for role "postgres" in schema "public" revoke all on tables from "anon";

alter default privileges for role "postgres" in schema "public" revoke all on tables from "authenticated";

alter default privileges for role "postgres" in schema "public" revoke all on tables from "service_role";

create table "public"."announcements" (
  "id"                uuid                     not null default gen_random_uuid(),
  "title"             text                     not null,
  "short_description" text                     not null,
  "content"           text,
  "image_id"          uuid,
  "cta_text"          text,
  "cta_url"           text,
  "starts_at"         timestamp with time zone not null,
  "ends_at"           timestamp with time zone,
  "is_active"         boolean                  not null default true,
  "created_by"        uuid,
  "updated_by"        uuid,
  "created_at"        timestamp with time zone not null default now(),
  "updated_at"        timestamp with time zone not null default now(),
  constraint "announcement_dates_valid" check (((ends_at IS NULL) OR (ends_at > starts_at))),
  constraint "announcements_pkey" primary key (id)
);

alter table "public"."announcements"
  enable row level security;

create table "public"."audit_logs" (
  "id"             uuid                     not null default gen_random_uuid(),
  "actor_user_id"  uuid,
  "actor_role"     text,
  "action"         text                     not null,
  "entity_type"    text                     not null,
  "entity_id"      uuid,
  "summary"        text                     not null,
  "previous_state" jsonb,
  "new_state"      jsonb,
  "ip_address"     inet,
  "user_agent"     text,
  "created_at"     timestamp with time zone not null default now(),
  constraint "audit_logs_pkey" primary key (id)
);

alter table "public"."audit_logs"
  enable row level security;

create table "public"."camp_assignments" (
  "id"          uuid                     not null default gen_random_uuid(),
  "user_id"     uuid                     not null,
  "camp_id"     uuid                     not null,
  "assigned_by" uuid,
  "assigned_at" timestamp with time zone not null default now(),
  "expires_at"  timestamp with time zone,
  "is_active"   boolean                  not null default true,
  "created_at"  timestamp with time zone not null default now(),
  constraint "camp_assignment_expiry_valid" check (((expires_at IS NULL) OR (expires_at > assigned_at))),
  constraint "camp_assignments_pkey" primary key (id),
  constraint "camp_assignments_user_camp_unique" unique (user_id, camp_id)
);

alter table "public"."camp_assignments"
  enable row level security;

create table "public"."camp_schedule_items" (
  "id"            uuid                     not null default gen_random_uuid(),
  "camp_id"       uuid                     not null,
  "title"         text                     not null,
  "description"   text,
  "starts_at"     timestamp with time zone not null,
  "ends_at"       timestamp with time zone,
  "location"      text,
  "speaker_id"    uuid,
  "display_order" integer                  not null default 0,
  "created_by"    uuid,
  "updated_by"    uuid,
  "created_at"    timestamp with time zone not null default now(),
  "updated_at"    timestamp with time zone not null default now(),
  constraint "camp_schedule_items_pkey" primary key (id),
  constraint "schedule_end_after_start" check (((ends_at IS NULL) OR (ends_at > starts_at)))
);

alter table "public"."camp_schedule_items"
  enable row level security;

create table "public"."camp_speakers" (
  "id"            uuid                     not null default gen_random_uuid(),
  "camp_id"       uuid                     not null,
  "name"          text                     not null,
  "description"   text,
  "image_id"      uuid,
  "display_order" integer                  not null default 0,
  "created_by"    uuid,
  "updated_by"    uuid,
  "created_at"    timestamp with time zone not null default now(),
  "updated_at"    timestamp with time zone not null default now(),
  constraint "camp_speakers_pkey" primary key (id)
);

alter table "public"."camp_speakers"
  enable row level security;

create table "public"."camps" (
  "id"                      uuid                     not null default gen_random_uuid(),
  "slug"                    text                     not null,
  "name"                    text                     not null,
  "tagline"                 text,
  "description"             text,
  "cover_image_id"          uuid,
  "start_at"                timestamp with time zone not null,
  "end_at"                  timestamp with time zone not null,
  "timezone"                text                     not null default 'Asia/Kolkata'::text,
  "venue_name"              text                     not null,
  "venue_address"           text                     not null,
  "map_url"                 text,
  "registration_enabled"    boolean                  not null default false,
  "registration_opens_at"   timestamp with time zone,
  "registration_closes_at"  timestamp with time zone,
  "registration_limit"      integer,
  "base_fee"                numeric(10,2)            not null default 0,
  "currency"                text                     not null default 'INR'::text,
  "age_restriction_enabled" boolean                  not null default false,
  "minimum_age"             integer,
  "maximum_age"             integer,
  "tshirt_enabled"          boolean                  not null default false,
  "tshirt_image_id"         uuid,
  "tshirt_price"            numeric(10,2),
  "youtube_url"             text,
  "google_sheets_enabled"   boolean                  not null default false,
  "published_at"            timestamp with time zone,
  "created_by"              uuid,
  "updated_by"              uuid,
  "created_at"              timestamp with time zone not null default now(),
  "updated_at"              timestamp with time zone not null default now(),
  constraint "camps_age_range_valid" check (((NOT age_restriction_enabled) OR ((minimum_age IS NOT NULL) AND (maximum_age IS
    NOT NULL) AND (minimum_age >= 0) AND (maximum_age >= minimum_age)))),
  constraint "camps_base_fee_nonnegative" check ((base_fee >= (0)::numeric)),
  constraint "camps_end_after_start" check ((end_at > start_at)),
  constraint "camps_pkey" primary key (id),
  constraint "camps_registration_limit_positive" check (((registration_limit IS NULL) OR (registration_limit > 0))),
  constraint "camps_slug_key" unique (slug),
  constraint "camps_tshirt_price_nonnegative" check (((tshirt_price IS NULL) OR (tshirt_price >= (0)::numeric)))
);

alter table "public"."camps"
  enable row level security;

create table "public"."checkins" (
  "id"              uuid                     not null default gen_random_uuid(),
  "registration_id" uuid                     not null,
  "camp_id"         uuid                     not null,
  "checked_in_at"   timestamp with time zone not null default now(),
  "checked_in_by"   uuid,
  "reversed_at"     timestamp with time zone,
  "reversed_by"     uuid,
  "reversal_reason" text,
  "created_at"      timestamp with time zone not null default now(),
  constraint "checkins_pkey" primary key (id),
  constraint "checkins_registration_id_key" unique (registration_id)
);

alter table "public"."checkins"
  enable row level security;

create table "public"."contact_submissions" (
  "id"         uuid                     not null default gen_random_uuid(),
  "name"       text                     not null,
  "email"      text                     not null,
  "phone"      text,
  "subject"    text,
  "message"    text                     not null,
  "created_at" timestamp with time zone not null default now(),
  constraint "contact_submissions_pkey" primary key (id)
);

alter table "public"."contact_submissions"
  enable row level security;

create table "public"."coupon_camps" (
  "coupon_id" uuid not null,
  "camp_id"   uuid not null,
  constraint "coupon_camps_pkey" primary key (coupon_id, camp_id)
);

alter table "public"."coupon_camps"
  enable row level security;

create table "public"."coupon_usages" (
  "id"              uuid                     not null default gen_random_uuid(),
  "coupon_id"       uuid                     not null,
  "registration_id" uuid                     not null,
  "discount_amount" numeric(10,2)            not null,
  "used_at"         timestamp with time zone not null default now(),
  constraint "coupon_usage_discount_nonnegative" check ((discount_amount >= (0)::numeric)),
  constraint "coupon_usages_coupon_id_registration_id_key" unique (coupon_id, registration_id),
  constraint "coupon_usages_pkey" primary key (id)
);

alter table "public"."coupon_usages"
  enable row level security;

create table "public"."coupons" (
  "id"               uuid                     not null default gen_random_uuid(),
  "code"             text                     not null,
  "name"             text                     not null,
  "discount_value"   numeric(10,2)            not null,
  "maximum_discount" numeric(10,2),
  "minimum_amount"   numeric(10,2),
  "max_usage"        integer,
  "first_x_users"    integer,
  "starts_at"        timestamp with time zone not null,
  "expires_at"       timestamp with time zone,
  "is_active"        boolean                  not null default true,
  "created_by"       uuid,
  "updated_by"       uuid,
  "created_at"       timestamp with time zone not null default now(),
  "updated_at"       timestamp with time zone not null default now(),
  constraint "coupon_discount_positive" check ((discount_value >= (0)::numeric)),
  constraint "coupon_expiry_valid" check (((expires_at IS NULL) OR (expires_at > starts_at))),
  constraint "coupon_first_x_positive" check (((first_x_users IS NULL) OR (first_x_users > 0))),
  constraint "coupon_max_discount_positive" check (((maximum_discount IS NULL) OR (maximum_discount >= (0)::numeric))),
  constraint "coupon_minimum_positive" check (((minimum_amount IS NULL) OR (minimum_amount >= (0)::numeric))),
  constraint "coupon_usage_positive" check (((max_usage IS NULL) OR (max_usage > 0))),
  constraint "coupons_code_key" unique (code),
  constraint "coupons_pkey" primary key (id)
);

alter table "public"."coupons"
  enable row level security;

create table "public"."form_acknowledgements" (
  "id"              uuid                     not null default gen_random_uuid(),
  "form_version_id" uuid                     not null,
  "text"            text                     not null,
  "version_label"   text                     not null,
  "is_required"     boolean                  not null default true,
  "display_order"   integer                  not null default 0,
  "created_at"      timestamp with time zone not null default now(),
  constraint "form_acknowledgements_pkey" primary key (id)
);

alter table "public"."form_acknowledgements"
  enable row level security;

create table "public"."form_conditions" (
  "id"                     uuid                     not null default gen_random_uuid(),
  "question_id"            uuid                     not null,
  "depends_on_question_id" uuid                     not null,
  "comparison_value"       jsonb                    not null,
  "created_at"             timestamp with time zone not null default now(),
  constraint "condition_not_self_reference" check ((question_id <> depends_on_question_id)),
  constraint "form_conditions_pkey" primary key (id)
);

alter table "public"."form_conditions"
  enable row level security;

create table "public"."form_options" (
  "id"            uuid    not null default gen_random_uuid(),
  "question_id"   uuid    not null,
  "label"         text    not null,
  "value"         text    not null,
  "display_order" integer not null default 0,
  "is_active"     boolean not null default true,
  constraint "form_options_pkey" primary key (id),
  constraint "form_options_question_id_value_key" unique (question_id, value)
);

alter table "public"."form_options"
  enable row level security;

create table "public"."form_questions" (
  "id"               uuid                     not null default gen_random_uuid(),
  "step_id"          uuid                     not null,
  "field_key"        text                     not null,
  "label"            text                     not null,
  "description"      text,
  "placeholder"      text,
  "is_required"      boolean                  not null default false,
  "default_value"    jsonb,
  "validation_rules" jsonb                    not null default '{}'::jsonb,
  "display_order"    integer                  not null default 0,
  "is_active"        boolean                  not null default true,
  "created_at"       timestamp with time zone not null default now(),
  constraint "form_questions_pkey" primary key (id),
  constraint "form_questions_step_id_field_key_key" unique (step_id, field_key)
);

alter table "public"."form_questions"
  enable row level security;

create table "public"."form_steps" (
  "id"              uuid                     not null default gen_random_uuid(),
  "form_version_id" uuid                     not null,
  "title"           text                     not null,
  "description"     text,
  "icon"            text,
  "display_order"   integer                  not null default 0,
  "is_active"       boolean                  not null default true,
  "created_at"      timestamp with time zone not null default now(),
  constraint "form_steps_pkey" primary key (id)
);

alter table "public"."form_steps"
  enable row level security;

create table "public"."google_sheet_integrations" (
  "id"                      uuid                     not null default gen_random_uuid(),
  "camp_id"                 uuid                     not null,
  "sheet_url"               text                     not null,
  "spreadsheet_id"          text,
  "sheet_name"              text,
  "webhook_url"             text,
  "integration_secret_hash" text,
  "last_sync_at"            timestamp with time zone,
  "last_success_at"         timestamp with time zone,
  "last_failure_at"         timestamp with time zone,
  "last_error"              text,
  "created_by"              uuid,
  "created_at"              timestamp with time zone not null default now(),
  "updated_at"              timestamp with time zone not null default now(),
  constraint "google_sheet_integrations_camp_id_key" unique (camp_id),
  constraint "google_sheet_integrations_pkey" primary key (id)
);

alter table "public"."google_sheet_integrations"
  enable row level security;

create table "public"."impact_statistics" (
  "id"            uuid                     not null default gen_random_uuid(),
  "stat_key"      text                     not null,
  "label"         text                     not null,
  "value"         numeric                  not null,
  "suffix"        text,
  "display_order" integer                  not null default 0,
  "is_active"     boolean                  not null default true,
  "created_by"    uuid,
  "updated_by"    uuid,
  "created_at"    timestamp with time zone not null default now(),
  "updated_at"    timestamp with time zone not null default now(),
  constraint "impact_statistics_pkey" primary key (id),
  constraint "impact_statistics_stat_key_key" unique (stat_key)
);

alter table "public"."impact_statistics"
  enable row level security;

create table "public"."media" (
  "id"                uuid                     not null default gen_random_uuid(),
  "bucket"            text                     not null,
  "storage_path"      text                     not null,
  "original_filename" text                     not null,
  "mime_type"         text                     not null,
  "file_size"         bigint                   not null,
  "alt_text"          text,
  "uploaded_by"       uuid,
  "created_at"        timestamp with time zone not null default now(),
  constraint "media_bucket_storage_path_key" unique (bucket, storage_path),
  constraint "media_file_size_positive" check ((file_size >= 0)),
  constraint "media_pkey" primary key (id)
);

alter table "public"."media"
  enable row level security;

create table "public"."payment_events" (
  "id"               uuid                     not null default gen_random_uuid(),
  "payment_id"       uuid,
  "event_id"         text,
  "event_type"       text                     not null,
  "signature"        text,
  "payload"          jsonb                    not null,
  "received_at"      timestamp with time zone not null default now(),
  "processed_at"     timestamp with time zone,
  "processing_error" text,
  constraint "payment_events_event_id_key" unique (event_id),
  constraint "payment_events_pkey" primary key (id)
);

alter table "public"."payment_events"
  enable row level security;

create table "public"."payments" (
  "id"                  uuid                     not null default gen_random_uuid(),
  "registration_id"     uuid                     not null,
  "cashfree_order_id"   text                     not null,
  "cashfree_payment_id" text,
  "payment_session_id"  text,
  "amount"              numeric(10,2)            not null,
  "currency"            text                     not null default 'INR'::text,
  "gateway_status"      text,
  "gateway_response"    jsonb,
  "created_at"          timestamp with time zone not null default now(),
  "updated_at"          timestamp with time zone not null default now(),
  "paid_at"             timestamp with time zone,
  constraint "payment_amount_positive" check ((amount >= (0)::numeric)),
  constraint "payments_cashfree_order_id_key" unique (cashfree_order_id),
  constraint "payments_pkey" primary key (id)
);

alter table "public"."payments"
  enable row level security;

create table "public"."permissions" (
  "id"          uuid                     not null default gen_random_uuid(),
  "code"        text                     not null,
  "name"        text                     not null,
  "module"      text                     not null,
  "description" text,
  "created_at"  timestamp with time zone not null default now(),
  constraint "permissions_code_key" unique (code),
  constraint "permissions_pkey" primary key (id)
);

alter table "public"."permissions"
  enable row level security;

create table "public"."profiles" (
  "id"            uuid                     not null,
  "full_name"     text                     not null,
  "email"         text                     not null,
  "phone"         text,
  "avatar_url"    text,
  "is_active"     boolean                  not null default true,
  "last_login_at" timestamp with time zone,
  "created_at"    timestamp with time zone not null default now(),
  "updated_at"    timestamp with time zone not null default now(),
  constraint "profiles_pkey" primary key (id)
);

alter table "public"."profiles"
  enable row level security;

create table "public"."refunds" (
  "id"                 uuid                     not null default gen_random_uuid(),
  "registration_id"    uuid                     not null,
  "payment_id"         uuid                     not null,
  "cashfree_refund_id" text,
  "amount"             numeric(10,2)            not null,
  "reason"             text                     not null,
  "initiated_by"       uuid,
  "initiated_at"       timestamp with time zone not null default now(),
  "completed_at"       timestamp with time zone,
  "failure_reason"     text,
  "gateway_response"   jsonb,
  "created_at"         timestamp with time zone not null default now(),
  "updated_at"         timestamp with time zone not null default now(),
  constraint "refund_amount_positive" check ((amount > (0)::numeric)),
  constraint "refunds_cashfree_refund_id_key" unique (cashfree_refund_id),
  constraint "refunds_pkey" primary key (id)
);

alter table "public"."refunds"
  enable row level security;

create table "public"."registration_acknowledgements" (
  "id"                               uuid                     not null default gen_random_uuid(),
  "registration_id"                  uuid                     not null,
  "acknowledgement_id"               uuid,
  "acknowledgement_text_snapshot"    text                     not null,
  "acknowledgement_version_snapshot" text                     not null,
  "accepted"                         boolean                  not null default false,
  "accepted_at"                      timestamp with time zone,
  "created_at"                       timestamp with time zone not null default now(),
  constraint "registration_acknowledgements_pkey" primary key (id),
  constraint "registration_acknowledgements_registration_id_acknowledgeme_key" unique (registration_id, acknowledgement_id)
);

alter table "public"."registration_acknowledgements"
  enable row level security;

create table "public"."registration_answers" (
  "id"              uuid                     not null default gen_random_uuid(),
  "registration_id" uuid                     not null,
  "question_id"     uuid                     not null,
  "field_key"       text                     not null,
  "answer_value"    jsonb,
  "created_at"      timestamp with time zone not null default now(),
  "updated_at"      timestamp with time zone not null default now(),
  constraint "registration_answers_pkey" primary key (id),
  constraint "registration_answers_registration_id_question_id_key" unique (registration_id, question_id)
);

alter table "public"."registration_answers"
  enable row level security;

create table "public"."registration_counters" (
  "year"        integer                  not null,
  "last_number" bigint                   not null default 0,
  "updated_at"  timestamp with time zone not null default now(),
  constraint "registration_counter_number_valid" check ((last_number >= 0)),
  constraint "registration_counter_year_valid" check ((year >= 2000)),
  constraint "registration_counters_pkey" primary key (year)
);

alter table "public"."registration_counters"
  enable row level security;

create table "public"."registration_form_versions" (
  "id"             uuid                     not null default gen_random_uuid(),
  "form_id"        uuid                     not null,
  "version_number" integer                  not null,
  "published_at"   timestamp with time zone,
  "created_by"     uuid,
  "created_at"     timestamp with time zone not null default now(),
  constraint "registration_form_versions_form_id_version_number_key" unique (form_id, version_number),
  constraint "registration_form_versions_pkey" primary key (id)
);

alter table "public"."registration_form_versions"
  enable row level security;

create table "public"."registration_forms" (
  "id"          uuid                     not null default gen_random_uuid(),
  "camp_id"     uuid                     not null,
  "name"        text                     not null,
  "description" text,
  "created_by"  uuid,
  "created_at"  timestamp with time zone not null default now(),
  "updated_at"  timestamp with time zone not null default now(),
  constraint "registration_forms_camp_id_key" unique (camp_id),
  constraint "registration_forms_pkey" primary key (id)
);

alter table "public"."registration_forms"
  enable row level security;

create table "public"."registration_seat_reservations" (
  "id"              uuid                     not null default gen_random_uuid(),
  "camp_id"         uuid                     not null,
  "registration_id" uuid                     not null,
  "expires_at"      timestamp with time zone not null,
  "released_at"     timestamp with time zone,
  "created_at"      timestamp with time zone not null default now(),
  constraint "registration_seat_reservations_pkey" primary key (id),
  constraint "registration_seat_reservations_registration_id_key" unique (registration_id)
);

alter table "public"."registration_seat_reservations"
  enable row level security;

create table "public"."registrations" (
  "id"                  uuid                     not null default gen_random_uuid(),
  "registration_number" text                     not null,
  "camp_id"             uuid                     not null,
  "form_version_id"     uuid                     not null,
  "participant_name"    text                     not null,
  "participant_email"   text                     not null,
  "participant_phone"   text                     not null,
  "participant_dob"     date,
  "base_amount"         numeric(10,2)            not null default 0,
  "tshirt_amount"       numeric(10,2)            not null default 0,
  "discount_amount"     numeric(10,2)            not null default 0,
  "final_amount"        numeric(10,2)            not null default 0,
  "currency"            text                     not null default 'INR'::text,
  "coupon_id"           uuid,
  "form_snapshot"       jsonb                    not null default '{}'::jsonb,
  "created_at"          timestamp with time zone not null default now(),
  "updated_at"          timestamp with time zone not null default now(),
  constraint "registration_amounts_nonnegative"
    check (((base_amount >= (0)::numeric) AND (tshirt_amount >= (0)::numeric) AND (discount_amount >= (0)::numeric) AND (final_amount >= (0)::numeric))),
  constraint "registrations_pkey" primary key (id),
  constraint "registrations_registration_number_key" unique (registration_number)
);

alter table "public"."registrations"
  enable row level security;

create table "public"."role_permissions" (
  "role_id"       uuid                     not null,
  "permission_id" uuid                     not null,
  "created_at"    timestamp with time zone not null default now(),
  constraint "role_permissions_pkey" primary key (role_id, permission_id)
);

alter table "public"."role_permissions"
  enable row level security;

create table "public"."roles" (
  "id"             uuid                     not null default gen_random_uuid(),
  "code"           text                     not null,
  "name"           text                     not null,
  "description"    text,
  "is_system_role" boolean                  not null default true,
  "created_at"     timestamp with time zone not null default now(),
  constraint "roles_code_key" unique (code),
  constraint "roles_pkey" primary key (id)
);

alter table "public"."roles"
  enable row level security;

create table "public"."system_settings" (
  "key"         text                     not null,
  "value"       jsonb                    not null,
  "description" text,
  "updated_by"  uuid,
  "updated_at"  timestamp with time zone not null default now(),
  constraint "system_settings_pkey" primary key (key)
);

alter table "public"."system_settings"
  enable row level security;

create table "public"."testimonials" (
  "id"            uuid                     not null default gen_random_uuid(),
  "name"          text                     not null,
  "text"          text                     not null,
  "context"       text,
  "image_id"      uuid,
  "display_order" integer                  not null default 0,
  "is_active"     boolean                  not null default true,
  "created_by"    uuid,
  "updated_by"    uuid,
  "created_at"    timestamp with time zone not null default now(),
  "updated_at"    timestamp with time zone not null default now(),
  constraint "testimonials_pkey" primary key (id)
);

alter table "public"."testimonials"
  enable row level security;

create table "public"."user_roles" (
  "user_id"    uuid                     not null,
  "role_id"    uuid                     not null,
  "created_at" timestamp with time zone not null default now(),
  constraint "user_roles_pkey" primary key (user_id, role_id)
);

alter table "public"."user_roles"
  enable row level security;

create type "public"."camp_content_status" as enum (
  'draft',
  'published',
  'archived'
);

alter table "public"."camps"
  add column "content_status" public.camp_content_status not null default 'draft'::public.camp_content_status;

create type "public"."camp_registration_status" as enum (
  'scheduled',
  'open',
  'paused',
  'closed'
);

alter table "public"."camps"
  add column "operational_registration_status" public.camp_registration_status not null default 'scheduled'::public.camp_registration_status;

create type "public"."condition_operator" as enum (
  'equals',
  'not_equals',
  'contains',
  'not_contains',
  'greater_than',
  'less_than',
  'greater_or_equal',
  'less_or_equal',
  'in',
  'not_in'
);

alter table "public"."form_conditions"
  add column "operator" public.condition_operator not null;

create type "public"."coupon_discount_type" as enum (
  'percentage',
  'fixed'
);

alter table "public"."coupons"
  add column "discount_type" public.coupon_discount_type not null;

create type "public"."coupon_visibility" as enum (
  'public',
  'private'
);

alter table "public"."coupons"
  add column "visibility" public.coupon_visibility not null;

create type "public"."form_version_status" as enum (
  'draft',
  'published',
  'retired'
);

alter table "public"."registration_form_versions"
  add column "status" public.form_version_status not null default 'draft'::public.form_version_status;

create type "public"."google_sheet_status" as enum (
  'not_configured',
  'configured',
  'active',
  'error',
  'disabled'
);

alter table "public"."google_sheet_integrations"
  add column "status" public.google_sheet_status not null default 'not_configured'::public.google_sheet_status;

create type "public"."media_visibility" as enum (
  'public',
  'private'
);

alter table "public"."media"
  add column "visibility" public.media_visibility not null default 'public'::public.media_visibility;

create type "public"."payment_event_processing_status" as enum (
  'received',
  'processing',
  'processed',
  'ignored',
  'failed'
);

alter table "public"."payment_events"
  add column "processing_status" public.payment_event_processing_status not null default 'received'::public.payment_event_processing_status;

create type "public"."payment_status" as enum (
  'created',
  'pending',
  'paid',
  'failed',
  'expired',
  'cancelled',
  'partially_refunded',
  'refunded'
);

alter table "public"."payments"
  add column "status" public.payment_status not null default 'created'::public.payment_status;

create type "public"."question_type" as enum (
  'short_text',
  'long_text',
  'number',
  'email',
  'phone',
  'date',
  'time',
  'dropdown',
  'radio',
  'checkbox',
  'multi_select',
  'yes_no',
  'file',
  'tshirt_size'
);

alter table "public"."form_questions"
  add column "question_type" public.question_type not null;

create type "public"."refund_status" as enum (
  'requested',
  'processing',
  'completed',
  'failed',
  'cancelled'
);

alter table "public"."refunds"
  add column "status" public.refund_status not null default 'requested'::public.refund_status;

create type "public"."registration_status" as enum (
  'draft',
  'payment_pending',
  'paid',
  'payment_failed',
  'cancelled',
  'refunded',
  'partially_refunded'
);

alter table "public"."registrations"
  add column "status" public.registration_status not null default 'draft'::public.registration_status;

create or replace function public.consume_registration_seat (
  p_registration_id uuid
)
  returns boolean
  language plpgsql
  security definer
  set search_path to ''
  AS $function$
BEGIN

    UPDATE public.registration_seat_reservations
    SET
        expires_at = now(),
        released_at = NULL
    WHERE registration_id = p_registration_id;

    RETURN FOUND;

END;
$function$;

create or replace function public.current_user_role()
  returns text
  language sql
  stable
  security definer
  set search_path to ''
  AS $function$
    SELECT r.code
    FROM public.user_roles ur
    JOIN public.roles r
        ON r.id = ur.role_id
    JOIN public.profiles p
        ON p.id = ur.user_id
    WHERE ur.user_id = auth.uid()
      AND p.is_active = true
    LIMIT 1;
$function$;

create or replace function public.generate_registration_number()
  returns text
  language plpgsql
  security definer
  set search_path to ''
  AS $function$
DECLARE
    current_year integer;
    next_number bigint;
    prefix text;
BEGIN

    current_year := EXTRACT(YEAR FROM now())::integer;

    SELECT COALESCE(
        (
            SELECT value #>> '{}'
            FROM public.system_settings
            WHERE key = 'registration_id_prefix'
        ),
        'ICPF'
    )
    INTO prefix;

    INSERT INTO public.registration_counters (
        year,
        last_number
    )
    VALUES (
        current_year,
        1
    )
    ON CONFLICT (year)
    DO UPDATE
    SET
        last_number =
            public.registration_counters.last_number + 1,
        updated_at = now()
    RETURNING last_number
    INTO next_number;

    RETURN
        prefix
        || RIGHT(current_year::text, 2)
        || '-'
        || LPAD(next_number::text, 5, '0');

END;
$function$;

create or replace function public.handle_new_user()
  returns trigger
  language plpgsql
  security definer
  set search_path to 'public'
  AS $function$
BEGIN
    INSERT INTO public.profiles (
        id,
        full_name,
        email
    )
    VALUES (
        NEW.id,
        COALESCE(
            NEW.raw_user_meta_data ->> 'full_name',
            NEW.email
        ),
        NEW.email
    );

    RETURN NEW;
END;
$function$;

create or replace function public.has_camp_access (
  target_camp_id uuid
)
  returns boolean
  language sql
  stable
  security definer
  set search_path to ''
  AS $function$
    SELECT
        public.has_role('admin')
        OR target_camp_id IN (
            SELECT public.user_assigned_camp_ids()
        );
$function$;

create or replace function public.has_permission (
  required_permission text
)
  returns boolean
  language sql
  stable
  security definer
  set search_path to ''
  AS $function$
    SELECT EXISTS (
        SELECT 1
        FROM public.user_roles ur
        JOIN public.role_permissions rp
            ON rp.role_id = ur.role_id
        JOIN public.permissions p
            ON p.id = rp.permission_id
        JOIN public.profiles pr
            ON pr.id = ur.user_id
        WHERE ur.user_id = auth.uid()
          AND p.code = required_permission
          AND pr.is_active = true
    );
$function$;

create or replace function public.has_role (
  required_role text
)
  returns boolean
  language sql
  stable
  security definer
  set search_path to ''
  AS $function$
    SELECT EXISTS (
        SELECT 1
        FROM public.user_roles ur
        JOIN public.roles r
            ON r.id = ur.role_id
        JOIN public.profiles p
            ON p.id = ur.user_id
        WHERE ur.user_id = auth.uid()
          AND r.code = required_role
          AND p.is_active = true
    );
$function$;

create or replace function public.is_admin()
  returns boolean
  language sql
  stable
  security definer
  set search_path to ''
  AS $function$
    SELECT public.has_role('admin');
$function$;

create or replace function public.mark_registration_paid (
  p_registration_id uuid,
  p_payment_id      uuid
)
  returns boolean
  language plpgsql
  security definer
  set search_path to ''
  AS $function$
DECLARE
    payment_amount numeric;
    registration_amount numeric;
BEGIN

    SELECT amount
    INTO payment_amount
    FROM public.payments
    WHERE id = p_payment_id
      AND registration_id = p_registration_id
    FOR UPDATE;


    IF NOT FOUND THEN
        RAISE EXCEPTION
            'PAYMENT_NOT_FOUND';
    END IF;


    SELECT final_amount
    INTO registration_amount
    FROM public.registrations
    WHERE id = p_registration_id
    FOR UPDATE;


    IF NOT FOUND THEN
        RAISE EXCEPTION
            'REGISTRATION_NOT_FOUND';
    END IF;


    IF payment_amount <> registration_amount THEN
        RAISE EXCEPTION
            'PAYMENT_AMOUNT_MISMATCH';
    END IF;


    UPDATE public.payments
    SET
        status = 'paid',
        paid_at = COALESCE(paid_at, now()),
        updated_at = now()
    WHERE id = p_payment_id;


    UPDATE public.registrations
    SET
        status = 'paid',
        updated_at = now()
    WHERE id = p_registration_id;


    PERFORM public.consume_registration_seat(
        p_registration_id
    );


    RETURN true;

END;
$function$;

create or replace function public.prevent_audit_log_mutation()
  returns trigger
  language plpgsql
  AS $function$
BEGIN

    RAISE EXCEPTION
        'AUDIT_LOG_IMMUTABLE: Audit logs cannot be updated or deleted.';

END;
$function$;

create or replace function public.prevent_locked_form_child_mutation()
  returns trigger
  language plpgsql
  AS $function$
DECLARE
    version_status public.form_version_status;
    target_question_id uuid;
BEGIN

    IF TG_TABLE_NAME = 'form_steps' THEN

        SELECT fv.status
        INTO version_status
        FROM public.registration_form_versions fv
        WHERE fv.id = COALESCE(
            NEW.form_version_id,
            OLD.form_version_id
        );


    ELSIF TG_TABLE_NAME = 'form_questions' THEN

        SELECT fv.status
        INTO version_status
        FROM public.registration_form_versions fv
        JOIN public.form_steps fs
            ON fs.form_version_id = fv.id
        WHERE fs.id = COALESCE(
            NEW.step_id,
            OLD.step_id
        );


    ELSIF TG_TABLE_NAME = 'form_options' THEN

        target_question_id := COALESCE(
            NEW.question_id,
            OLD.question_id
        );

        SELECT fv.status
        INTO version_status
        FROM public.registration_form_versions fv
        JOIN public.form_steps fs
            ON fs.form_version_id = fv.id
        JOIN public.form_questions fq
            ON fq.step_id = fs.id
        WHERE fq.id = target_question_id;


    ELSIF TG_TABLE_NAME = 'form_conditions' THEN

        target_question_id := COALESCE(
            NEW.question_id,
            OLD.question_id
        );

        SELECT fv.status
        INTO version_status
        FROM public.registration_form_versions fv
        JOIN public.form_steps fs
            ON fs.form_version_id = fv.id
        JOIN public.form_questions fq
            ON fq.step_id = fs.id
        WHERE fq.id = target_question_id;


    ELSIF TG_TABLE_NAME = 'form_acknowledgements' THEN

        SELECT fv.status
        INTO version_status
        FROM public.registration_form_versions fv
        WHERE fv.id = COALESCE(
            NEW.form_version_id,
            OLD.form_version_id
        );

    END IF;


    IF version_status IN ('published', 'retired') THEN

        RAISE EXCEPTION
            'FORM_VERSION_IMMUTABLE: Cannot modify a published or retired form version. Create a new version instead.';

    END IF;


    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;

    RETURN NEW;

END;
$function$;

create or replace function public.prevent_locked_form_version_delete()
  returns trigger
  language plpgsql
  AS $function$
BEGIN

    IF OLD.status IN ('published', 'retired') THEN
        RAISE EXCEPTION
            'FORM_VERSION_IMMUTABLE: Published or retired form versions cannot be deleted.';
    END IF;

    RETURN OLD;

END;
$function$;

create or replace function public.prevent_locked_form_version_update()
  returns trigger
  language plpgsql
  AS $function$
BEGIN

    IF OLD.status IN ('published', 'retired') THEN
        RAISE EXCEPTION
            'FORM_VERSION_IMMUTABLE: Published or retired form versions cannot be modified.';
    END IF;

    RETURN NEW;

END;
$function$;

create or replace function public.prevent_transactional_camp_delete()
  returns trigger
  language plpgsql
  AS $function$
BEGIN

    IF EXISTS (
        SELECT 1
        FROM public.registrations
        WHERE camp_id = OLD.id
        LIMIT 1
    ) THEN

        RAISE EXCEPTION
            'CAMP_HAS_TRANSACTIONS: Camp must be archived instead of deleted.';

    END IF;


    RETURN OLD;

END;
$function$;

create or replace function public.release_registration_seat (
  p_registration_id uuid
)
  returns boolean
  language plpgsql
  security definer
  set search_path to ''
  AS $function$
BEGIN

    UPDATE public.registration_seat_reservations
    SET released_at = now()
    WHERE registration_id = p_registration_id
      AND released_at IS NULL;


    RETURN FOUND;

END;
$function$;

create or replace function public.reserve_registration_seat (
  p_camp_id         uuid,
  p_registration_id uuid,
  p_expires_at      timestamp with time zone
)
  returns boolean
  language plpgsql
  security definer
  set search_path to ''
  AS $function$
DECLARE
    camp_limit integer;
    paid_count integer;
    active_reservation_count integer;
BEGIN

    -- Lock camp row to serialize capacity checks.
    SELECT registration_limit
    INTO camp_limit
    FROM public.camps
    WHERE id = p_camp_id
    FOR UPDATE;


    IF NOT FOUND THEN
        RAISE EXCEPTION
            'CAMP_NOT_FOUND';

    END IF;


    -- No limit means unlimited capacity.
    IF camp_limit IS NULL THEN

        INSERT INTO public.registration_seat_reservations (
            camp_id,
            registration_id,
            expires_at
        )
        VALUES (
            p_camp_id,
            p_registration_id,
            p_expires_at
        )
        ON CONFLICT (registration_id)
        DO UPDATE SET
            expires_at = EXCLUDED.expires_at,
            released_at = NULL;

        RETURN true;

    END IF;


    -- Release expired temporary reservations first.
    UPDATE public.registration_seat_reservations
    SET released_at = now()
    WHERE camp_id = p_camp_id
      AND released_at IS NULL
      AND expires_at <= now();


    SELECT COUNT(*)
    INTO paid_count
    FROM public.registrations
    WHERE camp_id = p_camp_id
      AND status IN (
          'paid',
          'partially_refunded'
      );


    SELECT COUNT(*)
    INTO active_reservation_count
    FROM public.registration_seat_reservations
    WHERE camp_id = p_camp_id
      AND released_at IS NULL
      AND expires_at > now();


    -- Existing reservation for this registration
    -- should not consume another seat.
    IF EXISTS (
        SELECT 1
        FROM public.registration_seat_reservations
        WHERE registration_id = p_registration_id
          AND camp_id = p_camp_id
          AND released_at IS NULL
          AND expires_at > now()
    ) THEN

        RETURN true;

    END IF;


    IF paid_count + active_reservation_count >= camp_limit THEN

        RAISE EXCEPTION
            'REGISTRATION_FULL';

    END IF;


    INSERT INTO public.registration_seat_reservations (
        camp_id,
        registration_id,
        expires_at
    )
    VALUES (
        p_camp_id,
        p_registration_id,
        p_expires_at
    )
    ON CONFLICT (registration_id)
    DO UPDATE SET
        camp_id = EXCLUDED.camp_id,
        expires_at = EXCLUDED.expires_at,
        released_at = NULL;


    RETURN true;

END;
$function$;

create or replace function public.set_registration_number()
  returns trigger
  language plpgsql
  security definer
  set search_path to ''
  AS $function$
BEGIN

    IF NEW.registration_number IS NULL
       OR BTRIM(NEW.registration_number) = '' THEN

        NEW.registration_number :=
            public.generate_registration_number();

    END IF;

    RETURN NEW;

END;
$function$;

create or replace function public.set_updated_at()
  returns trigger
  language plpgsql
  AS $function$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$function$;

create or replace function public.user_assigned_camp_ids()
  returns SETOF uuid
  language sql
  stable
  security definer
  set search_path to ''
  AS $function$
    SELECT ca.camp_id
    FROM public.camp_assignments ca
    WHERE ca.user_id = auth.uid()
      AND ca.is_active = true
      AND (
          ca.expires_at IS NULL
          OR ca.expires_at > now()
      );
$function$;

create or replace function public.validate_checkin_registration()
  returns trigger
  language plpgsql
  AS $function$
DECLARE
    registration_status_value public.registration_status;
    registration_camp_id uuid;
BEGIN

    SELECT
        status,
        camp_id
    INTO
        registration_status_value,
        registration_camp_id
    FROM public.registrations
    WHERE id = NEW.registration_id;


    IF NOT FOUND THEN
        RAISE EXCEPTION
            'REGISTRATION_NOT_FOUND';
    END IF;


    IF registration_status_value NOT IN (
        'paid',
        'partially_refunded'
    ) THEN
        RAISE EXCEPTION
            'REGISTRATION_NOT_PAID';
    END IF;


    IF registration_camp_id <> NEW.camp_id THEN
        RAISE EXCEPTION
            'CAMP_SCOPE_MISMATCH';
    END IF;


    RETURN NEW;

END;
$function$;

create or replace function public.validate_form_version_transition()
  returns trigger
  language plpgsql
  AS $function$
BEGIN

    IF OLD.status = 'draft'
       AND NEW.status NOT IN ('draft', 'published') THEN

        RAISE EXCEPTION
            'INVALID_FORM_VERSION_TRANSITION';

    END IF;


    IF OLD.status = 'published'
       AND NEW.status NOT IN ('retired') THEN

        RAISE EXCEPTION
            'INVALID_FORM_VERSION_TRANSITION';

    END IF;


    IF OLD.status = 'retired'
       AND NEW.status <> 'retired' THEN

        RAISE EXCEPTION
            'INVALID_FORM_VERSION_TRANSITION';

    END IF;


    IF NEW.status = 'published'
       AND OLD.status <> 'published' THEN

        NEW.published_at := COALESCE(
            NEW.published_at,
            now()
        );

    END IF;


    RETURN NEW;

END;
$function$;

create or replace function public.validate_refund_amount()
  returns trigger
  language plpgsql
  AS $function$
DECLARE
    payment_total numeric;
    previous_refunds numeric;
BEGIN

    SELECT amount
    INTO payment_total
    FROM public.payments
    WHERE id = NEW.payment_id;


    IF NOT FOUND THEN
        RAISE EXCEPTION
            'PAYMENT_NOT_FOUND';
    END IF;


    SELECT COALESCE(SUM(amount), 0)
    INTO previous_refunds
    FROM public.refunds
    WHERE payment_id = NEW.payment_id
      AND status IN (
          'requested',
          'processing',
          'completed'
      )
      AND id <> COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid);


    IF previous_refunds + NEW.amount > payment_total THEN
        RAISE EXCEPTION
            'REFUND_AMOUNT_EXCEEDS_PAYMENT';
    END IF;


    RETURN NEW;

END;
$function$;

create or replace function public.validate_registration_answer_question()
  returns trigger
  language plpgsql
  AS $function$
DECLARE
    registration_form_version uuid;
    question_form_version uuid;
BEGIN

    SELECT form_version_id
    INTO registration_form_version
    FROM public.registrations
    WHERE id = NEW.registration_id;


    SELECT fv.id
    INTO question_form_version
    FROM public.form_questions fq
    JOIN public.form_steps fs
        ON fs.id = fq.step_id
    JOIN public.registration_form_versions fv
        ON fv.id = fs.form_version_id
    WHERE fq.id = NEW.question_id;


    IF registration_form_version IS NULL
       OR question_form_version IS NULL
       OR registration_form_version <> question_form_version THEN

        RAISE EXCEPTION
            'FORM_VERSION_MISMATCH';

    END IF;


    RETURN NEW;

END;
$function$;

create or replace function public.write_audit_log (
  p_action         text,
  p_entity_type    text,
  p_entity_id      uuid,
  p_summary        text,
  p_previous_state jsonb default null::jsonb,
  p_new_state      jsonb default null::jsonb,
  p_ip_address     inet  default null::inet,
  p_user_agent     text  default null::text
)
  returns uuid
  language plpgsql
  security definer
  set search_path to ''
  AS $function$
DECLARE
    new_id uuid;
    actor_role_value text;
BEGIN

    SELECT r.code
    INTO actor_role_value
    FROM public.user_roles ur
    JOIN public.roles r
        ON r.id = ur.role_id
    WHERE ur.user_id = auth.uid()
    LIMIT 1;


    INSERT INTO public.audit_logs (
        actor_user_id,
        actor_role,
        action,
        entity_type,
        entity_id,
        summary,
        previous_state,
        new_state,
        ip_address,
        user_agent
    )
    VALUES (
        auth.uid(),
        actor_role_value,
        p_action,
        p_entity_type,
        p_entity_id,
        p_summary,
        p_previous_state,
        p_new_state,
        p_ip_address,
        p_user_agent
    )
    RETURNING id
    INTO new_id;


    RETURN new_id;

END;
$function$;

alter table "public"."camp_schedule_items"
  add constraint "camp_schedule_items_speaker_id_fkey" foreign key (speaker_id) references public.camp_speakers(id) on delete set null;

alter table "public"."camp_assignments"
  add constraint "camp_assignments_camp_id_fkey" foreign key (camp_id) references public.camps(id) on delete cascade;

alter table "public"."camp_schedule_items"
  add constraint "camp_schedule_items_camp_id_fkey" foreign key (camp_id) references public.camps(id) on delete cascade;

alter table "public"."camp_speakers"
  add constraint "camp_speakers_camp_id_fkey" foreign key (camp_id) references public.camps(id) on delete cascade;

alter table "public"."checkins"
  add constraint "checkins_camp_id_fkey" foreign key (camp_id) references public.camps(id) on delete restrict;

alter table "public"."coupon_camps"
  add constraint "coupon_camps_camp_id_fkey" foreign key (camp_id) references public.camps(id) on delete cascade;

alter table "public"."coupon_camps"
  add constraint "coupon_camps_coupon_id_fkey" foreign key (coupon_id) references public.coupons(id) on delete cascade;

alter table "public"."coupon_usages"
  add constraint "coupon_usages_coupon_id_fkey" foreign key (coupon_id) references public.coupons(id) on delete restrict;

alter table "public"."form_conditions"
  add constraint "form_conditions_depends_on_question_id_fkey" foreign key (depends_on_question_id) references public.form_questions(id) on delete cascade;

alter table "public"."form_conditions"
  add constraint "form_conditions_question_id_fkey" foreign key (question_id) references public.form_questions(id) on delete cascade;

alter table "public"."form_options"
  add constraint "form_options_question_id_fkey" foreign key (question_id) references public.form_questions(id) on delete cascade;

alter table "public"."form_questions"
  add constraint "form_questions_step_id_fkey" foreign key (step_id) references public.form_steps(id) on delete cascade;

alter table "public"."google_sheet_integrations"
  add constraint "google_sheet_integrations_camp_id_fkey" foreign key (camp_id) references public.camps(id) on delete cascade;

alter table "public"."payment_events"
  add constraint "payment_events_payment_id_fkey" foreign key (payment_id) references public.payments(id) on delete set null;

alter table "public"."profiles"
  add constraint "profiles_id_fkey" foreign key (id) references auth.users(id) on delete cascade;

alter table "public"."announcements"
  add constraint "announcements_created_by_fkey" foreign key (created_by) references public.profiles(id) on delete set null;

alter table "public"."announcements"
  add constraint "announcements_updated_by_fkey" foreign key (updated_by) references public.profiles(id) on delete set null;

alter table "public"."audit_logs"
  add constraint "audit_logs_actor_user_id_fkey" foreign key (actor_user_id) references public.profiles(id) on delete set null;

alter table "public"."camp_assignments"
  add constraint "camp_assignments_assigned_by_fkey" foreign key (assigned_by) references public.profiles(id) on delete set null;

alter table "public"."camp_assignments"
  add constraint "camp_assignments_user_id_fkey" foreign key (user_id) references public.profiles(id) on delete cascade;

alter table "public"."camp_schedule_items"
  add constraint "camp_schedule_items_created_by_fkey" foreign key (created_by) references public.profiles(id) on delete set null;

alter table "public"."camp_schedule_items"
  add constraint "camp_schedule_items_updated_by_fkey" foreign key (updated_by) references public.profiles(id) on delete set null;

alter table "public"."camp_speakers"
  add constraint "camp_speakers_created_by_fkey" foreign key (created_by) references public.profiles(id) on delete set null;

alter table "public"."camp_speakers"
  add constraint "camp_speakers_updated_by_fkey" foreign key (updated_by) references public.profiles(id) on delete set null;

alter table "public"."camps"
  add constraint "camps_created_by_fkey" foreign key (created_by) references public.profiles(id) on delete set null;

alter table "public"."camps"
  add constraint "camps_updated_by_fkey" foreign key (updated_by) references public.profiles(id) on delete set null;

alter table "public"."checkins"
  add constraint "checkins_checked_in_by_fkey" foreign key (checked_in_by) references public.profiles(id) on delete set null;

alter table "public"."checkins"
  add constraint "checkins_reversed_by_fkey" foreign key (reversed_by) references public.profiles(id) on delete set null;

alter table "public"."coupons"
  add constraint "coupons_created_by_fkey" foreign key (created_by) references public.profiles(id) on delete set null;

alter table "public"."coupons"
  add constraint "coupons_updated_by_fkey" foreign key (updated_by) references public.profiles(id) on delete set null;

alter table "public"."google_sheet_integrations"
  add constraint "google_sheet_integrations_created_by_fkey" foreign key (created_by) references public.profiles(id) on delete set null;

alter table "public"."impact_statistics"
  add constraint "impact_statistics_created_by_fkey" foreign key (created_by) references public.profiles(id) on delete set null;

alter table "public"."impact_statistics"
  add constraint "impact_statistics_updated_by_fkey" foreign key (updated_by) references public.profiles(id) on delete set null;

alter table "public"."media"
  add constraint "media_uploaded_by_fkey" foreign key (uploaded_by) references public.profiles(id) on delete set null;

alter table "public"."refunds"
  add constraint "refunds_initiated_by_fkey" foreign key (initiated_by) references public.profiles(id) on delete set null;

alter table "public"."refunds"
  add constraint "refunds_payment_id_fkey" foreign key (payment_id) references public.payments(id) on delete restrict;

alter table "public"."registration_acknowledgements"
  add constraint "registration_acknowledgements_acknowledgement_id_fkey" foreign key (acknowledgement_id) references public.form_acknowledgements(id) on delete restrict;

alter table "public"."registration_answers"
  add constraint "registration_answers_question_id_fkey" foreign key (question_id) references public.form_questions(id) on delete restrict;

alter table "public"."registration_form_versions"
  add constraint "registration_form_versions_created_by_fkey" foreign key (created_by) references public.profiles(id) on delete set null;

alter table "public"."form_acknowledgements"
  add constraint "form_acknowledgements_form_version_id_fkey" foreign key (form_version_id) references public.registration_form_versions(id) on delete cascade;

alter table "public"."form_steps"
  add constraint "form_steps_form_version_id_fkey" foreign key (form_version_id) references public.registration_form_versions(id) on delete cascade;

alter table "public"."registration_forms"
  add constraint "registration_forms_camp_id_fkey" foreign key (camp_id) references public.camps(id) on delete cascade;

alter table "public"."registration_forms"
  add constraint "registration_forms_created_by_fkey" foreign key (created_by) references public.profiles(id) on delete set null;

alter table "public"."registration_form_versions"
  add constraint "registration_form_versions_form_id_fkey" foreign key (form_id) references public.registration_forms(id) on delete cascade;

alter table "public"."registration_seat_reservations"
  add constraint "registration_seat_reservations_camp_id_fkey" foreign key (camp_id) references public.camps(id) on delete cascade;

alter table "public"."registrations"
  add constraint "registrations_camp_id_fkey" foreign key (camp_id) references public.camps(id) on delete restrict;

alter table "public"."registrations"
  add constraint "registrations_form_version_id_fkey" foreign key (form_version_id) references public.registration_form_versions(id) on delete restrict;

alter table "public"."checkins"
  add constraint "checkins_registration_id_fkey" foreign key (registration_id) references public.registrations(id) on delete restrict;

alter table "public"."coupon_usages"
  add constraint "coupon_usages_registration_id_fkey" foreign key (registration_id) references public.registrations(id) on delete restrict;

alter table "public"."payments"
  add constraint "payments_registration_id_fkey" foreign key (registration_id) references public.registrations(id) on delete restrict;

alter table "public"."refunds"
  add constraint "refunds_registration_id_fkey" foreign key (registration_id) references public.registrations(id) on delete restrict;

alter table "public"."registration_acknowledgements"
  add constraint "registration_acknowledgements_registration_id_fkey" foreign key (registration_id) references public.registrations(id) on delete cascade;

alter table "public"."registration_answers"
  add constraint "registration_answers_registration_id_fkey" foreign key (registration_id) references public.registrations(id) on delete cascade;

alter table "public"."registration_seat_reservations"
  add constraint "registration_seat_reservations_registration_id_fkey" foreign key (registration_id) references public.registrations(id) on delete cascade;

alter table "public"."role_permissions"
  add constraint "role_permissions_permission_id_fkey" foreign key (permission_id) references public.permissions(id) on delete cascade;

alter table "public"."role_permissions"
  add constraint "role_permissions_role_id_fkey" foreign key (role_id) references public.roles(id) on delete cascade;

alter table "public"."system_settings"
  add constraint "system_settings_updated_by_fkey" foreign key (updated_by) references public.profiles(id) on delete set null;

alter table "public"."testimonials"
  add constraint "testimonials_created_by_fkey" foreign key (created_by) references public.profiles(id) on delete set null;

alter table "public"."testimonials"
  add constraint "testimonials_updated_by_fkey" foreign key (updated_by) references public.profiles(id) on delete set null;

alter table "public"."user_roles"
  add constraint "user_roles_role_id_fkey" foreign key (role_id) references public.roles(id) on delete restrict;

alter table "public"."user_roles"
  add constraint "user_roles_user_id_fkey" foreign key (user_id) references public.profiles(id) on delete cascade;

create view "public"."cgpf_payment_view" with (security_invoker=true) AS  SELECT p.id AS payment_id,
    r.registration_number,
    p.amount,
    p.currency,
    p.status,
    p.paid_at,
    p.created_at
   FROM (public.payments p
     JOIN public.registrations r ON ((r.id = p.registration_id)))
  WHERE public.has_role('cgpf'::text);

create view "public"."cgpf_registration_view" with (security_invoker=true) AS  SELECT r.id AS registration_id,
    r.registration_number,
    r.camp_id,
    c.name AS camp_name,
    r.participant_name,
    r.status AS registration_status,
    r.final_amount,
    r.currency,
        CASE
            WHEN (EXISTS ( SELECT 1
               FROM public.payments p
              WHERE ((p.registration_id = r.id) AND (p.status = 'paid'::public.payment_status)))) THEN 'paid'::text
            WHEN (EXISTS ( SELECT 1
               FROM public.payments p
              WHERE ((p.registration_id = r.id) AND (p.status = 'pending'::public.payment_status)))) THEN 'pending'::text
            WHEN (EXISTS ( SELECT 1
               FROM public.payments p
              WHERE ((p.registration_id = r.id) AND (p.status = 'failed'::public.payment_status)))) THEN 'failed'::text
            ELSE 'not_paid'::text
        END AS payment_status,
        CASE
            WHEN (EXISTS ( SELECT 1
               FROM public.checkins ci
              WHERE ((ci.registration_id = r.id) AND (ci.reversed_at IS NULL)))) THEN true
            ELSE false
        END AS checked_in,
    ( SELECT
                CASE
                    WHEN (jsonb_typeof(ra.answer_value) = 'string'::text) THEN (ra.answer_value #>> '{}'::text[])
                    ELSE (ra.answer_value)::text
                END AS answer_value
           FROM public.registration_answers ra
          WHERE ((ra.registration_id = r.id) AND (lower(ra.field_key) = ANY (ARRAY['tshirt_size'::text, 't_shirt_size'::text, 'tshirt'::text, 't-shirt-size'::text])))
         LIMIT 1) AS tshirt_size,
    r.created_at
   FROM (public.registrations r
     JOIN public.camps c ON ((c.id = r.camp_id)))
  WHERE public.has_role('cgpf'::text);

create view "public"."coordinator_registration_view" with (security_invoker=true) AS  SELECT id AS registration_id,
    registration_number,
    camp_id,
    participant_name,
    participant_email,
    participant_phone,
    participant_dob,
    status,
    base_amount,
    tshirt_amount,
    discount_amount,
    final_amount,
    currency,
    created_at,
    updated_at
   FROM public.registrations r;

create index idx_announcements_active on public.announcements using btree (is_active, starts_at);

create index idx_audit_logs_action on public.audit_logs using btree (action);

create index idx_audit_logs_actor on public.audit_logs using btree (actor_user_id);

create index idx_audit_logs_created on public.audit_logs using btree (created_at desc);

create index idx_audit_logs_entity on public.audit_logs using btree (entity_type, entity_id);

create index idx_camp_assignments_active on public.camp_assignments using btree (user_id, camp_id, is_active);

create index idx_camp_assignments_camp on public.camp_assignments using btree (camp_id);

create index idx_camp_assignments_user_active on public.camp_assignments using btree (user_id, is_active, expires_at, camp_id);

create index idx_camp_assignments_user on public.camp_assignments using btree (user_id);

create index idx_camp_speakers_camp on public.camp_speakers using btree (camp_id, display_order);

create index idx_camps_content_status on public.camps using btree (content_status);

create index idx_camps_published_start on public.camps using btree (content_status, start_at);

create index idx_camps_registration_status on public.camps using btree (operational_registration_status);

create index idx_camps_start_at on public.camps using btree (start_at);

create index idx_checkins_camp on public.checkins using btree (camp_id);

create index idx_checkins_registration_active on public.checkins using btree (registration_id, reversed_at);

create index idx_checkins_registration on public.checkins using btree (registration_id);

create index idx_contact_submissions_created on public.contact_submissions using btree (created_at desc);

create index idx_coupon_camps_camp on public.coupon_camps using btree (camp_id);

create index idx_coupon_usages_coupon on public.coupon_usages using btree (coupon_id);

create index idx_coupon_usages_registration on public.coupon_usages using btree (registration_id);

create index idx_coupons_active on public.coupons using btree (is_active);

create index idx_coupons_code on public.coupons using btree (code);

create index idx_coupons_visibility on public.coupons using btree (visibility);

create index idx_form_acknowledgements_version on public.form_acknowledgements using btree (form_version_id, display_order);

create unique index idx_form_conditions_one_per_question on public.form_conditions using btree (question_id);

create index idx_form_options_question on public.form_options using btree (question_id, display_order);

create index idx_form_questions_step on public.form_questions using btree (step_id, display_order);

create index idx_form_steps_version on public.form_steps using btree (form_version_id, display_order);

create index idx_form_versions_form on public.registration_form_versions using btree (form_id);

create index idx_form_versions_status on public.registration_form_versions using btree (status);

create index idx_google_sheet_status on public.google_sheet_integrations using btree (status);

create index idx_impact_statistics_active on public.impact_statistics using btree (is_active, display_order);

create unique index idx_one_published_form_version on public.registration_form_versions using btree (form_id)
  where (status = 'published'::public.form_version_status);

create index idx_payment_events_payment on public.payment_events using btree (payment_id);

create index idx_payment_events_processing on public.payment_events using btree (processing_status, received_at);

create index idx_payment_events_received on public.payment_events using btree (received_at desc);

create index idx_payment_events_type on public.payment_events using btree (event_type);

create index idx_payments_cashfree_payment on public.payments using btree (cashfree_payment_id);

create index idx_payments_registration_status on public.payments using btree (registration_id, status);

create index idx_payments_registration on public.payments using btree (registration_id);

create index idx_payments_status on public.payments using btree (status);

create index idx_profiles_email on public.profiles using btree (email);

create index idx_profiles_is_active on public.profiles using btree (is_active);

create index idx_refunds_payment on public.refunds using btree (payment_id);

create index idx_refunds_registration on public.refunds using btree (registration_id);

create index idx_refunds_status on public.refunds using btree (status);

create index idx_registration_answers_registration on public.registration_answers using btree (registration_id);

create index idx_registrations_camp_status on public.registrations using btree (camp_id, status);

create index idx_registrations_camp on public.registrations using btree (camp_id);

create index idx_registrations_created on public.registrations using btree (created_at desc);

create index idx_registrations_email on public.registrations using btree (participant_email);

create index idx_registrations_phone on public.registrations using btree (participant_phone);

create index idx_registrations_status on public.registrations using btree (status);

create index idx_schedule_camp on public.camp_schedule_items using btree (camp_id, starts_at);

create index idx_seat_reservations_camp on public.registration_seat_reservations using btree (camp_id);

create index idx_seat_reservations_expiry on public.registration_seat_reservations using btree (expires_at);

create index idx_testimonials_active on public.testimonials using btree (is_active, display_order);

create unique index idx_user_roles_one_role_per_user on public.user_roles using btree (user_id);

create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute function public.handle_new_user();

create trigger set_announcements_updated_at
  before update on public.announcements
  for each row
  execute function public.set_updated_at();

create trigger prevent_audit_log_delete
  before delete on public.audit_logs
  for each row
  execute function public.prevent_audit_log_mutation();

create trigger prevent_audit_log_update
  before update on public.audit_logs
  for each row
  execute function public.prevent_audit_log_mutation();

create trigger set_camp_schedule_updated_at
  before update on public.camp_schedule_items
  for each row
  execute function public.set_updated_at();

create trigger set_camp_speakers_updated_at
  before update on public.camp_speakers
  for each row
  execute function public.set_updated_at();

create trigger prevent_transactional_camp_delete
  before delete on public.camps
  for each row
  execute function public.prevent_transactional_camp_delete();

create trigger set_camps_updated_at
  before update on public.camps
  for each row
  execute function public.set_updated_at();

create trigger validate_checkin_registration
  before insert or update on public.checkins
  for each row
  execute function public.validate_checkin_registration();

create trigger set_coupons_updated_at
  before update on public.coupons
  for each row
  execute function public.set_updated_at();

create trigger prevent_locked_form_acknowledgements
  before insert or delete or update on public.form_acknowledgements
  for each row
  execute function public.prevent_locked_form_child_mutation();

create trigger prevent_locked_form_conditions
  before insert or delete or update on public.form_conditions
  for each row
  execute function public.prevent_locked_form_child_mutation();

create trigger prevent_locked_form_options
  before insert or delete or update on public.form_options
  for each row
  execute function public.prevent_locked_form_child_mutation();

create trigger prevent_locked_form_questions
  before insert or delete or update on public.form_questions
  for each row
  execute function public.prevent_locked_form_child_mutation();

create trigger prevent_locked_form_steps
  before insert or delete or update on public.form_steps
  for each row
  execute function public.prevent_locked_form_child_mutation();

create trigger set_google_sheet_integrations_updated_at
  before update on public.google_sheet_integrations
  for each row
  execute function public.set_updated_at();

create trigger set_impact_statistics_updated_at
  before update on public.impact_statistics
  for each row
  execute function public.set_updated_at();

create trigger set_payments_updated_at
  before update on public.payments
  for each row
  execute function public.set_updated_at();

create trigger set_profiles_updated_at
  before update on public.profiles
  for each row
  execute function public.set_updated_at();

create trigger set_refunds_updated_at
  before update on public.refunds
  for each row
  execute function public.set_updated_at();

create trigger validate_refund_amount
  before insert or update on public.refunds
  for each row
  execute function public.validate_refund_amount();

create trigger set_registration_answers_updated_at
  before update on public.registration_answers
  for each row
  execute function public.set_updated_at();

create trigger validate_registration_answer_question
  before insert or update on public.registration_answers
  for each row
  execute function public.validate_registration_answer_question();

create trigger prevent_locked_form_version_delete
  before delete on public.registration_form_versions
  for each row
  execute function public.prevent_locked_form_version_delete();

create trigger prevent_locked_form_version_update
  before update on public.registration_form_versions
  for each row
  execute function public.prevent_locked_form_version_update();

create trigger validate_form_version_transition
  before update on public.registration_form_versions
  for each row
  execute function public.validate_form_version_transition();

create trigger set_registration_forms_updated_at
  before update on public.registration_forms
  for each row
  execute function public.set_updated_at();

create trigger set_registration_number_before_insert
  before insert on public.registrations
  for each row
  execute function public.set_registration_number();

create trigger set_registrations_updated_at
  before update on public.registrations
  for each row
  execute function public.set_updated_at();

create trigger set_testimonials_updated_at
  before update on public.testimonials
  for each row
  execute function public.set_updated_at();

create policy "admin_announcements" on "public"."announcements"
  for all
  to "authenticated"
  using (public.is_admin())
  with check (public.is_admin());

create policy "public_read_active_announcements" on "public"."announcements"
  for select
  to "anon", "authenticated"
  using (((is_active = true) AND (starts_at <= now()) AND ((ends_at is null) or (ends_at >= now()))));

create policy "staff_create_announcements" on "public"."announcements"
  for insert
  to "authenticated"
  with check (public.has_role('staff'::text));

create policy "staff_read_announcements" on "public"."announcements"
  for select
  to "authenticated"
  using (public.has_role('staff'::text));

create policy "admin_audit_logs" on "public"."audit_logs"
  for select
  to "authenticated"
  using ((public.has_role('admin'::text) AND public.has_permission('audit.read'::text)));

create policy "admin_camp_assignments" on "public"."camp_assignments"
  for all
  to "authenticated"
  using (public.is_admin())
  with check (public.is_admin());

create policy "admin_camp_schedule" on "public"."camp_schedule_items"
  for all
  to "authenticated"
  using (public.is_admin())
  with check (public.is_admin());

create policy "coordinator_schedule" on "public"."camp_schedule_items"
  for all
  to "authenticated"
  using ((public.has_role('camp_coordinator'::text) AND public.has_camp_access(camp_id)))
  with check ((public.has_role('camp_coordinator'::text) AND public.has_camp_access(camp_id)));

create policy "public_read_camp_schedule" on "public"."camp_schedule_items"
  for select
  to "anon", "authenticated"
  using ((exists ( select 1
   from public.camps c
  where ((c.id = camp_schedule_items.camp_id) AND (c.content_status = 'published'::public.camp_content_status)))));

create policy "admin_camp_speakers" on "public"."camp_speakers"
  for all
  to "authenticated"
  using (public.is_admin())
  with check (public.is_admin());

create policy "coordinator_camp_speakers" on "public"."camp_speakers"
  for all
  to "authenticated"
  using ((public.has_role('camp_coordinator'::text) AND public.has_camp_access(camp_id)))
  with check ((public.has_role('camp_coordinator'::text) AND public.has_camp_access(camp_id)));

create policy "public_read_camp_speakers" on "public"."camp_speakers"
  for select
  to "anon", "authenticated"
  using ((exists ( select 1
   from public.camps c
  where ((c.id = camp_speakers.camp_id) AND (c.content_status = 'published'::public.camp_content_status)))));

create policy "admin_camps" on "public"."camps"
  for all
  to "authenticated"
  using (public.is_admin())
  with check (public.is_admin());

create policy "coordinator_read_assigned_camps" on "public"."camps"
  for select
  to "authenticated"
  using ((public.has_role('camp_coordinator'::text) AND public.has_permission('camp.read'::text) AND public.has_camp_access(id)));

create policy "coordinator_update_assigned_camps" on "public"."camps"
  for update
  to "authenticated"
  using ((public.has_role('camp_coordinator'::text) AND public.has_permission('camp.update'::text) AND public.has_camp_access(id)))
  with check ((public.has_role('camp_coordinator'::text) AND public.has_permission('camp.update'::text) AND public.has_camp_access(id)));

create policy "public_read_published_camps" on "public"."camps"
  for select
  to "anon", "authenticated"
  using ((content_status = 'published'::public.camp_content_status));

create policy "staff_create_camps" on "public"."camps"
  for insert
  to "authenticated"
  with check (public.has_role('staff'::text));

create policy "staff_read_camps" on "public"."camps"
  for select
  to "authenticated"
  using
    ((public.has_role('staff'::text) AND public.has_permission('camp.read'::text) AND ((content_status = 'published'::public.camp_content_status) or (created_by = auth.uid()))));

create policy "admin_checkins" on "public"."checkins"
  for all
  to "authenticated"
  using (public.is_admin())
  with check (public.is_admin());

create policy "coordinator_checkins" on "public"."checkins"
  for all
  to "authenticated"
  using ((public.has_role('camp_coordinator'::text) AND public.has_camp_access(camp_id)))
  with check ((public.has_role('camp_coordinator'::text) AND public.has_camp_access(camp_id)));

create policy "admin_contact_submissions" on "public"."contact_submissions"
  for all
  to "authenticated"
  using (public.is_admin())
  with check (public.is_admin());

create policy "public_create_contact_submission" on "public"."contact_submissions"
  for insert
  to "anon", "authenticated"
  with
    check
    ((((length(btrim(name)) >= 1) AND (length(btrim(name)) <= 200)) AND ((length(btrim(email)) >= 3) AND (length(btrim(email)) <= 320)) AND ((length(btrim(message)) >= 1) AND
    (length(btrim(message)) <= 5000))));

create policy "admin_coupon_camps" on "public"."coupon_camps"
  for all
  to "authenticated"
  using (public.is_admin())
  with check (public.is_admin());

create policy "admin_coupon_usages" on "public"."coupon_usages"
  for all
  to "authenticated"
  using (public.is_admin())
  with check (public.is_admin());

create policy "admin_coupons" on "public"."coupons"
  for all
  to "authenticated"
  using (public.is_admin())
  with check (public.is_admin());

create policy "admin_form_acknowledgements" on "public"."form_acknowledgements"
  for all
  to "authenticated"
  using (public.is_admin())
  with check (public.is_admin());

create policy "public_read_published_form_acknowledgements" on "public"."form_acknowledgements"
  for select
  to "anon", "authenticated"
  using ((exists ( select 1
   from public.registration_form_versions fv
  where ((fv.id = form_acknowledgements.form_version_id) AND (fv.status = 'published'::public.form_version_status)))));

create policy "admin_form_conditions" on "public"."form_conditions"
  for all
  to "authenticated"
  using (public.is_admin())
  with check (public.is_admin());

create policy "public_read_published_form_conditions" on "public"."form_conditions"
  for select
  to "anon", "authenticated"
  using ((exists ( select 1
   from ((public.form_questions fq
     JOIN public.form_steps fs on ((fs.id = fq.step_id)))
     JOIN public.registration_form_versions fv on ((fv.id = fs.form_version_id)))
  where ((fq.id = form_conditions.question_id) AND (fv.status = 'published'::public.form_version_status)))));

create policy "admin_form_options" on "public"."form_options"
  for all
  to "authenticated"
  using (public.is_admin())
  with check (public.is_admin());

create policy "public_read_published_form_options" on "public"."form_options"
  for select
  to "anon", "authenticated"
  using ((exists ( select 1
   from ((public.form_questions fq
     JOIN public.form_steps fs on ((fs.id = fq.step_id)))
     JOIN public.registration_form_versions fv on ((fv.id = fs.form_version_id)))
  where ((fq.id = form_options.question_id) AND (fv.status = 'published'::public.form_version_status)))));

create policy "admin_form_questions" on "public"."form_questions"
  for all
  to "authenticated"
  using (public.is_admin())
  with check (public.is_admin());

create policy "public_read_published_form_questions" on "public"."form_questions"
  for select
  to "anon", "authenticated"
  using ((exists ( select 1
   from (public.form_steps fs
     JOIN public.registration_form_versions fv on ((fv.id = fs.form_version_id)))
  where ((fs.id = form_questions.step_id) AND (fv.status = 'published'::public.form_version_status)))));

create policy "admin_form_steps" on "public"."form_steps"
  for all
  to "authenticated"
  using (public.is_admin())
  with check (public.is_admin());

create policy "public_read_published_form_steps" on "public"."form_steps"
  for select
  to "anon", "authenticated"
  using ((exists ( select 1
   from public.registration_form_versions fv
  where ((fv.id = form_steps.form_version_id) AND (fv.status = 'published'::public.form_version_status)))));

create policy "admin_google_sheet_integrations" on "public"."google_sheet_integrations"
  for all
  to "authenticated"
  using (public.is_admin())
  with check (public.is_admin());

create policy "admin_impact_statistics" on "public"."impact_statistics"
  for all
  to "authenticated"
  using (public.is_admin())
  with check (public.is_admin());

create policy "public_read_impact_statistics" on "public"."impact_statistics"
  for select
  to "anon", "authenticated"
  using ((is_active = true));

create policy "admin_media" on "public"."media"
  for all
  to "authenticated"
  using (public.is_admin())
  with check (public.is_admin());

create policy "authenticated_read_public_media" on "public"."media"
  for select
  to "authenticated"
  using ((visibility = 'public'::public.media_visibility));

create policy "public_read_public_media" on "public"."media"
  for select
  to "anon", "authenticated"
  using ((visibility = 'public'::public.media_visibility));

create policy "staff_create_media" on "public"."media"
  for insert
  to "authenticated"
  with check (public.has_role('staff'::text));

create policy "staff_read_media" on "public"."media"
  for select
  to "authenticated"
  using (public.has_role('staff'::text));

create policy "admin_payment_events" on "public"."payment_events"
  for all
  to "authenticated"
  using (public.is_admin())
  with check (public.is_admin());

create policy "cgpf_raw_payment_events_block" on "public"."payment_events"
  for all
  to "authenticated"
  using ((not public.has_role('cgpf'::text)))
  with check ((NOT public.has_role('cgpf'::text)));

create policy "admin_payments" on "public"."payments"
  for all
  to "authenticated"
  using (public.is_admin())
  with check (public.is_admin());

create policy "cgpf_raw_payments_block" on "public"."payments"
  for all
  to "authenticated"
  using ((not public.has_role('cgpf'::text)))
  with check ((NOT public.has_role('cgpf'::text)));

create policy "coordinator_payment_read" on "public"."payments"
  for select
  to "authenticated"
  using ((exists ( select 1
   from public.registrations r
  where ((r.id = payments.registration_id) AND public.has_camp_access(r.camp_id)))));

create policy "admin_permissions" on "public"."permissions"
  for all
  to "authenticated"
  using (public.is_admin())
  with check (public.is_admin());

create policy "admin_profiles" on "public"."profiles"
  for all
  to "authenticated"
  using (public.is_admin())
  with check (public.is_admin());

create policy "admin_refunds" on "public"."refunds"
  for all
  to "authenticated"
  using (public.is_admin())
  with check (public.is_admin());

create policy "cgpf_raw_refunds_block" on "public"."refunds"
  for all
  to "authenticated"
  using ((not public.has_role('cgpf'::text)))
  with check ((NOT public.has_role('cgpf'::text)));

create policy "coordinator_refund_create" on "public"."refunds"
  for insert
  to "authenticated"
  with check ((public.has_role('camp_coordinator'::text) AND (EXISTS ( SELECT 1
   FROM public.registrations r
  WHERE ((r.id = refunds.registration_id) AND public.has_camp_access(r.camp_id))))));

create policy "coordinator_refund_read" on "public"."refunds"
  for select
  to "authenticated"
  using ((exists ( select 1
   from public.registrations r
  where ((r.id = refunds.registration_id) AND public.has_camp_access(r.camp_id)))));

create policy "admin_registration_acknowledgements" on "public"."registration_acknowledgements"
  for all
  to "authenticated"
  using (public.is_admin())
  with check (public.is_admin());

create policy "cgpf_raw_acknowledgements_block" on "public"."registration_acknowledgements"
  for all
  to "authenticated"
  using ((not public.has_role('cgpf'::text)))
  with check ((NOT public.has_role('cgpf'::text)));

create policy "admin_registration_answers" on "public"."registration_answers"
  for all
  to "authenticated"
  using (public.is_admin())
  with check (public.is_admin());

create policy "cgpf_raw_answers_block" on "public"."registration_answers"
  for all
  to "authenticated"
  using ((not public.has_role('cgpf'::text)))
  with check ((NOT public.has_role('cgpf'::text)));

create policy "coordinator_answers" on "public"."registration_answers"
  for select
  to "authenticated"
  using ((exists ( select 1
   from public.registrations r
  where ((r.id = registration_answers.registration_id) AND public.has_camp_access(r.camp_id)))));

create policy "admin_form_versions" on "public"."registration_form_versions"
  for all
  to "authenticated"
  using (public.is_admin())
  with check (public.is_admin());

create policy "public_read_published_form_versions" on "public"."registration_form_versions"
  for select
  to "anon", "authenticated"
  using (((status = 'published'::public.form_version_status) AND (exists ( select 1
   from (public.registration_forms rf
     JOIN public.camps c on ((c.id = rf.camp_id)))
  where ((rf.id = registration_form_versions.form_id) AND (c.content_status = 'published'::public.camp_content_status))))));

create policy "admin_forms" on "public"."registration_forms"
  for all
  to "authenticated"
  using (public.is_admin())
  with check (public.is_admin());

create policy "public_read_registration_forms" on "public"."registration_forms"
  for select
  to "anon", "authenticated"
  using ((exists ( select 1
   from public.camps c
  where ((c.id = registration_forms.camp_id) AND (c.content_status = 'published'::public.camp_content_status)))));

create policy "admin_seat_reservations" on "public"."registration_seat_reservations"
  for all
  to "authenticated"
  using (public.is_admin())
  with check (public.is_admin());

create policy "admin_registrations" on "public"."registrations"
  for all
  to "authenticated"
  using (public.is_admin())
  with check (public.is_admin());

create policy "cgpf_raw_registration_block" on "public"."registrations"
  for all
  to "authenticated"
  using ((not public.has_role('cgpf'::text)))
  with check ((NOT public.has_role('cgpf'::text)));

create policy "coordinator_registration_update" on "public"."registrations"
  for update
  to "authenticated"
  using ((public.has_role('camp_coordinator'::text) AND public.has_camp_access(camp_id)))
  with check ((public.has_role('camp_coordinator'::text) AND public.has_camp_access(camp_id)));

create policy "coordinator_registrations" on "public"."registrations"
  for select
  to "authenticated"
  using ((public.has_role('camp_coordinator'::text) AND public.has_camp_access(camp_id)));

create policy "admin_role_permissions" on "public"."role_permissions"
  for all
  to "authenticated"
  using (public.is_admin())
  with check (public.is_admin());

create policy "admin_roles" on "public"."roles"
  for all
  to "authenticated"
  using (public.is_admin())
  with check (public.is_admin());

create policy "admin_system_settings" on "public"."system_settings"
  for all
  to "authenticated"
  using ((public.has_role('admin'::text) AND public.has_permission('settings.read'::text)))
  with check ((public.has_role('admin'::text) AND public.has_permission('settings.update'::text)));

create policy "admin_testimonials" on "public"."testimonials"
  for all
  to "authenticated"
  using (public.is_admin())
  with check (public.is_admin());

create policy "public_read_active_testimonials" on "public"."testimonials"
  for select
  to "anon", "authenticated"
  using ((is_active = true));

create policy "staff_create_testimonials" on "public"."testimonials"
  for insert
  to "authenticated"
  with check (public.has_role('staff'::text));

create policy "staff_read_testimonials" on "public"."testimonials"
  for select
  to "authenticated"
  using (public.has_role('staff'::text));

create policy "admin_user_roles" on "public"."user_roles"
  for all
  to "authenticated"
  using (public.is_admin())
  with check (public.is_admin());

comment on table "public"."audit_logs" is 'Append-only administrative audit history. UPDATE and DELETE are prohibited.';

comment on table "public"."registration_counters" is 'Concurrency-safe yearly registration number counter. Backend-only.';

comment on table "public"."registration_seat_reservations" is 'Temporary transactional seat reservations used to protect camp capacity during payment.';

revoke all on function "public"."consume_registration_seat"(uuid) from public;

grant execute on function "public"."consume_registration_seat"(uuid) to "authenticated", "postgres", "service_role";

revoke all on function "public"."current_user_role"() from public;

grant execute on function "public"."current_user_role"() to "authenticated", "postgres", "service_role";

revoke all on function "public"."generate_registration_number"() from public;

grant execute on function "public"."generate_registration_number"() to "postgres", "service_role";

grant execute on function "public"."handle_new_user"() to public, "anon", "authenticated", "postgres", "service_role";

revoke all on function "public"."has_camp_access"(uuid) from public;

grant execute on function "public"."has_camp_access"(uuid) to "authenticated", "postgres", "service_role";

revoke all on function "public"."has_permission"(text) from public;

grant execute on function "public"."has_permission"(text) to "authenticated", "postgres", "service_role";

revoke all on function "public"."has_role"(text) from public;

grant execute on function "public"."has_role"(text) to "authenticated", "postgres", "service_role";

revoke all on function "public"."is_admin"() from public;

grant execute on function "public"."is_admin"() to "authenticated", "postgres", "service_role";

revoke all on function "public"."mark_registration_paid"(uuid, uuid) from public;

grant execute on function "public"."mark_registration_paid"(uuid, uuid) to "authenticated", "postgres", "service_role";

revoke all on function "public"."prevent_audit_log_mutation"() from public;

grant execute on function "public"."prevent_audit_log_mutation"() to "postgres", "service_role";

revoke all on function "public"."prevent_locked_form_child_mutation"() from public;

grant execute on function "public"."prevent_locked_form_child_mutation"() to "postgres", "service_role";

revoke all on function "public"."prevent_locked_form_version_delete"() from public;

grant execute on function "public"."prevent_locked_form_version_delete"() to "postgres", "service_role";

revoke all on function "public"."prevent_locked_form_version_update"() from public;

grant execute on function "public"."prevent_locked_form_version_update"() to "postgres", "service_role";

revoke all on function "public"."prevent_transactional_camp_delete"() from public;

grant execute on function "public"."prevent_transactional_camp_delete"() to "postgres", "service_role";

revoke all on function "public"."release_registration_seat"(uuid) from public;

grant execute on function "public"."release_registration_seat"(uuid) to "authenticated", "postgres", "service_role";

revoke all on function "public"."reserve_registration_seat"(uuid, uuid, timestamp with time zone) from public;

grant execute on function "public"."reserve_registration_seat"(uuid, uuid, timestamp with time zone) to "authenticated", "postgres", "service_role";

grant execute on function "public"."set_registration_number"() to public, "anon", "authenticated", "postgres", "service_role";

grant execute on function "public"."set_updated_at"() to public, "anon", "authenticated", "postgres", "service_role";

revoke all on function "public"."user_assigned_camp_ids"() from public;

grant execute on function "public"."user_assigned_camp_ids"() to "authenticated", "postgres", "service_role";

revoke all on function "public"."validate_checkin_registration"() from public;

grant execute on function "public"."validate_checkin_registration"() to "postgres", "service_role";

revoke all on function "public"."validate_form_version_transition"() from public;

grant execute on function "public"."validate_form_version_transition"() to "postgres", "service_role";

revoke all on function "public"."validate_refund_amount"() from public;

grant execute on function "public"."validate_refund_amount"() to "postgres", "service_role";

revoke all on function "public"."validate_registration_answer_question"() from public;

grant execute on function "public"."validate_registration_answer_question"() to "postgres", "service_role";

revoke all on function "public"."write_audit_log"(text, text, uuid, text, jsonb, jsonb, inet, text) from public;

grant execute on function "public"."write_audit_log"(text, text, uuid, text, jsonb, jsonb, inet, text) to "authenticated", "postgres", "service_role";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."announcements" to "anon", "authenticated", "postgres", "service_role";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."audit_logs" to "anon", "authenticated", "postgres", "service_role";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."camp_assignments" to "anon", "authenticated", "postgres", "service_role";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."camp_schedule_items" to "anon", "authenticated", "postgres", "service_role";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."camp_speakers" to "anon", "authenticated", "postgres", "service_role";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."camps" to "anon", "authenticated", "postgres", "service_role";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."checkins" to "anon", "authenticated", "postgres", "service_role";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."contact_submissions" to "anon", "authenticated", "postgres", "service_role";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."coupon_camps" to "anon", "authenticated", "postgres", "service_role";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."coupon_usages" to "anon", "authenticated", "postgres", "service_role";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."coupons" to "anon", "authenticated", "postgres", "service_role";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."form_acknowledgements" to "anon", "authenticated", "postgres", "service_role";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."form_conditions" to "anon", "authenticated", "postgres", "service_role";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."form_options" to "anon", "authenticated", "postgres", "service_role";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."form_questions" to "anon", "authenticated", "postgres", "service_role";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."form_steps" to "anon", "authenticated", "postgres", "service_role";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."google_sheet_integrations" to "anon", "authenticated", "postgres", "service_role";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."impact_statistics" to "anon", "authenticated", "postgres", "service_role";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."media" to "anon", "authenticated", "postgres", "service_role";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."payment_events" to "anon";

revoke all on table "public"."payment_events" from "authenticated";

grant delete, insert, select, update on table "public"."payment_events" to "authenticated";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."payment_events" to "postgres", "service_role";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."payments" to "anon";

revoke all on table "public"."payments" from "authenticated";

grant delete, insert, select, update on table "public"."payments" to "authenticated";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."payments" to "postgres", "service_role";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."permissions" to "anon", "authenticated", "postgres", "service_role";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."profiles" to "anon", "authenticated", "postgres", "service_role";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."refunds" to "anon";

revoke all on table "public"."refunds" from "authenticated";

grant delete, insert, select, update on table "public"."refunds" to "authenticated";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."refunds" to "postgres", "service_role";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."registration_acknowledgements" to "anon";

revoke all on table "public"."registration_acknowledgements" from "authenticated";

grant delete, insert, select, update on table "public"."registration_acknowledgements" to "authenticated";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."registration_acknowledgements" to "postgres", "service_role";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."registration_answers" to "anon";

revoke all on table "public"."registration_answers" from "authenticated";

grant delete, insert, select, update on table "public"."registration_answers" to "authenticated";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."registration_answers" to "postgres", "service_role";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."registration_counters" to "postgres", "service_role";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."registration_form_versions" to "anon", "authenticated", "postgres", "service_role";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."registration_forms" to "anon", "authenticated", "postgres", "service_role";

grant delete, insert, maintain, references, select, trigger, truncate, update
  on table "public"."registration_seat_reservations"
  to "anon", "authenticated", "postgres", "service_role";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."registrations" to "anon";

revoke all on table "public"."registrations" from "authenticated";

grant delete, insert, select, update on table "public"."registrations" to "authenticated";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."registrations" to "postgres", "service_role";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."role_permissions" to "anon", "authenticated", "postgres", "service_role";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."roles" to "anon", "authenticated", "postgres", "service_role";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."system_settings" to "anon", "authenticated", "postgres", "service_role";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."testimonials" to "anon", "authenticated", "postgres", "service_role";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."user_roles" to "anon", "authenticated", "postgres", "service_role";

grant usage on type "public"."camp_content_status" to "postgres";

grant usage on type "public"."camp_registration_status" to "postgres";

grant usage on type "public"."condition_operator" to "postgres";

grant usage on type "public"."coupon_discount_type" to "postgres";

grant usage on type "public"."coupon_visibility" to "postgres";

grant usage on type "public"."form_version_status" to "postgres";

grant usage on type "public"."google_sheet_status" to "postgres";

grant usage on type "public"."media_visibility" to "postgres";

grant usage on type "public"."payment_event_processing_status" to "postgres";

grant usage on type "public"."payment_status" to "postgres";

grant usage on type "public"."question_type" to "postgres";

grant usage on type "public"."refund_status" to "postgres";

grant usage on type "public"."registration_status" to "postgres";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."cgpf_payment_view" to "anon", "authenticated", "postgres", "service_role";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."cgpf_registration_view" to "anon", "authenticated", "postgres", "service_role";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."coordinator_registration_view" to "authenticated", "postgres", "service_role";

alter default privileges for role "postgres" in schema "public" grant select, update, usage on sequences to "anon";

alter default privileges for role "postgres" in schema "public" grant select, update, usage on sequences to "authenticated";

alter default privileges for role "postgres" in schema "public" grant select, update, usage on sequences to "service_role";

alter default privileges for role "postgres" in schema "public" grant execute on FUNCTIONS to "service_role";

alter default privileges for role "postgres" in schema "public" grant delete, insert, maintain, references, select, trigger, truncate, update on tables to "anon";

alter default privileges for role "postgres" in schema "public" grant delete, insert, maintain, references, select, trigger, truncate, update on tables to "authenticated";

alter default privileges for role "postgres" in schema "public" grant delete, insert, maintain, references, select, trigger, truncate, update on tables to "service_role";

