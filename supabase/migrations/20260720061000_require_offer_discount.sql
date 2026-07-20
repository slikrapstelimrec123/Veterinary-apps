alter table public.announcements
  drop constraint if exists announcements_offer_requires_special_discount;

alter table public.announcements
  add constraint announcements_offer_requires_special_discount
  check (
    announcement_type <> 'offer'
    or nullif(btrim(offer_text), '') is not null
  ) not valid;

notify pgrst, 'reload schema';
