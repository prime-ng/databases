/**
 * Prime Design System — dropdown.js
 * Lightweight, framework-agnostic dropdown behavior for AdminLTE v4 / Bootstrap 5.3 markup.
 *
 * Markup contract:
 *   <div class="dropdown">
 *     <button data-p-dropdown aria-expanded="false">Toggle</button>
 *     <ul class="dropdown-menu"> <li><a class="dropdown-item" href="#">Item</a></li> ... </ul>
 *   </div>
 *
 * Features: toggle .dropdown-menu, outside-click + Esc close, aria-expanded sync,
 * keyboard arrow navigation between .dropdown-item elements.
 * Degrades gracefully (no menu = no-op). Idempotent init.
 */
(function (w, d) {
  'use strict';
  var U = w.PrimeUtils || {};
  var qsa = U.qsa || function (s, r) { return Array.prototype.slice.call((r || d).querySelectorAll(s)); };

  var OPEN = 'p-dropdown-open';

  function menuFor(toggle) {
    var menu = toggle.nextElementSibling;
    while (menu && !menu.classList.contains('dropdown-menu')) menu = menu.nextElementSibling;
    if (!menu && toggle.parentElement) menu = toggle.parentElement.querySelector('.dropdown-menu');
    return menu || null;
  }

  function items(menu) {
    return qsa('.dropdown-item:not([disabled]):not(.disabled)', menu);
  }

  function closeAll(except) {
    qsa('[data-p-dropdown]').forEach(function (t) {
      if (t === except) return;
      var m = menuFor(t);
      if (m && m.classList.contains(OPEN)) {
        m.classList.remove('show', OPEN);
        t.setAttribute('aria-expanded', 'false');
      }
    });
  }

  function open(toggle, menu, focusFirst) {
    closeAll(toggle);
    menu.classList.add('show', OPEN);
    toggle.setAttribute('aria-expanded', 'true');
    if (focusFirst) { var it = items(menu); if (it[0]) it[0].focus(); }
  }

  function close(toggle, menu, refocus) {
    menu.classList.remove('show', OPEN);
    toggle.setAttribute('aria-expanded', 'false');
    if (refocus) toggle.focus();
  }

  function bind(toggle) {
    if (toggle.__pDropdown) return;
    toggle.__pDropdown = true;
    var menu = menuFor(toggle);
    if (!menu) return;
    toggle.setAttribute('aria-haspopup', 'true');
    toggle.setAttribute('aria-expanded', 'false');

    toggle.addEventListener('click', function (e) {
      e.preventDefault();
      var isOpen = menu.classList.contains(OPEN);
      isOpen ? close(toggle, menu) : open(toggle, menu, false);
    });

    toggle.addEventListener('keydown', function (e) {
      if (e.key === 'ArrowDown' || e.key === 'Enter' || e.key === ' ') {
        e.preventDefault(); open(toggle, menu, true);
      }
    });

    menu.addEventListener('keydown', function (e) {
      var it = items(menu);
      var i = it.indexOf(d.activeElement);
      if (e.key === 'ArrowDown') { e.preventDefault(); (it[i + 1] || it[0]).focus(); }
      else if (e.key === 'ArrowUp') { e.preventDefault(); (it[i - 1] || it[it.length - 1]).focus(); }
      else if (e.key === 'Home') { e.preventDefault(); it[0] && it[0].focus(); }
      else if (e.key === 'End') { e.preventDefault(); it[it.length - 1] && it[it.length - 1].focus(); }
      else if (e.key === 'Escape') { e.preventDefault(); close(toggle, menu, true); }
    });
  }

  function init(root) {
    qsa('[data-p-dropdown]', root).forEach(bind);
  }

  // Global listeners bound once (guarded).
  if (!w.__pDropdownGlobal) {
    w.__pDropdownGlobal = true;
    d.addEventListener('click', function (e) {
      if (!e.target.closest('.dropdown-menu') && !e.target.closest('[data-p-dropdown]')) closeAll();
    });
    d.addEventListener('keydown', function (e) { if (e.key === 'Escape') closeAll(); });
  }

  w.PrimeComponents = w.PrimeComponents || {};
  w.PrimeComponents.dropdown = { init: init };

  if (d.readyState === 'loading') d.addEventListener('DOMContentLoaded', function () { init(); });
  else init();
})(window, document);
