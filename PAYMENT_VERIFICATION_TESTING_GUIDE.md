# Payment Verification Testing Guide

## Pre-requisites

### Environment Setup
Ensure the following environment variables are configured:

**Frontend (.env)**
```
VITE_PAYSTACK_PUBLIC_KEY=pk_test_xxx
```

**Backend (Supabase Dashboard → Settings → Edge Functions → Secrets)**
```
PAYSTACK_SECRET_KEY=sk_test_xxx
```

### Test Cards (Paystack Test Mode)
Use these test cards to simulate different scenarios:

| Card Number | Expiry | CVV | PIN | Scenario |
|------------|--------|-----|-----|----------|
| 4084084084084081 | Any future date | 408 | 0000 | Success immediately |
| 5060666666666666666 | Any future date | 123 | 1234 | Success after OTP |
| 4084080000000409 | Any future date | 408 | 0000 | Declined |

## Test Scenarios

### Test 1: Successful Payment (Happy Path)
**Objective**: Verify normal payment flow works end-to-end

**Steps**:
1. Create a new group
2. Use test card: `4084084084084081`
3. Complete payment
4. Verify backend verification succeeds
5. Confirm group membership is created

**Expected Result**:
- ✅ Toast: "Payment received! Verifying with backend..."
- ✅ Toast: "Payment verified! Processing your membership..."
- ✅ Toast: "Payment verified! You are now the group admin."
- ✅ Redirect to group detail page
- ✅ User is admin of the group
- ✅ Payment record in database with `verified: true`

**Console Logs to Check**:
```
Verifying payment with reference: XXX (attempt 1/3)
Edge Function response: { data: { success: true, verified: true, ... }, error: null }
Payment verification successful: {...}
```

### Test 2: Network Timeout (Retry Logic)
**Objective**: Verify retry mechanism works

**Steps**:
1. Simulate slow network (Chrome DevTools → Network → Slow 3G)
2. Create a new group
3. Use test card: `4084084084084081`
4. Complete payment
5. Observe retry attempts

**Expected Result**:
- ✅ Console shows multiple retry attempts
- ✅ Eventually succeeds after retries
- ✅ User membership created successfully

**Console Logs to Check**:
```
Verifying payment with reference: XXX (attempt 1/3)
Retrying due to network error...
Waiting 2000ms before retry...
Verifying payment with reference: XXX (attempt 2/3)
Payment verification successful: {...}
```

### Test 3: Declined Payment
**Objective**: Verify declined payments are handled correctly

**Steps**:
1. Create a new group
2. Use test card: `4084080000000409` (declined card)
3. Complete payment attempt
4. Observe error handling

**Expected Result**:
- ✅ Toast: "Payment was declined by your bank. Please try again."
- ✅ Group is deleted (cleanup)
- ✅ User redirected to groups list
- ✅ Clear error message with reference

**Console Logs to Check**:
```
Payment verification failed: { payment_status: 'failed', ... }
Group XXX deleted due to: Payment not successful
```

### Test 4: Edge Function Failure (Fallback Polling)
**Objective**: Verify fallback mechanism when Edge Function is unavailable

**Setup**:
- Temporarily break Edge Function (e.g., wrong Paystack key)
- Ensure webhook is properly configured

**Steps**:
1. Create a new group
2. Use test card: `4084084084084081`
3. Complete payment
4. Observe fallback polling

**Expected Result**:
- ✅ Toast: "Verification failed. Checking payment status..."
- ✅ Polling attempts visible in console
- ✅ Eventually finds payment via database (webhook processed it)
- ✅ Toast: "Payment verified via polling fallback"
- ✅ User membership created successfully

**Console Logs to Check**:
```
Verifying payment with reference: XXX (attempt 1/3)
API returned error: ...
Verification failed. Checking payment status...
Starting payment status polling for reference: XXX
Polling attempt 1/5
Payment found: { verified: true, status: 'success', ... }
Payment verified via polling fallback
```

### Test 5: Complete Verification Failure
**Objective**: Verify graceful error handling when all attempts fail

**Setup**:
- Break both Edge Function and webhook
- Or use invalid payment reference

**Steps**:
1. Create a new group
2. Use test card: `4084084084084081`
3. Complete payment
4. Observe all attempts fail

**Expected Result**:
- ✅ Toast: "Verification failed. Checking payment status..."
- ✅ Toast: "Unable to verify payment with Paystack. Please contact support with reference: XXX"
- ✅ Payment reference shown to user
- ✅ Group NOT deleted (support can verify manually)
- ✅ User redirected to groups list

**Console Logs to Check**:
```
Verifying payment with reference: XXX (attempt 1/3)
Retrying due to network error...
All verification attempts failed. Last error: ...
Starting payment status polling for reference: XXX
Payment status polling exhausted all attempts
Both verification and polling failed
```

### Test 6: Webhook-Only Success
**Objective**: Verify webhook can process payment independently

**Setup**:
- Configure webhook endpoint in Paystack dashboard
- Temporarily disable Edge Function verification

**Steps**:
1. Create a new group
2. Use test card: `4084084084084081`
3. Complete payment
4. Edge Function fails
5. Wait for webhook to process
6. Polling finds the verified payment

**Expected Result**:
- ✅ Edge Function verification fails
- ✅ Fallback polling finds webhook-processed payment
- ✅ User membership created via webhook data
- ✅ No duplicate processing

**Webhook Logs to Check (Supabase Dashboard)**:
```
Received Paystack event: charge.success reference: XXX
Payment record stored successfully
Business logic result: { success: true, message: '...' }
```

## Verification Checklist

### Database Verification
After each test, check:

```sql
-- Payment record created
SELECT * FROM payments WHERE reference = 'XXX';

-- Check fields
-- - verified: should be true for successful payments
-- - status: should be 'success' for successful payments
-- - payment_status: Paystack's status
-- - paid_at: timestamp when paid

-- Group membership created
SELECT * FROM group_members WHERE user_id = 'YYY' AND group_id = 'ZZZ';

-- Transaction record created
SELECT * FROM transactions WHERE reference = 'XXX';
```

### Log Verification

**Edge Function Logs** (Supabase Dashboard → Edge Functions → Logs):
```
Look for:
- ===== PAYMENT VERIFICATION START =====
- Paystack API response status: 200
- Payment status: success
- Store result: { success: true, ... }
- Business logic result: { success: true, ... }
- ===== PAYMENT VERIFICATION END =====
```

**Browser Console**:
```
Look for:
- Verifying payment with reference: XXX
- Edge Function response: { data: {...}, error: null }
- Payment verification successful: {...}
- Verification result: { verified: true, ... }
```

### Error Scenarios to Test

1. **Network Timeout**
   - Slow 3G network
   - Expect: Retry 3 times, then try polling

2. **Paystack API Down**
   - Simulate with wrong API key
   - Expect: Retry 3 times, then try polling

3. **Invalid Reference**
   - Use non-existent reference
   - Expect: Clear error message with reference

4. **Payment Pending**
   - Payment processing on Paystack side
   - Expect: Retry with delays until settled

5. **Edge Function Timeout**
   - Paystack API slow to respond
   - Expect: Timeout after 30s, retry

## Performance Testing

### Measure Latency
Use browser DevTools Network tab:

1. **Normal verification**: Should be < 3 seconds
2. **With 1 retry**: Should be < 5 seconds
3. **With 3 retries**: Should be < 9 seconds
4. **With polling fallback**: Should be < 25 seconds

### Load Testing
Test with multiple simultaneous payments:

```javascript
// Run in browser console
for (let i = 0; i < 5; i++) {
  // Create 5 groups with payments
  // Check all verify correctly
}
```

## Debugging Tips

### Enable Verbose Logging
Browser console should show:
- All retry attempts
- Response data from Edge Function
- Polling attempts and results
- Error details with stack traces

### Check Edge Function Logs
Supabase Dashboard → Edge Functions → verify-payment → Logs:
- Filter by payment reference
- Look for error messages
- Check Paystack API response status

### Check Webhook Logs
Supabase Dashboard → Edge Functions → paystack-webhook → Logs:
- Verify webhook is receiving events
- Check signature verification
- Confirm payment storage

### Common Issues

| Issue | Symptom | Solution |
|-------|---------|----------|
| "Server configuration error" | Edge Function fails immediately | Check PAYSTACK_SECRET_KEY in Supabase |
| "Payment verification timed out" | Requests taking > 30s | Check Paystack API status |
| "Transaction not found" | Verification fails with 404 | Wait 2-3 seconds before verifying |
| Webhook not firing | Polling always times out | Check webhook URL in Paystack dashboard |
| Duplicate memberships | User added twice | Check idempotency in payment processing |

## Rollback Testing

If issues found, test rollback:

```bash
# Revert changes
git revert 1703dfe 1729c77 ce68975

# Test original flow still works
# Verify no regressions
```

## Success Criteria

All tests should pass with:
- ✅ 100% success rate for valid payments
- ✅ < 10s average verification time
- ✅ Clear error messages for all failure scenarios
- ✅ No duplicate memberships
- ✅ Proper cleanup on payment failure
- ✅ Support-friendly error messages with references
- ✅ Comprehensive logs for debugging

## Production Readiness Checklist

Before deploying to production:

- [ ] All test scenarios pass
- [ ] Edge Functions deployed with updated code
- [ ] Environment variables configured (PAYSTACK_SECRET_KEY)
- [ ] Webhook URL configured in Paystack dashboard
- [ ] Webhook signature verification working
- [ ] Monitoring and alerts set up
- [ ] Support team briefed on new error messages
- [ ] Rollback plan documented and tested

## Monitoring in Production

Set up alerts for:
- High verification failure rate (> 5%)
- Slow verification times (> 15s average)
- Edge Function errors (> 1% error rate)
- Webhook processing failures

Monitor:
- Payment verification success rate
- Average verification time
- Retry attempt frequency
- Fallback polling usage
- Support tickets related to payment issues

## Support Response Guide

When users report payment issues:

1. **Get payment reference** from user or logs
2. **Check payment record**:
   ```sql
   SELECT * FROM payments WHERE reference = 'XXX';
   ```
3. **Check Edge Function logs** for that reference
4. **Check webhook logs** for that reference
5. **Verify with Paystack dashboard** if needed
6. **Manual verification** if payment succeeded but membership not created:
   ```sql
   -- Call processing function manually
   SELECT process_group_creation_payment('XXX', 'group_id', 'user_id', slot);
   ```

## Conclusion

This testing guide ensures comprehensive validation of the payment verification fixes. Follow each scenario to confirm the system handles all cases correctly and provides a reliable payment experience.
