import { createService, updateService } from "../lib/clinic-actions";
import type { Service } from "../types";

export function ServiceForm({ service }: { service?: Service }) {
  const action = service ? updateService : createService;

  return (
    <form action={action} className="card" style={{ display: "grid", gap: 14 }}>
      {service ? <input name="id" type="hidden" value={service.id} /> : null}
      <div className="form-grid">
        <label className="field">
          Назва послуги
          <input name="name" defaultValue={service?.name ?? ""} required />
        </label>
        <label className="field">
          Категорія
          <input name="category" defaultValue={service?.category ?? ""} />
        </label>
        <label className="field">
          Ціна
          <input name="price_amount" type="number" min="0" step="0.01" defaultValue={service?.price_amount ?? ""} />
        </label>
        <label className="field">
          Тривалість (хв)
          <input name="duration_minutes" type="number" min="1" defaultValue={service?.duration_minutes ?? 30} />
        </label>
        <label className="field">
          Статус
          <select name="status" defaultValue={service?.status ?? "inactive"}>
            <option value="active">Активна</option>
            <option value="inactive">Неактивна</option>
            <option value="archived">Архівована</option>
          </select>
        </label>
      </div>
      <label className="field">
        Опис
        <textarea name="description" defaultValue={service?.description ?? ""} />
      </label>
      <label style={{ display: "flex", alignItems: "center", gap: 10 }}>
        <input name="is_public" type="checkbox" defaultChecked={service?.is_public ?? true} />
        Публічна у майбутньому профілі клініки
      </label>
      <div className="form-actions">
        <button className="button" type="submit">{service ? "Зберегти послугу" : "Додати послугу"}</button>
      </div>
    </form>
  );
}

