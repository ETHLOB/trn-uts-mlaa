CREATE TABLE "customers" (
  "customer_id" bigint PRIMARY KEY,
  "age" int,
  "gender" varchar,
  "annual_income" decimal,
  "income_band" varchar,
  "credit_score_band" varchar,
  "postcode" varchar,
  "city" varchar,
  "state" varchar,
  "vulnerable_customer_flag" int
);

CREATE TABLE "accounts" (
  "account_id" bigint PRIMARY KEY,
  "customer_id" bigint,
  "account_type" varchar,
  "account_status" varchar,
  "current_balance" decimal
);

CREATE TABLE "cards" (
  "card_id" bigint PRIMARY KEY,
  "account_id" bigint,
  "card_type" varchar,
  "network" varchar,
  "international_enabled" int
);

CREATE TABLE "loans" (
  "loan_id" bigint PRIMARY KEY,
  "customer_id" bigint,
  "account_id" bigint,
  "loan_type" varchar,
  "original_amount" decimal,
  "outstanding_balance" decimal,
  "interest_rate" decimal,
  "loan_risk_grade" varchar
);

CREATE TABLE "transactions" (
  "transaction_id" bigint PRIMARY KEY,
  "customer_id" bigint,
  "account_id" bigint,
  "card_id" bigint,
  "merchant_id" bigint,
  "transaction_timestamp" datetime,
  "amount" decimal,
  "transaction_type" varchar,
  "channel" varchar,
  "international_transaction_flag" int
);

CREATE TABLE "account_balance_history" (
  "history_id" bigint PRIMARY KEY,
  "account_id" bigint,
  "customer_id" bigint,
  "balance_date" date,
  "balance" decimal,
  "balance_change" decimal
);

CREATE TABLE "economics" (
  "economic_date" date PRIMARY KEY,
  "inflation_rate" decimal,
  "interest_rate" decimal,
  "unemployment_rate" decimal,
  "consumer_sentiment" decimal,
  "economic_cycle" varchar
);

CREATE TABLE "devices" (
  "device_id" bigint PRIMARY KEY,
  "customer_id" bigint,
  "device_type" varchar,
  "device_make" varchar,
  "operating_system" varchar,
  "device_trust_score" int
);

CREATE TABLE "digital_sessions" (
  "session_id" bigint PRIMARY KEY,
  "customer_id" bigint,
  "device_id" bigint,
  "session_start" datetime,
  "session_end" datetime,
  "duration_minutes" int,
  "ip_country" varchar,
  "vpn_flag" int,
  "proxy_flag" int,
  "ip_risk_score" int
);

CREATE TABLE "counterparty_transfers" (
  "transfer_id" bigint PRIMARY KEY,
  "from_customer_id" bigint,
  "to_customer_id" bigint,
  "transfer_timestamp" datetime,
  "amount" decimal,
  "transfer_type" varchar
);

CREATE TABLE "products" (
  "product_id" bigint PRIMARY KEY,
  "product_name" varchar,
  "product_category" varchar,
  "product_subcategory" varchar,
  "risk_level" varchar
);

CREATE TABLE "customer_products" (
  "customer_product_id" bigint PRIMARY KEY,
  "customer_id" bigint,
  "product_id" bigint,
  "ownership_status" varchar,
  "product_balance" decimal,
  "profitability_band" varchar
);

CREATE TABLE "marketing_campaigns" (
  "campaign_id" bigint PRIMARY KEY,
  "campaign_type" varchar,
  "target_segment" varchar,
  "start_date" date,
  "end_date" date,
  "budget" decimal
);

CREATE TABLE "campaign_responses" (
  "response_id" bigint PRIMARY KEY,
  "campaign_id" bigint,
  "customer_id" bigint,
  "responded" int,
  "response_date" date
);

CREATE TABLE "product_uptake" (
  "uptake_id" bigint PRIMARY KEY,
  "customer_id" bigint,
  "campaign_id" bigint,
  "product_id" bigint,
  "uptake_date" date,
  "campaign_attributed_flag" int,
  "cross_sell_flag" int
);

CREATE TABLE "postcode_reference" (
  "postcode" varchar PRIMARY KEY,
  "suburb" varchar,
  "state" varchar,
  "remoteness_category" varchar,
  "irsd_decile" int,
  "median_household_income" decimal
);

CREATE TABLE "merchant_reference" (
  "merchant_id" bigint PRIMARY KEY,
  "merchant_category" varchar,
  "merchant_country" varchar,
  "merchant_state" varchar,
  "merchant_city" varchar,
  "merchant_size" varchar,
  "risk_score" int
);

ALTER TABLE "customers" ADD FOREIGN KEY ("postcode") REFERENCES "postcode_reference" ("postcode") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "accounts" ADD FOREIGN KEY ("customer_id") REFERENCES "customers" ("customer_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "cards" ADD FOREIGN KEY ("account_id") REFERENCES "accounts" ("account_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "loans" ADD FOREIGN KEY ("customer_id") REFERENCES "customers" ("customer_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "loans" ADD FOREIGN KEY ("account_id") REFERENCES "accounts" ("account_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "transactions" ADD FOREIGN KEY ("customer_id") REFERENCES "customers" ("customer_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "transactions" ADD FOREIGN KEY ("account_id") REFERENCES "accounts" ("account_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "transactions" ADD FOREIGN KEY ("card_id") REFERENCES "cards" ("card_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "transactions" ADD FOREIGN KEY ("merchant_id") REFERENCES "merchant_reference" ("merchant_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "account_balance_history" ADD FOREIGN KEY ("account_id") REFERENCES "accounts" ("account_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "account_balance_history" ADD FOREIGN KEY ("customer_id") REFERENCES "customers" ("customer_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "devices" ADD FOREIGN KEY ("customer_id") REFERENCES "customers" ("customer_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "digital_sessions" ADD FOREIGN KEY ("customer_id") REFERENCES "customers" ("customer_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "digital_sessions" ADD FOREIGN KEY ("device_id") REFERENCES "devices" ("device_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "counterparty_transfers" ADD FOREIGN KEY ("from_customer_id") REFERENCES "customers" ("customer_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "counterparty_transfers" ADD FOREIGN KEY ("to_customer_id") REFERENCES "customers" ("customer_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "customer_products" ADD FOREIGN KEY ("customer_id") REFERENCES "customers" ("customer_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "customer_products" ADD FOREIGN KEY ("product_id") REFERENCES "products" ("product_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "campaign_responses" ADD FOREIGN KEY ("campaign_id") REFERENCES "marketing_campaigns" ("campaign_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "campaign_responses" ADD FOREIGN KEY ("customer_id") REFERENCES "customers" ("customer_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "product_uptake" ADD FOREIGN KEY ("customer_id") REFERENCES "customers" ("customer_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "product_uptake" ADD FOREIGN KEY ("campaign_id") REFERENCES "marketing_campaigns" ("campaign_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "product_uptake" ADD FOREIGN KEY ("product_id") REFERENCES "products" ("product_id") DEFERRABLE INITIALLY IMMEDIATE;
