alter table public.pets
  add column if not exists emergency_allergies text,
  add column if not exists emergency_conditions text,
  add column if not exists emergency_surgeries text,
  add column if not exists emergency_contraindications text,
  add column if not exists emergency_behavior_notes text,
  add column if not exists emergency_blood_type text,
  add column if not exists emergency_notes text;

comment on column public.pets.emergency_allergies is 'Owner-entered allergies and adverse reactions for urgent care.';
comment on column public.pets.emergency_conditions is 'Owner-entered chronic conditions for urgent care.';
