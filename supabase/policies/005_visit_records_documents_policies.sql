-- Reference policy intent for visit records and private medical documents.
-- The executable version lives in supabase/migrations/20260630160000_visit_records_documents_module.sql.

-- visit_records:
-- Clinic owners, clinic managers, veterinarians linked through clinic workflows, and platform admins can read clinic records.
-- Pet owners can read only published records for pets they own.
-- Draft records and internal notes are never returned by owner-facing mobile queries.
-- Clinic staff can create records for clinic appointments; veterinarians can create records for assigned appointments.
-- Created records can be saved as draft, published to owner, or archived.

-- visit_documents:
-- Documents belong to a visit record, clinic, and pet.
-- Clinic staff can upload and manage documents in their clinic.
-- Pet owners can read only visible documents connected to published records for their own pets.
-- Hidden/internal documents remain clinic-only.

-- storage.objects in bucket visit-documents:
-- Bucket is private.
-- Upload paths use clinic_id/pet_id/visit_record_id/file_name.
-- Clinic staff can upload/read/update within their clinic folder.
-- Clinic owners/managers can delete files in their clinic folder.
-- Pet owners can read only files that have visible visit_documents metadata and published visit_records.
