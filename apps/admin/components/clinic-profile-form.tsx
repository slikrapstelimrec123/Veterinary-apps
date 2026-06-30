import { updateClinicProfile } from "../lib/clinic-actions";
import type { Clinic } from "../types";

export function ClinicProfileForm({ clinic, canEdit }: { clinic: Clinic; canEdit: boolean }) {
  return (
    <form action={updateClinicProfile} className="card" style={{ display: "grid", gap: 16 }}>
      <div className="form-grid">
        <label className="field">
          Назва клініки
          <input name="name" defaultValue={clinic.name} required disabled={!canEdit} />
        </label>
        <label className="field">
          Місто
          <input name="city" defaultValue={clinic.city ?? ""} required disabled={!canEdit} />
        </label>
        <label className="field">
          Країна
          <input name="country" defaultValue={clinic.country ?? ""} disabled={!canEdit} />
        </label>
        <label className="field">
          Адреса
          <input name="address" defaultValue={clinic.address ?? ""} disabled={!canEdit} />
        </label>
        <label className="field">
          Телефон
          <input name="phone" defaultValue={clinic.phone ?? ""} disabled={!canEdit} />
        </label>
        <label className="field">
          Електронна пошта
          <input name="email" defaultValue={clinic.email ?? ""} type="email" disabled={!canEdit} />
        </label>
        <label className="field">
          Вебсайт
          <input name="website" defaultValue={clinic.website ?? ""} disabled={!canEdit} />
        </label>
        <label className="field">
          URL логотипу
          <input name="logo_url" defaultValue={clinic.logo_url ?? ""} disabled={!canEdit} />
        </label>
        <label className="field">
          URL обкладинки
          <input name="cover_image_url" defaultValue={clinic.cover_image_url ?? ""} disabled={!canEdit} />
        </label>
        <label className="field">
          Статус
          <select name="status" defaultValue={clinic.status} disabled={!canEdit}>
            <option value="draft">Чернетка</option>
            <option value="pending_verification">На перевірці</option>
            <option value="published">Опубліковано</option>
          </select>
        </label>
      </div>
      <label className="field">
        Опис
        <textarea name="description" defaultValue={clinic.description ?? ""} disabled={!canEdit} />
      </label>
      <label style={{ display: "flex", alignItems: "center", gap: 10 }}>
        <input name="published" type="checkbox" defaultChecked={clinic.published} disabled={!canEdit} />
        Опубліковано для майбутнього пошуку власниками тварин
      </label>
      <div className="form-actions">
        <button className="button" type="submit" disabled={!canEdit}>Зберегти зміни</button>
        {!canEdit ? <span className="muted">Ви можете переглядати цей профіль, але не можете його редагувати.</span> : null}
      </div>
    </form>
  );
}
