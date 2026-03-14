# Security Rules — MANDATORY

## Input Validation

1. **Always validate every user input through Form Requests.** No raw `$request->input()` without validation.

2. **Always use `$request->validated()`** to get only validated fields — never pass unvalidated data to models.

3. **Always use mass assignment protection** (`$fillable`) on every Model. Never use `$guarded = []`.

## Tenant Isolation

4. **Always scope queries to the current tenant.** Never allow cross-tenant data access. The tenancy bootstrapper handles DB-level isolation, but verify in code:
   ```php
   // With database-per-tenant, this is automatic.
   // But never bypass tenancy context.
   ```

5. **Never expose tenant UUIDs or internal IDs unnecessarily.** Use route model binding with authorization.

## Authentication & Authorization

6. **Always use authenticated + tenant-aware middleware on protected routes:**
   ```php
   Route::middleware(['auth', 'verified'])->group(function () { ... });
   ```

7. **Spatie permission checks at BOTH levels:**
   - Route middleware: `->middleware('permission:manage-students')`
   - Controller/Policy: `$this->authorize('update', $student)`

8. **API endpoints must use `auth:sanctum`** middleware.

9. **Rate limiting on all public endpoints:**
   ```php
   Route::middleware('throttle:60,1')->group(function () { ... });
   ```

## Sensitive Data

10. **Never store passwords, tokens, or secrets in logs.** Use Laravel's log scrubbing for sensitive fields.

11. **Never log full request bodies** that may contain passwords or payment details.

12. **Never commit `.env` files** or files containing credentials to version control.

13. **Never expose database errors to end users.** Return generic error messages in production.

## File Uploads

14. **Validate file type and size** for all uploads:
    ```php
    'document' => ['required', 'file', 'mimes:pdf,jpg,png', 'max:10240'], // 10MB
    ```

15. **Store uploaded files in tenant-specific paths.** Never share storage paths across tenants.

16. **Never execute uploaded files.** Store outside the web root or use signed URLs.

## SQL & Query Safety

17. **Never use raw SQL with user input** without parameterized queries:
    ```php
    // WRONG
    DB::select("SELECT * FROM students WHERE name = '$name'");

    // CORRECT
    DB::select("SELECT * FROM students WHERE name = ?", [$name]);
    ```

18. **Always use Eloquent or Query Builder** — avoid raw SQL unless absolutely necessary.

## XSS Prevention

19. **Always use `{{ }}` (escaped) in Blade templates**, not `{!! !!}` (unescaped) unless rendering trusted HTML.

20. **Sanitize any user-generated HTML content** before storage and display.

## CSRF Protection

21. **All POST/PUT/PATCH/DELETE forms must include `@csrf`** token.

22. **API routes using Sanctum tokens are exempt** from CSRF (handled by token auth).

## Session Security

23. **Session driver:** Database (configured in `.env`).
24. **Session lifetime:** 120 minutes (configurable).
25. **HTTPS only cookies** in production (`SESSION_SECURE_COOKIE=true`).
