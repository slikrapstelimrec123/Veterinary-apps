# AI Agent Instructions

This repository contains Lappo, a mobile application for pet owners.

## Product Rules

- Follow the owner-only MVP scope in `docs/prd.md`.
- Treat the pet medical card as the center of the product.
- Medical visit records are created and managed by pet owners.
- Do not add clinic administration, doctor accounts, online booking, clinic subscriptions, clinic reviews, or clinic marketplace features.
- Do not implement payments, chat, AI diagnosis, insurance, or telemedicine in this stage.

## Engineering Rules

- Keep code clean, readable, and feature-oriented.
- Prefer simple architecture over clever abstractions.
- Do not hardcode secrets or environment-specific values.
- Keep Supabase Row Level Security as the source of truth for sensitive access.
- Historical migrations may retain legacy clinic tables for reproducibility, but application roles must not access them.

## Security And Privacy

- Pet records, medical records, and uploaded documents are sensitive data.
- Users must see only pets and records they own or were explicitly granted access to.
- Uploaded documents must remain private.
- Public users may see only deliberately published announcement content.

## UI Rules

- Keep UI minimalistic, premium, calm, and trustworthy.
- Use Ukrainian for visible product text.
- Make primary actions obvious.
- Protect destructive or high-impact actions with confirmation.
