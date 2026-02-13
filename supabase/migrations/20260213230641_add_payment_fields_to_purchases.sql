/*
  # Add Payment Fields to Purchases

  1. Purchases Table Updates
    - Add payment_method (cash, mobile_money, bank_transfer, check)
    - Add payment_status (unpaid, partial, paid)
    - Add payment_date
    - Add payment_reference (transaction ID, check number, etc.)
    - Add paid_amount

  2. Features
    - Support for manual payment tracking (cash, check, bank transfer)
    - Support for mobile money payments
    - Track partial and full payments
*/

-- Add payment fields to purchases table
ALTER TABLE purchases
ADD COLUMN IF NOT EXISTS payment_method text CHECK (payment_method IN ('cash', 'mobile_money', 'bank_transfer', 'check')),
ADD COLUMN IF NOT EXISTS payment_status text DEFAULT 'unpaid' CHECK (payment_status IN ('unpaid', 'partial', 'paid')),
ADD COLUMN IF NOT EXISTS payment_date date,
ADD COLUMN IF NOT EXISTS payment_reference text,
ADD COLUMN IF NOT EXISTS paid_amount numeric DEFAULT 0;

-- Create index for payment status queries
CREATE INDEX IF NOT EXISTS idx_purchases_payment_status ON purchases(payment_status);
CREATE INDEX IF NOT EXISTS idx_purchases_payment_date ON purchases(payment_date);