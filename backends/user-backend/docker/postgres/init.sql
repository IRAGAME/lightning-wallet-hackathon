CREATE TABLE IF NOT EXISTS users (
  id BIGSERIAL PRIMARY KEY,
  username VARCHAR(50) NOT NULL,
  email VARCHAR(255) NOT NULL,
  phone VARCHAR(20),
  password_hash TEXT NOT NULL,
  balance_sats BIGINT NOT NULL DEFAULT 0,
  status VARCHAR(20) NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS users_username_uq ON users (username);
CREATE UNIQUE INDEX IF NOT EXISTS users_email_lower_uq ON users ((LOWER(email)));

CREATE TABLE IF NOT EXISTS transactions (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  related_user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
  type VARCHAR(40) NOT NULL,
  amount_sats BIGINT NOT NULL CHECK (amount_sats > 0),
  payment_request TEXT,
  status VARCHAR(20) NOT NULL DEFAULT 'pending',
  lnd_invoice_id VARCHAR(255),
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS transactions_user_id_id_desc_idx
  ON transactions (user_id, id DESC);

CREATE INDEX IF NOT EXISTS transactions_status_type_idx
  ON transactions (status, type);
