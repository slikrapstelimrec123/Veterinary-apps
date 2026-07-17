# Lappo Mobile

Flutter-застосунок для власників тварин. Основні сценарії: профіль тварини, самостійні медичні записи, документи, препарати, харчування, події, сповіщення, оголошення та передача тварини.

## Локальний запуск

```powershell
flutter pub get
flutter run `
  --dart-define=SUPABASE_URL=https://your-project.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

У застосунок можна передавати лише публічний Supabase anon key. `service_role` є серверним секретом і не повинен потрапляти в мобільну збірку.

## Перевірка

```powershell
flutter analyze
flutter test
```

Перед релізом перевірте реальні сценарії авторизації, RLS, приватні файли, експорт даних і видалення акаунта на фізичному пристрої.
