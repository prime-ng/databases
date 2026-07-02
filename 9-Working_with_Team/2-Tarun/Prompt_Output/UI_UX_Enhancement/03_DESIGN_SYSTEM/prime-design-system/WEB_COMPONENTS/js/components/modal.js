/**
 * Prime Design System — modal.js
 * Accessible modal open/close for AdminLTE v4 / Bootstrap 5.3 markup.
 *
 * Markup contract:
 *   <button data-p-modal-open="#myModal">Open</button>
 *   <div class="modal" id="myModal" role="dialog" aria-modal="true">
 *     <div class="modal-dialog">...  <button data-p-modal-close>×</button> ...</div>
 *   </div>
 *
 * Features: focus trap while open, Esc closes, returns focus to trigger,
 * backdrop element, body scroll lock, prefers-reduced-motion aware.
 * Idempotent; degrades gracefully when the target is missing.
 */
(function (w, d) {
  'use strict';
  var U = w.PrimeUtils || {};
  var qsa = U.qsa || function (s, r) { return Array.prototype.slice.call((r || d).querySelectorAll(s)); };

  var FOCUSABLE = 'a[href],button:not([disabled]),textarea,input,select,[tabindex]:not([tabindex="-1"])';
  var lastTrigger = null;
  var openModal = null;

  function focusables(modal) {
    return qsa(FOCUSABLE, modal).filter(function (el) { return el.offsetParent !== null || el === d.activeElement; });
  }

  function ensureBackdrop() {
    var bd = d.querySelector('.modal-backdrop.p-backdrop');
    if (!bd) {
      bd = d.createElement('div');
      bd.className = 'modal-backdrop fade show p-backdrop';
      d.body.appendChild(bd);
    }
    return bd;
  }

  function open(modal, trigger) {
    if (!modal || openModal) return;
    openModal = modal;
    lastTrigger = trigger || d.activeElement;
    ensureBackdrop();
    modal.classList.add('show');
    modal.style.display = 'block';
    modal.removeAttribute('aria-hidden');
    modal.setAttribute('aria-modal', 'true');
    d.body.classList.add('modal-open');
    d.body.style.overflow = 'hidden';
    var f = focusables(modal);
    (f[0] || modal).focus();
  }

  function close(modal) {
    modal = modal || openModal;
    if (!modal) return;
    modal.classList.remove('show');
    modal.style.display = 'none';
    modal.setAttribute('aria-hidden', 'true');
    var bd = d.querySelector('.modal-backdrop.p-backdrop');
    if (bd) bd.parentNode.removeChild(bd);
    d.body.classList.remove('modal-open');
    d.body.style.overflow = '';
    openModal = null;
    if (lastTrigger && lastTrigger.focus) lastTrigger.focus();
    lastTrigger = null;
  }

  function onKeydown(e) {
    if (!openModal) return;
    if (e.key === 'Escape') { e.preventDefault(); close(); return; }
    if (e.key === 'Tab') {
      var f = focusables(openModal);
      if (!f.length) { e.preventDefault(); return; }
      var first = f[0], last = f[f.length - 1];
      if (e.shiftKey && d.activeElement === first) { e.preventDefault(); last.focus(); }
      else if (!e.shiftKey && d.activeElement === last) { e.preventDefault(); first.focus(); }
    }
  }

  function init(root) {
    qsa('[data-p-modal-open]', root).forEach(function (btn) {
      if (btn.__pModal) return; btn.__pModal = true;
      btn.addEventListener('click', function (e) {
        e.preventDefault();
        var sel = btn.getAttribute('data-p-modal-open');
        open(sel && d.querySelector(sel), btn);
      });
    });
    qsa('[data-p-modal-close]', root).forEach(function (btn) {
      if (btn.__pModal) return; btn.__pModal = true;
      btn.addEventListener('click', function (e) { e.preventDefault(); close(btn.closest('.modal')); });
    });
  }

  if (!w.__pModalGlobal) {
    w.__pModalGlobal = true;
    d.addEventListener('keydown', onKeydown);
    d.addEventListener('click', function (e) {
      // Backdrop click (clicking the .modal element itself, not its dialog) closes.
      if (openModal && e.target === openModal) close();
    });
  }

  w.PrimeComponents = w.PrimeComponents || {};
  w.PrimeComponents.modal = { init: init, open: open, close: close };

  if (d.readyState === 'loading') d.addEventListener('DOMContentLoaded', function () { init(); });
  else init();
})(window, document);
