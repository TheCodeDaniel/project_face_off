-- Face Off — initial Postgres schema (game/UI/backend guideline Section 3).
--
-- Everything durable and relational lives here. Ephemeral, high-frequency,
-- small-payload state (matchmaking queue, in-match event log, rematch
-- requests, presence) stays in Firebase Realtime Database and is NOT
-- represented here — see CLAUDE.md's "Backend architecture" section for the
-- full hybrid-split reasoning.
--
-- Auth stays Firebase Auth (Google/Apple), untouched. `users.id` IS the
-- Firebase UID (a text UID, not a Postgres-generated uuid) — there is
-- deliberately no second identity system. Row-level security below keys off
-- that same UID via a custom JWT claim; verify the exact current Supabase
-- pattern for wiring a Firebase UID into RLS (custom JWT vs. external auth
-- integration) against Supabase's live docs before applying this for real —
-- their auth-integration guidance changes, and this hasn't been run against
-- a live project.
--
-- Apply with the Supabase CLI once a project exists: `supabase db push`.

create extension if not exists "pgcrypto"; -- for gen_random_uuid()

-- ---------------------------------------------------------------------------
-- users — profile data (display name, avatar, tier/level, region)
-- ---------------------------------------------------------------------------
create table users (
  id text primary key, -- Firebase UID
  display_name text not null,
  avatar_url text,
  tier_label text not null default 'Iron I',
  tier_progress numeric(3, 2) not null default 0 check (tier_progress between 0 and 1),
  region text not null default 'unitedStates', -- matches lib Region enum names
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- user_game_stats — one row per user per game, plus an aggregate view rather
-- than a duplicated aggregate row (keeps the per-game rows as the single
-- source of truth; the aggregate is always derived, never re-entered).
-- ---------------------------------------------------------------------------
create table user_game_stats (
  user_id text not null references users (id) on delete cascade,
  game_id text not null, -- 'faceOff' | 'bowDraw' | 'freeze' — matches GameId.name
  total_matches integer not null default 0,
  win_streak integer not null default 0,
  win_rate_percent integer not null default 0 check (win_rate_percent between 0 and 100),
  primary key (user_id, game_id)
);

create view user_aggregate_stats as
select
  user_id,
  sum(total_matches) as total_matches,
  max(win_streak) as win_streak,
  case
    when sum(total_matches) = 0 then 0
    else round(sum(win_rate_percent * total_matches)::numeric / sum(total_matches))
  end as win_rate_percent
from user_game_stats
group by user_id;

-- ---------------------------------------------------------------------------
-- friendships / friend_requests / blocks / reports — relational data with
-- real query needs ("has this user blocked that user," "list pending
-- requests") that a relational model handles more naturally than Firestore's
-- document model.
-- ---------------------------------------------------------------------------

-- One row per pair, ordered (user_id_a < user_id_b) so a friendship is
-- represented exactly once regardless of who added whom.
create table friendships (
  user_id_a text not null references users (id) on delete cascade,
  user_id_b text not null references users (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id_a, user_id_b),
  check (user_id_a < user_id_b)
);

create table friend_requests (
  id uuid primary key default gen_random_uuid(),
  from_user_id text not null references users (id) on delete cascade,
  to_user_id text not null references users (id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'accepted', 'declined')),
  created_at timestamptz not null default now(),
  unique (from_user_id, to_user_id)
);

create table blocks (
  blocker_id text not null references users (id) on delete cascade,
  blocked_id text not null references users (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id)
);

create table reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id text not null references users (id) on delete cascade,
  reported_id text not null references users (id) on delete cascade,
  reason text not null,
  details text,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- matches — durable match history, written once a match concludes. The live
-- event-by-event data (round-by-round fire/dodge/crack, draw/release, etc.)
-- stays in Realtime DB and is never migrated here — this is only the final
-- summary a real MatchRepository writes at MatchCompleteMatchState.
-- ---------------------------------------------------------------------------
create table matches (
  id uuid primary key default gen_random_uuid(),
  game_id text not null,
  player_a_id text not null references users (id),
  player_b_id text not null references users (id),
  winner_id text references users (id), -- null = draw or an edge-case forfeit
  player_a_score integer not null,
  player_b_score integer not null,
  concluded_at timestamptz not null default now()
);

create index matches_player_a_idx on matches (player_a_id, concluded_at desc);
create index matches_player_b_idx on matches (player_b_id, concluded_at desc);

-- ---------------------------------------------------------------------------
-- cosmetics_owned / subscriptions_cache — entitlement records. Purchases are
-- driven by RevenueCat, never trusted purely from client-reported state —
-- subscriptions_cache.tier is kept in sync via a RevenueCat webhook.
-- ---------------------------------------------------------------------------
create table cosmetics_owned (
  user_id text not null references users (id) on delete cascade,
  cosmetic_id text not null,
  equipped boolean not null default false,
  acquired_at timestamptz not null default now(),
  primary key (user_id, cosmetic_id)
);

create table subscriptions_cache (
  user_id text primary key references users (id) on delete cascade,
  tier text not null default 'free' check (tier in ('free', 'plus')),
  revenuecat_customer_id text,
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Row-level security — illustrative, not verified against a live project.
-- `users` shown as the representative example; every other table needs the
-- same "row belongs to (or is visible to) the requesting Firebase UID"
-- shape, not written out repeatedly here since the exact JWT-claim wiring
-- needs confirming against Supabase's current docs first (see header note).
-- ---------------------------------------------------------------------------
alter table users enable row level security;

create policy "users can read their own row"
on users for select
using (id = (auth.jwt() ->> 'firebase_uid'));

create policy "users can update their own row"
on users for update
using (id = (auth.jwt() ->> 'firebase_uid'));
