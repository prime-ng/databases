/**
 * Prime Design System — tabs.js
 * Accessible tabs for AdminLTE v4 / Bootstrap 5.3 markup.
 *
 * Markup contract:
 *   <div data-p-tabs data-p-hash="true">
 *     <ul class="nav nav-tabs" role="tablist">
 *       <li class="nav-item"><a class="nav-link active" data-p-target="#tab1" role="tab">One</a></li>
 *     </ul>
 *     <div class="tab-content">
 *       <div class="tab-pane active" id="tab1" role="tabpanel">...</div>
 *     </div>
 *   </div>
 *
 * Features: click switch, roving tabindex, Left/Right/Home/End arrow nav,
 * aria-selected sync, optional URL hash sync (data-p-hash="true").
 * Idempotent; degrades gracefully.
 */
(function (w, d) {
  'use strict';
  var U = w.PrimeUtils || {};
  var qsa = U.qsa || function (s, r) { return Array.prototype.slice.call((r || d).querySelectorAll(s)); };

  function tabsIn(group) { return qsa('.nav-link[data-p-target]', group); }

  function paneFor(group, tab) {
    var sel = tab.getAttribute('data-p-target');
    return sel ? group.querySelector(sel) : null;
  }

  function activate(group, tab, useHash) {
    tabsIn(group).forEach(function (t) {
      var on = t === tab;
      t.classList.toggle('active', on);
      t.setAttribute('aria-selected', on ? 'true' : 'false');
      t.setAttribute('role', 'tab');
      t.tabIndex = on ? 0 : -1;
      var pane = paneFor(group, t);
      if (pane) { pane.classList.toggle('active', on); pane.classList.toggle('show', on); pane.setAttribute('role', 'tabpanel'); }
    });
    if (useHash && tab.getAttribute('data-p-target')) {
      try { history.replaceState(null, '', tab.getAttribute('data-p-target')); } catch (e) {}
    }
  }

  function bind(group) {
    if (group.__pTabs) return; group.__pTabs = true;
    var tabs = tabsIn(group);
    if (!tabs.length) return;
    var useHash = group.getAttribute('data-p-hash') === 'true';

    tabs.forEach(function (tab) {
      tab.addEventListener('click', function (e) { e.preventDefault(); activate(group, tab, useHash); tab.focus(); });
      tab.addEventListener('keydown', function (e) {
        var i = tabs.indexOf(tab), next;
        if (e.key === 'ArrowRight' || e.key === 'ArrowDown') next = tabs[i + 1] || tabs[0];
        else if (e.key === 'ArrowLeft' || e.key === 'ArrowUp') next = tabs[i - 1] || tabs[tabs.length - 1];
        else if (e.key === 'Home') next = tabs[0];
        else if (e.key === 'End') next = tabs[tabs.length - 1];
        if (next) { e.preventDefault(); activate(group, next, useHash); next.focus(); }
      });
    });

    // Restore from hash, else keep the markup's active tab (default first).
    var initial = null;
    if (useHash && w.location.hash) {
      initial = tabs.filter(function (t) { return t.getAttribute('data-p-target') === w.location.hash; })[0];
    }
    if (!initial) initial = tabs.filter(function (t) { return t.classList.contains('active'); })[0] || tabs[0];
    activate(group, initial, false);
  }

  function init(root) { qsa('[data-p-tabs]', root).forEach(bind); }

  w.PrimeComponents = w.PrimeComponents || {};
  w.PrimeComponents.tabs = { init: init };

  if (d.readyState === 'loading') d.addEventListener('DOMContentLoaded', function () { init(); });
  else init();
})(window, document);
