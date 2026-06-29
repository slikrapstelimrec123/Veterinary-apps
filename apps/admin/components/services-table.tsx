import { ConfirmSubmitButton } from "./confirm-submit-button";
import { deactivateService, deleteService } from "../lib/clinic-actions";
import type { Service } from "../types";

export function ServicesTable({ services, canManage }: { services: Service[]; canManage: boolean }) {
  return (
    <table className="table">
      <thead>
        <tr>
          <th>Назва</th>
          <th>Категорія</th>
          <th>Тривалість</th>
          <th>Ціна</th>
          <th>Статус</th>
          {canManage ? <th>Дії</th> : null}
        </tr>
      </thead>
      <tbody>
        {services.map((service) => (
          <tr key={service.id}>
            <td>{service.name}</td>
            <td>{service.category ?? "Загальна"}</td>
            <td>{service.duration_minutes ?? 30} хв</td>
            <td>{service.price_amount ? `${service.price_amount} ${service.price_currency ?? "UAH"}` : "Не вказано"}</td>
            <td><span className="status">{service.status}</span></td>
            {canManage ? (
              <td>
                <div className="form-actions">
                  <form action={deactivateService}>
                    <input name="id" type="hidden" value={service.id} />
                    <button className="button button-muted" type="submit">Деактивувати</button>
                  </form>
                  <form action={deleteService}>
                    <input name="id" type="hidden" value={service.id} />
                    <ConfirmSubmitButton className="button button-danger" message="Видалити цю послугу, якщо вона не пов'язана із записами?">
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
