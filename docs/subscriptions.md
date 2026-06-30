# Clinic Subscriptions

This MVP implements clinic subscription plans, configurable limits, usage tracking, and a safe manual upgrade flow.

Real payment processing is intentionally not implemented yet.

## Plans

Plans are stored in `subscription_plans`.

- `free`: 2 doctors, 10 services, 50 appointments per month, 50 visit records, 50 documents, 512 MB storage.
- `basic`: 5 doctors, 30 services, 300 appointments per month, 1000 visit records, 1000 documents, 5120 MB storage.
- `pro`: 20 doctors, 200 services, 2000 appointments per month, 20000 visit records, 20000 documents, 51200 MB storage, analytics/export placeholders.
- `enterprise`: unlimited or custom limits with manual activation placeholder.

Limits live in JSONB so they can be changed without frontend redeploys.

## Limit Keys

- `max_doctors`
- `max_services`
- `max_clinic_managers`
- `max_appointments_per_month`
- `max_visit_records`
- `max_documents`
- `max_storage_mb`
- `can_publish_clinic_profile`
- `can_use_reviews`
- `can_use_advanced_analytics`
- `can_export_data`
- `can_use_multi_location`
- `can_use_priority_support`

`-1` means unlimited for numeric limits.

## Usage Tracking

Current MVP calculates usage dynamically with `get_clinic_usage(clinic_id)`.

The helper counts:

- active/non-archived doctors;
- active/non-archived services;
- appointments in the current month;
- total visit records;
- visit documents;
- estimated storage in MB.

The `subscription_usage` table exists for future persisted monthly counters, but the UI currently uses dynamic counts.

## Enforcement

Database helpers:

- `get_clinic_active_subscription`
- `get_clinic_plan_limits`
- `get_clinic_usage`
- `can_clinic_add_doctor`
- `can_clinic_add_service`
- `can_clinic_create_appointment`
- `can_clinic_create_visit_record`
- `can_clinic_upload_document`
- `can_clinic_publish_profile`
- `can_clinic_use_reviews`

Admin server actions call plan checks before:

- adding a doctor;
- adding a service;
- confirming an appointment;
- creating a visit record;
- uploading a visit document;
- publishing clinic profile.

## Upgrade Flow

The clinic owner opens `/clinic/subscription/plans` and sends a request.

The request is stored in `subscription_upgrade_requests` with `pending` status.

A platform admin opens `/platform/subscription-requests` and manually approves or rejects the request.

On approval, the clinic subscription is updated to the requested plan with `manual` billing period and `manual` status.

## Pet Owner Visibility

The mobile app never shows clinic billing details.

If a clinic cannot accept online booking, the owner sees:

`Ця клініка тимчасово недоступна для онлайн-запису.`

The app does not mention unpaid subscription, tariff limits, provider status, invoices, or internal billing state.

## Future Payment Integration

Later integration can add Stripe, LiqPay, WayForPay, Fondy, Apple Billing, or Google Billing only after product validation.

Future provider work should:

- keep provider IDs private;
- handle webhooks server-side;
- update `clinic_subscriptions` from trusted backend code;
- avoid exposing service role keys;
- preserve existing clinic data during downgrade.
