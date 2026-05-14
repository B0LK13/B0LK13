CREATE TABLE countries (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  legal_links JSONB NOT NULL DEFAULT '[]'::jsonb
);

CREATE TABLE cities (
  id TEXT PRIMARY KEY,
  country_id TEXT NOT NULL REFERENCES countries(id),
  name TEXT NOT NULL,
  language_notes TEXT NOT NULL,
  tech_scene_notes TEXT NOT NULL,
  cost_band_low NUMERIC NOT NULL,
  cost_band_median NUMERIC NOT NULL,
  cost_band_high NUMERIC NOT NULL,
  safety_index NUMERIC NOT NULL
);

CREATE TABLE city_snapshots (
  city_id TEXT PRIMARY KEY REFERENCES cities(id),
  fixed_median_down_mbps NUMERIC NOT NULL,
  fixed_median_up_mbps NUMERIC NOT NULL,
  fixed_latency_ms NUMERIC NOT NULL,
  mobile_median_down_mbps NUMERIC NOT NULL,
  mobile_median_up_mbps NUMERIC NOT NULL,
  rail_hub BOOLEAN NOT NULL,
  coach_hub BOOLEAN NOT NULL,
  airport_within_60_min BOOLEAN NOT NULL,
  hsr BOOLEAN NOT NULL,
  freq_score NUMERIC NOT NULL,
  coworking_day_pass_eur NUMERIC NOT NULL,
  coworking_monthly_eur NUMERIC NOT NULL,
  evidence_label TEXT NOT NULL,
  last_verified DATE NOT NULL,
  mobility_score NUMERIC NOT NULL,
  net_score NUMERIC NOT NULL
);

CREATE TABLE trips (
  id TEXT PRIMARY KEY,
  city_id TEXT NOT NULL REFERENCES cities(id),
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  trip_length_days INTEGER NOT NULL,
  uwv_task_due DATE NOT NULL,
  ehic_check BOOLEAN NOT NULL DEFAULT FALSE,
  post_ready BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE evidence_log (
  id TEXT PRIMARY KEY,
  city_id TEXT NOT NULL REFERENCES cities(id),
  field_name TEXT NOT NULL,
  evidence_label TEXT NOT NULL,
  source_url TEXT NOT NULL,
  last_verified DATE NOT NULL,
  notes TEXT NOT NULL
);
