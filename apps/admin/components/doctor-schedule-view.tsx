import { ConfirmSubmitButton } from "./confirm-submit-button";
import { DoctorScheduleForm, days } from "./doctor-schedule-form";
import { deleteSchedule } from "../lib/clinic-actions";
import type { Doctor, DoctorSchedule } from "../types";

export function DoctorScheduleView({
  doctors,
  schedules,
  canManage,
}: {
  doctors: Doctor[];
  schedules: DoctorSchedule[];
  canManage: boolean;
}) {
  return (
    <section className="schedule-grid">
      {days.map(([dayNumber, dayName]) => {
        const daySchedules = schedules.filter((schedule) => schedule.day_of_week === dayNumber);

        return (
          <div className="card" key={dayNumber}>
            <h2>{dayName}</h2>
            {daySchedules.length === 0 ? <p className="muted">No active hours set.</p> : null}
            <div style={{ display: "grid", gap: 12 }}>
              {daySchedules.map((schedule) => (
                <div key={schedule.id} style={{ borderTop: "1px solid var(--border)", paddingTop: 12 }}>
                  <p style={{ margin: "0 0 6px", fontWeight: 800 }}>
                    {schedule.doctors?.full_name ?? "Doctor"} · {schedule.start_time.slice(0, 5)}-{schedule.end_time.slice(0, 5)}
                  </p>
                  <p className="muted" style={{ marginTop: 0 }}>
                    Slot {schedule.slot_duration_minutes} min
                    {schedule.break_start_time ? ` · break ${schedule.break_start_time.slice(0, 5)}-${schedule.break_end_time?.slice(0, 5)}` : ""}
                  </p>
                  {canManage ? (
                    <>
                      <DoctorScheduleForm doctors={doctors} schedule={schedule} />
                      <form action={deleteSchedule} style={{ marginTop: 10 }}>
                        <input name="id" type="hidden" value={schedule.id} />
                        <ConfirmSubmitButton className="button button-danger" message="Delete this schedule item?">
                          Delete schedule item
                        </ConfirmSubmitButton>
                      </form>
                    </>
                  ) : null}
                </div>
              ))}
            </div>
          </div>
        );
      })}
    </section>
  );
}
