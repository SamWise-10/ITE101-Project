-- ════════════════════════════════════════════════════════════════════════
--  TDLF-Educ · Supabase schema
--  Run this ONCE in your Supabase project: Dashboard → SQL Editor → New query
--  → paste everything → Run.
--
--  It is safe to re-run (uses IF NOT EXISTS / CREATE OR REPLACE / drop+create
--  for policies and the trigger).
-- ════════════════════════════════════════════════════════════════════════

-- ── 1. TABLES ───────────────────────────────────────────────────────────────

-- Profile data that extends Supabase Auth's built-in `auth.users`.
create table if not exists public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  username    text unique,
  full_name   text default '',
  email       text,
  role        text default 'Student',   -- Student | Teacher | Guest
  course      text default '',
  student_id  text default '',
  grade_level text default '',
  created_at  timestamptz default now()
);

create table if not exists public.books (
  book_id      uuid primary key default gen_random_uuid(),
  book_name    text not null,
  link         text not null,           -- direct PDF URL
  book_picture text default '',
  course_id    text default '',
  created_at   timestamptz default now()
);

create table if not exists public.quizzes (
  quiz_id        uuid primary key default gen_random_uuid(),
  question       text not null,
  quiz_type      text not null,         -- multiple_choice | true_false | fill_blank | enumeration | open_ended
  correct_answer text not null,
  reason         text default '',
  course_id      text default '',
  options        jsonb,                 -- choices for multiple_choice questions
  created_at     timestamptz default now()
);
-- For projects created before the `options` column existed:
alter table public.quizzes add column if not exists options jsonb;

create table if not exists public.quiz_results (
  id              uuid primary key default gen_random_uuid(),
  student_id      uuid references auth.users(id) on delete cascade,
  student_name    text,
  score           numeric,
  total_questions int,
  passed          boolean,
  course_id       text default '',   -- which course this attempt was for
  submitted_at    timestamptz default now()
);
-- For projects created before the `course_id` column existed:
alter table public.quiz_results add column if not exists course_id text default '';

-- Per-question attempts (the "History" tab). Stored in the cloud so a student's
-- history follows their account across devices / the embedded app.
create table if not exists public.quiz_attempts (
  id           uuid primary key default gen_random_uuid(),
  student_id   uuid references auth.users(id) on delete cascade,
  quiz_id      text,
  user_answer  text,
  is_correct   boolean,
  submitted_at timestamptz default now()
);

-- Optional: courses (the app also has these IDs hard-coded as a fallback)
create table if not exists public.courses (
  id          text primary key,
  title       text not null,
  created_at  timestamptz default now()
);
insert into public.courses (id, title) values
  ('course-001', 'Computer Fundamentals'),
  ('course-002', 'Basic Mathematics'),
  ('course-003', 'Science and Technology'),
  ('course-004', 'English Communication')
on conflict (id) do nothing;

-- ── 2. AUTO-CREATE A PROFILE ON SIGN-UP ─────────────────────────────────────
-- Reads the metadata sent from the Flutter app (auth.signUp `data:`).

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  base_username  text := coalesce(
                           nullif(new.raw_user_meta_data->>'username', ''),
                           split_part(new.email, '@', 1));
  final_username text := base_username;
  suffix         int  := 0;
begin
  -- Guarantee a unique username so a collision never blocks sign-up
  -- (Supabase otherwise hides it as a vague "Database error saving new user").
  while exists (select 1 from public.profiles where username = final_username) loop
    suffix := suffix + 1;
    final_username := base_username || suffix::text;
  end loop;

  insert into public.profiles
    (id, email, username, full_name, role, course, student_id, grade_level)
  values (
    new.id,
    new.email,
    final_username,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    coalesce(new.raw_user_meta_data->>'role', 'Student'),
    coalesce(new.raw_user_meta_data->>'course', ''),
    coalesce(new.raw_user_meta_data->>'student_id', ''),
    coalesce(new.raw_user_meta_data->>'grade_level', '')
  );
  return new;
exception when others then
  -- Last-resort safety net: never let a profile hiccup abort account creation.
  insert into public.profiles (id, email, username)
    values (new.id, new.email, new.id::text)
    on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ── 3. ROW LEVEL SECURITY ───────────────────────────────────────────────────

alter table public.profiles     enable row level security;
alter table public.books        enable row level security;
alter table public.quizzes      enable row level security;
alter table public.quiz_results enable row level security;
alter table public.courses      enable row level security;

-- PROFILES: any signed-in user can read (faculty/student lists); edit only your own.
drop policy if exists "profiles readable" on public.profiles;
create policy "profiles readable" on public.profiles
  for select to authenticated using (true);

drop policy if exists "update own profile" on public.profiles;
create policy "update own profile" on public.profiles
  for update to authenticated using (auth.uid() = id);

-- COURSES: readable by anyone signed in; only Teachers can add/edit/delete.
drop policy if exists "courses readable" on public.courses;
create policy "courses readable" on public.courses
  for select to authenticated using (true);

drop policy if exists "teachers manage courses" on public.courses;
create policy "teachers manage courses" on public.courses
  for all to authenticated
  using      ((select role from public.profiles where id = auth.uid()) = 'Teacher')
  with check ((select role from public.profiles where id = auth.uid()) = 'Teacher');

-- BOOKS: everyone signed in reads; only Teachers write.
drop policy if exists "books readable" on public.books;
create policy "books readable" on public.books
  for select to authenticated using (true);

drop policy if exists "teachers manage books" on public.books;
create policy "teachers manage books" on public.books
  for all to authenticated
  using      ((select role from public.profiles where id = auth.uid()) = 'Teacher')
  with check ((select role from public.profiles where id = auth.uid()) = 'Teacher');

-- QUIZZES: everyone signed in reads; only Teachers write.
drop policy if exists "quizzes readable" on public.quizzes;
create policy "quizzes readable" on public.quizzes
  for select to authenticated using (true);

drop policy if exists "teachers manage quizzes" on public.quizzes;
create policy "teachers manage quizzes" on public.quizzes
  for all to authenticated
  using      ((select role from public.profiles where id = auth.uid()) = 'Teacher')
  with check ((select role from public.profiles where id = auth.uid()) = 'Teacher');

-- QUIZ RESULTS: a student inserts/reads their own; teachers read everyone's.
drop policy if exists "insert own result" on public.quiz_results;
create policy "insert own result" on public.quiz_results
  for insert to authenticated with check (auth.uid() = student_id);

drop policy if exists "read results" on public.quiz_results;
create policy "read results" on public.quiz_results
  for select to authenticated using (
    auth.uid() = student_id
    or (select role from public.profiles where id = auth.uid()) = 'Teacher'
  );

-- QUIZ ATTEMPTS (per-question history): a student inserts/reads their own.
alter table public.quiz_attempts enable row level security;

drop policy if exists "insert own attempt" on public.quiz_attempts;
create policy "insert own attempt" on public.quiz_attempts
  for insert to authenticated with check (auth.uid() = student_id);

drop policy if exists "read own attempts" on public.quiz_attempts;
create policy "read own attempts" on public.quiz_attempts
  for select to authenticated using (
    auth.uid() = student_id
    or (select role from public.profiles where id = auth.uid()) = 'Teacher'
  );

-- ── 4. ITE103 INTEGRATION (Tawi-Tawi backend-to-backend handshake) ──────────
-- Lets another backend (the central Tawi-Tawi Express API) read this app's
-- PUBLIC catalog over Supabase's REST API using only the public anon key:
--   GET https://<project>.supabase.co/rest/v1/books?select=*
--   headers: apikey: <anon key>, Authorization: Bearer <anon key>
-- Only public educational content is exposed. Student results / profiles stay
-- protected (no anon policy), so no private data leaks.
drop policy if exists "anon read books" on public.books;
create policy "anon read books" on public.books
  for select to anon using (true);

drop policy if exists "anon read quizzes" on public.quizzes;
create policy "anon read quizzes" on public.quizzes
  for select to anon using (true);

drop policy if exists "anon read courses" on public.courses;
create policy "anon read courses" on public.courses
  for select to anon using (true);

-- ════════════════════════════════════════════════════════════════════════
--  After running this:
--  → Authentication → Sign In / Providers → Email → turn OFF "Confirm email"
--    (so new accounts can sign in immediately during development).
-- ════════════════════════════════════════════════════════════════════════
