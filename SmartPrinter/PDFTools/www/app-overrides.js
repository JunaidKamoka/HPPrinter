// app-overrides.js
// Injected as FIRST script in <head>.
// Applies dark theme, redirects home → tools, hides all web chrome.

(function () {
  "use strict";

  // ── A. Redirect home page → tools listing ───────────────────────
  // Open directly on the PDF tools screen, not the landing/home page.
  var p = window.location.pathname;
  if (p === "/" || p === "" || p === "/en" || p === "/en/" ||
      p === "/en/index.html" || p === "/index.html") {
    // Replace history so back button doesn't loop
    window.location.replace("/en/tools/");
  }

  // ── B. Dark theme via injected <style> (safe for React hydration) ─
  var darkCSS = [
    ":root,html,.dark,html.dark{",
    "--color-background:240 23% 5%!important;",       /* #0a0a0f */
    "--color-card:240 20% 9%!important;",              /* #12121a */
    "--color-muted:240 19% 13%!important;",            /* #1a1a26 */
    "--color-border:244 30% 18%!important;",
    "--color-input:244 30% 18%!important;",
    "--color-foreground:240 33% 96%!important;",       /* #f0f0f8 */
    "--color-card-foreground:240 33% 96%!important;",
    "--color-muted-foreground:240 14% 63%!important;", /* #9090b0 */
    "--color-primary:243 100% 69%!important;",         /* #6c63ff */
    "--color-primary-foreground:0 0% 100%!important;",
    "--color-primary-hover:243 100% 58%!important;",
    "--color-accent:243 100% 69%!important;",
    "--color-accent-foreground:0 0% 100%!important;",
    "--color-secondary:243 20% 16%!important;",
    "--color-secondary-foreground:240 33% 96%!important;",
    "--color-ring:243 100% 69%!important;",
    "--radius-lg:18px!important;",
    "--radius-md:14px!important;",
    "--radius-sm:10px!important;",
    "}",
    "html,body{background:#0a0a0f!important;color:#f0f0f8!important;padding-top:0!important;margin-top:0!important;}",
    // Hide header + footer before React paints
    "header,header[role='banner'],footer,footer[role='contentinfo']{display:none!important;}",
    // Kill frosted glass
    ".glass-card,[class*='glass']{",
    "background:#12121a!important;",
    "background-image:none!important;",
    "backdrop-filter:none!important;",
    "-webkit-backdrop-filter:none!important;",
    "border-color:rgba(255,255,255,0.08)!important;",
    "}",
    // Remove top padding reserved for fixed header
    "main,[role='main'],.pt-20,.pt-16,.pt-14,.pt-12{padding-top:0!important;}",
    // Hide hero title and subtitle on tools page immediately
    "section[class*='pt-36'] h1,section[class*='pt-32'] h1{display:none!important;}",
    "section[class*='pt-36']>div>div>p,section[class*='pt-32']>div>div>p{display:none!important;}",
    "section[class*='pt-36'],section[class*='pt-32']{padding-top:8px!important;padding-bottom:0!important;}",
    "section[class*='py-8'][class*='min-h']{padding-top:0!important;background:transparent!important;min-height:0!important;}",
  ].join("");

  var styleEl = document.createElement("style");
  styleEl.id = "sp-dark-override";
  styleEl.textContent = darkCSS;
  var head = document.head || document.getElementsByTagName("head")[0];
  if (head.firstChild) {
    head.insertBefore(styleEl, head.firstChild);
  } else {
    head.appendChild(styleEl);
  }

  // ── C. After React hydration: DOM cleanup ────────────────────────
  function afterHydration() {
    var html = document.documentElement;
    html.classList.add("dark");
    html.classList.remove("light");

    // Brand text replacement
    replaceTextInNode(document.body);

    // Hide unwanted elements
    hideElements();

    // Remove top padding added by layout for the nav bar
    removeHeaderSpacing();

    // Compact tools listing page: merge search + filter onto one row
    compactToolsPage();
  }

  // ── D. Compact tools listing page ────────────────────────────────
  // Hides title/subtitle, merges search input into the filter bar row.
  var _toolsCompacted = false;
  function compactToolsPage() {
    var path = window.location.pathname;
    if (!/\/tools\/?(\?|#|$)/.test(path)) { _toolsCompacted = false; return; }
    if (_toolsCompacted) return;

    // Find hero section (has pt-36 or pt-32 class)
    var hero = document.querySelector("section[class*='pt-36']") ||
               document.querySelector("section[class*='pt-32']");
    if (!hero) return;

    // Find filter bar (sticky row with category chips)
    var filterBar = document.querySelector("[class*='sticky'][class*='top-20']");
    if (!filterBar) return;

    // 1. Hide decorative blobs, h1, subtitle
    var deco = hero.querySelector("div[class*='absolute'][class*='-z-10']");
    if (deco) deco.style.display = "none";
    var h1 = hero.querySelector("h1");
    if (h1) h1.style.display = "none";
    var subtitle = hero.querySelector("p");
    if (subtitle) subtitle.style.display = "none";
    hero.style.padding = "8px 0 0";

    // 2. Find search wrapper inside hero
    var searchWrap = hero.querySelector("[class*='max-w-2xl']");
    if (!searchWrap) return;

    // 3. Compact the input: smaller padding
    var searchInput = searchWrap.querySelector("input");
    if (searchInput) {
      searchInput.style.paddingTop = "10px";
      searchInput.style.paddingBottom = "10px";
      searchInput.style.fontSize = "15px";
    }

    // 4. Style search wrapper for inline layout
    searchWrap.style.flex = "1";
    searchWrap.style.maxWidth = "none";
    searchWrap.style.minWidth = "0";

    // 5. Hide the mobile-only "Filters" toggle button
    filterBar.querySelectorAll("button").forEach(function (btn) {
      if (!btn.getAttribute("aria-pressed") && /ilter/.test(btn.textContent)) {
        btn.style.display = "none";
      }
    });

    // 6. Show category chips on mobile (override hidden md:flex)
    var chipGroup = filterBar.querySelector("[role='group']");
    if (chipGroup) {
      chipGroup.style.display = "flex";
      chipGroup.style.flexWrap = "nowrap";
      chipGroup.style.overflowX = "auto";
      chipGroup.style.webkitOverflowScrolling = "touch";
      chipGroup.style.flex = "1";
      chipGroup.style.gap = "4px";
      chipGroup.style.scrollbarWidth = "none";
    }

    // 7. Move search wrapper into filter bar as first child
    filterBar.insertBefore(searchWrap, filterBar.firstChild);

    // 8. Make filter bar a compact flex row
    filterBar.style.flexDirection = "row";
    filterBar.style.alignItems = "center";
    filterBar.style.flexWrap = "nowrap";
    filterBar.style.gap = "8px";
    filterBar.style.padding = "6px 12px";
    filterBar.style.marginBottom = "6px";
    filterBar.style.position = "sticky";
    filterBar.style.top = "0";

    // 9. Collapse filter section background/padding
    var filterSection = filterBar.closest("section");
    if (filterSection) {
      filterSection.style.paddingTop = "0";
      filterSection.style.paddingBottom = "0";
      filterSection.style.background = "transparent";
      filterSection.style.minHeight = "0";
    }

    // 10. Compact result count bar
    var countBar = filterBar.nextElementSibling;
    if (countBar) {
      countBar.style.marginBottom = "6px";
      countBar.style.padding = "0 4px";
    }

    _toolsCompacted = true;
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
      "header",
      "header[role='banner']",
      "footer",
      "footer[role='contentinfo']",
      "a[href*='/workflow']",
      "a[href*='/about']",
      "a[href*='/faq']",
      "a[href*='/contact']",
      "a[href*='/privacy']",
      "a[href*='github.com']",
      "a[href*='x.com/']",
      "a[href*='twitter.com']",
      "a[href*='producthunt.com']",
      "#language-selector-slot",
      "[aria-label='Breadcrumb']",
      "nav[aria-label='breadcrumb']",
    ];
    sels.forEach(function (sel) {
      document.querySelectorAll(sel).forEach(function (el) {
        var li = el.closest("li");
        if (li) li.style.display = "none";
        el.style.display = "none";
      });
    });
    if (document.title)
      document.title = document.title.replace(/PDFCraft/gi, "Smart PDF");
  }

  function removeHeaderSpacing() {
    // Some layouts add top padding = header height; zero it out
    var candidates = [
      document.querySelector("main"),
      document.querySelector("[role='main']"),
      document.querySelector("#__next > div"),
      document.querySelector("body > div"),
    ];
    candidates.forEach(function (el) {
      if (!el) return;
      var pt = parseInt(window.getComputedStyle(el).paddingTop, 10);
      // If padding-top looks like a header offset (> 40px), remove it
      if (pt > 40) el.style.paddingTop = "0";
    });
  }

  // Run after React hydrates
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", function () {
      requestAnimationFrame(function () { requestAnimationFrame(afterHydration); });
    });
  } else {
    requestAnimationFrame(function () { requestAnimationFrame(afterHydration); });
  }

  // Re-run on client-side navigation (Next.js SPA transitions)
  var observer = new MutationObserver(function (mutations) {
    if (mutations.some(function (m) { return m.addedNodes.length > 0; })) {
      hideElements();
      removeHeaderSpacing();
      compactToolsPage();
    }
  });
  document.addEventListener("DOMContentLoaded", function () {
    observer.observe(document.body, { childList: true, subtree: false });
  });
})();
