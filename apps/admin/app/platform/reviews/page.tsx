import { PageHeader } from "../../../components/page-header";
import { StatusMessage } from "../../../components/status-message";
import { updateReviewStatus } from "../../../lib/clinic-actions";
import { getPlatformReviewsData } from "../../../lib/clinic-data";
import type { Review } from "../../../types";

const statusLabels: Record<Review["status"], string> = {
  pending_moderation: "Очікує модерації",
  published: "Опубліковано",
  hidden: "Приховано",
  reported: "Поскаржилися",
  removed: "Видалено модератором",
};

export default async function PlatformReviewsPage({ searchParams }: { searchParams: { success?: string; error?: string } }) {
  const { profile, reviews } = await getPlatformReviewsData();

  return (
    <div className="page">
      <PageHeader
        eyebrow="Платформа"
        title="Модерація відгуків"
        description="Базова черга для перегляду, приховування та відновлення відгуків. Повний moderation workflow можна розширити пізніше."
      />
      <StatusMessage success={searchParams.success} error={searchParams.error} />

      {profile?.role !== "platform_admin" ? (
        <section className="card"><p className="muted">Ця сторінка доступна лише адміністратору платформи.</p></section>
      ) : reviews.length === 0 ? (
        <section className="card"><p className="muted">Відгуків для модерації ще немає.</p></section>
      ) : (
        <section className="card" style={{ display: "grid", gap: 12 }}>
          {reviews.map((review) => (
            <form key={review.id} action={updateReviewStatus} style={{ display: "grid", gap: 8, borderBottom: "1px solid var(--border)", paddingBottom: 12 }}>
              <input type="hidden" name="id" value={review.id} />
              <strong>{stars(review.rating)} {review.pets?.name ?? "Тварина"} · {review.doctors?.full_name ?? "Лікар не вказаний"}</strong>
              <p className="muted">{review.profiles?.full_name ?? review.profiles?.email ?? "Власник"} · {statusLabels[review.status]}</p>
              <p>{review.comment ?? "Коментар не додано."}</p>
              <label className="field">
                <span>Статус</span>
                <select name="status" defaultValue={review.status}>
                  <option value="pending_moderation">Очікує модерації</option>
                  <option value="published">Опублікувати</option>
                  <option value="hidden">Приховати</option>
                  <option value="reported">Поскаржилися</option>
                  <option value="removed">Видалено модератором</option>
                </select>
              </label>
              <button className="button" type="submit">Зберегти статус</button>
            </form>
          ))}
        </section>
      )}
    </div>
  );
}

function stars(value: number) {
  return "★".repeat(value) + "☆".repeat(Math.max(0, 5 - value));
}
