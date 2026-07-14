@echo off
setlocal

if exist .env (
  for /f "usebackq tokens=1,* delims==" %%A in (".env") do (
    if not "%%A"=="" set "%%A=%%B"
  )
)

if not defined SUPABASE_URL (
  echo SUPABASE_URL is missing. Copy .env.example to .env and fill it in.
  exit /b 1
)

if not defined SUPABASE_ANON_KEY (
  echo SUPABASE_ANON_KEY is missing. Copy .env.example to .env and fill it in.
  exit /b 1
)

C:\flutter\bin\flutter run ^
  --dart-define=SUPABASE_URL=%SUPABASE_URL% ^
  --dart-define=SUPABASE_ANON_KEY=%SUPABASE_ANON_KEY%

endlocal
