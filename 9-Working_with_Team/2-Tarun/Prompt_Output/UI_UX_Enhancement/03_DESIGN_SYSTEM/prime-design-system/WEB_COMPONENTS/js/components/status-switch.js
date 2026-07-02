/**
 * Prime Design System — status-switch.js
 * Optimistic status toggle with server sync (reference implementation).
 *
 * Markup contract:
 *   <button data-p-status-switch role="switch" aria-checked="true"
 *           data-url="/api/records/5/status" data-method="PATCH"
 *           data-on-label="Active" data-off-label="Inactive">
 *     <span class="badge text-bg-success p-status-pill">Active</span>
 *   </button>
 *
 * Features: optimistically flips the pill + aria-checked, POSTs to data-url via
 * fetch, reverts on failure. Guarded to no-op (still flips locally) when no url
 * is present, so it is safe as a pure UI demo. Idempotent. Reduced-motion safe.
 */
(function (w, d) {
  'use strict';
  var U = w.PrimeUtils || {};
  var qsa = U.qsa || function (s, r) { return Array.prototype.slice.call((r || d).querySelectorAll(s)); };

  function csrf() {
    var m = d.querySelector('meta[name="csrf-token"]');
    return m ? m.getAttribute('content') : null;
  }

  function paint(el, on) {
    el.setAttribute('aria-checked', on ? 'true' : 'false');
    var pill = el.querySelector('.p-status-pill') || el;
    var onLabel = el.getAttribute('data-on-label') || 'Active';
    var offLabel = el.getAttribute('data-off-label') || 'Inactive';
    if (pill !== el || pill.classList.contains('p-status-pill')) pill.textContent = on ? onLabel : offLabel;
    pill.classList.toggle('text-bg-success', on);
    pill.classList.toggle('text-bg-secondary', !on);
  }

  function sync(el, on) {
    var url = el.getAttribute('data-url');
    if (!url) return Promise.resolve(true); // Guarded: no url -> local-only demo, no network.
    if (typeof w.fetch !== 'function') return Promise.resolve(true);
    var headers = { 'Accept': 'application/json', 'Content-Type': 'application/json', 'X-Requested-With': 'XMLHttpRequest' };
    var token = csrf();
    if (token) headers['X-CSRF-TOKEN'] = token;
    return w.fetch(url, {
      method: (el.getAttribute('data-method') || 'PATCH').toUpperCase(),
      headers: headers,
      credentials: 'same-origin',
      body: JSON.stringify({ status: on ? 1 : 0 })
    }).then(function (r) { return r.ok; }).catch(function () { return false; });
  }

  function toggle(el) {
    if (el.__busy) return;
    var current = el.getAttribute('aria-checked') === 'true';
    var next = !current;
    el.__busy = true;
    el.setAttribute('aria-busy', 'true');
    paint(el, next); // optimistic

    sync(el, next).then(function (ok) {
      if (!ok) {
        paint(el, current); // revert on failure
        if (w.PrimeToast) w.PrimeToast.show({ type: 'danger', title: 'Update failed', message: 'Status was reverted.' });
      }
    }).then(function () {
      el.__busy = false;
      el.removeAttribute('aria-busy');
    });
  }

  function bind(el) {
    if (el.__pStatus) return; el.__pStatus = true;
    el.setAttribute('role', 'switch');
    if (!el.hasAttribute('aria-checked')) el.setAttribute('aria-checked', 'true');
    el.addEventListener('click', function (e) { e.preventDefault(); toggle(el); });
    el.addEventListener('keydown', function (e) {
      if (e.key === ' ' || e.key === 'Enter') { e.preventDefault(); toggle(el); }
    });
  }

  function init(root) { qsa('[data-p-status-switch]', root).forEach(bind); }

  w.PrimeComponents = w.PrimeComponents || {};
  w.PrimeComponents.statusSwitch = { init: init };

  if (d.readyState === 'loading') d.addEventListener('DOMContentLoaded', function () { init(); });
  else init();
})(window, document);
