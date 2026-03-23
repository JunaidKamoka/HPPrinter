// app-overrides.js
// Injected as FIRST script in <head>.
// Uses a <style> tag injection to apply dark theme so React hydration
// never sees a mismatch on html.className or html.style.

(function () {
  "use strict";

  // ── A. Dark theme via injected <style> (safe for React hydration) ──
  // Do NOT touch html.classList or html.style — React owns those during
  // hydration and any mutation causes error #418.
  var darkCSS = [
    ":root,html,.dark,html.dark{",
    "--color-background:240 28% 8%!important;",
    "--color-card:240 24% 12%!important;",
    "--color-muted:240 20% 16%!important;",
    "--color-border:244 35% 24%!important;",
    "--color-input:244 35% 24%!important;",
    "--color-foreground:240 8% 96%!important;",
    "--color-card-foreground:240 8% 96%!important;",
    "--color-muted-foreground:240 8% 62%!important;",
    "--color-primary:244 82% 70%!important;",
    "--color-primary-foreground:0 0% 100%!important;",
    "--color-primary-hover:244 82% 58%!important;",
    "--color-accent:244 82% 70%!important;",
    "--color-accent-foreground:0 0% 100%!important;",
    "--color-secondary:244 20% 18%!important;",
    "--color-secondary-foreground:240 8% 96%!important;",
    "--color-ring:244 82% 70%!important;",
    "--radius-lg:18px!important;",
    "--radius-md:14px!important;",
    "--radius-sm:10px!important;",
    "}",
    // Force dark bg/color on body (property, not variable – immediate)
    "html,body{background:#0f0f1c!important;color:#f2f2f8!important;}",
    // Kill frosted-glass white gradient
    ".glass-card,[class*='glass']{",
    "background:#171728!important;",
    "background-image:none!important;",
    "backdrop-filter:none!important;",
    "-webkit-backdrop-filter:none!important;",
    "border-color:rgba(120,117,240,.25)!important;",
    "}",
  ].join("");

  var styleEl = document.createElement("style");
  styleEl.id = "sp-dark-override";
  styleEl.textContent = darkCSS;
  // Insert at the very beginning of <head> so it applies before any other styles
  var head = document.head || document.getElementsByTagName("head")[0];
  if (head.firstChild) {
    head.insertBefore(styleEl, head.firstChild);
  } else {
    head.appendChild(styleEl);
  }

  // ── B. After React hydration: add .dark class + text cleanup ───────
  // Wait until React has finished hydrating before touching the DOM.
  function afterHydration() {
    // Now safe to add .dark class (React is done)
    var html = document.documentElement;
    html.classList.add("dark");
    html.classList.remove("light");

    // Text brand replacements
    replaceTextInNode(document.body);

    // Hide unwanted elements
    hideElements();
  }

  function replaceTextInNode(node) {
    if (!node) return;
    if (node.nodeType === Node.TEXT_NODE) {
      var t = node.textContent;
      var n = t.replace(/PDFCraft/g, "Smart PDF").replace(/pdfcraft/g, "smartpdf");
      if (n !== t) node.textContent = n;
    } else if (
      node.nodeType === Node.ELEMENT_NODE &&
      node.tagName !== "SCRIPT" &&
      node.tagName !== "STYLE"
    ) {
      ["title", "alt", "placeholder", "aria-label", "content"].forEach(function (a) {
        if (node.hasAttribute(a)) {
          var v = node.getAttribute(a);
          var nv = v.replace(/PDFCraft/g, "Smart PDF").replace(/pdfcraft/g, "smartpdf");
          if (nv !== v) node.setAttribute(a, nv);
        }
      });
      for (var i = 0; i < node.childNodes.length; i++) {
        replaceTextInNode(node.childNodes[i]);
      }
    }
  }

  function hideElements() {
    var sels = [
      'a[href*="/workflow"]', 'a[href*="/about"]',
      'a[href*="/faq"]',      'a[href*="/contact"]',
      'a[href*="github.com"]','a[href*="x.com/"]',
      '#language-selector-slot',
      'footer[role="contentinfo"]',
    ];
    sels.forEach(function (sel) {
      document.querySelectorAll(sel).forEach(function (el) {
        var li = el.closest("li");
        if (li) li.style.display = "none";
        el.style.display = "none";
      });
    });
    if (document.title)
      document.title = document.title.replace(/PDFCraft/g, "Smart PDF");
  }

  // Run after DOMContentLoaded (React hydration happens shortly after)
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", function () {
      // Small delay to let React finish hydration
      requestAnimationFrame(function () { requestAnimationFrame(afterHydration); });
    });
  } else {
    requestAnimationFrame(function () { requestAnimationFrame(afterHydration); });
  }

  // Re-run hide on client-side navigation
  var observer = new MutationObserver(function (mutations) {
    if (mutations.some(function (m) { return m.addedNodes.length > 0; })) {
      hideElements();
    }
  });
  document.addEventListener("DOMContentLoaded", function () {
    observer.observe(document.body, { childList: true, subtree: false });
  });
})();
