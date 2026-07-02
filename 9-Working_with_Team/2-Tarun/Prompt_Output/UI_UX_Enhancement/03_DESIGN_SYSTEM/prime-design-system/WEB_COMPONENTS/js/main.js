/* ============================================================================
   Prime Design System — main.js
   Shared behavior for the gallery pages: theme toggle, mobile-width preview,
   copy-to-clipboard, and self-initializing component hooks.
   Vanilla JS (no framework). The app itself uses jQuery; these helpers are
   framework-agnostic and safe to port into public/backend/js/prime-modern-ui.js
   ========================================================================== */
(function () {
  'use strict';

  /* ── Theme toggle (light/dark via data-bs-theme, matching AdminLTE v4) ───── */
  var THEME_KEY = 'prime-ds-theme';
  function applyTheme(t) {
    document.documentElement.setAttribute('data-bs-theme', t);
    try { localStorage.setItem(THEME_KEY, t); } catch (e) {}
    var btn = document.querySelector('[data-ds-theme-toggle] .ds-theme-label');
    var icon = document.querySelector('[data-ds-theme-toggle] i');
    if (btn) btn.textContent = t === 'dark' ? 'Dark' : 'Light';
    if (icon) icon.className = t === 'dark' ? 'bi bi-moon-stars' : 'bi bi-sun';
  }
  // restore saved theme (flash-prevention: run early)
  try {
    var saved = localStorage.getItem(THEME_KEY);
    if (saved) applyTheme(saved);
  } catch (e) {}

  /* ── Width preview toggle (desktop <-> mobile 520px frame) ────────────────── */
  function toggleWidth() {
    var content = document.querySelector('.ds-content');
    if (content) content.classList.toggle('ds-narrow');
    var label = document.querySelector('[data-ds-width-toggle] .ds-width-label');
    if (label) label.textContent = content && content.classList.contains('ds-narrow') ? 'Mobile' : 'Desktop';
  }

  /* ── Copy-to-clipboard for code blocks ───────────────────────────────────── */
  function copyCode(btn) {
    var pre = btn.closest('.ds-code');
    if (!pre) return;
    var code = pre.querySelector('code') || pre;
    var text = code.innerText.replace(/\n\s*Copy\s*$/, '');
    navigator.clipboard && navigator.clipboard.writeText(text).then(function () {
      var old = btn.textContent; btn.textContent = 'Copied!';
      setTimeout(function () { btn.textContent = old; }, 1200);
    });
  }

  /* ── Wire up on load ─────────────────────────────────────────────────────── */
  document.addEventListener('DOMContentLoaded', function () {
    var tt = document.querySelector('[data-ds-theme-toggle]');
    if (tt) tt.addEventListener('click', function () {
      var cur = document.documentElement.getAttribute('data-bs-theme') || 'light';
      applyTheme(cur === 'dark' ? 'light' : 'dark');
    });
    var wt = document.querySelector('[data-ds-width-toggle]');
    if (wt) wt.addEventListener('click', toggleWidth);

    document.querySelectorAll('.ds-copy').forEach(function (b) {
      b.addEventListener('click', function () { copyCode(b); });
    });

    // sync initial labels
    applyTheme(document.documentElement.getAttribute('data-bs-theme') || 'light');
  });

  /* Expose for component demo pages that self-init */
  window.PrimeDS = { applyTheme: applyTheme, toggleWidth: toggleWidth };
})();
