# Testing Plan: New Payment Flow

## Overview
This document provides a comprehensive testing plan for the new group creation and payment flow.

## Test Environment Setup

### Prerequisites
1. ✅ Development server running: `npm run dev`
2. ✅ Supabase backend accessible
3. ✅ Paystack test keys configured
4. ✅ Test user account created and verified

### Test Cards
- **Success**: 4084084084084081
- **Failed**: 4084084084084099
- **CVV**: Any 3 digits (e.g., 123)
- **Expiry**: Any future date (e.g., 12/28)
- **PIN**: 1234
- **OTP**: 123456

## Test Cases

### 1. Group Creation (Happy Path)

**Steps:**
1. Navigate to `/groups/create`
2. Fill in group details:
   - Name: "Test Savings Group"
   - Description: "Testing new payment flow"
   - Contribution Amount: 5000
   - Frequency: Monthly
   - Total Members: 5
   - Security Deposit: 20%
   - Start Date: [Future date]
3. Click "Create Group"

**Expected Results:**
- ✅ Form validates correctly
- ✅ Group is created in database
- ✅ No payment dialog appears
- ✅ Success toast: "Group created successfully! You can now join and pay to become the admin."
- ✅ Redirected to `/groups/{group-id}`

### 2. Group Detail Page - Creator View

**Steps:**
1. After creating group, verify you're on group detail page
2. Check page content

**Expected Results:**
- ✅ Group name and description displayed
- ✅ Status badge shows "forming"
- ✅ Current members: 0/5
- ✅ Orange alert visible with:
  - Title: "Complete Your Payment to Become Group Admin"
  - Description: Details about payment requirement
  - "Join & Pay" button visible
- ✅ No member list yet (0 members)

### 3. Open Creator Payment Dialog

**Steps:**
1. On group detail page, click "Join & Pay" button

**Expected Results:**
- ✅ Dialog opens with title "Join Your Group as Admin"
- ✅ Payment summary card shows:
  - Security Deposit: ₦1,000
  - First Contribution: ₦5,000
  - Total Amount: ₦6,000
- ✅ Slot selector displays positions 1-5
- ✅ All slots show as "Available"
- ✅ Info alert explains payout positions
- ✅ "Pay" button is disabled (no slot selected yet)
- ✅ "Cancel" button is enabled

### 4. Select Payout Slot

**Steps:**
1. In the dialog, click on slot 2
2. Verify selection

**Expected Results:**
- ✅ Slot 2 highlights as selected
- ✅ Other slots remain unselected
- ✅ "Pay ₦6,000" button becomes enabled
- ✅ No errors shown

### 5. Payment Flow - Successful Payment

**Steps:**
1. Click "Pay ₦6,000" button
2. Paystack popup opens
3. Enter test card: 4084084084084081
4. Complete payment flow with PIN and OTP

**Expected Results:**
- ✅ Paystack popup opens correctly
- ✅ Amount shows ₦6,000
- ✅ Payment processes successfully
- ✅ Toast: "Payment received! Verifying with backend..."
- ✅ Toast: "Payment verified! Processing your membership..."
- ✅ Toast: "Payment verified! You are now the group admin."
- ✅ Dialog closes automatically
- ✅ Orange alert disappears
- ✅ Group detail page refreshes
- ✅ Current members: 1/5
- ✅ User appears in members list at position 2
- ✅ "Deposit Paid" badge shows on member
- ✅ Status badge still shows "forming"

### 6. Payment Flow - Failed Payment

**Setup:** Create another test group

**Steps:**
1. Click "Join & Pay"
2. Select slot 3
3. Click "Pay"
4. Enter failed test card: 4084084084084099
5. Complete payment flow

**Expected Results:**
- ✅ Paystack shows payment declined
- ✅ Toast: "Payment was not successful"
- ✅ Dialog remains open
- ✅ Group still exists (not deleted)
- ✅ Creator can retry by clicking "Pay" again
- ✅ Can select different slot and retry

### 7. Payment Flow - Cancelled Payment

**Setup:** Create another test group

**Steps:**
1. Click "Join & Pay"
2. Select slot 1
3. Click "Pay"
4. Close Paystack popup without completing payment

**Expected Results:**
- ✅ Toast: "Payment cancelled"
- ✅ Dialog remains open (not closed)
- ✅ Group still exists
- ✅ Can click "Pay" again to retry
- ✅ Slot selection preserved

### 8. Payment Flow - Verification Failure

**Note:** This test simulates Edge Function issues

**Steps:**
1. Create test group
2. Click "Join & Pay"
3. Select slot
4. Pay with success card
5. If Edge Function fails, verify fallback

**Expected Results:**
- ✅ Toast: "Verification failed. Checking payment status..."
- ✅ System polls database for payment status
- ✅ If polling succeeds: Member added, success message
- ✅ If polling fails: Clear error message with reference number
- ✅ Group remains intact (not deleted)
- ✅ Can contact support with reference number

### 9. Cancel Dialog

**Steps:**
1. Click "Join & Pay"
2. Select a slot
3. Click "Cancel" button

**Expected Results:**
- ✅ Dialog closes
- ✅ No payment initiated
- ✅ Group still exists
- ✅ Can reopen dialog and try again
- ✅ Previous slot selection is cleared

### 10. Close Dialog Without Selection

**Steps:**
1. Click "Join & Pay"
2. Don't select any slot
3. Click outside dialog or press Escape

**Expected Results:**
- ✅ Dialog closes
- ✅ No payment initiated
- ✅ Group still exists

### 11. Multiple Payment Attempts

**Steps:**
1. Create test group
2. Click "Join & Pay", select slot 1, cancel
3. Click "Join & Pay", select slot 2, cancel
4. Click "Join & Pay", select slot 3, pay successfully

**Expected Results:**
- ✅ Each attempt works independently
- ✅ Slot selection resets between attempts
- ✅ Final payment uses last selected slot (3)
- ✅ Member added at position 3

### 12. Navigation Away and Back

**Steps:**
1. Create test group
2. Don't pay yet
3. Navigate to `/groups`
4. Navigate back to created group

**Expected Results:**
- ✅ Group appears in groups list
- ✅ Shows status "forming"
- ✅ Shows 0/5 members
- ✅ Clicking group opens detail page
- ✅ Orange alert still shows "Join & Pay" button
- ✅ Payment can still be completed

### 13. Existing Groups Compatibility

**Steps:**
1. View an existing group (created before this change)
2. Verify it still works

**Expected Results:**
- ✅ Existing groups load correctly
- ✅ If creator already paid: No "Join & Pay" button
- ✅ Member list shows correctly
- ✅ All other functionality works

### 14. Non-Creator View

**Setup:** Login with different user account

**Steps:**
1. Navigate to test group (created by another user)
2. View group detail page

**Expected Results:**
- ✅ No "Join & Pay" button (not creator)
- ✅ "Join Group" button shows if group accepting members
- ✅ Can request to join (separate flow)

### 15. Responsive Design

**Steps:**
1. Test on mobile viewport (375px width)
2. Test on tablet viewport (768px width)
3. Test on desktop viewport (1920px width)

**Expected Results:**
- ✅ "Join & Pay" button visible on all sizes
- ✅ Dialog is responsive and scrollable
- ✅ Slot selector works on touch devices
- ✅ Payment summary readable on small screens

## Edge Cases

### EC1: Network Interruption During Payment
**Test:** Disconnect internet after clicking "Pay" but before Paystack loads
**Expected:** Error message, can retry when reconnected

### EC2: Multiple Browser Tabs
**Test:** Open same group in two tabs, pay in one
**Expected:** Other tab shows outdated info until refresh

### EC3: Session Expiry
**Test:** Leave page open for extended period, then try to pay
**Expected:** Redirect to login, can resume after login

### EC4: Browser Back Button
**Test:** Click browser back during payment flow
**Expected:** Proper navigation, no broken state

### EC5: Paystack API Down
**Test:** If Paystack is unavailable
**Expected:** Clear error message, group remains intact

## Performance Tests

### P1: Large Group Creation
**Test:** Create group with 50 members (max)
**Expected:** Page loads quickly, slot selector performs well

### P2: Multiple Concurrent Payments
**Test:** Multiple users paying for different groups
**Expected:** No race conditions, all payments process correctly

## Security Tests

### S1: CSRF Protection
**Test:** Attempt payment from different origin
**Expected:** Paystack handles CSRF, our backend validates

### S2: Duplicate Payment
**Test:** Try to pay twice for same group
**Expected:** Second payment rejected or handled gracefully

### S3: Invalid Slot Selection
**Test:** Manually modify slot in request
**Expected:** Backend validates slot availability

## Accessibility Tests

### A1: Keyboard Navigation
**Test:** Navigate and pay using only keyboard
**Expected:** All interactive elements accessible

### A2: Screen Reader
**Test:** Use NVDA/JAWS to navigate payment flow
**Expected:** All content announced properly

### A3: Color Contrast
**Test:** Verify button and text contrast ratios
**Expected:** Meets WCAG AA standards

## Regression Tests

### R1: Member Join Flow
**Test:** Non-creator joins group
**Expected:** Still works as before

### R2: Group Listing
**Test:** View /groups page
**Expected:** Shows all groups correctly

### R3: Contributions
**Test:** Make contribution to active group
**Expected:** Contribution flow unaffected

### R4: Payouts
**Test:** Process payout in active group
**Expected:** Payout flow unaffected

## Browser Compatibility

Test on:
- ✅ Chrome (latest)
- ✅ Firefox (latest)
- ✅ Safari (latest)
- ✅ Edge (latest)
- ✅ Mobile Safari (iOS 14+)
- ✅ Mobile Chrome (Android 10+)

## Known Limitations

1. **No automatic cleanup**: Groups without members remain in database
   - **Mitigation**: Future enhancement to delete after X days
   
2. **No payment reminder**: Creator must remember to pay
   - **Mitigation**: Future enhancement for email reminders

3. **Slot becomes unavailable if payment pending**: Brief window where slot is locked
   - **Mitigation**: Acceptable - payment usually completes in seconds

## Test Automation Opportunities

Future automation candidates:
1. Group creation form validation
2. Payment dialog interactions
3. Slot selection logic
4. Toast message verification
5. Member list updates

## Sign-Off Checklist

Before marking as complete:
- [ ] All happy path tests pass
- [ ] All error cases handled gracefully
- [ ] No orphaned groups created
- [ ] Performance acceptable
- [ ] Responsive design works
- [ ] Accessibility requirements met
- [ ] Browser compatibility verified
- [ ] Documentation updated

## Rollback Plan

If critical issues found:
1. Revert commits: `git revert 578d847^..578d847`
2. Redeploy previous version
3. No database cleanup needed (backward compatible)
4. Existing groups unaffected

---

**Test Plan Version:** 1.0
**Created:** January 13, 2026
**Status:** Ready for Testing
**Assigned To:** QA Team / Developer
