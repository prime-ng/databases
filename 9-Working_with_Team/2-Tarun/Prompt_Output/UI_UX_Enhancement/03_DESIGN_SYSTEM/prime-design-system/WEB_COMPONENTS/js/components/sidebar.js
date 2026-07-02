/**
 * Prime Design System — sidebar.js
 * Collapse/expand and treeview behavior for the AdminLTE v4 .app-sidebar.
 *
 * Markup contract:
 *   <button data-p-sidebar-toggle>☰</button>
 *   <aside class="app-sidebar">
 *     <li class="nav-item has-treeview">
 *       <a class="nav-link" data-p-treeview-toggle>Parent</a>
 *       <ul class="nav nav-treeview">...</ul>
 *     </li>
 *   </aside>
 *
 * Features: toggles .sidebar-collapse on <body> (AdminLTE convention),
 * treeview submenu open/close (.menu-open), persists collapsed state in
 * localStorage. Idempotent; degrades gracefully. Respects reduced motion.
 */
(function (w, d) {
  'use strict';
  var U = w.PrimeUtils || {};
  var qsa = U.qsa || function (s, r) { return Array.prototype.slice.call((r || d).querySelectorAll(s)); };
  var KEY = 'prime.sidebar.collapsed';

  function setCollapsed(on) {
    d.body.classList.toggle('sidebar-collapse', on);
    try { localStorage.setItem(KEY, on ? '1' : '0'); } catch (e) {}
    qsa('[data-p-sidebar-toggle]').forEach(function (b) { b.setAttribute('aria-expanded', on ? 'false' : 'true'); });
  }

  function toggleTreeview(item) {
    var submenu = item.querySelector('.nav-treeview');
    if (!submenu) return;
    var willOpen = !item.classList.contains('menu-open');
    item.classList.toggle('menu-open', willOpen);
    var link = item.querySelector('[data-p-treeview-toggle]');
    if (link) link.setAttribute('aria-expanded', willOpen ? 'true' : 'false');
  }

  function init(root) {
    // Restore persisted collapsed state (once).
    if (!w.__pSidebarRestored) {
      w.__pSidebarRestored = true;
      var saved;
      try { saved = localStorage.getItem(KEY); } catch (e) {}
      if (saved === '1') d.body.classList.add('sidebar-collapse');
    }

    qsa('[data-p-sidebar-toggle]', root).forEach(function (btn) {
      if (btn.__pSidebar) return; btn.__pSidebar = true;
      btn.setAttribute('aria-controls', 'app-sidebar');
      btn.setAttribute('aria-expanded', d.body.classList.contains('sidebar-collapse') ? 'false' : 'true');
      btn.addEventListener('click', function (e) {
        e.preventDefault();
        setCollapsed(!d.body.classList.contains('sidebar-collapse'));
      });
    });

    qsa('.app-sidebar [data-p-treeview-toggle], .app-sidebar .has-treeview > .nav-link', root).forEach(function (link) {
      if (link.__pTree) return; link.__pTree = true;
      var item = link.closest('.nav-item, .has-treeview');
      if (!item || !item.querySelector('.nav-treeview')) return;
      link.setAttribute('aria-expanded', item.classList.contains('menu-open') ? 'true' : 'false');
      link.addEventListener('click', function (e) {
        // Only intercept parents (no real navigation target).
        var href = link.getAttribute('href');
        if (!href || href === '#') e.preventDefault();
        toggleTreeview(item);
      });
    });
  }

  w.PrimeComponents = w.PrimeComponents || {};
  w.PrimeComponents.sidebar = { init: init, setCollapsed: setCollapsed };

  if (d.readyState === 'loading') d.addEventListener('DOMContentLoaded', function () { init(); });
  else init();
})(window, document);
