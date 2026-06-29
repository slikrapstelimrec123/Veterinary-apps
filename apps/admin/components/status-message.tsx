const successMessages: Record<string, string> = {
  saved: "Changes saved.",
  created: "Created successfully.",
  deactivated: "Deactivated.",
  deleted: "Deleted.",
};

const errorMessages: Record<string, string> = {
  validation: "Please check the highlighted required fields.",
  permission: "You do not have permission for this action.",
  not_found: "The requested item was not found.",
  publish_requirements: "Add name, city, address, and phone or email before publishing.",
  duplicate_schedule: "This doctor already has an active schedule for that day.",
  unsafe_delete: "This item is connected to future data, so it was archived instead.",
  unknown: "Something went wrong. Please try again.",
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

