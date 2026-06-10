-- Add optional bank details and wallet details columns to the bank_accounts table
ALTER TABLE bank_accounts 
ADD COLUMN IF NOT EXISTS bank_name TEXT,
ADD COLUMN IF NOT EXISTS account_number TEXT,
ADD COLUMN IF NOT EXISTS branch_name TEXT,
ADD COLUMN IF NOT EXISTS esewa_id TEXT,
ADD COLUMN IF NOT EXISTS esewa_name TEXT;
