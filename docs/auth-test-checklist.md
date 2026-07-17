# Authentication Test Checklist

- Email registration creates a `pet_owner` profile.
- Email login and logout work after reinstall.
- Google login returns to Lappo and opens the owner home screen.
- Apple login returns to Lappo and opens the owner home screen.
- Cancelled OAuth returns a clear error without creating a partial session.
- Password reset opens the application callback.
- A legacy non-owner role cannot enter owner features.
- A second account cannot read the first account's pets or records.
