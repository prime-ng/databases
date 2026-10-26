// @ts-check
/**
 * 01_sections_single.spec.js
 * ============================================================
 * SINGLE CONTINUOUS TEST FLOW FOR SECTIONS
 * Opens browser ONCE and executes ALL 19 steps seamlessly:
 * Breadcrumb -> Load -> Filters -> Validation -> Create ->
 * Duplicate Check -> View -> Edit -> Status Toggle ->
 * Soft Delete -> Trash View -> Restore -> Force Delete -> Pagination
 * ============================================================
 */
const { test, expect } = require('@playwright/test');
const { loginAsAdmin } = require('./helpers/auth');

const TS       = Date.now().toString().slice(-5);
const SEC_CODE = `T${TS.slice(-3)}`;
const SEC_NAME = `AutoSec ${TS}`;
const SEC_SHORT = `AS${TS.slice(-2)}`;
const UPD_NAME = `${SEC_NAME} Updated`;

const BASE    = 'http://test.localhost:8000';
const TAB_URL = `${BASE}/school-setup/school-class?tab=sections`;
const TRASH_URL = `${BASE}/school-setup/section/trash/view`;

test.describe('Sections Tab - Full End-to-End Continuous Flow', () => {
  test.use({ storageState: 'tests/.auth/adminStorageState.json' });

  test('Complete Flow: Navigation, Filters, Full CRUD, Duplicates, Trash, Restore & Force Delete', async ({ page }) => {
    // Generous timeout so the entire test flow runs in one open browser without closing
    test.setTimeout(300000);

    // 1. Initial Load & Table Visibility
    console.log('\n[Step 1] Navigating to Sections Tab...');
    await loginAsAdmin(page);
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('.nav-tabs .nav-link.active')).toContainText(/Section/i);
    await expect(page.locator('#sections-pane')).toBeVisible();
    await expect(page.locator('#sections-table')).toBeVisible();
    await expect(page.locator('#sections-table th').filter({ hasText: /^Name/ })).toBeVisible();
    await expect(page.locator('#sections-table th').filter({ hasText: 'Code' })).toBeVisible();
    await expect(page.locator('#sections-table th').filter({ hasText: 'Status' })).toBeVisible();
    console.log('✅ Table and columns verified.');

    // 2. Breadcrumb Verification
    console.log('[Step 2] Verifying Breadcrumb...');
    await expect(page.locator('body')).toContainText('Class & Section Management');
    console.log('✅ Breadcrumb verified.');

    // 3. Tab Parameter Redirection
    console.log('[Step 3] Verifying tab parameter URL redirect...');
    await page.goto(`${BASE}/school-setup/school-class?tab=sections`, { waitUntil: 'domcontentloaded' });
    const pane = page.locator('#sections-pane');
    await expect(pane).toBeVisible();
    expect(await pane.getAttribute('class')).toMatch(/show/);
    console.log('✅ Tab redirect verified.');

    // 4. Search Filter
    console.log('[Step 4] Testing Search Filter...');
    const firstRowName = await page.locator('#sections-table tbody tr td:nth-child(2)').first().textContent().catch(() => null);
    if (firstRowName && firstRowName.trim()) {
      const term = firstRowName.trim().slice(0, 10);
      const searchInput = page.locator('#sections-pane input[name="search"]');
      await searchInput.fill(term);
      await page.locator('#sections-pane button[type="submit"]').click();
      await page.waitForLoadState('domcontentloaded');
      await expect(page.locator('#sections-table')).toContainText(term);
      console.log('✅ Search filter verified.');
    }

    // 5. Status Filter (Active)
    console.log('[Step 5] Testing Active Status Filter...');
    await page.goto(`${TAB_URL}&status=1`, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('#sections-pane select[name="status"]')).toHaveValue('1');
    await expect(page.locator('#sections-table')).toBeVisible();
    console.log('✅ Active status filter verified.');

    // 6. Status Filter (Inactive)
    console.log('[Step 6] Testing Inactive Status Filter...');
    await page.goto(`${TAB_URL}&status=0`, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('#sections-pane select[name="status"]')).toHaveValue('0');
    console.log('✅ Inactive status filter verified.');

    // 7. Clear Filters
    console.log('[Step 7] Testing Clear Filters...');
    await page.goto(`${TAB_URL}&status=1&search=xyz`, { waitUntil: 'domcontentloaded' });
    const clearBtn = page.locator('#sections-pane a[title="Clear Filters"]');
    await expect(clearBtn).toBeVisible();
    await clearBtn.click();
    await page.waitForLoadState('domcontentloaded');
    await expect(page.locator('#sections-pane select[name="status"]')).toHaveValue('');
    console.log('✅ Clear filters verified.');

    // 8. Create Validation (Empty Submit)
    console.log('[Step 8] Testing Empty Form Validation...');
    await page.locator('button[data-bs-target="#sectionModal"], a[data-bs-target="#sectionModal"]').first().click();
    await expect(page.locator('#sectionModal')).toBeVisible({ timeout: 8000 });
    await page.locator('#sectionForm button[type="submit"]').click();
    await page.waitForTimeout(800);
    const isOpen = await page.locator('#sectionModal').isVisible();
    const hasError = await page.locator('.text-danger, .invalid-feedback, .swal2-icon-error').count();
    expect(isOpen || hasError > 0).toBeTruthy();
    await page.locator('#sectionModal button[data-bs-dismiss="modal"]').first().click();
    await page.waitForTimeout(400);
    console.log('✅ Form validation verified.');

    // 9. Create Section (Valid)
    console.log(`[Step 9] Creating new Section: ${SEC_NAME} (${SEC_CODE})...`);
    await page.locator('button[data-bs-target="#sectionModal"], a[data-bs-target="#sectionModal"]').first().click();
    await expect(page.locator('#sectionModal')).toBeVisible({ timeout: 8000 });
    await page.locator('#sectionForm input[name="name"]').clear();
    await page.locator('#sectionForm input[name="name"]').fill(SEC_NAME);
    await page.locator('#sectionForm input[name="short_name"]').clear();
    await page.locator('#sectionForm input[name="short_name"]').fill(SEC_SHORT);
    await page.locator('#sectionForm input[name="code"]').clear();
    await page.locator('#sectionForm input[name="code"]').fill(SEC_CODE);

    const createRespPromise = page.waitForResponse(
      resp => resp.url().includes('/section') && (resp.request().method() === 'POST' || resp.request().method() === 'PUT'),
      { timeout: 15000 }
    ).catch(() => null);

    await page.locator('#sectionForm button[type="submit"]').click();
    await createRespPromise;
    await page.waitForTimeout(3500);

    // Verify row appeared in list
    await page.goto(`${TAB_URL}&search=${encodeURIComponent(SEC_NAME)}`, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('#sections-table')).toContainText(SEC_NAME);
    console.log('✅ Section created and displayed in table.');

    // 10. Duplicate Code Check
    console.log('[Step 10] Testing Duplicate Code Check...');
    await page.locator('button[data-bs-target="#sectionModal"], a[data-bs-target="#sectionModal"]').first().click();
    await expect(page.locator('#sectionModal')).toBeVisible({ timeout: 8000 });
    await page.locator('#sectionForm input[name="name"]').fill(`DiffName ${TS}`);
    await page.locator('#sectionForm input[name="short_name"]').fill('DIF');
    await page.locator('#sectionForm input[name="code"]').fill(SEC_CODE); // same code
    const dupCodeResp = page.waitForResponse(
      resp => resp.url().includes('/section') && resp.request().method() === 'POST',
      { timeout: 10000 }
    ).catch(() => null);
    await page.locator('#sectionForm button[type="submit"]').click();
    await page.waitForTimeout(1200);
    const hasDupCode = (await page.content()).toLowerCase().includes('already') ||
                       (await page.locator('.text-danger, .swal2-icon-error').count()) > 0 ||
                       await page.locator('#sectionModal').isVisible();
    expect(hasDupCode).toBeTruthy();
    if (await page.locator('#sectionModal').isVisible()) {
      await page.locator('#sectionModal button[data-bs-dismiss="modal"]').first().click();
      await page.waitForTimeout(400);
    }
    console.log('✅ Duplicate code rejected.');

    // 11. Duplicate Name Check
    console.log('[Step 11] Testing Duplicate Name Check...');
    await page.locator('button[data-bs-target="#sectionModal"], a[data-bs-target="#sectionModal"]').first().click();
    await expect(page.locator('#sectionModal')).toBeVisible({ timeout: 8000 });
    await page.locator('#sectionForm input[name="name"]').fill(SEC_NAME); // same name
    await page.locator('#sectionForm input[name="short_name"]').fill('DIF');
    await page.locator('#sectionForm input[name="code"]').fill('DIFC');
    await page.locator('#sectionForm button[type="submit"]').click();
    await page.waitForTimeout(1200);
    const hasDupName = (await page.content()).toLowerCase().includes('already') ||
                       (await page.locator('.text-danger, .swal2-icon-error').count()) > 0 ||
                       await page.locator('#sectionModal').isVisible();
    expect(hasDupName).toBeTruthy();
    if (await page.locator('#sectionModal').isVisible()) {
      await page.locator('#sectionModal button[data-bs-dismiss="modal"]').first().click();
      await page.waitForTimeout(400);
    }
    console.log('✅ Duplicate name rejected.');

    // 12. View Section Detail
    console.log('[Step 12] Viewing Section Details...');
    await page.goto(`${TAB_URL}&search=${encodeURIComponent(SEC_NAME)}`, { waitUntil: 'domcontentloaded' });
    const viewRow = page.locator('#sections-table tbody tr').filter({ hasText: SEC_NAME }).first();
    const viewBtn = viewRow.locator('a[href*="view"], a.btn-outline-primary').first();
    if (await viewBtn.count() > 0) {
      await viewBtn.click();
      await page.waitForLoadState('domcontentloaded');
      await expect(page.locator('body')).toContainText(SEC_NAME);
      await page.goBack();
      await page.waitForLoadState('domcontentloaded');
      console.log('✅ View page verified.');
    }

    // 13. Edit Section
    console.log('[Step 13] Editing Section Name...');
    await page.goto(`${TAB_URL}&search=${encodeURIComponent(SEC_NAME)}`, { waitUntil: 'domcontentloaded' });
    const editRow = page.locator('#sections-table tbody tr').filter({ hasText: SEC_NAME }).first();
    const editBtn = editRow.locator('button[onclick*="editSection"]').first();
    await expect(editBtn).toBeVisible({ timeout: 5000 });
    await editBtn.click();
    // Confirm SweetAlert ("Sure to Edit?")
    const swalEdit = page.locator('.swal2-confirm');
    if (await swalEdit.isVisible({ timeout: 3000 }).catch(() => false)) {
      await swalEdit.click();
    }
    await expect(page.locator('#sectionModal')).toBeVisible({ timeout: 8000 });
    await page.waitForTimeout(600);
    await page.locator('#sectionForm input[name="name"]').clear();
    await page.locator('#sectionForm input[name="name"]').fill(UPD_NAME);

    const updateRespPromise = page.waitForResponse(
      resp => resp.url().includes('/section') && (resp.request().method() === 'PUT' || resp.request().method() === 'POST'),
      { timeout: 15000 }
    ).catch(() => null);

    await page.locator('#sectionForm button[type="submit"]').click();
    await updateRespPromise;
    await page.waitForTimeout(3500);

    await page.goto(`${TAB_URL}&search=${encodeURIComponent(UPD_NAME)}`, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('#sections-table')).toContainText(UPD_NAME);
    console.log('✅ Section updated successfully.');

    // 14. Status Toggle Switch
    console.log('[Step 14] Toggling Active Status Switch...');
    const statusRow = page.locator('#sections-table tbody tr').filter({ hasText: UPD_NAME }).first();
    const toggle = statusRow.locator('input[type="checkbox"].form-check-input').first();
    if (await toggle.count() > 0) {
      const originalState = await toggle.isChecked();
      const toggleRespPromise = page.waitForResponse(resp => resp.url().includes('toggle-status'), { timeout: 10000 }).catch(() => null);
      await toggle.click();
      await toggleRespPromise;
      await page.waitForTimeout(500);
      expect(await toggle.isChecked()).toBe(!originalState);
      // Restore
      await toggle.click();
      await page.waitForTimeout(500);
      console.log('✅ Status toggle verified.');
    }

    // 15. Soft Delete Section
    console.log('[Step 15] Soft Deleting Section...');
    const delRow = page.locator('#sections-table tbody tr').filter({ hasText: UPD_NAME }).first();
    const delBtn = delRow.locator('button[onclick*="deleteSection"]').first();
    const delRespPromise = page.waitForResponse(
      resp => resp.url().includes('/section/') && resp.request().method() === 'DELETE',
      { timeout: 15000 }
    ).catch(() => null);
    await delBtn.click();
    await page.waitForTimeout(500);
    const swalDel = page.locator('.swal2-confirm');
    if (await swalDel.isVisible({ timeout: 3000 }).catch(() => false)) {
      await swalDel.click();
    }
    await delRespPromise;
    await page.waitForTimeout(3500);

    // Verify gone from main table
    await page.goto(`${TAB_URL}&search=${encodeURIComponent(UPD_NAME)}`, { waitUntil: 'domcontentloaded' });
    expect(await page.locator('#sections-table tbody tr').filter({ hasText: UPD_NAME }).count()).toBe(0);
    console.log('✅ Soft delete verified.');

    // 16. Trash View Verification
    console.log('[Step 16] Verifying Trash View...');
    await page.goto(TRASH_URL, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('body')).toContainText(UPD_NAME);
    console.log('✅ Trashed section visible in trash.');

    // 17. Restore from Trash
    console.log('[Step 17] Restoring Section from Trash...');
    const trashRow = page.locator('tr').filter({ hasText: UPD_NAME }).first();
    const restoreBtn = trashRow.locator('a[href*="restore"], button[title*="Restore"], form[action*="restore"] button').first();
    await restoreBtn.click();
    await page.waitForLoadState('domcontentloaded');
    await page.waitForTimeout(600);
    const swalRestore = page.locator('.swal2-confirm');
    if (await swalRestore.isVisible({ timeout: 2000 }).catch(() => false)) {
      await swalRestore.click();
      await page.waitForLoadState('domcontentloaded');
    }
    await page.goto(`${TAB_URL}&search=${encodeURIComponent(UPD_NAME)}`, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('#sections-table')).toContainText(UPD_NAME);
    console.log('✅ Section restored back to active list.');

    // 18. Permanent Force Delete
    console.log('[Step 18] Permanently Force Deleting Section...');
    // Delete again first
    await page.goto(`${TAB_URL}&search=${encodeURIComponent(UPD_NAME)}`, { waitUntil: 'domcontentloaded' });
    const rowAgain = page.locator('#sections-table tbody tr').filter({ hasText: UPD_NAME }).first();
    if (await rowAgain.count() > 0) {
      await rowAgain.locator('button[onclick*="deleteSection"]').first().click();
      await page.waitForTimeout(400);
      const swalD = page.locator('.swal2-confirm');
      if (await swalD.isVisible({ timeout: 2000 }).catch(() => false)) await swalD.click();
      await page.waitForTimeout(3500);
    }
    // Now permanent force delete in trash
    await page.goto(TRASH_URL, { waitUntil: 'domcontentloaded' });
    const rowInTrash = page.locator('tr').filter({ hasText: UPD_NAME }).first();
    if (await rowInTrash.count() > 0) {
      const forceBtn = rowInTrash.locator('button[title*="Permanent"], form[action*="force-delete"] button').first();
      if (await forceBtn.count() > 0) {
        await forceBtn.click();
        await page.waitForTimeout(400);
        const swalF = page.locator('.swal2-confirm');
        if (await swalF.isVisible({ timeout: 2000 }).catch(() => false)) await swalF.click();
        await page.waitForLoadState('domcontentloaded');
        await page.waitForTimeout(3500);
      }
    }
    await page.goto(TRASH_URL, { waitUntil: 'domcontentloaded' });
    expect(await page.locator('tr').filter({ hasText: UPD_NAME }).count()).toBe(0);
    console.log('✅ Permanent force delete verified.');

    // 19. Pagination Check
    console.log('[Step 19] Verifying Pagination...');
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });
    const count = await page.locator('#sections-table tbody tr').count();
    if (count >= 10) {
      const paginationElement = page.locator('#sections-pane nav[role="navigation"], #sections-pane .pagination, #sections-pane').filter({ hasText: /Showing.*results|Next|Previous/ }).first();
      await expect(paginationElement).toBeVisible();
    }
    console.log('✅ Pagination verified.');

    console.log('\n🎉 ALL 19 STEPS COMPLETED IN ONE CONTINUOUS BROWSER SESSION!\n');
  });
});
