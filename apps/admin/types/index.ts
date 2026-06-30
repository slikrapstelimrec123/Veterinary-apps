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

export type Subscription = {
  id: string;
  clinicId: string;
  plan: "free" | "paid";
  status: "inactive" | "trialing" | "active" | "past_due" | "cancelled";
};
