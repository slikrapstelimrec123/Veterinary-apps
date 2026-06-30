import Link from "next/link";
import { PageHeader } from "../../../components/page-header";
import { StatusMessage } from "../../../components/status-message";
import { getClinicReviewsData } from "../../../lib/clinic-data";
import type { Review } from "../../../types";

const statusLabels: Record<Review["status"], string> = {
  pending_moderation: "Очікує модерації",
  published: "Опубліковано",
  hidden: "Приховано",
  reported: "Поскаржилися",
  removed: "Видалено модератором",
};

export default async function ClinicReviewsPage({ searchParams }: { searchParams: { success?: string; error?: string } }) {
  const { reviews } = await getClinicReviewsData();

  return (
    <div className="page">
      <PageHeader
        eyebrow="Довіра"
        title="Відгуки"
        description="Переглядайте відгуки власників тварин після завершених записів. Клініка не може редагувати або видаляти текст відгуку."
      />
      <StatusMessage success={searchParams.success} error={searchParams.error} />

      <section className="card">
        {reviews.length === 0 ? (
          <p className="muted">Відгуків ще немає. Вони з’являться після завершених прийомів.</p>
        ) : (
          <div style={{ display: "grid", gap: 12 }}>
            {reviews.map((review) => (
              <ReviewRow key={review.id} review={review} />
            ))}
          </div>
        )}
      </section>
    </div>
  );
}

function ReviewRow({ review }: { review: Review }) {
  return (
    <div style={{ display: "grid", gap: 6, borderBottom: "1px solid var(--border)", paddingBottom: 12 }}>
      <div style={{ display: "flex", justifyContent: "space-between", gap: 12 }}>
        <strong>{stars(review.rating)} {review.pets?.name ?? "Тварина"}</strong>
        <span className="status">{statusLabels[review.status]}</span>
      </div>
      <p className="muted">
        {formatDate(review.created_at)} · {review.is_anonymous ? "Анонімний власник" : review.profiles?.full_name ?? review.profiles?.email ?? "Власник"}
        {review.doctors?.full_name ? ` · ${review.doctors.full_name}` : ""}
      </p>
      <p>{preview(review.comment)}</p>
      <Link className="button button-secondary" href={`/clinic/reviews/${review.id}`}>Відкрити</Link>
    </div>
  );
}

function preview(value?: string | null) {
  if (!value) return "Коментар не додано.";
  return value.length > 160 ? `${value.slice(0, 160)}...` : value;
}

function stars(value: number) {
  return "★".repeat(value) + "☆".repeat(Math.max(0, 5 - value));
}

function formatDate(value: string) {
  return new Intl.DateTimeFormat("uk-UA", { day: "2-digit", month: "short", year: "numeric" }).format(new Date(value));
}
