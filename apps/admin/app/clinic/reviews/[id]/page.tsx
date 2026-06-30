import Link from "next/link";
import { notFound } from "next/navigation";
import { PageHeader } from "../../../../components/page-header";
import { StatusMessage } from "../../../../components/status-message";
import { reportReviewPlaceholder } from "../../../../lib/clinic-actions";
import { getClinicReviewDetails } from "../../../../lib/clinic-data";
import type { Review } from "../../../../types";

const statusLabels: Record<Review["status"], string> = {
  pending_moderation: "Очікує модерації",
  published: "Опубліковано",
  hidden: "Приховано",
  reported: "Поскаржилися",
  removed: "Видалено модератором",
};

export default async function ClinicReviewDetailsPage({
  params,
  searchParams,
}: {
  params: { id: string };
  searchParams: { success?: string; error?: string };
}) {
  const { review } = await getClinicReviewDetails(params.id);

  if (!review) {
    notFound();
  }

  return (
    <div className="page">
      <PageHeader
        eyebrow="Відгук"
        title={`${stars(review.rating)} ${review.pets?.name ?? "Тварина"}`}
        description="Контекст запису, лікаря, тварини та статусу модерації."
        action={<Link className="button button-secondary" href="/clinic/reviews">Назад до відгуків</Link>}
      />
      <StatusMessage success={searchParams.success} error={searchParams.error} />

      <section className="grid">
        <article className="card">
          <h2>Оцінки</h2>
          <p>Загальна: {stars(review.rating)}</p>
          <p>Клініка: {review.clinic_rating ? stars(review.clinic_rating) : "Не вказано"}</p>
          <p>Лікар: {review.doctor_rating ? stars(review.doctor_rating) : "Не вказано"}</p>
          <p>Сервіс: {review.service_quality_rating ? stars(review.service_quality_rating) : "Не вказано"}</p>
        </article>
        <article className="card">
          <h2>Статус</h2>
          <p><span className="status">{statusLabels[review.status]}</span></p>
          <p className="muted">Клініка не може змінювати текст або видаляти негативні відгуки.</p>
        </article>
      </section>

      <section className="card">
        <h2>Коментар</h2>
        <p>{review.comment ?? "Коментар не додано."}</p>
        <p className="muted">{review.is_anonymous ? "Анонімний власник" : review.profiles?.full_name ?? review.profiles?.email ?? "Власник"}</p>
      </section>

      <section className="grid">
        <article className="card">
          <h2>Контекст</h2>
          <p>Тварина: {review.pets?.name ?? "Не вказано"}</p>
          <p>Лікар: {review.doctors?.full_name ?? "Не призначено"}</p>
          <p>Запис: {review.appointments ? `${formatDate(review.appointments.appointment_date)} ${review.appointments.start_time}` : "Не вказано"}</p>
          <p>Медичний запис: {review.visit_records ? review.visit_records.diagnosis ?? review.visit_records.status : "Не прив’язано"}</p>
        </article>
        <form className="card" action={reportReviewPlaceholder}>
          <h2>Модерація</h2>
          <input type="hidden" name="id" value={review.id} />
          <p className="muted">На цьому етапі клініка може лише передати відгук на перевірку платформи.</p>
          <button className="button button-secondary" type="submit">Поскаржитися</button>
        </form>
      </section>
    </div>
  );
}

function stars(value: number) {
  return "★".repeat(value) + "☆".repeat(Math.max(0, 5 - value));
}

function formatDate(value: string) {
  return new Intl.DateTimeFormat("uk-UA", { day: "2-digit", month: "short", year: "numeric" }).format(new Date(value));
}
