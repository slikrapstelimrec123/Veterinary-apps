import type { SubscriptionPlan, SubscriptionPlanLimits, SubscriptionUsage } from "../types";
import { usagePercent } from "../lib/subscription-data";

const limitLabels: Record<keyof SubscriptionPlanLimits, string> = {
  max_doctors: "Лікарі",
  max_services: "Послуги",
  max_clinic_managers: "Менеджери клініки",
  max_appointments_per_month: "Записи на місяць",
  max_visit_records: "Медичні записи",
  max_documents: "Документи",
  max_storage_mb: "Сховище, МБ",
  can_publish_clinic_profile: "Публічний профіль",
  can_use_reviews: "Відгуки",
  can_use_advanced_analytics: "Аналітика",
  can_export_data: "Експорт даних",
  can_use_multi_location: "Multi-location",
  can_use_priority_support: "Пріоритетна підтримка",
};

export const usageItems = [
  { key: "doctors_count", limitKey: "max_doctors", label: "Лікарі" },
  { key: "services_count", limitKey: "max_services", label: "Послуги" },
  { key: "appointments_count", limitKey: "max_appointments_per_month", label: "Записи цього місяця" },
  { key: "visit_records_count", limitKey: "max_visit_records", label: "Медичні записи" },
  { key: "documents_count", limitKey: "max_documents", label: "Документи" },
  { key: "storage_used_mb", limitKey: "max_storage_mb", label: "Сховище, МБ" },
] as const;

const subscriptionStatusLabels: Record<string, string> = {
  trialing: "Тріал",
  active: "Активна",
  past_due: "Потребує уваги",
  cancelled: "Скасована",
  expired: "Завершена",
  suspended: "Призупинена",
  manual: "Ручна активація",
  pending: "Очікує",
  approved: "Підтверджено",
  rejected: "Відхилено",
};

const billingPeriodLabels: Record<string, string> = {
  monthly: "Щомісяця",
  yearly: "Щороку",
  manual: "Ручний режим",
};

export function formatSubscriptionStatus(status?: string | null) {
  return status ? subscriptionStatusLabels[status] ?? status : "Активна";
}

export function formatBillingPeriod(period?: string | null) {
  return period ? billingPeriodLabels[period] ?? period : "Ручний режим";
}

export function formatLimit(limit?: number | boolean | null) {
  if (typeof limit === "boolean") {
    return limit ? "Доступно" : "Недоступно";
  }

  if (limit === undefined || limit === null) {
    return "Не задано";
  }

  if (limit < 0) {
    return "Без ліміту";
  }

  return new Intl.NumberFormat("uk-UA").format(limit);
}

export function formatPrice(plan: SubscriptionPlan, yearly = false) {
  const price = yearly ? plan.price_yearly : plan.price_monthly;
  if (price === null || price === undefined) {
    return "Індивідуально";
  }

  if (price === 0) {
    return "0";
  }

  return new Intl.NumberFormat("uk-UA", {
    style: "currency",
    currency: plan.currency || "USD",
    maximumFractionDigits: 0,
  }).format(price);
}

export function PlanLimitList({ limits }: { limits: SubscriptionPlanLimits }) {
  const entries = Object.entries(limits) as [keyof SubscriptionPlanLimits, number | boolean][];

  return (
    <ul className="checklist">
      {entries.map(([key, value]) => (
        <li key={key}>
          <span>{limitLabels[key] ?? key}</span>
          <strong>{formatLimit(value)}</strong>
        </li>
      ))}
    </ul>
  );
}

export function UsageCard({
  usage,
  limits,
  item,
}: {
  usage: SubscriptionUsage;
  limits: SubscriptionPlanLimits;
  item: (typeof usageItems)[number];
}) {
  const current = Number(usage[item.key] ?? 0);
  const max = Number(limits[item.limitKey] ?? 0);
  const percent = usagePercent(current, max);

  return (
    <article className="card">
      <p className="eyebrow">{item.label}</p>
      <h2>
        {new Intl.NumberFormat("uk-UA").format(current)}
        <span className="muted" style={{ fontSize: 16, fontWeight: 700 }}> / {formatLimit(max)}</span>
      </h2>
      {max > 0 ? (
        <div style={{ height: 8, borderRadius: 999, background: "var(--surface-soft)", overflow: "hidden" }}>
          <div style={{ width: `${percent}%`, height: "100%", background: percent >= 90 ? "#b45309" : "var(--accent)" }} />
        </div>
      ) : (
        <p className="muted">Ліміт не обмежує роботу цього показника.</p>
      )}
    </article>
  );
}
