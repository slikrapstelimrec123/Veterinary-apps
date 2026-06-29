import { createSchedule, updateSchedule } from "../lib/clinic-actions";
import type { Doctor, DoctorSchedule } from "../types";

export const days = [
  [1, "Понеділок"],
  [2, "Вівторок"],
  [3, "Середа"],
  [4, "Четвер"],
  [5, "П'ятниця"],
  [6, "Субота"],
  [7, "Неділя"],
] as const;

export function DoctorScheduleForm({
  doctors,
  schedule,
}: {
  doctors: Doctor[];
  schedule?: DoctorSchedule;
}) {
  const action = schedule ? updateSchedule : createSchedule;

  return (
    <form action={action} className="card" style={{ display: "grid", gap: 14 }}>
      {schedule ? <input name="id" type="hidden" value={schedule.id} /> : null}
      <div className="form-grid">
        {!schedule ? (
          <>
            <label className="field">
              Лікар
              <select name="doctor_id" required defaultValue="">
                <option value="" disabled>Оберіть лікаря</option>
                {doctors.map((doctor) => (
                  <option key={doctor.id} value={doctor.id}>{doctor.full_name}</option>
                ))}
              </select>
            </label>
            <label className="field">
              День
              <select name="day_of_week" required defaultValue="">
                <option value="" disabled>Оберіть день</option>
                {days.map(([value, label]) => (
                  <option key={value} value={value}>{label}</option>
                ))}
              </select>
            </label>
          </>
        ) : null}
        <label className="field">
          Початок роботи
          <input name="start_time" type="time" defaultValue={schedule?.start_time ?? "09:00"} required />
        </label>
        <label className="field">
          Кінець роботи
          <input name="end_time" type="time" defaultValue={schedule?.end_time ?? "18:00"} required />
        </label>
        <label className="field">
          Початок перерви
          <input name="break_start_time" type="time" defaultValue={schedule?.break_start_time ?? ""} />
        </label>
        <label className="field">
          Кінець перерви
          <input name="break_end_time" type="time" defaultValue={schedule?.break_end_time ?? ""} />
        </label>
        <label className="field">
          Тривалість слоту
          <input name="slot_duration_minutes" type="number" min="1" defaultValue={schedule?.slot_duration_minutes ?? 30} />
        </label>
      </div>
      <label style={{ display: "flex", alignItems: "center", gap: 10 }}>
        <input name="is_active" type="checkbox" defaultChecked={schedule?.is_active ?? true} />
        Активний запис розкладу
      </label>
      <div className="form-actions">
        <button className="button" type="submit">{schedule ? "Зберегти розклад" : "Додати робочий день"}</button>
      </div>
    </form>
  );
}

