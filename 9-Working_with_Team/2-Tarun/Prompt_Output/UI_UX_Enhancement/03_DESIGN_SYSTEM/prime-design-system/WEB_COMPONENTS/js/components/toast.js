/**
 * Prime Design System — toast.js
 * Programmatic toast notifications for AdminLTE v4 / Bootstrap 5.3 styling.
 *
 * API:
 *   window.PrimeToast.show({ type:'success', title:'Saved', message:'Done', timeout:4000 });
 *
 * Features: top-right stack container, auto-dismiss with progress bar,
 * aria-live="polite", capped stack (oldest removed), click-to-dismiss,
 * prefers-reduced-motion aware (no progress animation). Idempotent.
 */
(function (w, d) {
  'use strict';
  var U = w.PrimeUtils || {};
  var esc = U.escapeHtml || function (s) {
    return String(s).replace(/[&<>"']/g, function (c) {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
    });
  };

  var MAX = 5;
  var TYPES = { success: 'text-bg-success', danger: 'text-bg-danger', error: 'text-bg-danger', warning: 'text-bg-warning', info: 'text-bg-info', primary: 'text-bg-primary' };
  var reduce = w.matchMedia && w.matchMedia('(prefers-reduced-motion: reduce)').matches;

  function container() {
    var c = d.querySelector('.p-toast-stack');
    if (!c) {
      c = d.createElement('div');
      c.className = 'toast-container p-toast-stack position-fixed top-0 end-0 p-3';
      c.setAttribute('aria-live', 'polite');
      c.setAttribute('aria-atomic', 'true');
      c.style.zIndex = '1090';
      d.body.appendChild(c);
    }
    return c;
  }

  function dismiss(el) {
    if (!el || el.__gone) return;
    el.__gone = true;
    el.classList.remove('show');
    el.style.opacity = '0';
    setTimeout(function () { if (el.parentNode) el.parentNode.removeChild(el); }, reduce ? 0 : 200);
  }

  function show(opts) {
    opts = opts || {};
    var type = TYPES[opts.type] || TYPES.info;
    var timeout = typeof opts.timeout === 'number' ? opts.timeout : 4000;
    var c = container();

    // Enforce max stack: drop the oldest.
    while (c.children.length >= MAX) c.removeChild(c.firstChild);

    var el = d.createElement('div');
    el.className = 'toast show p-toast ' + type;
    el.setAttribute('role', 'status');
    el.style.transition = reduce ? 'none' : 'opacity .2s ease';
    el.innerHTML =
      (opts.title ? '<div class="toast-header"><strong class="me-auto">' + esc(opts.title) + '</strong>' +
        '<button type="button" class="btn-close" aria-label="Close"></button></div>' : '') +
      '<div class="toast-body">' + esc(opts.message || '') + '</div>' +
      (timeout > 0 && !reduce ? '<div class="p-toast-progress" style="height:3px;background:rgba(0,0,0,.25);width:100%"></div>' : '');

    // Click anywhere (or the close button) dismisses.
    el.addEventListener('click', function () { dismiss(el); });
    c.appendChild(el);

    if (timeout > 0) {
      var bar = el.querySelector('.p-toast-progress');
      if (bar) {
        requestAnimationFrame(function () {
          bar.style.transition = 'width ' + timeout + 'ms linear';
          bar.style.width = '0%';
        });
      }
      el.__timer = setTimeout(function () { dismiss(el); }, timeout);
    }
    return el;
  }

  w.PrimeToast = w.PrimeToast || { show: show };
  w.PrimeComponents = w.PrimeComponents || {};
  // init is a no-op (toast is programmatic) but kept for a uniform interface.
  w.PrimeComponents.toast = { init: function () {}, show: show };
})(window, document);
