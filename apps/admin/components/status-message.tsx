const successMessages: Record<string, string> = {
  saved: "Зміни збережено.",
  created: "Успішно створено.",
  deactivated: "Деактивовано.",
  deleted: "Видалено.",
};

const errorMessages: Record<string, string> = {
  validation: "Будь ласка, перевірте виділені обов'язкові поля.",
  permission: "У вас немає дозволу на цю дію.",
  not_found: "Запитаний елемент не знайдено.",
  publish_requirements: "Додайте назву, місто, адресу та телефон або email перед публікацією.",
  duplicate_schedule: "Цей лікар вже має активний розклад на цей день.",
  unsafe_delete: "Цей елемент пов'язаний із майбутніми даними, тому він був заархівований.",
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

