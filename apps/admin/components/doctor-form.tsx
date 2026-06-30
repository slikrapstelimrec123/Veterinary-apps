import { createDoctor, updateDoctor } from "../lib/clinic-actions";
import type { Doctor } from "../types";

export function DoctorForm({ doctor }: { doctor?: Doctor }) {
  const action = doctor ? updateDoctor : createDoctor;

  return (
    <form action={action} className="card" style={{ display: "grid", gap: 14 }}>
      {doctor ? <input name="id" type="hidden" value={doctor.id} /> : null}
      <div className="form-grid">
        <label className="field">
          Повне ім'я
          <input name="full_name" defaultValue={doctor?.full_name ?? ""} required />
        </label>
        <label className="field">
          Спеціалізація
          <input name="specialization" defaultValue={doctor?.specialization ?? ""} required />
        </label>
        <label className="field">
          Роки досвіду
          <input name="experience_years" type="number" min="0" defaultValue={doctor?.experience_years ?? ""} />
        </label>
        <label className="field">
          Телефон
          <input name="phone" defaultValue={doctor?.phone ?? ""} />
        </label>
        <label className="field">
          Електронна пошта
          <input name="email" type="email" defaultValue={doctor?.email ?? ""} />
        </label>
        <label className="field">
          URL аватара
          <input name="avatar_url" defaultValue={doctor?.avatar_url ?? ""} />
        </label>
        <label className="field">
          Статус
          <select name="status" defaultValue={doctor?.status ?? "draft"}>
            <option value="draft">Чернетка</option>
            <option value="active">Активний</option>
            <option value="inactive">Неактивний</option>
            <option value="archived">Архівований</option>
          </select>
        </label>
      </div>
      <label className="field">
        Біографія
        <textarea name="bio" defaultValue={doctor?.bio ?? ""} />
      </label>
      <label style={{ display: "flex", alignItems: "center", gap: 10 }}>
        <input name="is_public" type="checkbox" defaultChecked={doctor?.is_public ?? true} />
        Публічний у майбутньому профілі клініки
      </label>
      <div className="form-actions">
        <button className="button" type="submit">{doctor ? "Зберегти лікаря" : "Додати лікаря"}</button>
      </div>
    </form>
  );
}

