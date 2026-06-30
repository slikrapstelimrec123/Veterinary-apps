const successMessages: Record<string, string> = {
  saved: "Зміни збережено.",
  created: "Успішно створено.",
  deactivated: "Деактивовано.",
  deleted: "Видалено.",
  reported: "Відгук передано на модерацію.",
  requested: "Запит на зміну тарифу надіслано.",
  approved: "Запит на тариф підтверджено.",
  rejected: "Запит на тариф відхилено.",
};

const errorMessages: Record<string, string> = {
  validation: "Будь ласка, перевірте виділені обов'язкові поля.",
  permission: "У вас немає дозволу на цю дію.",
  not_found: "Запитаний елемент не знайдено.",
  publish_requirements: "Додайте назву, місто, адресу та телефон або email перед публікацією.",
  visit_publish_requirements: "Перед публікацією медичного запису додайте діагноз, лікування або рекомендації.",
  duplicate_schedule: "Цей лікар вже має активний розклад на цей день.",
  unsafe_delete: "Цей елемент пов'язаний із майбутніми даними, тому він був заархівований.",
  limit_reached: "Досягнуто ліміт поточного тарифу. Перегляньте підписку, щоб розширити можливості.",
  feature_locked: "Ця можливість недоступна на поточному тарифі.",
  upgrade_pending: "У клініки вже є активний запит на зміну тарифу.",
  unknown: "Щось пішло не так. Спробуйте ще раз.",
};

export function StatusMessage({
  success,
  error,
}: {
  success?: string;
  error?: string;
}) {
  const message = success ? successMessages[success] : error ? errorMessages[error] : null;

  if (!message) {
    return null;
  }

  return <p className={`notice ${success ? "notice-success" : "notice-error"}`}>{message}</p>;
}

