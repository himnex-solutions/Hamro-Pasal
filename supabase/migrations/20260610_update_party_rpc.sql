-- RPC function to update a party, bypassing RLS issues
-- while still verifying business membership
CREATE OR REPLACE FUNCTION update_party(
  p_party_id UUID,
  p_name TEXT,
  p_phone TEXT DEFAULT NULL,
  p_email TEXT DEFAULT NULL,
  p_address TEXT DEFAULT NULL,
  p_type TEXT DEFAULT 'customer',
  p_notes TEXT DEFAULT NULL
)
RETURNS JSONB
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_business_id UUID;
  v_result JSONB;
BEGIN
  -- 1. Get business_id from the party row
  SELECT business_id INTO v_business_id
  FROM parties WHERE id = p_party_id;

  IF v_business_id IS NULL THEN
    RAISE EXCEPTION 'Party not found';
  END IF;

  -- 2. Verify the caller has access to this business
  IF NOT user_has_business_access(v_business_id) THEN
    RAISE EXCEPTION 'Access denied: you are not a member of this business';
  END IF;

  -- 3. Perform the update
  UPDATE parties SET
    name       = p_name,
    phone      = p_phone,
    email      = p_email,
    address    = p_address,
    type       = p_type,
    notes      = p_notes,
    updated_at = NOW()
  WHERE id = p_party_id;

  -- 4. Return the updated row
  SELECT to_jsonb(p.*) INTO v_result
  FROM parties p WHERE p.id = p_party_id;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- RPC function to update a product, bypassing RLS issues
CREATE OR REPLACE FUNCTION update_product(
  p_product_id UUID,
  p_name TEXT,
  p_sku TEXT DEFAULT NULL,
  p_barcode TEXT DEFAULT NULL,
  p_unit TEXT DEFAULT NULL,
  p_cost_price NUMERIC DEFAULT 0,
  p_selling_price NUMERIC DEFAULT 0,
  p_stock_quantity NUMERIC DEFAULT 0,
  p_min_stock_alert NUMERIC DEFAULT 5,
  p_image_url TEXT DEFAULT NULL
)
RETURNS JSONB
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_business_id UUID;
  v_result JSONB;
BEGIN
  SELECT business_id INTO v_business_id
  FROM products WHERE id = p_product_id;

  IF v_business_id IS NULL THEN
    RAISE EXCEPTION 'Product not found';
  END IF;

  IF NOT user_has_business_access(v_business_id) THEN
    RAISE EXCEPTION 'Access denied: you are not a member of this business';
  END IF;

  UPDATE products SET
    name            = p_name,
    sku             = p_sku,
    barcode         = p_barcode,
    unit            = p_unit,
    cost_price      = p_cost_price,
    selling_price   = p_selling_price,
    stock_quantity  = p_stock_quantity,
    min_stock_alert = p_min_stock_alert,
    image_url       = COALESCE(p_image_url, image_url),
    updated_at      = NOW()
  WHERE id = p_product_id;

  SELECT to_jsonb(p.*) INTO v_result
  FROM products p WHERE p.id = p_product_id;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql;
