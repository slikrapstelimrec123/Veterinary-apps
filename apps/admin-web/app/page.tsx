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

type UserRow = {
  user_id: string;
  email: string;
  full_name: string;
  phone: string | null;
  city: string | null;
  created_at: string;
  role: string;
  pet_count: number;
  visit_count: number;
  document_count: number;
  announcement_count: number;
  active_announcement_count: number;
  plan_code: string;
  plan_status: string;
  plan_end: string | null;
  available_listing_credits: number;
  standard_listing_credits: number;
  top_7_listing_credits: number;
  top_15_listing_credits: number;
  is_banned: boolean;
};

type AnnouncementRow = {
  announcement_id: string;
  owner_id: string;
  owner_email: string;
  owner_name: string;
  announcement_type: string;
  title: string;
  summary: string | null;
  city: string | null;
  status: string;
  moderation_status: string;
  publication_tier: string;
  publication_source: string | null;
  view_count: number;
  created_at: string;
  publication_expires_at: string | null;
  details: Record<string, unknown>;
};

type DashboardData = {
  overview: Overview;
  cities: CityRow[];
  plans: PlanRow[];
  users: UserRow[];
  announcements: AnnouncementRow[];
};

type AuthMode = "login" | "request-reset" | "set-password";
type DashboardView =
  | "overview"
  | "users"
  | "announcements"
  | "geography"
  | "plans";

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
  const [newPassword, setNewPassword] = useState("");
  const [authMode, setAuthMode] = useState<AuthMode>("login");
  const [busy, setBusy] = useState(true);
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");
  const [updatedAt, setUpdatedAt] = useState<Date | null>(null);
  const [dashboardView, setDashboardView] =
    useState<DashboardView>("overview");
  const [userSearch, setUserSearch] = useState("");
  const [announcementSearch, setAnnouncementSearch] = useState("");
  const [selectedAnnouncementId, setSelectedAnnouncementId] = useState<
    string | null
  >(null);
  const [selectedUserId, setSelectedUserId] = useState<string | null>(null);
  const [actionBusy, setActionBusy] = useState(false);
  const [actionMessage, setActionMessage] = useState("");
  const [data, setData] = useState<DashboardData>({
    overview: emptyOverview,
    cities: [],
    plans: [],
    users: [],
    announcements: [],
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
            // handles only its own explicit PKCE recovery code, so Supabase
            // must never consume that token as a session automatically.
            detectSessionInUrl: false,
            flowType: "pkce",
          },
        });
        if (!active) return;
        setClient(supabase);
        const params = new URLSearchParams(window.location.search);
        const recoveryCode = params.get("code");
        const isRecovery = params.get("recovery") === "1";
        if (isRecovery && recoveryCode) {
          return supabase.auth
            .exchangeCodeForSession(recoveryCode)
            .then(({ error: recoveryError }) => {
              if (!active) return;
              if (recoveryError) {
                setError(
                  "Посилання для відновлення недійсне або вже використане. Запросіть нове.",
                );
                setAuthMode("request-reset");
              } else {
                setAuthMode("set-password");
              }
              window.history.replaceState(
                {},
                document.title,
                `${window.location.pathname}${window.location.hash}`,
              );
              setBusy(false);
            });
        }
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
    const [overview, cities, plans, users, announcements] = await Promise.all([
      client.rpc("admin_dashboard_overview"),
      client.rpc("admin_city_analytics"),
      client.rpc("admin_plan_analytics"),
      client.rpc("admin_user_analytics"),
      client.rpc("admin_announcement_analytics"),
    ]);
    const failures = [
      ["overview", overview.error],
      ["cities", cities.error],
      ["plans", plans.error],
      ["users", users.error],
      ["announcements", announcements.error],
    ].filter((entry) => entry[1]);

    setData({
      overview: overview.error
        ? emptyOverview
        : ((overview.data ?? emptyOverview) as Overview),
      cities: cities.error ? [] : ((cities.data ?? []) as CityRow[]),
      plans: plans.error ? [] : ((plans.data ?? []) as PlanRow[]),
      users: users.error ? [] : ((users.data ?? []) as UserRow[]),
      announcements: announcements.error
        ? []
        : ((announcements.data ?? []) as AnnouncementRow[]),
    });
    setUpdatedAt(new Date());

    if (failures.length > 0) {
      const details = failures
        .map(([name, failure]) => {
          const code =
            typeof failure === "object" && failure && "code" in failure
              ? String(failure.code)
              : "UNKNOWN";
          return `${name}: ${code}`;
        })
        .join(", ");
      setError(
        `Не вдалося завантажити частину аналітики (${details}). Оновіть сторінку після застосування міграцій бази.`,
      );
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
        setData({
          overview: emptyOverview,
          cities: [],
          plans: [],
          users: [],
          announcements: [],
        });
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
    setNotice("");
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

  async function requestPasswordReset(event: FormEvent) {
    event.preventDefault();
    if (!client) return;
    setBusy(true);
    setError("");
    setNotice("");
    const { error: resetError } = await client.auth.resetPasswordForEmail(
      email.trim(),
      {
        redirectTo: `${window.location.origin}/?recovery=1`,
      },
    );
    if (resetError) {
      setError("Не вдалося надіслати лист. Перевірте адресу та спробуйте ще раз.");
    } else {
      setNotice(
        "Лист надіслано. Відкрийте його в цьому браузері та перейдіть за посиланням.",
      );
    }
    setBusy(false);
  }

  async function saveNewPassword(event: FormEvent) {
    event.preventDefault();
    if (!client) return;
    if (newPassword.length < 10) {
      setError("Новий пароль має містити щонайменше 10 символів.");
      return;
    }
    setBusy(true);
    setError("");
    setNotice("");
    const { error: updateError } = await client.auth.updateUser({
      password: newPassword,
    });
    if (updateError) {
      setError("Не вдалося встановити пароль. Запросіть нове посилання.");
      setBusy(false);
      return;
    }
    await client.auth.signOut();
    setSignedIn(false);
    setNewPassword("");
    setAuthMode("login");
    setNotice("Пароль встановлено. Тепер увійдіть із новим паролем.");
    setBusy(false);
  }

  const filteredUsers = useMemo(() => {
    const query = userSearch.trim().toLocaleLowerCase("uk-UA");
    if (!query) return data.users;
    return data.users.filter((user) =>
      [user.full_name, user.email, user.phone, user.city]
        .filter(Boolean)
        .some((value) =>
          String(value).toLocaleLowerCase("uk-UA").includes(query),
        ),
    );
  }, [data.users, userSearch]);

  const filteredAnnouncements = useMemo(() => {
    const query = announcementSearch.trim().toLocaleLowerCase("uk-UA");
    if (!query) return data.announcements;
    return data.announcements.filter((announcement) =>
      [
        announcement.title,
        announcement.summary,
        announcement.city,
        announcement.owner_name,
        announcement.owner_email,
        announcementTypeName(announcement.announcement_type),
      ]
        .filter(Boolean)
        .some((value) =>
          String(value).toLocaleLowerCase("uk-UA").includes(query),
        ),
    );
  }, [announcementSearch, data.announcements]);

  async function runUserAction(
    userId: string,
    rpc:
      | "admin_set_user_banned"
      | "admin_set_owner_plan"
      | "admin_grant_listing_credit"
      | "admin_revoke_listing_credit",
    params: Record<string, string | number | boolean>,
    successMessage: string,
  ) {
    if (!client) return;
    setSelectedUserId(userId);
    setActionBusy(true);
    setActionMessage("");
    setError("");
    const { error: actionError } = await client.rpc(rpc, params);
    if (actionError) {
      setError("Не вдалося виконати дію. Перевірте права адміністратора.");
    } else {
      setActionMessage(successMessage);
      await loadDashboard();
    }
    setActionBusy(false);
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

  if (authMode === "set-password") {
    return (
      <main className="auth-page">
        <div className="ambient ambient-one" />
        <div className="ambient ambient-two" />
        <section className="auth-shell">
          <div className="auth-story">
            <Logo />
            <span className="private-badge">Внутрішній простір</span>
            <h1>Створіть новий пароль адміністратора.</h1>
            <p>
              Пароль захистить окремий вхід до аналітики Lappo.
            </p>
          </div>
          <form className="login-card" onSubmit={saveNewPassword}>
            <p className="eyebrow">Відновлення доступу</p>
            <h2>Новий пароль</h2>
            <p className="muted">Використайте щонайменше 10 символів.</p>
            <label>
              Новий пароль
              <input
                type="password"
                value={newPassword}
                onChange={(event) => setNewPassword(event.target.value)}
                autoComplete="new-password"
                minLength={10}
                required
              />
            </label>
            <button className="primary-button" disabled={busy || !client}>
              {busy ? "Зберігаємо…" : "Встановити пароль"}
            </button>
            {error && <p className="error-message">{error}</p>}
          </form>
        </section>
      </main>
    );
  }

  if (!signedIn) {
    const requestingReset = authMode === "request-reset";
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
          <form
            className="login-card"
            onSubmit={requestingReset ? requestPasswordReset : signIn}
          >
            <p className="eyebrow">
              {requestingReset ? "Відновлення доступу" : "Захищений вхід"}
            </p>
            <h2>{requestingReset ? "Створити пароль" : "Панель керування"}</h2>
            <p className="muted">
              {requestingReset
                ? "Ми надішлемо захищене посилання на вашу пошту."
                : "Увійдіть під обліковим записом адміністратора."}
            </p>
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
            {!requestingReset && (
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
            )}
            <button className="primary-button" disabled={busy || !client}>
              {busy
                ? "Зачекайте…"
                : requestingReset
                  ? "Надіслати лист"
                  : "Увійти до панелі"}
            </button>
            <button
              className="auth-link"
              type="button"
              onClick={() => {
                setAuthMode(requestingReset ? "login" : "request-reset");
                setError("");
                setNotice("");
              }}
              disabled={busy}
            >
              {requestingReset ? "Повернутися до входу" : "Забули пароль?"}
            </button>
            {notice && <p className="success-message">{notice}</p>}
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
          <button
            type="button"
            className={dashboardView === "overview" ? "active" : ""}
            aria-current={dashboardView === "overview" ? "page" : undefined}
            onClick={() => setDashboardView("overview")}
          >
            <span>⌁</span> Огляд
          </button>
          <button
            type="button"
            className={dashboardView === "users" ? "active" : ""}
            aria-current={dashboardView === "users" ? "page" : undefined}
            onClick={() => setDashboardView("users")}
          >
            <span>◎</span> Користувачі
          </button>
          <button
            type="button"
            className={dashboardView === "announcements" ? "active" : ""}
            aria-current={
              dashboardView === "announcements" ? "page" : undefined
            }
            onClick={() => setDashboardView("announcements")}
          >
            <span>▤</span> Публікації
          </button>
          <button
            type="button"
            className={dashboardView === "geography" ? "active" : ""}
            aria-current={dashboardView === "geography" ? "page" : undefined}
            onClick={() => setDashboardView("geography")}
          >
            <span>⌖</span> Географія
          </button>
          <button
            type="button"
            className={dashboardView === "plans" ? "active" : ""}
            aria-current={dashboardView === "plans" ? "page" : undefined}
            onClick={() => setDashboardView("plans")}
          >
            <span>◇</span> Підписки
          </button>
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

        {dashboardView === "overview" && (
          <>
        <section className="metrics-grid" aria-live="polite">
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
          </>
        )}

        {dashboardView === "users" && (
          <div className="panels-grid single-panel">
            <section className="panel">
              <PanelHeading
                eyebrow="Користувачі"
                title="Клієнти та доступи"
                note="Тарифи, тварини, оголошення й адміністративні дії"
              />
              <div className="users-toolbar">
                <label className="user-search">
                  <span>Пошук</span>
                  <input
                    type="search"
                    placeholder="Ім’я, email, телефон або місто"
                    value={userSearch}
                    onChange={(event) => setUserSearch(event.target.value)}
                  />
                </label>
                <span className="users-total">
                  {number.format(filteredUsers.length)} користувачів
                </span>
              </div>
              {actionMessage && (
                <p className="action-success" role="status">
                  {actionMessage}
                </p>
              )}
              <div className="users-list">
                {filteredUsers.length === 0 ? (
                  <p className="users-empty">Користувачів не знайдено.</p>
                ) : (
                  filteredUsers.map((user) => {
                    const expanded = selectedUserId === user.user_id;
                    return (
                      <article
                        className={`user-card ${user.is_banned ? "banned" : ""}`}
                        key={user.user_id}
                      >
                        <button
                          type="button"
                          className="user-summary"
                          aria-expanded={expanded}
                          onClick={() =>
                            setSelectedUserId(expanded ? null : user.user_id)
                          }
                        >
                          <span className="user-avatar">
                            {(user.full_name || user.email)
                              .slice(0, 1)
                              .toUpperCase()}
                          </span>
                          <span className="user-identity">
                            <strong>{user.full_name || "Без імені"}</strong>
                            <small>{user.email}</small>
                          </span>
                          <span className="user-stat">
                            <strong>{number.format(user.pet_count)}</strong>
                            <small>тварин</small>
                          </span>
                          <span className="user-stat">
                            <strong>
                              {number.format(user.announcement_count)}
                            </strong>
                            <small>оголошень</small>
                          </span>
                          <span className={`user-plan ${user.plan_code}`}>
                            {planName(user.plan_code)}
                          </span>
                          <span
                            className={`user-state ${
                              user.is_banned ? "blocked" : ""
                            }`}
                          >
                            {user.role === "platform_admin"
                              ? "Адміністратор"
                              : user.is_banned
                                ? "Заблокований"
                                : "Активний"}
                          </span>
                          <span className="user-chevron">⌄</span>
                        </button>

                        {expanded && (
                          <div className="user-details">
                            <dl className="user-facts">
                              <div>
                                <dt>Місто</dt>
                                <dd>{user.city || "Не вказано"}</dd>
                              </div>
                              <div>
                                <dt>Телефон</dt>
                                <dd>{user.phone || "Не вказано"}</dd>
                              </div>
                              <div>
                                <dt>Прийоми</dt>
                                <dd>{number.format(user.visit_count)}</dd>
                              </div>
                              <div>
                                <dt>Документи</dt>
                                <dd>{number.format(user.document_count)}</dd>
                              </div>
                              <div>
                                <dt>Активні оголошення</dt>
                                <dd>
                                  {number.format(
                                    user.active_announcement_count,
                                  )}
                                </dd>
                              </div>
                              <div>
                                <dt>Усього подарованих</dt>
                                <dd>
                                  {number.format(
                                    user.available_listing_credits,
                                  )}
                                </dd>
                              </div>
                              <div>
                                <dt>Звичайні</dt>
                                <dd>
                                  {number.format(
                                    user.standard_listing_credits,
                                  )}
                                </dd>
                              </div>
                              <div>
                                <dt>TOP 7</dt>
                                <dd>
                                  {number.format(user.top_7_listing_credits)}
                                </dd>
                              </div>
                              <div>
                                <dt>TOP 15</dt>
                                <dd>
                                  {number.format(user.top_15_listing_credits)}
                                </dd>
                              </div>
                            </dl>

                            {user.role === "platform_admin" ? (
                              <p className="protected-admin-note">
                                Це захищений обліковий запис адміністратора.
                                Керування тарифом, публікаціями та блокування
                                недоступне.
                              </p>
                            ) : (
                            <div className="admin-actions">
                              <label>
                                Тариф на 30 днів
                                <select
                                  value={user.plan_code}
                                  disabled={actionBusy}
                                  onChange={(event) =>
                                    void runUserAction(
                                      user.user_id,
                                      "admin_set_owner_plan",
                                      {
                                        target_user_id: user.user_id,
                                        target_plan_code: event.target.value,
                                        target_duration_days: 30,
                                      },
                                      `Тариф для ${user.full_name} оновлено.`,
                                    )
                                  }
                                >
                                  <option value="free">Free</option>
                                  <option value="pro">Pro</option>
                                  <option value="pro_plus">Pro+</option>
                                </select>
                              </label>
                              <div className="credit-actions">
                                <span>Подаровані публікації</span>
                                {[
                                  {
                                    tier: "standard",
                                    label: "Звичайна",
                                    count: user.standard_listing_credits,
                                  },
                                  {
                                    tier: "top_7",
                                    label: "TOP 7",
                                    count: user.top_7_listing_credits,
                                  },
                                  {
                                    tier: "top_15",
                                    label: "TOP 15",
                                    count: user.top_15_listing_credits,
                                  },
                                ].map((credit) => (
                                  <div
                                    className="credit-control"
                                    key={credit.tier}
                                  >
                                    <strong>{credit.label}</strong>
                                    <small>{number.format(credit.count)}</small>
                                    <button
                                      type="button"
                                      className="credit-minus"
                                      aria-label={`Прибрати ${credit.label}`}
                                      title={`Прибрати останню подаровану публікацію ${credit.label}`}
                                      disabled={actionBusy || credit.count < 1}
                                      onClick={() => {
                                        const confirmed = window.confirm(
                                          `Прибрати одну доступну публікацію «${credit.label}» у ${user.full_name}? Придбані користувачем публікації не буде змінено.`,
                                        );
                                        if (!confirmed) return;
                                        void runUserAction(
                                          user.user_id,
                                          "admin_revoke_listing_credit",
                                          {
                                            target_user_id: user.user_id,
                                            target_tier: credit.tier,
                                          },
                                          `Публікацію ${credit.label} прибрано у ${user.full_name}.`,
                                        );
                                      }}
                                    >
                                      −
                                    </button>
                                    <button
                                      type="button"
                                      className="credit-plus"
                                      aria-label={`Додати ${credit.label}`}
                                      title={`Подарувати публікацію ${credit.label}`}
                                      disabled={actionBusy}
                                      onClick={() =>
                                        void runUserAction(
                                          user.user_id,
                                          "admin_grant_listing_credit",
                                          {
                                            target_user_id: user.user_id,
                                            target_tier: credit.tier,
                                          },
                                          `Публікацію ${credit.label} додано для ${user.full_name}.`,
                                        )
                                      }
                                    >
                                      +
                                    </button>
                                  </div>
                                ))}
                              </div>
                              <button
                                type="button"
                                className={
                                  user.is_banned
                                    ? "account-action unblock"
                                    : "account-action block"
                                }
                                disabled={actionBusy}
                                onClick={() => {
                                  const confirmed =
                                    user.is_banned ||
                                    window.confirm(
                                      `Заблокувати доступ для ${user.full_name}?`,
                                    );
                                  if (!confirmed) return;
                                  void runUserAction(
                                    user.user_id,
                                    "admin_set_user_banned",
                                    {
                                      target_user_id: user.user_id,
                                      target_banned: !user.is_banned,
                                    },
                                    user.is_banned
                                      ? `Доступ для ${user.full_name} відновлено.`
                                      : `${user.full_name} заблоковано.`,
                                  );
                                }}
                              >
                                {user.is_banned
                                  ? "Розблокувати"
                                  : "Заблокувати"}
                              </button>
                            </div>
                            )}
                          </div>
                        )}
                      </article>
                    );
                  })
                )}
              </div>
            </section>
          </div>
        )}

        {dashboardView === "announcements" && (
          <div className="panels-grid single-panel">
            <section className="panel">
              <PanelHeading
                eyebrow="Публікації"
                title="Оголошення клієнтів"
                note="Вміст, статус, термін і перегляди"
              />
              <div className="users-toolbar">
                <label className="user-search">
                  <span>Пошук</span>
                  <input
                    type="search"
                    placeholder="Назва, власник, місто або тип"
                    value={announcementSearch}
                    onChange={(event) =>
                      setAnnouncementSearch(event.target.value)
                    }
                  />
                </label>
                <span className="users-total">
                  {number.format(filteredAnnouncements.length)} публікацій
                </span>
              </div>
              <div className="announcement-list">
                {filteredAnnouncements.length === 0 ? (
                  <p className="users-empty">Публікацій не знайдено.</p>
                ) : (
                  filteredAnnouncements.map((announcement) => {
                    const expanded =
                      selectedAnnouncementId === announcement.announcement_id;
                    return (
                      <article
                        className="announcement-card"
                        key={announcement.announcement_id}
                      >
                        <button
                          type="button"
                          className="announcement-summary"
                          aria-expanded={expanded}
                          onClick={() =>
                            setSelectedAnnouncementId(
                              expanded ? null : announcement.announcement_id,
                            )
                          }
                        >
                          <span className="announcement-kind">
                            {announcementTypeName(
                              announcement.announcement_type,
                            )}
                          </span>
                          <span className="announcement-main">
                            <strong>{announcement.title}</strong>
                            <small>
                              {announcement.owner_name ||
                                announcement.owner_email}
                              {announcement.city
                                ? ` · ${announcement.city}`
                                : ""}
                            </small>
                          </span>
                          <span className="announcement-meta">
                            <strong>
                              {number.format(announcement.view_count)}
                            </strong>
                            <small>переглядів</small>
                          </span>
                          <span
                            className={`publication-status ${announcement.status}`}
                          >
                            {announcementStatusName(announcement.status)}
                          </span>
                          <span className="publication-tier">
                            {listingTierName(announcement.publication_tier)}
                          </span>
                          <span className="user-chevron">⌄</span>
                        </button>
                        {expanded && (
                          <div className="announcement-details">
                            {announcement.summary && (
                              <p className="announcement-description">
                                {announcement.summary}
                              </p>
                            )}
                            <dl className="publication-facts">
                              <div>
                                <dt>Власник</dt>
                                <dd>{announcement.owner_name || "Без імені"}</dd>
                                <small>{announcement.owner_email}</small>
                              </div>
                              <div>
                                <dt>Створено</dt>
                                <dd>
                                  {formatDateTime(announcement.created_at)}
                                </dd>
                              </div>
                              <div>
                                <dt>Діє до</dt>
                                <dd>
                                  {announcement.publication_expires_at
                                    ? formatDateTime(
                                        announcement.publication_expires_at,
                                      )
                                    : "Не обмежено"}
                                </dd>
                              </div>
                              <div>
                                <dt>Модерація</dt>
                                <dd>
                                  {moderationStatusName(
                                    announcement.moderation_status,
                                  )}
                                </dd>
                              </div>
                              {Object.entries(announcement.details).map(
                                ([key, value]) => (
                                  <div key={key}>
                                    <dt>{announcementFieldName(key)}</dt>
                                    <dd>{formatAnnouncementValue(value)}</dd>
                                  </div>
                                ),
                              )}
                            </dl>
                          </div>
                        )}
                      </article>
                    );
                  })
                )}
              </div>
            </section>
          </div>
        )}

        {dashboardView === "geography" && (
        <div className="panels-grid single-panel">
          <section className="panel">
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
        </div>
        )}

        {dashboardView === "plans" && (
        <div className="panels-grid single-panel">
          <section className="panel">
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
        )}
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

function announcementTypeName(type: string) {
  return (
    {
      breeding: "Пошук партнера",
      sale: "Цуценята",
      event: "Подія",
      service: "Послуга",
      offer: "Пропозиція",
    }[type] ?? type
  );
}

function announcementStatusName(status: string) {
  return { active: "Активна", inactive: "В архіві" }[status] ?? status;
}

function moderationStatusName(status: string) {
  return (
    { published: "Опубліковано", review: "На перевірці", blocked: "Заблоковано" }[
      status
    ] ?? status
  );
}

function listingTierName(tier: string) {
  return { standard: "Звичайна", top_7: "TOP 7", top_15: "TOP 15" }[tier] ?? tier;
}

function announcementFieldName(field: string) {
  return (
    {
      pet_name: "Тварина",
      breed: "Порода",
      gender: "Стать",
      birth_date: "Дата народження",
      price_amount: "Ціна",
      desired_breed: "Бажана порода",
      address: "Адреса",
      event_date: "Дата події",
      service_category: "Тип послуги",
      offer_category: "Тип пропозиції",
      website: "Сайт",
      offer_text: "Пропозиція",
      valid_from: "Початок дії",
      valid_until: "Кінець дії",
      promo_code: "Промокод",
      contact_name: "Контактна особа",
      contact_phone: "Телефон",
      contact_info: "Контакти",
    }[field] ?? field
  );
}

function formatAnnouncementValue(value: unknown) {
  if (typeof value === "boolean") return value ? "Так" : "Ні";
  if (typeof value === "number") return number.format(value);
  return String(value);
}

function formatDateTime(value: string) {
  return new Intl.DateTimeFormat("uk-UA", {
    dateStyle: "medium",
    timeStyle: "short",
  }).format(new Date(value));
}
