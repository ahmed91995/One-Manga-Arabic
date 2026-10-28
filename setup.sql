-- Manga One database setup
-- Run this in Supabase Dashboard > SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.manga (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  english_title text,
  description text default '',
  cover_url text default '',
  genre text default 'أكشن',
  status text default 'مستمرة',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.chapters (
  id uuid primary key default gen_random_uuid(),
  manga_id uuid not null references public.manga(id) on delete cascade,
  chapter_number numeric not null,
  title text default '',
  created_at timestamptz not null default now(),
  unique(manga_id, chapter_number)
);

create table if not exists public.chapter_pages (
  id uuid primary key default gen_random_uuid(),
  chapter_id uuid not null references public.chapters(id) on delete cascade,
  page_number integer not null,
  image_url text not null,
  created_at timestamptz not null default now(),
  unique(chapter_id, page_number)
);

alter table public.manga enable row level security;
alter table public.chapters enable row level security;
alter table public.chapter_pages enable row level security;

-- Public can read published catalogue and chapters.
drop policy if exists "Public read manga" on public.manga;
create policy "Public read manga" on public.manga for select using (true);
drop policy if exists "Public read chapters" on public.chapters;
create policy "Public read chapters" on public.chapters for select using (true);
drop policy if exists "Public read pages" on public.chapter_pages;
create policy "Public read pages" on public.chapter_pages for select using (true);

-- Writes require a signed-in Supabase user. For production, create an admin user
-- in Supabase Auth and use only that account for content management.
drop policy if exists "Signed-in manage manga" on public.manga;
create policy "Signed-in manage manga" on public.manga for all to authenticated using (true) with check (true);
drop policy if exists "Signed-in manage chapters" on public.chapters;
create policy "Signed-in manage chapters" on public.chapters for all to authenticated using (true) with check (true);
drop policy if exists "Signed-in manage pages" on public.chapter_pages;
create policy "Signed-in manage pages" on public.chapter_pages for all to authenticated using (true) with check (true);

-- Storage bucket for covers and chapter pages.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('manga-images', 'manga-images', true, 15728640, array['image/jpeg','image/png','image/webp','image/avif'])
on conflict (id) do nothing;

drop policy if exists "Public view manga images" on storage.objects;
create policy "Public view manga images" on storage.objects for select using (bucket_id = 'manga-images');
drop policy if exists "Signed-in upload manga images" on storage.objects;
create policy "Signed-in upload manga images" on storage.objects for insert to authenticated with check (bucket_id = 'manga-images');
drop policy if exists "Signed-in update manga images" on storage.objects;
create policy "Signed-in update manga images" on storage.objects for update to authenticated using (bucket_id = 'manga-images') with check (bucket_id = 'manga-images');
drop policy if exists "Signed-in delete manga images" on storage.objects;
create policy "Signed-in delete manga images" on storage.objects for delete to authenticated using (bucket_id = 'manga-images');
