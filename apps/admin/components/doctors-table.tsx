import { ConfirmSubmitButton } from "./confirm-submit-button";
import { deactivateDoctor, deleteDoctor } from "../lib/clinic-actions";
import type { Doctor } from "../types";

export function DoctorsTable({ doctors, canManage }: { doctors: Doctor[]; canManage: boolean }) {
  return (
    <table className="table">
      <thead>
        <tr>
          <th>Ім'я</th>
          <th>Спеціалізація</th>
          <th>Контакт</th>
          <th>Статус</th>
          {canManage ? <th>Дії</th> : null}
        </tr>
      </thead>
      <tbody>
        {doctors.map((doctor) => (
          <tr key={doctor.id}>
            <td>{doctor.full_name}</td>
            <td>{doctor.specialization ?? "Не вказано"}</td>
            <td>{doctor.email ?? doctor.phone ?? "Не вказано"}</td>
            <td><span className="status">{doctor.status}</span></td>
            {canManage ? (
              <td>
                <div className="form-actions">
                  <a className="button button-secondary" href={`/clinic/doctors/${doctor.id}`}>Редагувати</a>
                  <form action={deactivateDoctor}>
                    <input name="id" type="hidden" value={doctor.id} />
                    <button className="button button-muted" type="submit">Деактивувати</button>
                  </form>
                  <form action={deleteDoctor}>
                    <input name="id" type="hidden" value={doctor.id} />
                    <ConfirmSubmitButton className="button button-danger" message="Видалити цього лікаря, якщо він не пов'язаний із записами?">
                      Видалити
                    </ConfirmSubmitButton>
                  </form>
                </div>
              </td>
            ) : null}
          </tr>
        ))}
      </tbody>
    </table>
  );
}
