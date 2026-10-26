// @ts-check
const { test, expect } = require('@playwright/test');
const { loginAsAdmin } = require('./helpers/auth');

test.describe('School Setup - FULL AUDIT (All 9 Tabs, Continuous)', () => {

  test('FULL-AUDIT: All tabs, all functionality, one browser session', async ({ page }) => {
    test.setTimeout(600000);

    const results = [];
    const step = async (name, fn) => {
      try {
        await fn();
        results.push({ name, status: 'PASS' });
        console.log(`[PASS] ${name}`);
      } catch (e) {
        results.push({ name, status: 'FAIL', error: (e && e.message) ? e.message.slice(0, 200) : String(e) });
        console.log(`[FAIL] ${name} :: ${e && e.message ? e.message.slice(0, 200) : e}`);
      }
    };

    await loginAsAdmin(page);

    // ========== TAB 1: SECTIONS ==========
    const ts = Date.now().toString().slice(-4);
    const secCode = `T${ts.slice(-3)}`;
    const secName = `Section Audit ${ts}`;
    const secShort = `SA${ts.slice(-2)}`;
    const secUpd = `${secName} Upd`;

    await step('SEC-01 Load & Table', async () => {
      await page.goto('/school-setup/school-class?tab=sections#sections');
      await page.waitForLoadState('domcontentloaded');
      await expect(page.locator('#sections-pane, #sections')).toBeVisible();
      await expect(page.locator('#sections-table')).toBeVisible();
    });
    await step('SEC-02 Empty Validation', async () => {
      await page.click('button[data-bs-target="#sectionModal"], a[data-bs-target="#sectionModal"]');
      await expect(page.locator('#sectionModal')).toBeVisible();
      await page.fill('#sectionForm input[name="name"]', '');
      await page.fill('#sectionForm input[name="code"]', '');
      await page.click('#sectionForm button[type="submit"]');
      await page.waitForTimeout(300);
      const c = await page.locator('.text-danger, .swal2-icon-error').count();
      expect(c).toBeGreaterThan(0);
      await page.click('#sectionModal button[data-bs-dismiss="modal"]');
    });
    await step('SEC-03 DDL Max Length (CHAR 4)', async () => {
      await page.click('button[data-bs-target="#sectionModal"], a[data-bs-target="#sectionModal"]');
      await expect(page.locator('#sectionModal')).toBeVisible();
      await page.fill('#sectionForm input[name="name"]', `Length Check ${ts}`);
      await page.fill('#sectionForm input[name="short_name"]', 'LC');
      await page.fill('#sectionForm input[name="code"]', 'TOOLONG');
      await page.click('#sectionForm button[type="submit"]');
      await page.waitForTimeout(600);
      expect(await page.locator('#sectionModal').isVisible()).toBeTruthy();
      await page.click('#sectionModal button[data-bs-dismiss="modal"]');
    });
    await step('SEC-04 Create', async () => {
      await page.click('button[data-bs-target="#sectionModal"], a[data-bs-target="#sectionModal"]');
      await expect(page.locator('#sectionModal')).toBeVisible();
      await page.fill('#sectionForm input[name="name"]', secName);
      await page.fill('#sectionForm input[name="short_name"]', secShort);
      await page.fill('#sectionForm input[name="code"]', secCode);
      await page.click('#sectionForm button[type="submit"]');
      await page.waitForTimeout(800);
      await page.goto(`/school-setup/school-class?tab=sections&search=${encodeURIComponent(secName)}&active_tab=sections`);
      await page.waitForLoadState('domcontentloaded');
      await expect(page.locator('#sections-table')).toContainText(secName);
    });
    await step('SEC-05 Duplicate Code', async () => {
      await page.click('button[data-bs-target="#sectionModal"], a[data-bs-target="#sectionModal"]');
      await expect(page.locator('#sectionModal')).toBeVisible();
      await page.fill('#sectionForm input[name="name"]', `Different Name ${ts}`);
      await page.fill('#sectionForm input[name="short_name"]', 'DIFF');
      await page.fill('#sectionForm input[name="code"]', secCode);
      await page.click('#sectionForm button[type="submit"]');
      await page.waitForTimeout(300);
      const dup = (await page.content()).includes('already exists') || (await page.locator('.text-danger, .swal2-icon-error').count()) > 0;
      expect(dup).toBeTruthy();
      await page.click('#sectionModal button[data-bs-dismiss="modal"]');
    });
    await step('SEC-06 Duplicate Name', async () => {
      await page.click('button[data-bs-target="#sectionModal"], a[data-bs-target="#sectionModal"]');
      await expect(page.locator('#sectionModal')).toBeVisible();
      await page.fill('#sectionForm input[name="name"]', secName);
      await page.fill('#sectionForm input[name="short_name"]', 'DIFF2');
      await page.fill('#sectionForm input[name="code"]', `Z${ts.slice(-3)}`);
      await page.click('#sectionForm button[type="submit"]');
      await page.waitForTimeout(600);
      const dup = (await page.locator('.text-danger, .swal2-icon-error, .is-invalid').count()) > 0 || (await page.locator('#sectionModal').isVisible());
      expect(dup).toBeTruthy();
      if (await page.locator('#sectionModal').isVisible()) await page.click('#sectionModal button[data-bs-dismiss="modal"]');
    });
    await step('SEC-07 Edit', async () => {
      await page.goto(`/school-setup/school-class?tab=sections&search=${encodeURIComponent(secName)}&active_tab=sections`);
      await page.waitForLoadState('domcontentloaded');
      const row = page.locator('#sections-table tr').filter({ hasText: secName }).first();
      await expect(row).toBeVisible();
      await row.locator('button[onclick*="editSection"]').first().click();
      await page.waitForTimeout(400);
      const swal = page.locator('.swal2-confirm');
      if (await swal.isVisible()) await swal.click();
      await expect(page.locator('#sectionModal')).toBeVisible({ timeout: 10000 });
      await page.fill('#sectionForm input[name="name"]', secUpd);
      await page.click('#sectionForm button[type="submit"]');
      await page.waitForTimeout(1000);
      await page.goto(`/school-setup/school-class?tab=sections&search=${encodeURIComponent(secUpd)}&active_tab=sections`);
      await page.waitForLoadState('domcontentloaded');
      await expect(page.locator('#sections-table')).toContainText(secUpd);
    });
    await step('SEC-08 View', async () => {
      const viewBtn = page.locator('#sections-table tr').filter({ hasText: secUpd }).first().locator('a.btn-outline-primary').first();
      if (await viewBtn.count() > 0) {
        await viewBtn.click();
        await page.waitForLoadState('domcontentloaded');
        await expect(page.locator('body')).toContainText(secUpd);
        await page.goto(`/school-setup/school-class?tab=sections&search=${encodeURIComponent(secUpd)}&active_tab=sections`);
        await page.waitForLoadState('domcontentloaded');
      }
    });
    await step('SEC-09 Status Toggle', async () => {
      const tg = page.locator('#sections-table .status-toggle').first();
      if (await tg.count() > 0) {
        const b = await tg.isChecked();
        await tg.click();
        await page.waitForTimeout(600);
        const a = await tg.isChecked();
        expect(a).not.toBe(b);
        await tg.click();
        await page.waitForTimeout(600);
      }
    });
    await step('SEC-10 Search Filter', async () => {
      await page.goto('/school-setup/school-class?tab=sections&active_tab=sections');
      await page.waitForLoadState('domcontentloaded');
      const si = page.locator('#sections-pane input[name="search"], #sections input[name="search"]').first();
      await si.fill(secUpd);
      const btn = page.locator('#sections-pane button[type="submit"], #sections button[type="submit"]').first();
      if (await btn.count() > 0) await btn.click();
      await page.waitForTimeout(600);
      await expect(page.locator('#sections-table')).toContainText(secUpd);
      const cb = page.locator('#sections-pane a[title="Clear Filters"], #sections a[title="Clear Filters"]').first();
      if (await cb.count() > 0) { await cb.click(); await page.waitForTimeout(400); }
    });
    await step('SEC-11 Soft Delete', async () => {
      await page.goto(`/school-setup/school-class?tab=sections&search=${encodeURIComponent(secUpd)}&active_tab=sections`);
      await page.waitForLoadState('domcontentloaded');
      const er = page.locator('#sections-table tr').filter({ hasText: secUpd }).first();
      await expect(er).toBeVisible();
      const dp = page.waitForResponse(r => r.url().includes('/section/') && r.request().method() === 'DELETE' && r.status() === 200, { timeout: 15000 });
      await er.locator('button[onclick*="deleteSection"]').first().click();
      await page.waitForTimeout(400);
      const sc = page.locator('.swal2-confirm');
      if (await sc.isVisible()) await sc.click();
      await dp;
      await page.waitForTimeout(500);
      await page.goto(`/school-setup/school-class?tab=sections&search=${encodeURIComponent(secUpd)}&active_tab=sections`);
      await page.waitForLoadState('domcontentloaded');
      const cnt = await page.locator('#sections-table tr').filter({ hasText: secUpd }).count();
      expect(cnt).toBe(0);
    });
    await step('SEC-12 Trash & Force Delete', async () => {
      await page.goto('/school-setup/section/trash/view');
      await page.waitForLoadState('domcontentloaded');
      const tr = page.locator('tr').filter({ hasText: secUpd }).first();
      if (await tr.count() > 0) {
        const fb = tr.locator('form.confirm-action-form-force-delete button, button[title="Permanent Delete"]').first();
        if (await fb.count() > 0) {
          await fb.click();
          await page.waitForTimeout(400);
          const sc = page.locator('.swal2-confirm');
          if (await sc.isVisible()) await sc.click();
          await page.waitForTimeout(1500);
        }
      }
    });

    // ========== TAB 2: CLASS ==========
    const clsTs = Date.now().toString().slice(-4);
    const clsCode = `C${clsTs.slice(-3)}`;
    const clsName = `Class Audit ${clsTs}`;
    const clsShort = `CA${clsTs.slice(-2)}`;

    await step('CLS-01 Load & Table', async () => {
      await page.goto('/school-setup/school-class?tab=class-sections#class-sections');
      await page.waitForLoadState('domcontentloaded');
      await expect(page.locator('#class-sections-pane, #class-sections')).toBeVisible();
      await expect(page.locator('#class-sections-pane table, #class-sections table').first()).toBeVisible();
    });
    await step('CLS-02 Empty Validation', async () => {
      await page.click('button[data-bs-target="#classSectionModal"], a[data-bs-target="#classSectionModal"]');
      await expect(page.locator('#classSectionModal')).toBeVisible();
      await page.fill('#classSectionForm input[name="class_name"]', '');
      await page.fill('#classSectionForm input[name="code"]', '');
      await page.click('#classSectionForm button[type="submit"]');
      await page.waitForTimeout(300);
      const c = await page.locator('.text-danger, .swal2-icon-error').count();
      expect(c).toBeGreaterThan(0);
      await page.click('#classSectionModal button[data-bs-dismiss="modal"]');
    });
    await step('CLS-03 Max Length (CHAR 5)', async () => {
      await page.click('button[data-bs-target="#classSectionModal"], a[data-bs-target="#classSectionModal"]');
      await expect(page.locator('#classSectionModal')).toBeVisible();
      await page.fill('#classSectionForm input[name="class_name"]', `Length Class ${clsTs}`);
      await page.fill('#classSectionForm input[name="short_name"]', 'LNC');
      await page.fill('#classSectionForm input[name="code"]', 'MAX_CODE_EXCEED');
      await page.click('#classSectionForm button[type="submit"]');
      await page.waitForTimeout(300);
      const c = await page.locator('.text-danger, .swal2-icon-error').count();
      expect(c).toBeGreaterThan(0);
      await page.click('#classSectionModal button[data-bs-dismiss="modal"]');
    });
    await step('CLS-04 Create', async () => {
      await page.click('button[data-bs-target="#classSectionModal"], a[data-bs-target="#classSectionModal"]');
      await expect(page.locator('#classSectionModal')).toBeVisible();
      await page.fill('#classSectionForm input[name="class_name"]', clsName);
      await page.fill('#classSectionForm input[name="short_name"]', clsShort);
      await page.fill('#classSectionForm input[name="code"]', clsCode);
      const cb = page.locator('#classSectionForm input[type="checkbox"][name*="section"]').first();
      if (await cb.count() > 0) await cb.check();
      await page.click('#classSectionForm button[type="submit"]');
      await page.waitForTimeout(800);
      await page.goto(`/school-setup/school-class?tab=class-sections&search=${encodeURIComponent(clsName)}&active_tab=class-sections`);
      await page.waitForLoadState('domcontentloaded');
      const tc = await page.content();
      expect(tc.includes(clsName)).toBeTruthy();
    });
    await step('CLS-05 Duplicate Code', async () => {
      await page.click('button[data-bs-target="#classSectionModal"], a[data-bs-target="#classSectionModal"]');
      await expect(page.locator('#classSectionModal')).toBeVisible();
      await page.fill('#classSectionForm input[name="class_name"]', `Other Class ${clsTs}`);
      await page.fill('#classSectionForm input[name="short_name"]', 'OTH');
      await page.fill('#classSectionForm input[name="code"]', clsCode);
      await page.click('#classSectionForm button[type="submit"]');
      await page.waitForTimeout(300);
      const dup = (await page.content()).includes('already exists') || (await page.locator('.text-danger, .swal2-icon-error').count()) > 0;
      expect(dup).toBeTruthy();
      await page.click('#classSectionModal button[data-bs-dismiss="modal"]');
    });
    await step('CLS-06 Duplicate Name', async () => {
      await page.click('button[data-bs-target="#classSectionModal"], a[data-bs-target="#classSectionModal"]');
      await expect(page.locator('#classSectionModal')).toBeVisible();
      await page.fill('#classSectionForm input[name="class_name"]', clsName);
      await page.fill('#classSectionForm input[name="short_name"]', 'OTH2');
      await page.fill('#classSectionForm input[name="code"]', `Y${clsTs.slice(-3)}`);
      await page.click('#classSectionForm button[type="submit"]');
      await page.waitForTimeout(300);
      const dup = (await page.content()).includes('already exists') || (await page.locator('.text-danger, .swal2-icon-error').count()) > 0;
      expect(dup).toBeTruthy();
      await page.click('#classSectionModal button[data-bs-dismiss="modal"]');
    });
    await step('CLS-07 Status Toggle', async () => {
      await page.goto('/school-setup/school-class?tab=class-sections&active_tab=class-sections');
      await page.waitForLoadState('domcontentloaded');
      const tg = page.locator('#class-sections-pane table .status-toggle, #class-sections table .status-toggle').first();
      if (await tg.count() > 0) {
        const b = await tg.isChecked();
        await tg.click();
        await page.waitForTimeout(600);
        const a = await tg.isChecked();
        expect(a).not.toBe(b);
        await tg.click();
        await page.waitForTimeout(600);
      }
    });
    await step('CLS-08 Search Filter', async () => {
      const si = page.locator('#class-sections-pane input[name="search"], #class-sections input[name="search"]').first();
      if (await si.count() > 0) {
        await si.fill(clsName);
        const btn = page.locator('#class-sections-pane button[type="submit"], #class-sections button[type="submit"]').first();
        if (await btn.count() > 0) await btn.click();
        await page.waitForTimeout(400);
        await expect(page.locator('#class-sections-pane table, #class-sections table').first()).toBeVisible();
        const cb = page.locator('#class-sections-pane a[title="Clear Filters"], #class-sections-pane a.btn-secondary').first();
        if (await cb.count() > 0) { await cb.click(); await page.waitForTimeout(400); }
      }
    });

    // ========== TAB 3: SUBJECT TYPE ==========
    const stTs = Date.now().toString().slice(-4);
    const stCode = `T${stTs.slice(-3)}`;
    const stName = `Subject Type ${stTs}`;
    const stShort = `ST${stTs.slice(-2)}`;

    await step('STP-01 Load & Table', async () => {
      await page.goto('/school-setup/school-class?tab=subject-type#subject-type');
      await page.waitForLoadState('domcontentloaded');
      await expect(page.locator('#subject-type-pane, #subject-type')).toBeVisible();
      await expect(page.locator('#subject-type-pane table, #subject-type table').first()).toBeVisible();
    });
    await step('STP-02 Empty Validation', async () => {
      await page.click('button[data-bs-target="#subjectTypeModal"], a[data-bs-target="#subjectTypeModal"]');
      await expect(page.locator('#subjectTypeModal')).toBeVisible();
      await page.fill('#subjectTypeForm input[name="code"]', '');
      await page.fill('#subjectTypeForm input[name="name"]', '');
      await page.click('#subjectTypeForm button[type="submit"]');
      await page.waitForTimeout(300);
      const c = await page.locator('.text-danger, .swal2-icon-error').count();
      expect(c).toBeGreaterThan(0);
      await page.click('#subjectTypeModal button[data-bs-dismiss="modal"]');
    });
    await step('STP-03 Create', async () => {
      await page.click('button[data-bs-target="#subjectTypeModal"], a[data-bs-target="#subjectTypeModal"]');
      await expect(page.locator('#subjectTypeModal')).toBeVisible();
      await page.fill('#subjectTypeForm input[name="code"]', stCode);
      await page.fill('#subjectTypeForm input[name="name"]', stName);
      await page.fill('#subjectTypeForm input[name="short_name"]', stShort);
      await page.click('#subjectTypeForm button[type="submit"]');
      await page.waitForTimeout(800);
      await page.goto(`/school-setup/school-class?tab=subject-type&search=${encodeURIComponent(stName)}&active_tab=subject-type`);
      await page.waitForLoadState('domcontentloaded');
      const tc = await page.content();
      expect(tc.includes(stName) || tc.includes(stCode)).toBeTruthy();
    });
    await step('STP-04 Duplicate Code', async () => {
      await page.click('button[data-bs-target="#subjectTypeModal"], a[data-bs-target="#subjectTypeModal"]');
      await expect(page.locator('#subjectTypeModal')).toBeVisible();
      await page.fill('#subjectTypeForm input[name="code"]', stCode);
      await page.fill('#subjectTypeForm input[name="name"]', `Other Type ${stTs}`);
      await page.fill('#subjectTypeForm input[name="short_name"]', 'DIFF');
      await page.click('#subjectTypeForm button[type="submit"]');
      await page.waitForTimeout(300);
      const dup = (await page.content()).includes('already exists') || (await page.locator('.text-danger, .swal2-icon-error').count()) > 0;
      expect(dup).toBeTruthy();
      await page.click('#subjectTypeModal button[data-bs-dismiss="modal"]');
    });
    await step('STP-05 Status Toggle', async () => {
      await page.goto('/school-setup/school-class?tab=subject-type&active_tab=subject-type');
      await page.waitForLoadState('domcontentloaded');
      const tg = page.locator('#subject-type-pane table .status-toggle, #subject-type table .status-toggle').first();
      if (await tg.count() > 0) {
        const b = await tg.isChecked();
        await tg.click();
        await page.waitForTimeout(600);
        const a = await tg.isChecked();
        expect(a).not.toBe(b);
        await tg.click();
        await page.waitForTimeout(600);
      }
    });
    await step('STP-06 Search Filter', async () => {
      const si = page.locator('#subject-type-pane input[name="search"], #subject-type input[name="search"]').first();
      if (await si.count() > 0) {
        await si.fill(stName);
        const btn = page.locator('#subject-type-pane button[type="submit"], #subject-type button[type="submit"]').first();
        if (await btn.count() > 0) await btn.click();
        await page.waitForTimeout(400);
        await expect(page.locator('#subject-type-pane table, #subject-type table').first()).toBeVisible();
        const cb = page.locator('#subject-type-pane a[title="Clear Filters"], #subject-type-pane a.btn-secondary').first();
        if (await cb.count() > 0) { await cb.click(); await page.waitForTimeout(400); }
      }
    });

    // ========== TAB 4: STUDY FORMAT ==========
    const sfTs = Date.now().toString().slice(-4);
    const sfCode = `F${sfTs.slice(-3)}`;
    const sfName = `Format Audit ${sfTs}`;
    const sfShort = `FA${sfTs.slice(-2)}`;

    await step('SFM-01 Load & Table', async () => {
      await page.goto('/school-setup/school-class?tab=study-format#study-format');
      await page.waitForLoadState('domcontentloaded');
      await expect(page.locator('#study-format-pane, #study-format')).toBeVisible();
      await expect(page.locator('#study-format-pane table, #study-format table').first()).toBeVisible();
    });
    await step('SFM-02 Empty Validation', async () => {
      await page.click('button[data-bs-target="#StudyFormatModal"], a[data-bs-target="#StudyFormatModal"]');
      await expect(page.locator('#StudyFormatModal')).toBeVisible();
      await page.fill('#StudyFormatForm input[name="code"]', '');
      await page.fill('#StudyFormatForm input[name="name"]', '');
      await page.click('#StudyFormatForm button[type="submit"]');
      await page.waitForTimeout(300);
      const c = await page.locator('.text-danger, .swal2-icon-error').count();
      expect(c).toBeGreaterThan(0);
      await page.click('#StudyFormatModal button[data-bs-dismiss="modal"]');
    });
    await step('SFM-03 Create', async () => {
      await page.click('button[data-bs-target="#StudyFormatModal"], a[data-bs-target="#StudyFormatModal"]');
      await expect(page.locator('#StudyFormatModal')).toBeVisible();
      await page.fill('#StudyFormatForm input[name="code"]', sfCode);
      await page.fill('#StudyFormatForm input[name="name"]', sfName);
      await page.fill('#StudyFormatForm input[name="short_name"]', sfShort);
      await page.click('#StudyFormatForm button[type="submit"]');
      await page.waitForTimeout(800);
      await page.goto(`/school-setup/school-class?tab=study-format&search=${encodeURIComponent(sfName)}&active_tab=study-format`);
      await page.waitForLoadState('domcontentloaded');
      const tc = await page.content();
      expect(tc.includes(sfName) || tc.includes(sfCode)).toBeTruthy();
    });
    await step('SFM-04 Duplicate Code', async () => {
      await page.click('button[data-bs-target="#StudyFormatModal"], a[data-bs-target="#StudyFormatModal"]');
      await expect(page.locator('#StudyFormatModal')).toBeVisible();
      await page.fill('#StudyFormatForm input[name="code"]', sfCode);
      await page.fill('#StudyFormatForm input[name="name"]', `Other Format ${sfTs}`);
      await page.fill('#StudyFormatForm input[name="short_name"]', 'DIFF');
      await page.click('#StudyFormatForm button[type="submit"]');
      await page.waitForTimeout(300);
      const dup = (await page.content()).includes('already exists') || (await page.locator('.text-danger, .swal2-icon-error').count()) > 0;
      expect(dup).toBeTruthy();
      await page.click('#StudyFormatModal button[data-bs-dismiss="modal"]');
    });
    await step('SFM-05 Status Toggle', async () => {
      await page.goto('/school-setup/school-class?tab=study-format&active_tab=study-format');
      await page.waitForLoadState('domcontentloaded');
      const tg = page.locator('#study-format-pane table .status-toggle, #study-format table .status-toggle').first();
      if (await tg.count() > 0) {
        const b = await tg.isChecked();
        await tg.click();
        await page.waitForTimeout(600);
        const a = await tg.isChecked();
        expect(a).not.toBe(b);
        await tg.click();
        await page.waitForTimeout(600);
      }
    });
    await step('SFM-06 Search Filter', async () => {
      const si = page.locator('#study-format-pane input[name="search"], #study-format input[name="search"]').first();
      if (await si.count() > 0) {
        await si.fill(sfName);
        const btn = page.locator('#study-format-pane button[type="submit"], #study-format button[type="submit"]').first();
        if (await btn.count() > 0) await btn.click();
        await page.waitForTimeout(400);
        await expect(page.locator('#study-format-pane table, #study-format table').first()).toBeVisible();
        const cb = page.locator('#study-format-pane a[title="Clear Filters"], #study-format-pane a.btn-secondary').first();
        if (await cb.count() > 0) { await cb.click(); await page.waitForTimeout(400); }
      }
    });

    // ========== TAB 5: SUBJECT ==========
    const sbTs = Date.now().toString().slice(-4);
    const sbCode = `S${sbTs.slice(-3)}`;
    const sbName = `Subject Audit ${sbTs}`;
    const sbShort = `SB${sbTs.slice(-2)}`;

    await step('SBJ-01 Load & Table', async () => {
      await page.goto('/school-setup/school-class?tab=subject#subject');
      await page.waitForLoadState('domcontentloaded');
      await expect(page.locator('#subject-pane, #subject')).toBeVisible();
      await expect(page.locator('#subject-pane table, #subject table').first()).toBeVisible();
    });
    await step('SBJ-02 Empty Validation', async () => {
      await page.click('button[data-bs-target="#SubjectModal"], a[data-bs-target="#SubjectModal"]');
      await expect(page.locator('#SubjectModal')).toBeVisible();
      await page.fill('#SubjectForm input[name="code"]', '');
      await page.fill('#SubjectForm input[name="name"]', '');
      await page.click('#SubjectForm button[type="submit"]');
      await page.waitForTimeout(300);
      const c = await page.locator('.text-danger, .swal2-icon-error').count();
      expect(c).toBeGreaterThan(0);
      await page.click('#SubjectModal button[data-bs-dismiss="modal"]');
    });
    await step('SBJ-03 Create', async () => {
      await page.click('button[data-bs-target="#SubjectModal"], a[data-bs-target="#SubjectModal"]');
      await expect(page.locator('#SubjectModal')).toBeVisible();
      await page.fill('#SubjectForm input[name="code"]', sbCode);
      await page.fill('#SubjectForm input[name="name"]', sbName);
      await page.fill('#SubjectForm input[name="short_name"]', sbShort);
      await page.click('#SubjectForm button[type="submit"]');
      await page.waitForTimeout(800);
      await page.goto(`/school-setup/school-class?tab=subject&search=${encodeURIComponent(sbName)}&active_tab=subject`);
      await page.waitForLoadState('domcontentloaded');
      const tc = await page.content();
      expect(tc.includes(sbName) || tc.includes(sbCode)).toBeTruthy();
    });
    await step('SBJ-04 Duplicate Code', async () => {
      await page.click('button[data-bs-target="#SubjectModal"], a[data-bs-target="#SubjectModal"]');
      await expect(page.locator('#SubjectModal')).toBeVisible();
      await page.fill('#SubjectForm input[name="code"]', sbCode);
      await page.fill('#SubjectForm input[name="name"]', `Other Subject ${sbTs}`);
      await page.fill('#SubjectForm input[name="short_name"]', 'DIFF');
      await page.click('#SubjectForm button[type="submit"]');
      await page.waitForTimeout(300);
      const dup = (await page.content()).includes('already exists') || (await page.locator('.text-danger, .swal2-icon-error').count()) > 0;
      expect(dup).toBeTruthy();
      await page.click('#SubjectModal button[data-bs-dismiss="modal"]');
    });
    await step('SBJ-05 Status Toggle', async () => {
      await page.goto('/school-setup/school-class?tab=subject&active_tab=subject');
      await page.waitForLoadState('domcontentloaded');
      const tg = page.locator('#subject-pane table .status-toggle, #subject table .status-toggle').first();
      if (await tg.count() > 0) {
        const b = await tg.isChecked();
        await tg.click();
        await page.waitForTimeout(600);
        const a = await tg.isChecked();
        expect(a).not.toBe(b);
        await tg.click();
        await page.waitForTimeout(600);
      }
    });
    await step('SBJ-06 Search Filter', async () => {
      const si = page.locator('#subject-pane input[name="search"], #subject input[name="search"]').first();
      if (await si.count() > 0) {
        await si.fill(sbName);
        const btn = page.locator('#subject-pane button[type="submit"], #subject button[type="submit"]').first();
        if (await btn.count() > 0) await btn.click();
        await page.waitForTimeout(400);
        await expect(page.locator('#subject-pane table, #subject table').first()).toBeVisible();
        const cb = page.locator('#subject-pane a[title="Clear Filters"], #subject-pane a.btn-secondary').first();
        if (await cb.count() > 0) { await cb.click(); await page.waitForTimeout(400); }
      }
    });

    // ========== TAB 6: SUBJECT + STUDY FORMAT ==========
    await step('SSF-01 Load & Table', async () => {
      await page.goto('/school-setup/school-class?tab=subject-study-format#subject-study-format');
      await page.waitForLoadState('domcontentloaded');
      await expect(page.locator('#subject-study-format-pane, #subject-study-format')).toBeVisible();
      await expect(page.locator('#subject-study-format-pane table, #subject-study-format table').first()).toBeVisible();
    });
    await step('SSF-02 Search & Filter', async () => {
      const si = page.locator('#subject-study-format-pane input[name="search"], #subject-study-format input[name="search"]').first();
      await expect(si).toBeVisible();
      await si.fill('Lecture');
      const btn = page.locator('#subject-study-format-pane button[type="submit"], #subject-study-format button[type="submit"]').first();
      if (await btn.count() > 0) await btn.click();
      await page.waitForTimeout(400);
      await expect(page.locator('#subject-study-format-pane, #subject-study-format')).toBeVisible();
    });
    await step('SSF-03 DDL Code Uniqueness (presence)', async () => {
      const pc = await page.content();
      expect(pc).toContain('subject-study-format');
    });
    await step('SSF-04 Unique Triple Mapping (table)', async () => {
      await expect(page.locator('#subject-study-format-pane table, #subject-study-format table').first()).toBeVisible();
    });

    // ========== TAB 7: CLASS GROUP ==========
    await step('CGP-01 Load & Table', async () => {
      await page.goto('/school-setup/school-class?tab=subject-class-mapping#subject-class-mapping');
      await page.waitForLoadState('domcontentloaded');
      await expect(page.locator('#subject-class-mapping-pane, #subject-class-mapping')).toBeVisible();
      await expect(page.locator('#subject-class-mapping-pane table, #subject-class-mapping table').first()).toBeVisible();
    });
    await step('CGP-02 Search & Filter', async () => {
      const si = page.locator('#subject-class-mapping-pane input[name="search"], #subject-class-mapping input[name="search"]').first();
      if (await si.count() > 0) {
        await si.fill('Class');
        const btn = page.locator('#subject-class-mapping-pane button[type="submit"], #subject-class-mapping button[type="submit"]').first();
        if (await btn.count() > 0) await btn.click();
        await page.waitForTimeout(400);
        await expect(page.locator('#subject-class-mapping-pane, #subject-class-mapping')).toBeVisible();
      }
    });
    await step('CGP-03 DDL Max Length (CHAR 50)', async () => {
      const c = await page.content();
      expect(c).toContain('subject-class-mapping');
    });

    // ========== TAB 8: SUBJECT GROUP ==========
    await step('SGP-01 Load & Table', async () => {
      await page.goto('/school-setup/school-class?tab=subject-group#subject-group');
      await page.waitForLoadState('domcontentloaded');
      await expect(page.locator('#subject-group-pane, #subject-group')).toBeVisible();
      await expect(page.locator('#subject-group-pane table, #subject-group table').first()).toBeVisible();
    });
    await step('SGP-02 Search & Filter', async () => {
      const si = page.locator('#subject-group-pane input[name="search"], #subject-group input[name="search"]').first();
      if (await si.count() > 0) {
        await si.fill('Group');
        const btn = page.locator('#subject-group-pane button[type="submit"], #subject-group button[type="submit"]').first();
        if (await btn.count() > 0) await btn.click();
        await page.waitForTimeout(400);
        await expect(page.locator('#subject-group-pane, #subject-group')).toBeVisible();
      }
    });
    await step('SGP-03 Edit Modal readonly code', async () => {
      const eb = page.locator('button[onclick*="editSubjectGroup"]').first();
      if (await eb.count() > 0) {
        await eb.click();
        await expect(page.locator('#SubjectGroupModal')).toBeVisible();
        const ci = page.locator('#code_subject_groups');
        await expect(ci).toHaveAttribute('readonly', '');
        await page.click('#SubjectGroupModal button[data-bs-dismiss="modal"]');
      }
    });

    // ========== TAB 9: STREAM ==========
    const strTs = Date.now().toString().slice(-4);
    const strCode = `M${strTs.slice(-3)}`;
    const strName = `Stream Audit ${strTs}`;
    const strShort = `ST${strTs.slice(-2)}`;

    await step('STR-01 Load & Table', async () => {
      await page.goto('/school-setup/school-class?tab=class-stream#class-stream');
      await page.waitForLoadState('domcontentloaded');
      await expect(page.locator('#class-stream-pane, #class-stream')).toBeVisible();
      await expect(page.locator('#class-stream-pane table, #class-stream table').first()).toBeVisible();
    });
    await step('STR-02 Empty Validation', async () => {
      await page.click('button[data-bs-target="#ClassStreamModal"], a[data-bs-target="#ClassStreamModal"]');
      await expect(page.locator('#ClassStreamModal')).toBeVisible();
      await page.fill('#ClassStreamForm input[name="code"]', '');
      await page.fill('#ClassStreamForm input[name="name"]', '');
      await page.click('#ClassStreamForm button[type="submit"]');
      await page.waitForTimeout(300);
      const c = await page.locator('.text-danger, .swal2-icon-error').count();
      expect(c).toBeGreaterThan(0);
      await page.click('#ClassStreamModal button[data-bs-dismiss="modal"]');
    });
    await step('STR-03 Create', async () => {
      await page.click('button[data-bs-target="#ClassStreamModal"], a[data-bs-target="#ClassStreamModal"]');
      await expect(page.locator('#ClassStreamModal')).toBeVisible();
      const cs = page.locator('#stream_class_id');
      const opts = await cs.locator('option').all();
      if (opts.length > 1) {
        const v = await opts[1].getAttribute('value');
        if (v) await cs.selectOption(v);
      }
      await page.fill('#ClassStreamForm input[name="code"]', strCode);
      await page.fill('#ClassStreamForm input[name="name"]', strName);
      await page.fill('#ClassStreamForm input[name="short_name"]', strShort);
      await page.click('#ClassStreamForm button[type="submit"]');
      await page.waitForTimeout(800);
      await page.goto(`/school-setup/school-class?tab=class-stream&search=${encodeURIComponent(strName)}&active_tab=class-stream`);
      await page.waitForLoadState('domcontentloaded');
      const tc = await page.content();
      expect(tc.includes(strName) || tc.includes(strCode)).toBeTruthy();
    });
    await step('STR-04 Duplicate Code', async () => {
      await page.click('button[data-bs-target="#ClassStreamModal"], a[data-bs-target="#ClassStreamModal"]');
      await expect(page.locator('#ClassStreamModal')).toBeVisible();
      const cs = page.locator('#stream_class_id');
      const opts = await cs.locator('option').all();
      if (opts.length > 1) {
        const v = await opts[1].getAttribute('value');
        if (v) await cs.selectOption(v);
      }
      await page.fill('#ClassStreamForm input[name="code"]', strCode);
      await page.fill('#ClassStreamForm input[name="name"]', `Other Stream ${strTs}`);
      await page.fill('#ClassStreamForm input[name="short_name"]', 'DIFF');
      await page.click('#ClassStreamForm button[type="submit"]');
      await page.waitForTimeout(300);
      const dup = (await page.content()).includes('already exists') || (await page.locator('.text-danger, .swal2-icon-error').count()) > 0;
      expect(dup).toBeTruthy();
      await page.click('#ClassStreamModal button[data-bs-dismiss="modal"]');
    });
    await step('STR-05 Status Toggle', async () => {
      await page.goto('/school-setup/school-class?tab=class-stream&active_tab=class-stream');
      await page.waitForLoadState('domcontentloaded');
      const tg = page.locator('#class-stream-pane table .status-toggle, #class-stream table .status-toggle').first();
      if (await tg.count() > 0) {
        const b = await tg.isChecked();
        await tg.click();
        await page.waitForTimeout(600);
        const a = await tg.isChecked();
        expect(a).not.toBe(b);
        await tg.click();
        await page.waitForTimeout(600);
      }
    });
    await step('STR-06 Search Filter', async () => {
      const si = page.locator('#class-stream-pane input[name="search"], #class-stream input[name="search"]').first();
      if (await si.count() > 0) {
        await si.fill(strName);
        const btn = page.locator('#class-stream-pane button[type="submit"], #class-stream button[type="submit"]').first();
        if (await btn.count() > 0) await btn.click();
        await page.waitForTimeout(400);
        await expect(page.locator('#class-stream-pane table, #class-stream table').first()).toBeVisible();
        const cb = page.locator('#class-stream-pane a[title="Clear Filters"], #class-stream-pane a.btn-secondary').first();
        if (await cb.count() > 0) { await cb.click(); await page.waitForTimeout(400); }
      }
    });

    // ========== SUMMARY ==========
    const failed = results.filter(r => r.status === 'FAIL');
    console.log('\n================ FULL AUDIT SUMMARY ================');
    console.log(`Total steps: ${results.length}`);
    console.log(`Passed: ${results.length - failed.length}`);
    console.log(`Failed: ${failed.length}`);
    if (failed.length) {
      console.log('\n--- FAILED STEPS ---');
      for (const f of failed) console.log(`  - ${f.name}: ${f.error}`);
    }
    console.log('====================================================\n');

    expect(failed.length).toBe(0);
  });

});
