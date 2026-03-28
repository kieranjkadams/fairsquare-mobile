-- RPC: get_admin_stats
-- Returns app-wide statistics. Only callable by the admin user.
-- Replace 'YOUR_ADMIN_UUID_HERE' with the actual admin UUID.

CREATE OR REPLACE FUNCTION get_admin_stats()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result JSON;
  admin_id UUID := 'YOUR_ADMIN_UUID_HERE'; -- TODO: Replace with actual admin UUID
  month_start DATE := date_trunc('month', now())::date;
BEGIN
  -- Verify caller is admin
  IF auth.uid() IS NULL OR auth.uid() != admin_id THEN
    RAISE EXCEPTION 'Unauthorized: admin access required';
  END IF;

  SELECT json_build_object(
    'total_users', (SELECT count(*) FROM auth.users),
    'total_properties', (SELECT count(*) FROM properties),
    'total_investors', (SELECT count(*) FROM investors WHERE invitation_status = 'accepted'),
    'total_transactions', (SELECT count(*) FROM transactions WHERE is_auto_generated = false),
    'new_users_this_month', (SELECT count(*) FROM auth.users WHERE created_at >= month_start),
    'new_properties_this_month', (SELECT count(*) FROM properties WHERE created_at >= month_start),
    'transactions_this_month', (SELECT count(*) FROM transactions WHERE is_auto_generated = false AND created_at >= month_start)
  ) INTO result;

  RETURN result;
END;
$$;
