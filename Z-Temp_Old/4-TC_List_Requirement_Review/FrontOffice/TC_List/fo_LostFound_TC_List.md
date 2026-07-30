# fo_LostFound — Test Case List & Business Conditions

**Module:** FrontOffice (CODE `FOF`, prefix `fo_`) · **Feature:** Lost & Found (Item Tracking + Claim Processing)
**DB scope:** TENANT-side (`fof_lost_found`) · **Test style:** Browser Dusk
**Primary table:** `fof_lost_found` · **Module URL prefix:** `/front-office/registers?tab=lost-found`
**Test file:** `fo_LostFound_TestCas.php`
**Tab:** Lost & Found (fourth tab of Registers)

Controller: `FofMenuController::registers()`, `LostFoundController`
Model: `LostFound`
Request: `LostFoundRequest`
Policy: `LostFoundPolicy`

Routes: lost-found CRUD + claim + toggleStatus + trash/restore/forceDelete

---

## 1. Business Conditions

| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `fof_lost_found`: id, item_number, item_description, category (Electronics/Clothing/Stationery/ID_Card/Money/Jewellery/Books/Sports/Other), found_location, found_date (date), found_by_name, found_by_user_id (FK), photo_media_id, status (Unclaimed/Claimed/Disposed/Returned_to_Authority), claimant_name, claimant_contact, claimed_date (datetime), disposal_notes, remarks, is_active, created_by, updated_by, created_at, updated_at, deleted_at | Model |

| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `item_description` required string max:255 | FR |
| BC-VAL-02 | `found_date` required date before_or_equal:now | FR |
| BC-VAL-03 | `claimant_name` required on claim | FR |
| BC-VAL-04 | `claimant_contact` required on claim | FR |

| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | Tab visible gate `frontoffice.lost-found.viewAny` | Policy |
| BC-AUTH-02 | create/store gate `frontoffice.lost-found.create` | Policy |
| BC-AUTH-03 | update/claim gate `frontoffice.lost-found.update` | Policy |
| BC-AUTH-04 | delete gate `frontoffice.lost-found.delete` | Policy |

| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Unclaimed section (warning border) + Claimed/Disposed section (success border) | View |
| BC-BIZ-02 | Unclaimed card: item_number, description, location, found date, status badge, Claim button, Status toggle, Actions | View |
| BC-BIZ-03 | Claim button opens modal with claimant_name + claimant_contact required | View |
| BC-BIZ-04 | Claimed card shows claimant name + claimed date | View |
| BC-BIZ-05 | Status badges: Unclaimed (warning), Claimed (success), Disposed (secondary) | View |
| BC-BIZ-06 | Create modal: item_description, found_location, found_date, remarks | View |
| BC-BIZ-07 | Found date max = today (before_or_equal:now) | View |
| BC-BIZ-08 | Search across item_description, item_number, found_location, claimant_name, status | Ctrl |
| BC-BIZ-09 | Empty states: "No unclaimed items found" / "No closed items found" | View |
| BC-BIZ-10 | Status toggle Ajax → JSON success | Ctrl |

---

## 2. Test Case List

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-FOLF-P10 | Positive | View | Unclaimed (warning) + Claimed/Disposed (success) sections | Sections | test_fo_lf_10 | Automated |
| TC-FOLF-P11 | Positive | View | Unclaimed card: item_number, description, location, date, status, buttons | Card | test_fo_lf_11 | Automated |
| TC-FOLF-P12 | Positive | View | Claim button opens modal with name + contact fields | Modal | test_fo_lf_12 | Automated |
| TC-FOLF-P13 | Positive | Ctrl | Mark item as Claimed via claim modal → status=Claimed, claimant set | Claimed | test_fo_lf_13 | Automated |
| TC-FOLF-P14 | Positive | View | Claimed card shows claimant name + claimed date | Details | test_fo_lf_14 | Automated |
| TC-FOLF-P15 | Positive | Ctrl | Create item log via modal → stored | Created | test_fo_lf_15 | Automated |
| TC-FOLF-P16 | Positive | Ctrl | Soft delete → trashed | Deleted | test_fo_lf_16 | Automated |
| TC-FOLF-P17 | Positive | View | Empty states for unclaimed/closed sections | Empty | test_fo_lf_17 | Automated |
| TC-FOLF-N18 | Negative | Val | Future found_date → before_or_equal:now error | Error | test_fo_lf_18 | Automated |
| TC-FOLF-N19 | Negative | Val | Missing item_description → validation error | Error | test_fo_lf_19 | Automated |
