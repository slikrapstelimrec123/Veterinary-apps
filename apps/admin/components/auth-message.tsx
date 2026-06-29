export function authMessage(error?: string | null) {
  if (!error) {
    return null;
  }

  const messages: Record<string, string> = {
    profile_missing: "Your account exists, but the profile was not created yet.",
    admin_role_required: "This web cabinet is available only for clinic roles.",
    clinic_access_required: "Your clinic access is not active yet.",
  };

  return messages[error] ?? "Please sign in to continue.";
}

