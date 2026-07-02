@echo off
set SUPABASE_URL=https://krtjhmqiaelspjxtdfqu.supabase.co
set SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtydGpobXFpYWVsc3BqeHRkZnF1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI3MzM5MjMsImV4cCI6MjA5ODMwOTkyM30.Z3rqIqDJEeJz5d5J3yoj-ICB1-zuM2rMXq8U5GaWjeA

C:\flutter\bin\flutter run ^
  --dart-define=SUPABASE_URL=%SUPABASE_URL% ^
  --dart-define=SUPABASE_ANON_KEY=%SUPABASE_ANON_KEY%
