# D K Rai Newspaper Agency (डी के राय न्यूजपेपर एजेंसी) — Flutter App

An offline-first mobile and web application built with **Flutter (Dart)** for **D K Rai Newspaper Agency** to manage daily distribution lists according to **Started (चालू)** and **Paused (बंद)** papers, morning depot pickups, monthly society billing, and **Free Cloud Database Sync (Supabase PostgreSQL)**.

## Key Features
- **Free Cloud Database (Supabase PostgreSQL)**:
  - Connects to Supabase free cloud tier (500MB PostgreSQL, 50k MAU, zero credit card needed).
  - Two-way sync: Download latest records from cloud, upload offline local changes.
  - Auto-sync: Automatically pushes delivery updates and pause/resume changes to the cloud when online.
  - Built-in SQL setup generator and 1-tap schema copy directly inside the app.
- **100% Offline-First Local Storage**:
  - Full local device storage fallback. The app works flawlessly offline without an internet connection.
- **Started vs. Paused Paper Management**:
  - **1-Tap Pause / Start**: Quickly pause or resume any home's paper delivery directly from the distribution list.
  - **Scheduled Vacation Pause**: Set a `From Date` and `Paused Until Date` so paper delivery automatically resumes after vacations.
  - **Individual Paper Pause**: Pause a single newspaper or magazine while keeping others active.
  - **Status History Log**: Tracks timestamped reasons whenever deliveries are paused or resumed.
- **Multiple Newspapers & Magazines with Daily / Weekend Variants**:
  - Configurable variants: Daily, Weekdays Only, Weekends Only, Sunday Only, Saturday Only.
- **Morning Depot Bundle Counter (सुबह उठाने वाले अखबार)**:
  - Calculates exact copy counts needed per newspaper/magazine for the selected date.
- **Month-End Society Billing & Activity Report**:
  - Complete customer billing breakdown with active/paused days and exportable bills.
- **Bilingual Interface (English + हिंदी)**:
  - 1-tap instant switch between English and Hindi.

## Supabase Free Cloud DB Setup (1-Minute Guide)
1. Go to [https://supabase.com](https://supabase.com) and create a free project.
2. Open **SQL Editor** in your Supabase dashboard and run the schema script:
   ```sql
   create table if not exists publications (
     id text primary key,
     name_en text not null,
     name_hi text not null default '',
     type text not null default 'newspaper',
     default_frequency text not null default 'daily',
     weekday_price numeric not null default 5.0,
     weekend_price numeric not null default 5.0,
     updated_at timestamp with time zone default timezone('utc'::text, now())
   );

   create table if not exists customers (
     id text primary key,
     sequence_no integer default 0,
     name text not null,
     house_number text not null,
     block text default '',
     area text not null default '',
     phone text default '',
     status text not null default 'started',
     pause_start_date text,
     pause_end_date text,
     pause_reason text default '',
     subscriptions jsonb default '[]'::jsonb,
     delivered_dates jsonb default '[]'::jsonb,
     status_history jsonb default '[]'::jsonb,
     notes text default '',
     updated_at timestamp with time zone default timezone('utc'::text, now())
   );

   alter table publications enable row level security;
   alter table customers enable row level security;

   create policy "Allow all on publications for anon"
     on publications for all using (true) with check (true);

   create policy "Allow all on customers for anon"
     on customers for all using (true) with check (true);
   ```
3. In Supabase, go to **Project Settings > API**, copy your **Project URL** and **anon public key**.
4. In the app, tap the **Cloud Sync** icon or **Free Cloud Database** button, paste the URL and Anon Key, and tap **Save Settings**!

## Project Structure
- `lib/main.dart` — App entry point and theme configuration
- `lib/l10n/app_strings.dart` — Bilingual (English + Hindi) translations
- `lib/models/publication.dart` — Publication model and subscription frequencies
- `lib/models/customer.dart` — Customer model, status log, and JSON serialization
- `lib/services/cloud_sync_service.dart` — Supabase PostgREST cloud database sync and SQL generator
- `lib/services/local_storage_service.dart` — Offline persistence on local mobile storage
- `lib/providers/delivery_provider.dart` — State management, offline-first sync, and bundle calculations
- `lib/screens/home_screen.dart` — Main dashboard, bundle pickup, filters, and list
- `lib/screens/cloud_sync_screen.dart` — Cloud database configuration, two-way sync, test connection, and SQL guide
- `lib/screens/morning_delivery_list_screen.dart` — Daily morning delivery sheet
- `lib/screens/monthly_billing_report_screen.dart` — Month-end billing report
- `lib/screens/block_wise_consumption_screen.dart` — Block-wise newspaper count

## How to Run
```bash
# Run web version
flutter run -d chrome --release

# Build Android release APK
flutter build apk --release
```
