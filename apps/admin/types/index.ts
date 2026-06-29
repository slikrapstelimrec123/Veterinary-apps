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
  doctors?: Pick<Doctor, "id" | "full_name" | "specialization"> | null;
};

export type Pet = {
  id: string;
  name: string;
  species: string;
  breed?: string;
};

export type Appointment = {
  id: string;
  clinicId: string;
  petId: string;
  ownerName: string;
  startsAt: string;
  status: "scheduled" | "confirmed" | "cancelled" | "completed" | "no_show";
};

export type VisitRecord = {
  id: string;
  clinicId: string;
  petId: string;
  diagnosis?: string;
  status: "draft" | "completed";
};

export type VisitDocument = {
  id: string;
  visitRecordId: string;
  title: string;
  documentType: "diagnosis" | "recommendation" | "certificate" | "photo" | "lab_result" | "other";
};

export type Subscription = {
  id: string;
  clinicId: string;
  plan: "free" | "paid";
  status: "inactive" | "trialing" | "active" | "past_due" | "cancelled";
};
