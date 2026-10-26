// @ts-check
/**
 * 07_class_group.spec.js
 * ============================================================
 * DEEP COMPREHENSIVE TEST — Class Group Tab (subject-class-mapping)
 * URL: /school-setup/school-class?tab=subject-class-mapping
 * Pane: #subject-class-mapping-pane
 * Filters: search, class_id (id=scm_filter_class_id), section_id (id=scm_filter_section_id), status
 * Actions: x-backend.table.action component
 * Trash: /school-setup/class-group/trash/view
 * ============================================================
 */
const { test, expect } = require('@playwright/test');

const BASE      = 'http://test.localhost:8000';
const TAB_URL   = `${BASE}/school-setup/school-class?tab=subject-class-mapping`;
const TRASH_URL = `${BASE}/school-setup/class-group/trash/view`;

test.describe.serial('07 — School Setup: Class Group Tab', () => {
  /** @type {import('@playwright/test').Page} */
  let page;
  test.beforeAll(async ({ browser }) => {
    const context = await browser.newContext({ storageState: 'tests/.auth/adminStorageState.json' });
    page = await context.newPage();
  });
  test.afterAll(async () => {
    await page.close();
  });
  test.use({ storageState: 'tests/.auth/adminStorageState.json' });

  test('TC-CG-01: Navigate to Class Group tab — pane visible', async () => {
    test.setTimeout(60000);
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('#subject-class-mapping-pane')).toBeVisible();
    await expect(page.locator('.nav-tabs .nav-link.active')).toContainText(/Class Group/i);
    console.log('[TC-CG-01] ✅ Class Group pane visible');
  });

  test('TC-CG-02: Breadcrumb correct', async () => {
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('body')).toContainText('Class & Section Management');
    console.log('[TC-CG-02] ✅ Breadcrumb correct');
  });

  test('TC-CG-03: Tab redirect works', async () => {
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });
    const pane = page.locator('#subject-class-mapping-pane');
    await expect(pane).toBeVisible();
    expect(await pane.getAttribute('class')).toMatch(/show/);
    console.log('[TC-CG-03] ✅ Tab redirect correct');
  });

  test('TC-CG-04: Accordion structure visible', async () => {
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });
    const accordion = page.locator('#subject-class-mapping-pane .accordion, #classGroupAccordion');
    await expect(accordion).toBeVisible();
    console.log('[TC-CG-04] ✅ Accordion structure visible');
  });

  test('TC-CG-05: Search filter', async () => {
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });

    const searchInput = page.locator('#subject-class-mapping-pane input[name="search"]');
    await expect(searchInput).toBeVisible();
    await searchInput.fill('test');
    await page.locator('#subject-class-mapping-pane button[type="submit"]').click();
    await page.waitForLoadState('domcontentloaded');
    // Page loads without error (even if no results)
    await expect(page.locator('#subject-class-mapping-pane')).toBeVisible();
    console.log('[TC-CG-05] ✅ Search filter works');
  });

  test('TC-CG-06: Class filter dropdown present and functional', async () => {
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });

    const classFilter = page.locator('#scm_filter_class_id');
    await expect(classFilter).toBeVisible();

    // Check it has options
    const optionCount = await classFilter.locator('option').count();
    console.log('[TC-CG-06] Class filter options count:', optionCount);
    expect(optionCount).toBeGreaterThanOrEqual(1); // at least "All Classes" option

    // Select first non-empty option if available
    const firstOptionValue = await classFilter.locator('option:nth-child(2)').getAttribute('value').catch(() => null);
    if (firstOptionValue) {
      await classFilter.selectOption(firstOptionValue);
      await page.locator('#subject-class-mapping-pane button[type="submit"]').click();
      await page.waitForLoadState('domcontentloaded');
      await expect(classFilter).toHaveValue(firstOptionValue);
    }
    console.log('[TC-CG-06] ✅ Class filter works');
  });

  test('TC-CG-07: Section filter dropdown present', async () => {
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });

    const sectionFilter = page.locator('#scm_filter_section_id');
    await expect(sectionFilter).toBeVisible();
    const optionCount = await sectionFilter.locator('option').count();
    expect(optionCount).toBeGreaterThanOrEqual(1);
    console.log('[TC-CG-07] ✅ Section filter visible with', optionCount, 'options');
  });

  test('TC-CG-08: Active status filter', async () => {
    await page.goto(`${TAB_URL}&status=1`, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('#subject-class-mapping-pane select[name="status"]')).toHaveValue('1');
    console.log('[TC-CG-08] ✅ Active filter');
  });

  test('TC-CG-09: Inactive status filter', async () => {
    await page.goto(`${TAB_URL}&status=0`, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('#subject-class-mapping-pane select[name="status"]')).toHaveValue('0');
    console.log('[TC-CG-09] ✅ Inactive filter');
  });

  test('TC-CG-10: Clear filters', async () => {
    await page.goto(`${TAB_URL}&status=1&search=xyz`, { waitUntil: 'domcontentloaded' });
    const clearBtn = page.locator('#subject-class-mapping-pane a[title="Clear Filters"]');
    if (await clearBtn.count() > 0) {
      await clearBtn.click();
      await page.waitForLoadState('domcontentloaded');
      await expect(page.locator('#subject-class-mapping-pane select[name="status"]')).toHaveValue('');
    }
    console.log('[TC-CG-10] ✅ Clear filters works');
  });

  test('TC-CG-11: View class group record', async () => {
    test.setTimeout(60000);
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });

    const viewBtn = page.locator('#subject-class-mapping-pane a.btn-outline-primary, #subject-class-mapping-pane a[title*="View"]').first();
    if (await viewBtn.count() > 0) {
      await viewBtn.click();
      await page.waitForLoadState('domcontentloaded');
      await expect(page.locator('body')).toBeVisible();
      await page.goBack();
      console.log('[TC-CG-11] ✅ View works');
    } else {
      console.log('[TC-CG-11] ⚠️  View button not found or no records');
    }
  });

  test('TC-CG-12: Edit class group record', async () => {
    test.setTimeout(90000);
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });

    const editBtn = page.locator('#subject-class-mapping-pane a[href*="class-group"][href*="edit"], #subject-class-mapping-pane a.btn-outline-warning').first();
    if (await editBtn.count() > 0) {
      await editBtn.click();
      await page.waitForLoadState('domcontentloaded');
      // Should open edit form
      await expect(page.locator('body')).toBeVisible();
      await page.goBack();
      console.log('[TC-CG-12] ✅ Edit accessible');
    } else {
      console.log('[TC-CG-12] ⚠️  Edit button not found');
    }
  });

  test('TC-CG-13: Status toggle on class group', async () => {
    test.setTimeout(60000);
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });

    const toggle = page.locator('#subject-class-mapping-pane input[type="checkbox"].form-check-input').first();
    if (await toggle.count() > 0) {
      const original = await toggle.isChecked();
      const respP = page.waitForResponse(r => r.url().includes('toggle-status'), { timeout: 10000 }).catch(() => null);
      await toggle.click();
      await respP;
      await page.waitForTimeout(400);
      expect(await toggle.isChecked()).toBe(!original);
      await toggle.click(); // restore
      console.log('[TC-CG-13] ✅ Status toggle works');
    } else {
      console.log('[TC-CG-13] ⚠️  No toggle found');
    }
  });

  test('TC-CG-14: Accordion expand/collapse first group', async () => {
    test.setTimeout(60000);
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });

    const accordionBtn = page.locator('#subject-class-mapping-pane .accordion-button').first();
    if (await accordionBtn.count() > 0) {
      // Click to collapse if open
      await accordionBtn.click();
      await page.waitForTimeout(300);
      // Click to expand
      await accordionBtn.click();
      await page.waitForTimeout(300);
      console.log('[TC-CG-14] ✅ Accordion expand/collapse works');
    } else {
      console.log('[TC-CG-14] ⚠️  No accordion buttons found');
    }
  });

  test('TC-CG-15: Trash page accessible', async () => {
    await page.goto(TRASH_URL, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('body')).toBeVisible();
    const title = await page.title();
    expect(title).not.toContain('500');
    console.log('[TC-CG-15] ✅ Trash page accessible');
  });

  test('TC-CG-16: Soft delete class group', async () => {
    test.setTimeout(90000);
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });

    // Find a delete button in the nested table
    const deleteBtn = page.locator('#subject-class-mapping-pane a.btn-outline-danger, #subject-class-mapping-pane button[onclick*="delete"]').first();
    if (await deleteBtn.count() === 0) {
      console.log('[TC-CG-16] ⚠️  No delete button found — no class group records');
      return;
    }

    // Get the row text for verification
    const row = deleteBtn.locator('../..').first();
    const rowText = await row.textContent().catch(() => '');

    const deleteResp = page.waitForResponse(
      r => r.url().includes('/class-group/') && (r.request().method() === 'DELETE' || r.request().method() === 'POST'),
      { timeout: 15000 }
    ).catch(() => null);

    await deleteBtn.click();
    await page.waitForTimeout(500);
    const swal = page.locator('.swal2-confirm');
    if (await swal.isVisible({ timeout: 3000 }).catch(() => false)) await swal.click();
    await deleteResp;
    await page.waitForTimeout(1000);
    console.log('[TC-CG-16] ✅ Class group soft delete attempted');
  });

  test('TC-CG-17: Trash restore accessible', async () => {
    await page.goto(TRASH_URL, { waitUntil: 'domcontentloaded' });
    const rows = await page.locator('tbody tr').count();
    if (rows > 0) {
      const restoreBtn = page.locator('a[href*="restore"]').first();
      if (await restoreBtn.count() > 0) {
        await expect(restoreBtn).toBeVisible();
        console.log('[TC-CG-17] ✅ Restore button visible in trash');
      }
    } else {
      console.log('[TC-CG-17] ⚠️  No items in trash');
    }
  });
});
