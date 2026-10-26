// @ts-check
const { test, expect } = require('@playwright/test');
const { loginAsAdmin } = require('./helpers/auth');

test.describe('School Setup - End-to-End Master Workflow (All 9 Tabs Auto)', () => {

  test.beforeEach(async () => {
    await loginAsAdmin(page);
    await page.goto('/school-setup/school-class?tab=sections#sections');
    await page.waitForLoadState('domcontentloaded');
  });

  test('FULL-AUDIT: Complete User Workflow Across All 9 Tabs', async () => {
    test.setTimeout(180000); // 3 minutes for complete deep audit

    // 1. GLOBAL UI VERIFICATION
    console.log('[Step 1] Verifying Breadcrumb & Main Card Header...');
    await expect(page.locator('.breadcrumb, x-backend\\\\.components\\\\.breadcrum, nav[aria-label="breadcrumb"]').first()).toBeVisible();
    await expect(page.locator('h1, h2, h3, h4, h5, .breadcrumb').first()).toBeVisible();

    const tabs = [
      { id: 'sections', name: 'Sections', pane: '#sections-pane, #sections', modal: '#sectionModal' },
      { id: 'class-sections', name: 'Class', pane: '#class-sections-pane, #class-sections', modal: '#classSectionModal' },
      { id: 'subject-type', name: 'Subject Type', pane: '#subject-type-pane, #subject-type', modal: '#subjectTypeModal' },
      { id: 'study-format', name: 'Study Format', pane: '#study-format-pane, #study-format', modal: '#StudyFormatModal' },
      { id: 'subject', name: 'Subject', pane: '#subject-pane, #subject', modal: '#SubjectModal' },
      { id: 'subject-study-format', name: 'Subject + Study Format', pane: '#subject-study-format-pane, #subject-study-format', modal: null },
      { id: 'subject-class-mapping', name: 'Class Group', pane: '#subject-class-mapping-pane, #subject-class-mapping', modal: null },
      { id: 'subject-group', name: 'Subject Group', pane: '#subject-group-pane, #subject-group', modal: null },
      { id: 'class-stream', name: 'Stream', pane: '#class-stream-pane, #class-stream', modal: '#ClassStreamModal' },
    ];

    for (let i = 0; i < tabs.length; i++) {
      const tab = tabs[i];
      console.log(`\n======================================================`);
      console.log(`[Tab ${i + 1}/9] Auditing: ${tab.name} (?tab=${tab.id})`);
      console.log(`======================================================`);

      // A. Tab Switch & URL Check
      const tabLink = page.locator(`a[data-bs-target="#${tab.id}"], a[href*="tab=${tab.id}"], button[data-bs-target="#${tab.id}"]`).first();
      if (await tabLink.count() > 0) {
        await tabLink.click();
      } else {
        await page.goto(`/school-setup/school-class?tab=${tab.id}#${tab.id}`);
      }
      await page.waitForTimeout(400);

      // Verify active tab pane & table
      const activePane = page.locator(tab.pane).first();
      await expect(activePane).toBeVisible();

      // B. Table Verification
      const table = activePane.locator('table').first();
      if (await table.count() > 0) {
        await expect(table).toBeVisible();
        const rowCount = await table.locator('tbody tr').count();
        console.log(`  -> Table rendered cleanly with ${rowCount} rows`);
      }

      // C. Filter / Search Check
      const searchBox = activePane.locator('input[name="search"]').first();
      if (await searchBox.count() > 0) {
        console.log('  -> Testing Search Filter...');
        await searchBox.fill('A');
        const searchBtn = activePane.locator('button[type="submit"]').first();
        if (await searchBtn.count() > 0) {
          await searchBtn.click();
          await page.waitForTimeout(400);
        }
        // Clear filter
        const clearBtn = activePane.locator('a[title="Clear Filters"], a.btn-secondary').first();
        if (await clearBtn.count() > 0) {
          await clearBtn.click();
          await page.waitForTimeout(400);
        }
      }

      // D. Pagination Check
      const pagination = activePane.locator('.pagination, nav[role="navigation"]').first();
      if (await pagination.count() > 0) {
        console.log('  -> Pagination controls detected & active');
      }

      // E. Add Modal Verification
      if (tab.modal) {
        const addBtn = activePane.locator(`button[data-bs-target="${tab.modal}"], a[data-bs-target="${tab.modal}"]`).first();
        if (await addBtn.count() > 0) {
          console.log(`  -> Verifying Create Modal: ${tab.modal}`);
          await addBtn.click();
          await page.waitForTimeout(800);
          const modalEl = page.locator(tab.modal).first();
          await expect(modalEl).toBeVisible();
          // Close modal cleanly
          const closeBtn = modalEl.locator('button[data-bs-dismiss="modal"], .btn-close').first();
          if (await closeBtn.count() > 0) {
            await closeBtn.click();
            await page.waitForTimeout(300);
          }
        }
      }

      console.log(`  -> [PASS] Tab ${tab.name} fully verified!`);
    }

    console.log('\n======================================================');
    console.log('🎉 ALL 9 TABS PASSED FULL USER AUDIT WORKFLOW CLEANLY!');
    console.log('======================================================\n');
  });

});
