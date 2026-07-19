"use client";

import { FormEvent, useCallback, useEffect, useMemo, useState } from "react";
import { createClient, SupabaseClient } from "@supabase/supabase-js";

type Overview = {
  users_total: number;
  users_30d: number;
  pets_total: number;
  announcements_active: number;
  announcements_paid: number;
  pro_active: number;
  pro_plus_active: number;
  verified_revenue_minor: number;
  currency: string;
};

type CityRow = {
  city: string;
  users_count: number;
  pets_count: number;
  announcements_count: number;
};

type PlanRow = {
  plan_code: string;
  active_subscriptions: number;
  monthly_subscriptions: number;
  yearly_subscriptions: number;
};

type DashboardData = {
  overview: Overview;
  cities: CityRow[];
  plans: PlanRow[];
};

const emptyOverview: Overview = {
  users_total: 0,
  users_30d: 0,
  pets_total: 0,
  announcements_active: 0,
  announcements_paid: 0,
  pro_active: 0,
  pro_plus_active: 0,
  verified_revenue_minor: 0,
  currency: "UAH",
};

const number = new Intl.NumberFormat("uk-UA");
const money = new Intl.NumberFormat("uk-UA", {
  style: "currency",
  currency: "UAH",
  maximumFractionDigits: 0,
});

export default function Home() {
  const [client, setClient] = useState<SupabaseClient | null>(null);
  const [signedIn, setSignedIn] = useState(false);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [busy, setBusy] = useState(true);
  const [error, setError] = useState("");
  const [updatedAt, setUpdatedAt] = useState<Date | null>(null);
  const [data, setData] = useState<DashboardData>({
    overview: emptyOverview,
    cities: [],
    plans: [],
  });

  useEffect(() => {
    let active = true;
    fetch("/api/config")
      .then(async (response) => {
        if (!response.ok) throw new Error("config");
        return response.json();
      })
      .then(({ supabaseUrl, supabaseAnonKey }) => {
        if (!supabaseUrl || !supabaseAnonKey) throw new Error("config");
        const supabase = createClient(supabaseUrl, supabaseAnonKey, {
          auth: {
            persistSession: true,
            autoRefreshToken: true,
            // The private Sites access gate owns the URL token. This panel
            // deliberately uses password authentication only, so Supabase
            // must never try to consume that token as its own session.
            detectSessionInUrl: false,
          },
        });
        if (!active) return;
        setClient(supabase);
        return supabase.auth.getSession().then(({ data: sessionData }) => {
          if (!active) return;
          setSignedIn(Boolean(sessionData.session));
          setBusy(false);
        });
      })
      .catch(() => {
        if (!active) return;
        setError(
          "Панель ще не підключена до Supabase. Додайте змінні середовища.",
        );
        setBusy(false);
      });
    return () => {
      active = false;
    };
  }, []);

  const loadDashboard = useCallback(async () => {
    if (!client) return;
    setBusy(true);
    setError("");
    const [overview, cities, plans] = await Promise.all([
      client.rpc("admin_dashboard_overview"),
      client.rpc("admin_city_analytics"),
      client.rpc("admin_plan_analytics"),
    ]);
    const firstError = overview.error || cities.error || plans.error;
    if (firstError) {
      setError(
        "Немає доступу до аналітики. Перевірте роль platform_admin для цього облікового запису.",
      );
    } else {
      setData({
        overview: (overview.data ?? emptyOverview) as Overview,
        cities: (cities.data ?? []) as CityRow[],
        plans: (plans.data ?? []) as PlanRow[],
      });
      setUpdatedAt(new Date());
    }
    setBusy(false);
  }, [client]);

  useEffect(() => {
    if (!client) return;
    const {
      data: { subscription },
    } = client.auth.onAuthStateChange((_event, session) => {
      setSignedIn(Boolean(session));
      if (!session) {
        setData({ overview: emptyOverview, cities: [], plans: [] });
      }
    });
    return () => subscription.unsubscribe();
  }, [client]);

  useEffect(() => {
    if (!signedIn) return;
    const timer = window.setTimeout(() => void loadDashboard(), 0);
    return () => window.clearTimeout(timer);
  }, [signedIn, loadDashboard]);

  async function signIn(event: FormEvent) {
    event.preventDefault();
    if (!client) return;
    setBusy(true);
    setError("");
    const { error: signInError } = await client.auth.signInWithPassword({
      email: email.trim(),
      password,
    });
    if (signInError) {
      setError("Невірна електронна адреса або пароль.");
      setBusy(false);
    }
  }

  async function signOut() {
    await client?.auth.signOut();
  }

  const metrics = useMemo(
    () => [
      {
        label: "Клієнти",
        value: number.format(data.overview.users_total),
        hint: `+${number.format(data.overview.users_30d)} за 30 днів`,
        icon: "◉",
        tone: "violet",
      },
      {
        label: "Тварини",
        value: number.format(data.overview.pets_total),
        hint: "активні картки",
        icon: "●",
        tone: "mint",
      },
      {
        label: "Оголошення",
        value: number.format(data.overview.announcements_active),
        hint: `${number.format(data.overview.announcements_paid)} платних`,
        icon: "◆",
        tone: "blue",
      },
      {
        label: "Підписки",
        value: number.format(
          data.overview.pro_active + data.overview.pro_plus_active,
        ),
        hint: `${data.overview.pro_active} Pro · ${data.overview.pro_plus_active} Pro+`,
        icon: "✦",
        tone: "amber",
      },
      {
        label: "Підтверджений дохід",
        value: money.format(data.overview.verified_revenue_minor / 100),
        hint: "покупки та підписки",
        icon: "₴",
        tone: "rose",
      },
    ],
    [data],
  );

  if (!signedIn) {
    return (
      <main className="auth-page">
        <div className="ambient ambient-one" />
        <div className="ambient ambient-two" />
        <section className="auth-shell">
          <div className="auth-story">
            <Logo />
            <span className="private-badge">Внутрішній простір</span>
            <h1>Дані, що допомагають Lappo зростати розумно.</h1>
            <p>
              Клієнти, тварини, міста, підписки та платні публікації — в одному
              спокійному й захищеному просторі.
            </p>
            <div className="trust-note">
              <span>✓</span>
              Доступ мають лише адміністратори платформи
            </div>
          </div>
          <form className="login-card" onSubmit={signIn}>
            <p className="eyebrow">Захищений вхід</p>
            <h2>Панель керування</h2>
            <p className="muted">Увійдіть під обліковим записом адміністратора.</p>
            <label>
              Електронна адреса
              <input
                type="email"
                value={email}
                onChange={(event) => setEmail(event.target.value)}
                autoComplete="username"
                placeholder="admin@lappo.app"
                required
              />
            </label>
            <label>
              Пароль
              <input
                type="password"
                value={password}
                onChange={(event) => setPassword(event.target.value)}
                autoComplete="current-password"
                placeholder="••••••••"
                required
              />
            </label>
            <button className="primary-button" disabled={busy || !client}>
              {busy ? "Перевіряємо…" : "Увійти до панелі"}
            </button>
            <p className="login-help">
              Використовуйте пароль адміністратора Supabase.
            </p>
            {error && <p className="error-message">{error}</p>}
          </form>
        </section>
      </main>
    );
  }

  return (
    <main className="dashboard-page">
      <aside className="sidebar">
        <Logo />
        <nav aria-label="Навігація">
          <a className="active" href="#overview">
            <span>⌁</span> Огляд
          </a>
          <a href="#geography">
            <span>⌖</span> Географія
          </a>
          <a href="#plans">
            <span>◇</span> Підписки
          </a>
        </nav>
        <div className="sidebar-footer">
          <span className="status-dot" />
          Дані захищені RLS
        </div>
      </aside>

      <section className="dashboard-content">
        <header className="dashboard-header">
          <div>
            <p className="eyebrow">Аналітика платформи</p>
            <h1>Огляд Lappo</h1>
            <p className="muted">
              {updatedAt
                ? `Оновлено ${updatedAt.toLocaleTimeString("uk-UA", {
                    hour: "2-digit",
                    minute: "2-digit",
                  })}`
                : "Актуальні показники"}
            </p>
          </div>
          <div className="header-actions">
            <button
              className="secondary-button"
              onClick={() => void loadDashboard()}
              disabled={busy}
            >
              {busy ? "Оновлюємо…" : "Оновити дані"}
            </button>
            <button className="text-button" onClick={() => void signOut()}>
              Вийти
            </button>
          </div>
        </header>

        {error && <p className="dashboard-error">{error}</p>}

        <section id="overview" className="metrics-grid" aria-live="polite">
          {metrics.map((metric) => (
            <article className={`metric-card ${metric.tone}`} key={metric.label}>
              <div className="metric-top">
                <span>{metric.label}</span>
                <i>{metric.icon}</i>
              </div>
              <strong>{metric.value}</strong>
              <small>{metric.hint}</small>
            </article>
          ))}
        </section>

        <section className="insight-strip">
          <div>
            <span className="insight-icon">↗</span>
            <div>
              <strong>Монетизація під контролем</strong>
              <p>
                Платними є лише перевірені сервером покупки. Події залишаються
                безкоштовними для всіх.
              </p>
            </div>
          </div>
          <span className="plan-chip">Free · Pro · Pro+</span>
        </section>

        <div className="panels-grid">
          <section id="geography" className="panel">
            <PanelHeading
              eyebrow="Географія"
              title="Клієнти за містами"
              note="Реальні профілі та активність"
            />
            <Table
              headings={["Місто", "Клієнти", "Тварини", "Оголошення"]}
              empty="Даних за містами поки немає"
            >
              {data.cities.map((row) => (
                <tr key={row.city}>
                  <td>
                    <span className="city-mark">{row.city.slice(0, 1)}</span>
                    {row.city || "Не вказано"}
                  </td>
                  <td>{number.format(row.users_count)}</td>
                  <td>{number.format(row.pets_count)}</td>
                  <td>{number.format(row.announcements_count)}</td>
                </tr>
              ))}
            </Table>
          </section>

          <section id="plans" className="panel">
            <PanelHeading
              eyebrow="Монетизація"
              title="Активні підписки"
              note="Місячні та річні плани"
            />
            <Table
              headings={["План", "Активні", "Місяць", "Рік"]}
              empty="Активних підписок поки немає"
            >
              {data.plans.map((row) => (
                <tr key={row.plan_code}>
                  <td>
                    <span className={`plan-dot ${row.plan_code}`} />
                    {planName(row.plan_code)}
                  </td>
                  <td>{number.format(row.active_subscriptions)}</td>
                  <td>{number.format(row.monthly_subscriptions)}</td>
                  <td>{number.format(row.yearly_subscriptions)}</td>
                </tr>
              ))}
            </Table>
          </section>
        </div>
      </section>
    </main>
  );
}

function Logo() {
  return (
    <div className="logo" aria-label="Lappo">
      <span className="logo-mark">L</span>
      <span>
        <strong>Lappo</strong>
        <small>Admin intelligence</small>
      </span>
    </div>
  );
}

function PanelHeading({
  eyebrow,
  title,
  note,
}: {
  eyebrow: string;
  title: string;
  note: string;
}) {
  return (
    <header className="panel-heading">
      <div>
        <p className="eyebrow">{eyebrow}</p>
        <h2>{title}</h2>
      </div>
      <small>{note}</small>
    </header>
  );
}

function Table({
  headings,
  children,
  empty,
}: {
  headings: string[];
  children: React.ReactNode;
  empty: string;
}) {
  const hasChildren = Array.isArray(children) ? children.length > 0 : Boolean(children);
  return (
    <div className="table-wrap">
      <table>
        <thead>
          <tr>
            {headings.map((heading) => (
              <th key={heading}>{heading}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {hasChildren ? (
            children
          ) : (
            <tr>
              <td className="empty-row" colSpan={headings.length}>
                {empty}
              </td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
}

function planName(code: string) {
  return { free: "Free", pro: "Pro", pro_plus: "Pro+" }[code] ?? code;
}
