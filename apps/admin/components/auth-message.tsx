export function authMessage(error?: string | null) {
  if (!error) {
    return null;
  }

  const messages: Record<string, string> = {
    profile_missing: "Ваш обліковий запис існує, але профіль ще не було створено.",
    admin_role_required: "Цей кабінет доступний лише для ролей клініки.",
    clinic_access_required: "Ваш доступ до клініки ще не активний.",
  };

  return messages[error] ?? "Будь ласка, увійдіть, щоб продовжити.";
}

