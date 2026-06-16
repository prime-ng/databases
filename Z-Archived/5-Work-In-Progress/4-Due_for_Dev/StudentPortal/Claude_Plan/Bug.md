StudentPortal Planning — Complete

  ┌──────────────────────┬─────────────────────────────────────────────────────┬────────┐
  │         File         │                       Purpose                       │ Status │
  ├──────────────────────┼─────────────────────────────────────────────────────┼────────┤
  │ STP_FeatureSpec.md   │ 35-screen inventory, security audit, 30 FRs, 20 BRs │ Done   │
  ├──────────────────────┼─────────────────────────────────────────────────────┼────────┤
  │ STP_Security_Arch.md │ 10 security fixes, 4 FormRequests, Policy + Service │ Done   │
  ├──────────────────────┼─────────────────────────────────────────────────────┼────────┤
  │ STP_Dev_Plan.md      │ P0→P3 blueprint, 57 views, 65 routes, test strategy │ Done   │
  └──────────────────────┴─────────────────────────────────────────────────────┴────────┘

  ---
  Critical before any other work — P0 (1 person-day):

  1. routes/tenant.php — add role:Student|Parent + EnsureTenantHasModule:StudentPortal, change proceed-payment to POST, remove test-notification route
  2. StudentPortalController.php — add findStudentInvoice() helper, fix IDOR in viewInvoice() / payDueAmount() / proceedPayment()
  3. Create ProcessPaymentRequest.php + StudentPortalPolicy.php
  4. Register policy in StudentPortalServiceProvider.php
  