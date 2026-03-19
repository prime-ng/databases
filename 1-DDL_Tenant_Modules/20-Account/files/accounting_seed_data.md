# Accounting Module — Seed Data Reference

**Purpose:** Data to seed during tenant creation for immediate usability.

---

## 1. Tally's 28 Account Groups (Seeded per Tenant)

### Balance Sheet Groups (15)

| # | Group Name | Parent | Nature | Affects GP | System |
|---|-----------|--------|--------|:---:|:---:|
| 1 | Capital Account | — | liability | No | Yes |
| 2 | Reserves & Surplus | Capital Account | liability | No | Yes |
| 3 | Current Assets | — | asset | No | Yes |
| 4 | Bank Accounts | Current Assets | asset | No | Yes |
| 5 | Cash-in-Hand | Current Assets | asset | No | Yes |
| 6 | Sundry Debtors | Current Assets | asset | No | Yes |
| 7 | Stock-in-Hand | Current Assets | asset | No | Yes |
| 8 | Deposits (Asset) | Current Assets | asset | No | Yes |
| 9 | Loans & Advances (Asset) | Current Assets | asset | No | Yes |
| 10 | Fixed Assets | — | asset | No | Yes |
| 11 | Investments | — | asset | No | Yes |
| 12 | Current Liabilities | — | liability | No | Yes |
| 13 | Sundry Creditors | Current Liabilities | liability | No | Yes |
| 14 | Duties & Taxes | Current Liabilities | liability | No | Yes |
| 15 | Provisions | Current Liabilities | liability | No | Yes |
| 16 | Secured Loans | — | liability | No | Yes |
| 17 | Unsecured Loans | — | liability | No | Yes |
| 18 | Bank OD Accounts | Secured Loans | liability | No | Yes |

### Profit & Loss Groups (10)

| # | Group Name | Parent | Nature | Affects GP | System |
|---|-----------|--------|--------|:---:|:---:|
| 19 | Sales Account | — | income | Yes | Yes |
| 20 | Purchase Account | — | expense | Yes | Yes |
| 21 | Direct Income | — | income | Yes | Yes |
| 22 | Direct Expenses | — | expense | Yes | Yes |
| 23 | Indirect Income | — | income | No | Yes |
| 24 | Indirect Expenses | — | expense | No | Yes |
| 25 | Suspense Account | — | liability | No | Yes |
| 26 | Misc Expenses (Asset) | — | asset | No | Yes |
| 27 | Branch/Divisions | — | liability | No | Yes |

> **School-Specific Sub-Groups (custom, added to seed):**

| # | Group Name | Parent | Nature | System |
|---|-----------|--------|--------|:---:|
| 28 | Fee Income | Direct Income | income | Yes |
| 29 | Teaching Staff Expenses | Direct Expenses | expense | Yes |
| 30 | Non-Teaching Staff Expenses | Indirect Expenses | expense | Yes |
| 31 | Administrative Expenses | Indirect Expenses | expense | Yes |
| 32 | Infrastructure & Maintenance | Indirect Expenses | expense | Yes |

---

## 2. Default Ledgers (Seeded per Tenant)

| Ledger Name | Group | System | Notes |
|------------|-------|:---:|-------|
| Profit & Loss A/c | — | Yes | P&L virtual ledger |
| Cash A/c | Cash-in-Hand | Yes | Default cash account |
| Petty Cash | Cash-in-Hand | Yes | Small expenses |
| GST Payable | Duties & Taxes | Yes | GST liability |
| TDS Payable | Duties & Taxes | Yes | TDS liability |
| PF Payable | Provisions | Yes | PF contribution |
| ESI Payable | Provisions | Yes | ESI contribution |
| PT Payable | Duties & Taxes | Yes | Professional Tax |
| Salary Payable | Provisions | Yes | Monthly salary liability |

---

## 3. Voucher Types (Seeded per Tenant)

| Code | Name | Category | Prefix | Auto # |
|------|------|----------|--------|:---:|
| PAYMENT | Payment Voucher | accounting | PAY- | Yes |
| RECEIPT | Receipt Voucher | accounting | RCV- | Yes |
| CONTRA | Contra Voucher | accounting | CNT- | Yes |
| JOURNAL | Journal Voucher | accounting | JRN- | Yes |
| SALES | Sales Voucher | accounting | SAL- | Yes |
| PURCHASE | Purchase Voucher | accounting | PUR- | Yes |
| CREDIT_NOTE | Credit Note | accounting | CN- | Yes |
| DEBIT_NOTE | Debit Note | accounting | DN- | Yes |
| STOCK_JOURNAL | Stock Journal | inventory | STJ- | Yes |
| PAYROLL | Payroll Voucher | payroll | PRL- | Yes |

---

## 4. Units of Measure (Seeded per Tenant)

| Name | Symbol | Decimals |
|------|--------|:---:|
| Pieces | Pcs | 0 |
| Kilograms | Kg | 2 |
| Litres | Ltr | 2 |
| Box | Box | 0 |
| Ream | Ream | 0 |
| Set | Set | 0 |
| Pair | Pair | 0 |
| Bottles | Btl | 0 |
| Metres | Mtr | 2 |
| Numbers | Nos | 0 |

---

## 5. Default Employee Groups (Seeded per Tenant)

| Name | PF | ESI | PT |
|------|:---:|:---:|:---:|
| Teaching Staff | Yes | No | Yes |
| Non-Teaching Staff | Yes | Yes | Yes |
| Administrative Staff | Yes | No | Yes |
| Contract Staff | No | No | No |
| Management | No | No | Yes |

---

## 6. Default Pay Heads (Seeded per Tenant)

### Earnings

| Name | Calc Type | Statutory | Sequence |
|------|-----------|-----------|:---:|
| Basic Salary | flat_amount | — | 1 |
| Dearness Allowance | percentage (of Basic) | — | 2 |
| HRA | percentage (of Basic, 25%) | — | 3 |
| Conveyance Allowance | flat_amount | — | 4 |
| Special Allowance | flat_amount | — | 5 |
| Overtime | on_attendance | — | 6 |
| Bonus | flat_amount | — | 7 |

### Deductions

| Name | Calc Type | Statutory | Sequence |
|------|-----------|-----------|:---:|
| PF (Employee 12%) | percentage (of Basic+DA, 12%) | pf | 1 |
| ESI (Employee 0.75%) | percentage (of Gross, 0.75%) | esi | 2 |
| Professional Tax | computed (state slab) | pt | 3 |
| TDS | computed (income tax slab) | tds | 4 |
| Advance Recovery | flat_amount | — | 5 |
| Loan EMI | flat_amount | — | 6 |

### Employer Contributions (not deducted from salary)

| Name | Calc Type | Statutory | Sequence |
|------|-----------|-----------|:---:|
| PF (Employer 12%) | percentage (of Basic+DA, 12%) | pf | 1 |
| ESI (Employer 3.25%) | percentage (of Gross, 3.25%) | esi | 2 |

---

## 7. Default Cost Centers (Seeded per Tenant)

| Name | Category |
|------|----------|
| Primary Wing | Department |
| Middle Wing | Department |
| Senior Wing | Department |
| Administration | Department |
| Transport | Activity |
| Sports | Activity |
| Library | Activity |
| Science Lab | Activity |
| Computer Lab | Activity |

---

## 8. Indian Statutory Config (in `config/accounting.php`)

```php
return [
    'pf' => [
        'employee_rate' => 12.00,
        'employer_rate' => 12.00,
        'ceiling' => 15000,        // Basic + DA ceiling for PF
    ],
    'esi' => [
        'employee_rate' => 0.75,
        'employer_rate' => 3.25,
        'ceiling' => 21000,        // Gross salary ceiling for ESI
    ],
    'pt' => [
        // Himachal Pradesh slabs (configure per state)
        'slabs' => [
            ['min' => 0, 'max' => 10000, 'tax' => 0],
            ['min' => 10001, 'max' => 999999, 'tax' => 200],
        ],
    ],
    'tds' => [
        'old_regime' => [
            ['min' => 0, 'max' => 250000, 'rate' => 0],
            ['min' => 250001, 'max' => 500000, 'rate' => 5],
            ['min' => 500001, 'max' => 1000000, 'rate' => 20],
            ['min' => 1000001, 'max' => 999999999, 'rate' => 30],
        ],
    ],
    'financial_year' => [
        'start_month' => 4,  // April
        'end_month' => 3,    // March
    ],
];
```
