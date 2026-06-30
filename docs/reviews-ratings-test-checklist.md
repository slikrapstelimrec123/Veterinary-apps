# Reviews And Ratings Test Checklist

## Pet Owner

- Pet owner can leave a review after a completed appointment.
- Pet owner can leave a review after a published visit record connected to an appointment.
- Pet owner cannot leave a review before appointment completion.
- Pet owner cannot review another owner’s appointment.
- Pet owner cannot submit a duplicate review for the same appointment.
- Review form requires a 1-5 overall rating.
- Comment is optional and limited to 1000 characters.
- Success state appears after submission.

## Public Profiles

- Clinic profile shows average rating and published review count.
- Clinic profile shows latest published reviews.
- Doctor profile shows average rating and published review count.
- Doctor profile shows latest published doctor reviews.
- Hidden, removed, and pending reviews are not visible publicly.

## Clinic Cabinet

- Clinic staff can view reviews for their own clinic.
- Clinic staff can open review details with appointment, pet, doctor, and visit context.
- Clinic staff cannot edit owner review text.
- Clinic staff cannot delete negative reviews directly.
- Clinic staff can use the report placeholder.

## Platform Admin

- Platform admin can view reviews in `/platform/reviews`.
- Platform admin can publish, hide, remove, report, or restore review status.
- Public summaries update only from published reviews.

## Mock Mode

- Mock mode shows published clinic reviews.
- Mock mode shows published doctor reviews.
- Mock mode includes one completed appointment without a review.
- Mock mode includes one completed appointment that is already reviewed.
- Mock mode includes pending and hidden reviews for admin/moderation preview.
