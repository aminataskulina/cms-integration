CREATE TABLE IF NOT EXISTS historical_spares (
  id SERIAL PRIMARY KEY,
  student_id INTEGER NOT NULL,
  spare_code TEXT NOT NULL,
  spare_name TEXT,
  spare_description TEXT,
  spare_type TEXT,
  spare_status TEXT,
  price NUMERIC(12,2),
  quantity INTEGER,
  updated_at TIMESTAMP WITH TIME ZONE,
  inserted_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  last_seen_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  active BOOLEAN,
  CONSTRAINT uq_student_spare UNIQUE (student_id, spare_code)
);
