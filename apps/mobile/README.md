# Lappo Mobile

Flutter-приложение Lappo для владельцев домашних животных. Основные сценарии: профиль и медицинская карта животного, история визитов, документы, клиники, записи и уведомления.

## Локальный запуск

Без настроенного Supabase приложение автоматически использует демонстрационные данные:

```powershell
C:\flutter\bin\flutter.bat run
```

Для подключения Supabase передайте публичные параметры проекта:

```powershell
C:\flutter\bin\flutter.bat run `
  --dart-define=SUPABASE_URL=https://your-project.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

На Windows можно скопировать `.env.example` в локальный `.env`, заполнить два значения и запустить `run_with_supabase.bat`.

Секретный `service_role` ключ нельзя добавлять в приложение или `.env`.

## Проверка качества

```powershell
C:\flutter\bin\flutter.bat analyze --no-pub
C:\flutter\bin\flutter.bat test --no-pub
```

Перед релизом также нужно проверить реальные Supabase/RLS-сценарии, сборку на физическом iPhone и архивирование в Xcode на macOS.
