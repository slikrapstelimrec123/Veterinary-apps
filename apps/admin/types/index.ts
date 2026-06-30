export type UserProfile = {
  id: string;
  email: string;
  full_name: string;
  phone?: string;
  avatar_url?: string;
  role: UserRole;
};

export type UserRole = "pet_owner" | "clinic_owner" | "veterinarian" | "clinic_manager" | "platform_admin";

export type ClinicMemberRole = "clinic_owner" | "veterinarian" | "clinic_manager";

export type ClinicMemberStatus = "active" | "invited" | "suspended" | "removed";

export type Clinic = {
  id: string;
  name: string;
  legal_name?: string | null;
  description?: string | null;
  phone?: string | null;
  email?: string | null;
  website?: string | null;
  city?: string | null;
  country?: string | null;
  address?: string | null;
  logo_url?: string | null;
  cover_image_url?: string | null;
  working_hours?: Record<string, unknown> | null;
  status: "draft" | "pending_verification" | "published" | "suspended";
  published: boolean;
  created_at?: string;
  updated_at?: string;
};

export type Doctor = {
  id: string;
  clinic_id: string;
  profile_id?: string | null;
  full_name: string;
  specialization?: string | null;
  bio?: string | null;
  experience_years?: number | null;
  avatar_url?: string | null;
  phone?: string | null;
  email?: string | null;
  status: "draft" | "active" | "inactive" | "archived";
  is_public: boolean;
  created_at?: string;
  updated_at?: string;
};

export type Service = {
  id: string;
  clinic_id: string;
  name: string;
  description?: string | null;
  category?: string | null;
  duration_minutes?: number | null;
  price_amount?: number | null;
  price_currency?: string;
  is_public: boolean;
  status: "active" | "inactive" | "archived";
  created_at?: string;
  updated_at?: string;
};

export type DoctorSchedule = {
  id: string;
  clinic_id: string;
  doctor_id: string;
  day_of_week: number;
  start_time: string;
  end_time: string;
  break_start_time?: string | null;
  break_end_time?: string | null;
  slot_duration_minutes: number;
  is_active: boolean;
  created_at?: string;
  updated_at?: string;
  doctors?: Pick<Doctor, "id" | "full_name" | "specialization" | "profile_id"> | null;
};

export type Pet = {
  id: string;
  name: string;
  species: string;
  breed?: string;
};

export type Appointment = {
  id: string;
  clinic_id: string;
  pet_id: string;
  owner_id: string;
  doctor_id?: string | null;
  service_id: string;
  appointment_date: string;
  start_time: string;
  end_time: string;
  status: "pending" | "confirmed" | "completed" | "cancelled_by_owner" | "cancelled_by_clinic" | "no_show";
  owner_note?: string | null;
  clinic_note?: string | null;
  cancellation_reason?: string | null;
  pets?: { id: string; name: string; species?: string | null; breed?: string | null } | null;
  profiles?: { id: string; full_name?: string | null; email?: string | null; phone?: string | null } | null;
  doctors?: Pick<Doctor, "id" | "full_name" | "specialization" | "profile_id"> | null;
  services?: Pick<Service, "id" | "name" | "duration_minutes"> | null;
};

export type VisitRecord = {
  id: string;
  clinic_id: string;
  appointment_id?: string | null;
  pet_id: string;
  owner_id?: string | null;
  doctor_id?: string | null;
  created_by: string;
  visit_date: string;
  reason?: string | null;
  reason_for_visit?: string | null;
  symptoms?: string | null;
  diagnosis?: string | null;
  procedures_performed?: string | null;
  treatment_notes?: string | null;
  prescribed_medications?: string | null;
  recommendations?: string | null;
  next_visit_recommended: boolean;
  next_visit_date?: string | null;
  internal_notes?: string | null;
  status: "draft" | "published" | "archived";
  created_at?: string;
  updated_at?: string;
  appointments?: Appointment | null;
  pets?: { id: string; name: string; species?: string | null; breed?: string | null } | null;
  profiles?: { id: string; full_name?: string | null; email?: string | null; phone?: string | null } | null;
  doctors?: Pick<Doctor, "id" | "full_name" | "specialization" | "profile_id"> | null;
  visit_documents?: VisitDocument[];
};

export type VisitDocument = {
  id: string;
  visit_record_id: string;
  clinic_id: string;
  pet_id: string;
  uploaded_by: string;
  file_name?: string | null;
  file_type?: string | null;
  file_size?: number | null;
  storage_bucket: string;
  storage_path: string;
  document_type: "lab_result" | "certificate" | "prescription" | "xray" | "ultrasound" | "photo" | "vaccination_record" | "other";
  title?: string | null;
  description?: string | null;
  is_visible_to_owner: boolean;
  created_at?: string;
  updated_at?: string;
};

export type ReviewStatus = "pending_moderation" | "published" | "hidden" | "reported" | "removed";

export type Review = {
  id: string;
  clinic_id: string;
  doctor_id?: string | null;
  appointment_id: string;
  visit_record_id?: string | null;
  pet_id: string;
  owner_id: string;
  rating: number;
  doctor_rating?: number | null;
  clinic_rating?: number | null;
  service_quality_rating?: number | null;
  comment?: string | null;
  status: ReviewStatus;
  is_anonymous: boolean;
  created_at: string;
  updated_at?: string;
  appointments?: Appointment | null;
  visit_records?: Pick<VisitRecord, "id" | "status" | "visit_date" | "diagnosis"> | null;
  pets?: { id: string; name: string; species?: string | null; breed?: string | null } | null;
  profiles?: { id: string; full_name?: string | null; email?: string | null; phone?: string | null } | null;
  doctors?: Pick<Doctor, "id" | "full_name" | "specialization" | "profile_id"> | null;
};

export type SubscriptionPlanLimits = {
  max_doctors?: number;
  max_services?: number;
  max_clinic_managers?: number;
  max_appointments_per_month?: number;
  max_visit_records?: number;
  max_documents?: number;
  max_storage_mb?: number;
  can_publish_clinic_profile?: boolean;
  can_use_reviews?: boolean;
  can_use_advanced_analytics?: boolean;
  can_export_data?: boolean;
  can_use_multi_location?: boolean;
  can_use_priority_support?: boolean;
};

export type SubscriptionPlan = {
  id: string;
  code: "free" | "basic" | "pro" | "enterprise" | string;
  name: string;
  description?: string | null;
  price_monthly?: number | null;
  price_yearly?: number | null;
  currency: string;
  is_active: boolean;
  is_public: boolean;
  sort_order: number;
  limits: SubscriptionPlanLimits;
  features: string[];
  created_at?: string;
  updated_at?: string;
};

export type ClinicSubscription = {
  id: string;
  clinic_id: string;
  plan_id: string;
  status: "trialing" | "active" | "past_due" | "cancelled" | "expired" | "suspended" | "manual";
  billing_period?: "monthly" | "yearly" | "manual" | null;
  current_period_start?: string | null;
  current_period_end?: string | null;
  trial_ends_at?: string | null;
  cancel_at_period_end: boolean;
  external_provider?: string | null;
  external_subscription_id?: string | null;
  subscription_plans?: SubscriptionPlan | null;
};

export type SubscriptionUsage = {
  doctors_count: number;
  services_count: number;
  appointments_count: number;
  visit_records_count: number;
  documents_count: number;
  storage_used_mb: number;
  period_start?: string;
  period_end?: string;
};

export type SubscriptionUpgradeRequest = {
  id: string;
  clinic_id: string;
  requested_plan_id: string;
  requested_by: string;
  status: "pending" | "approved" | "rejected" | "cancelled";
  note?: string | null;
  created_at: string;
  updated_at?: string;
  clinics?: Pick<Clinic, "id" | "name"> | null;
  subscription_plans?: SubscriptionPlan | null;
  profiles?: Pick<UserProfile, "id" | "full_name" | "email"> | null;
};

export type NotificationStatus = "unread" | "read" | "archived";

export type NotificationType =
  | "appointment_created"
  | "appointment_confirmed"
  | "appointment_cancelled_by_clinic"
  | "appointment_reminder_24h"
  | "appointment_reminder_2h"
  | "visit_record_published"
  | "document_uploaded"
  | "next_visit_recommended"
  | "review_request"
  | "clinic_message_placeholder"
  | "new_appointment_request"
  | "appointment_cancelled_by_owner"
  | "appointment_upcoming_today"
  | "visit_record_missing"
  | "review_received"
  | "subscription_limit_warning"
  | "subscription_upgrade_request_status";

export type NotificationItem = {
  id: string;
  recipient_user_id: string;
  clinic_id?: string | null;
  pet_id?: string | null;
  appointment_id?: string | null;
  visit_record_id?: string | null;
  document_id?: string | null;
  review_id?: string | null;
  type: NotificationType;
  title: string;
  body: string;
  data?: Record<string, unknown> | null;
  status: NotificationStatus;
  read_at?: string | null;
  created_at: string;
  updated_at?: string;
};

export type NotificationPreferences = {
  id?: string;
  user_id: string;
  in_app_enabled: boolean;
  email_enabled: boolean;
  push_enabled: boolean;
  sms_enabled: boolean;
  appointment_reminders_enabled: boolean;
  treatment_updates_enabled: boolean;
  review_requests_enabled: boolean;
  new_appointment_alerts_enabled: boolean;
  appointment_cancellation_alerts_enabled: boolean;
  review_alerts_enabled: boolean;
  subscription_limit_alerts_enabled: boolean;
  marketing_enabled: boolean;
  created_at?: string;
  updated_at?: string;
};

export type BetaFeedback = {
  id: string;
  user_id: string;
  clinic_id?: string | null;
  role: string;
  rating?: number | null;
  category?: "bug" | "usability" | "feature_request" | "data_issue" | "other" | null;
  message: string;
  status: "new" | "reviewed" | "resolved" | "ignored";
  created_at: string;
  updated_at?: string;
};
