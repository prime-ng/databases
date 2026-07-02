/**
 * Prime Design System — table-actions.js
 * Bulk-select behavior for data tables (AdminLTE v4 / Bootstrap 5.3).
 *
 * Markup contract:
 *   <div data-p-table-actions>
 *     <table>
 *       <thead><tr><th><input type="checkbox" data-p-check-all></th>...</tr></thead>
 *       <tbody><tr><td><input type="checkbox" data-p-check-row></td>...</tr></tbody>
 *     </table>
 *     <div data-p-bulk-toolbar hidden>
 *       <span data-p-bulk-count>0</span> selected
 *       <a href="#" data-p-select-across hidden>Select all across pages</a>
 *     </div>
 *   </div>
 *
 * Features: header checkbox toggles all row checkboxes, indeterminate state,
 * show/hide bulk toolbar with live count, "select all across pages" stub.
 * Idempotent; degrades gracefully.
 */
(function (w, d) {
  'use strict';
  var U = w.PrimeUtils || {};
  var qs = U.qs || function (s, r) { return (r || d).querySelector(s); };
  var qsa = U.qsa || function (s, r) { return Array.prototype.slice.call((r || d).querySelectorAll(s)); };

  function rows(scope) { return qsa('[data-p-check-row]', scope); }

  function refresh(scope) {
    var all = rows(scope);
    var checked = all.filter(function (c) { return c.checked; });
    var head = qs('[data-p-check-all]', scope);
    if (head) {
      head.checked = all.length > 0 && checked.length === all.length;
      head.indeterminate = checked.length > 0 && checked.length < all.length;
    }
    var toolbar = qs('[data-p-bulk-toolbar]', scope);
    var count = qs('[data-p-bulk-count]', scope);
    if (count) count.textContent = String(checked.length);
    if (toolbar) toolbar.hidden = checked.length === 0;

    // "Select all across pages" affordance appears only when the whole page is selected.
    var across = qs('[data-p-select-across]', scope);
    if (across) across.hidden = !(all.length > 0 && checked.length === all.length);
  }

  function bind(scope) {
    if (scope.__pTableActions) return; scope.__pTableActions = true;

    var head = qs('[data-p-check-all]', scope);
    if (head) {
      head.addEventListener('change', function () {
        rows(scope).forEach(function (c) { c.checked = head.checked; });
        // Toggling the header cancels any prior across-pages selection.
        scope.__selectAcross = false;
        refresh(scope);
      });
    }

    scope.addEventListener('change', function (e) {
      if (e.target && e.target.matches('[data-p-check-row]')) { scope.__selectAcross = false; refresh(scope); }
    });

    var across = qs('[data-p-select-across]', scope);
    if (across) {
      across.addEventListener('click', function (e) {
        e.preventDefault();
        // Stub: flag intent so the host app can query all matching IDs server-side.
        scope.__selectAcross = true;
        across.textContent = 'All items across pages selected';
        var evt;
        try { evt = new CustomEvent('p:select-across', { bubbles: true }); } catch (ex) { evt = d.createEvent('Event'); evt.initEvent('p:select-across', true, false); }
        scope.dispatchEvent(evt);
      });
    }

    refresh(scope);
  }

  function selected(scope) { return rows(scope).filter(function (c) { return c.checked; }); }

  function init(root) { qsa('[data-p-table-actions]', root).forEach(bind); }

  w.PrimeComponents = w.PrimeComponents || {};
  w.PrimeComponents.tableActions = { init: init, selected: selected };

  if (d.readyState === 'loading') d.addEventListener('DOMContentLoaded', function () { init(); });
  else init();
})(window, document);
