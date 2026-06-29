import { createSchedule, updateSchedule } from "../lib/clinic-actions";
import type { Doctor, DoctorSchedule } from "../types";

export const days = [
  [1, "Monday"],
  [2, "Tuesday"],
  [3, "Wednesday"],
  [4, "Thursday"],
  [5, "Friday"],
  [6, "Saturday"],
  [7, "Sunday"],
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
              Doctor
              <select name="doctor_id" required defaultValue="">
                <option value="" disabled>Select doctor</option>
                {doctors.map((doctor) => (
                  <option key={doctor.id} value={doctor.id}>{doctor.full_name}</option>
                ))}
              </select>
            </label>
            <label className="field">
              Day
              <select name="day_of_week" required defaultValue="">
                <option value="" disabled>Select day</option>
                {days.map(([value, label]) => (
                  <option key={value} value={value}>{label}</option>
                ))}
              </select>
            </label>
          </>
        ) : null}
        <label className="field">
          Start time
          <input name="start_time" type="time" defaultValue={schedule?.start_time ?? "09:00"} required />
        </label>
        <label className="field">
          End time
          <input name="end_time" type="time" defaultValue={schedule?.end_time ?? "18:00"} required />
        </label>
        <label className="field">
          Break starts
          <input name="break_start_time" type="time" defaultValue={schedule?.break_start_time ?? ""} />
        </label>
        <label className="field">
          Break ends
          <input name="break_end_time" type="time" defaultValue={schedule?.break_end_time ?? ""} />
        </label>
        <label className="field">
          Slot duration
          <input name="slot_duration_minutes" type="number" min="1" defaultValue={schedule?.slot_duration_minutes ?? 30} />
        </label>
      </div>
      <label style={{ display: "flex", alignItems: "center", gap: 10 }}>
        <input name="is_active" type="checkbox" defaultChecked={schedule?.is_active ?? true} />
        Active schedule item
      </label>
      <div className="form-actions">
        <button className="button" type="submit">{schedule ? "Save schedule" : "Add working day"}</button>
      </div>
    </form>
  );
}

