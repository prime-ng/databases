/* ============================================================================
   Prime Design System — utils.js
   Tiny dependency-free DOM/helpers shared by the component JS in
   WEB_COMPONENTS/js/components/*. No framework, no build step — attach to
   window.Prime so components can call Prime.qs(...) etc.

   Exposed helpers:
     qs(sel, root?)      — querySelector shorthand
     qsa(sel, root?)     — querySelectorAll -> real Array
     on(el, evt, ...)    — addEventListener with optional delegation + cleanup fn
     debounce(fn, wait)  — trailing-edge debounce
     escapeHtml(str)     — escape text before injecting into innerHTML
   ========================================================================== */
(function (global) {
  'use strict';

  /**
   * querySelector shorthand.
   * @param {string} selector
   * @param {ParentNode} [root=document]
   * @returns {Element|null}
   */
  function qs(selector, root) {
    return (root || document).querySelector(selector);
  }

  /**
   * querySelectorAll returning a real Array (so map/filter/forEach just work).
   * @param {string} selector
   * @param {ParentNode} [root=document]
   * @returns {Element[]}
   */
  function qsa(selector, root) {
    return Array.prototype.slice.call((root || document).querySelectorAll(selector));
  }

  /**
   * addEventListener wrapper.
   * Two forms:
   *   on(el, 'click', handler, opts)                    — direct binding
   *   on(el, 'click', '.selector', handler, opts)       — delegated binding
   * Returns an off() function that removes the listener.
   *
   * @param {EventTarget} el
   * @param {string} type
   * @param {string|Function} selectorOrHandler
   * @param {Function|Object} [handlerOrOpts]
   * @param {Object|boolean} [opts]
   * @returns {Function} unbinder
   */
  function on(el, type, selectorOrHandler, handlerOrOpts, opts) {
    if (!el) return function () {};

    // Delegated form: selector string provided
    if (typeof selectorOrHandler === 'string') {
      var selector = selectorOrHandler;
      var handler = handlerOrOpts;
      var listener = function (event) {
        var target = event.target.closest(selector);
        if (target && el.contains(target)) {
          handler.call(target, event, target);
        }
      };
      el.addEventListener(type, listener, opts);
      return function () { el.removeEventListener(type, listener, opts); };
    }

    // Direct form
    var directHandler = selectorOrHandler;
    var directOpts = handlerOrOpts;
    el.addEventListener(type, directHandler, directOpts);
    return function () { el.removeEventListener(type, directHandler, directOpts); };
  }

  /**
   * Trailing-edge debounce — fires fn once activity stops for `wait` ms.
   * Useful for search inputs, resize handlers, etc.
   * @param {Function} fn
   * @param {number} [wait=200]
   * @returns {Function} debounced fn (with .cancel())
   */
  function debounce(fn, wait) {
    var timer = null;
    var w = wait == null ? 200 : wait;
    function debounced() {
      var ctx = this;
      var args = arguments;
      clearTimeout(timer);
      timer = setTimeout(function () {
        timer = null;
        fn.apply(ctx, args);
      }, w);
    }
    debounced.cancel = function () { clearTimeout(timer); timer = null; };
    return debounced;
  }

  /**
   * Escape a string for safe insertion into HTML (prevents markup injection).
   * @param {*} value
   * @returns {string}
   */
  function escapeHtml(value) {
    if (value == null) return '';
    return String(value)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  var Prime = global.Prime || {};
  Prime.qs = qs;
  Prime.qsa = qsa;
  Prime.on = on;
  Prime.debounce = debounce;
  Prime.escapeHtml = escapeHtml;
  global.Prime = Prime;

  // Also support ES-module / CommonJS consumers if bundled later.
  if (typeof module !== 'undefined' && module.exports) {
    module.exports = { qs: qs, qsa: qsa, on: on, debounce: debounce, escapeHtml: escapeHtml };
  }
})(typeof window !== 'undefined' ? window : this);
