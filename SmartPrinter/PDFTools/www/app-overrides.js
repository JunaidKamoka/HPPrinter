// app-overrides.js
// Injected as FIRST script in <head>.
// Applies dark theme, redirects home → tools, hides all web chrome.

(function () {
  "use strict";

  // ── 0. Favorites localStorage bridge for WKWebView custom scheme ──
  // WKWebView with smartpdf:// may not persist localStorage across sessions.
  // Proxy the favorites key through Swift UserDefaults via message handler.
  (function patchFavStorage() {
    var FAVKEY = "smartpdf-favorite-tools";
    var _mem = {};
    // Seed from Swift-injected window._spFavData (set before page load)
    try {
      if (window._spFavData && window._spFavData !== "null") {
        _mem[FAVKEY] = window._spFavData;
      }
    } catch (e) {}

    var _proto = Storage.prototype;
    var _origSet = _proto.setItem;
    var _origGet = _proto.getItem;
    var _origDel = _proto.removeItem;

    _proto.setItem = function (k, v) {
      try { _origSet.call(this, k, v); } catch (e) {}
      if (k === FAVKEY) {
        _mem[k] = String(v);
        try { window.webkit.messageHandlers.saveFavorites.postMessage(String(v)); } catch (e) {}
      }
    };

    _proto.getItem = function (k) {
      if (k === FAVKEY) {
        var real;
        try { real = _origGet.call(this, k); } catch (e) {}
        return (real !== null && real !== undefined) ? real : (_mem[k] || null);
      }
      try { return _origGet.call(this, k); } catch (e) { return null; }
    };

    _proto.removeItem = function (k) {
      try { _origDel.call(this, k); } catch (e) {}
      if (k === FAVKEY) {
        delete _mem[k];
        try { window.webkit.messageHandlers.saveFavorites.postMessage(""); } catch (e) {}
      }
    };
  })();

  // ── A. Redirect home page → tools listing ───────────────────────
  // Open directly on the PDF tools screen, not the landing/home page.
  var p = window.location.pathname;
  if (p === "/" || p === "" || p === "/en" || p === "/en/" ||
      p === "/en/index.html" || p === "/index.html") {
    // Replace history so back button doesn't loop
    window.location.replace("/en/tools/");
  }

  // ── B. Determine theme and apply class to <html> immediately ──────
  // Priority: native injection (window._appTheme) > prefers-color-scheme
  var _forced    = window._appTheme || "system";
  var _sysDark   = window.matchMedia("(prefers-color-scheme: dark)").matches;
  var _isDark    = _forced === "dark" || (_forced === "system" && _sysDark);

  // Set html class before any CSS loads — prevents flash of wrong theme
  var _html = document.documentElement;
  if (_isDark) {
    _html.classList.add("dark");
    _html.classList.remove("light");
  } else {
    _html.classList.add("light");
    _html.classList.remove("dark");
  }

  var darkVars = [
    "--color-background:222 63% 7%!important;",
    "--color-card:224 63% 12%!important;",
    "--color-muted:224 58% 16%!important;",
    "--color-border:224 50% 22%!important;",
    "--color-input:224 50% 22%!important;",
    "--color-foreground:220 40% 96%!important;",
    "--color-card-foreground:220 40% 96%!important;",
    "--color-muted-foreground:220 20% 63%!important;",
    "--color-primary:218 100% 62%!important;",
    "--color-primary-foreground:0 0% 100%!important;",
    "--color-primary-hover:218 100% 52%!important;",
    "--color-accent:218 100% 62%!important;",
    "--color-accent-foreground:0 0% 100%!important;",
    "--color-secondary:222 50% 18%!important;",
    "--color-secondary-foreground:220 40% 96%!important;",
    "--color-ring:218 100% 62%!important;",
  ].join("");

  var lightVars = [
    "--color-background:0 0% 100%!important;",
    "--color-card:220 100% 97%!important;",
    "--color-muted:220 80% 94%!important;",
    "--color-border:220 50% 88%!important;",
    "--color-input:220 50% 88%!important;",
    "--color-foreground:222 40% 10%!important;",
    "--color-card-foreground:222 40% 10%!important;",
    "--color-muted-foreground:222 20% 40%!important;",
    "--color-primary:222 99% 44%!important;",
    "--color-primary-foreground:0 0% 100%!important;",
    "--color-primary-hover:222 99% 36%!important;",
    "--color-accent:222 99% 44%!important;",
    "--color-accent-foreground:0 0% 100%!important;",
    "--color-secondary:220 80% 94%!important;",
    "--color-secondary-foreground:222 40% 10%!important;",
    "--color-ring:222 99% 44%!important;",
  ].join("");

  var sharedVars = "--radius-lg:18px!important;--radius-md:14px!important;--radius-sm:10px!important;";
  var baseBg  = _isDark ? "background:#060D1F!important;color:#E8EEFF!important;" : "background:#ffffff!important;color:#0A0F1F!important;";

  var earlyCSS = [
    ":root,html{", (_isDark ? darkVars : lightVars), sharedVars, "}",
    "html,body{", baseBg, "padding-top:0!important;margin-top:0!important;}",
    "header,header[role='banner'],footer,footer[role='contentinfo']{display:none!important;}",
    ".glass-card,[class*='glass']{background:hsl(var(--color-card))!important;background-image:none!important;backdrop-filter:none!important;-webkit-backdrop-filter:none!important;}",
    "main,[role='main'],.pt-20,.pt-16,.pt-14,.pt-12{padding-top:0!important;}",
    "section[class*='pt-36'] h1,section[class*='pt-32'] h1{display:none!important;}",
    "section[class*='pt-36']>div>div>p,section[class*='pt-32']>div>div>p{display:none!important;}",
    "section[class*='pt-36'],section[class*='pt-32']{padding-top:8px!important;padding-bottom:0!important;}",
    "section[class*='py-8'][class*='min-h']{padding-top:0!important;background:transparent!important;min-height:0!important;}",
  ].join("");

  var styleEl = document.createElement("style");
  styleEl.id = "sp-theme-override";
  styleEl.textContent = earlyCSS;
  var head = document.head || document.getElementsByTagName("head")[0];
  if (head.firstChild) {
    head.insertBefore(styleEl, head.firstChild);
  } else {
    head.appendChild(styleEl);
  }

  // Listen for system theme changes (applies when app theme = "system")
  window.matchMedia("(prefers-color-scheme: dark)").addEventListener("change", function(e) {
    if ((window._appTheme || "system") === "system") {
      applyThemeClass(e.matches);
    }
  });

  function applyThemeClass(isDark) {
    var h = document.documentElement;
    if (isDark) { h.classList.add("dark"); h.classList.remove("light"); }
    else        { h.classList.add("light"); h.classList.remove("dark"); }
  }

  // ── C. After React hydration: DOM cleanup ────────────────────────
  function afterHydration() {
    // Re-apply the correct theme class after React hydration
    applyThemeClass(_isDark);

    // Brand text replacement
    replaceTextInNode(document.body);

    // Hide unwanted elements
    hideElements();

    // Remove top padding added by layout for the nav bar
    removeHeaderSpacing();

    // Compact tools listing page: merge search + filter onto one row
    compactToolsPage();

    // Inject back button on tool detail pages
    injectBackButton();
  }

  // ── D-0. Tool detail page — back button ──────────────────────────
  function injectBackButton() {
    var path = window.location.pathname;
    // Tool detail: /en/tools/some-tool/ — NOT the listing /en/tools/
    var isToolDetail = /\/tools\/[^/]+\/?$/.test(path) && !/\/tools\/?$/.test(path);

    // Remove stale bar on non-tool pages
    var existing = document.getElementById("sp-back-bar");
    if (!isToolDetail) { if (existing) existing.remove(); return; }
    if (existing) return; // already injected

    // Build bar
    var bar = document.createElement("div");
    bar.id = "sp-back-bar";

    var btn = document.createElement("button");
    btn.id = "sp-back-btn";
    btn.type = "button";
    btn.innerHTML =
      '<svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="15 18 9 12 15 6"/></svg>' +
      '<span>All Tools</span>';
    btn.addEventListener("click", function () {
      window.location.href = "/en/tools/";
    });

    bar.appendChild(btn);

    // Insert as very first element inside body
    document.body.insertBefore(bar, document.body.firstChild);
  }

  // ── D. Compact tools listing page ────────────────────────────────
  // Hides title/subtitle, merges search + funnel-filter button into one row.
  var _toolsCompacted = false;
  var _filterUIInjected = false;
  function compactToolsPage() {
    var path = window.location.pathname;
    if (!/\/tools\/?(\?|#|$)/.test(path)) {
      _toolsCompacted = false;
      _filterUIInjected = false;
      return;
    }
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

    // 6. Hide chip group; inject professional funnel filter button instead
    var chipGroup = filterBar.querySelector("[role='group']");
    if (chipGroup) {
      chipGroup.style.display = "none";
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

    // 11. Inject funnel filter button + dropdown
    injectFilterUI(filterBar, chipGroup);

    _toolsCompacted = true;
  }

  // ── E. Funnel filter button + dropdown ───────────────────────────
  function injectFilterUI(filterBar, chipGroup) {
    if (_filterUIInjected || !chipGroup) return;
    var chips = Array.from(chipGroup.querySelectorAll("button[aria-pressed][class*='px-']"));
    if (chips.length === 0) return;

    // Wrapper (shrink, positioned)
    var wrap = document.createElement("div");
    wrap.id = "sp-filter-wrap";

    // Trigger button
    var btn = document.createElement("button");
    btn.id = "sp-filter-btn";
    btn.type = "button";
    btn.setAttribute("aria-haspopup", "listbox");
    btn.setAttribute("aria-expanded", "false");
    _updateFilterBtn(btn, chips);

    // Dropdown panel
    var dd = document.createElement("div");
    dd.id = "sp-filter-dropdown";
    dd.setAttribute("role", "listbox");
    dd.setAttribute("aria-hidden", "true");

    chips.forEach(function (chip, idx) {
      var raw   = chip.textContent.trim();
      var match = raw.match(/^(.*?)\((\d+)\)$/) || [raw, raw, ""];
      var label = match[1].trim();
      var count = match[2] || "";
      var isFav = label === "Favorite Tools";

      // Divider after Favorite Tools row
      if (idx > 0 && isFav) {
        var div = document.createElement("div");
        div.className = "sp-fi-divider";
        dd.appendChild(div);
      }

      var item = document.createElement("button");
      item.type = "button";
      item.className = "sp-filter-item" + (chip.getAttribute("aria-pressed") === "true" ? " sp-fi-active" : "");
      item.setAttribute("role", "option");
      item.dataset.label = label;

      item.innerHTML =
        '<span class="sp-fi-icon">' + (isFav ? _spStarSVG() : _spCatIcon(label)) + '</span>' +
        '<span class="sp-fi-label">' + label + '</span>' +
        (count ? '<span class="sp-fi-count">' + count + '</span>' : '') +
        '<span class="sp-fi-check">' + _spCheckSVG() + '</span>';

      item.addEventListener("click", function (e) {
        e.stopPropagation();
        chip.click();
        setTimeout(function () {
          _updateFilterBtn(btn, chips);
          dd.querySelectorAll(".sp-filter-item").forEach(function (it) {
            var c = chips.find(function (ch) {
              return ch.textContent.trim().replace(/\(\d+\)$/, "").trim() === it.dataset.label;
            });
            it.classList.toggle("sp-fi-active", !!(c && c.getAttribute("aria-pressed") === "true"));
          });
        }, 80);
        _closeDD(btn, dd);
      });

      dd.appendChild(item);
    });

    wrap.appendChild(btn);
    wrap.appendChild(dd);

    // Toggle dropdown on button click
    btn.addEventListener("click", function (e) {
      e.stopPropagation();
      var isOpen = dd.classList.toggle("sp-filter-open");
      btn.setAttribute("aria-expanded", isOpen ? "true" : "false");
      dd.setAttribute("aria-hidden", isOpen ? "false" : "true");
    });

    // Close on outside tap
    document.addEventListener("click", function () { _closeDD(btn, dd); });

    // Insert after search wrap
    var searchWrap = filterBar.querySelector("[class*='max-w-2xl']");
    if (searchWrap && searchWrap.nextSibling) {
      filterBar.insertBefore(wrap, searchWrap.nextSibling);
    } else {
      filterBar.appendChild(wrap);
    }

    _filterUIInjected = true;
  }

  function _closeDD(btn, dd) {
    dd.classList.remove("sp-filter-open");
    btn.setAttribute("aria-expanded", "false");
    dd.setAttribute("aria-hidden", "true");
  }

  function _updateFilterBtn(btn, chips) {
    var active = chips.find(function (c) { return c.getAttribute("aria-pressed") === "true"; });
    var raw    = active ? active.textContent.trim() : "All Tools";
    var match  = raw.match(/^(.*?)\((\d+)\)$/) || [raw, raw, ""];
    var label  = match[1].trim();
    var count  = match[2] || "";
    var filtered = label !== "All Tools";
    btn.className = filtered ? "sp-filtered" : "";
    btn.innerHTML =
      '<span class="sp-fb-icon">' + _spFunnelSVG(filtered) + '</span>' +
      '<span class="sp-fb-label">' + label + '</span>' +
      (filtered && count ? '<span class="sp-fb-badge">' + count + '</span>' : '') +
      '<span class="sp-fb-chevron">' + _spChevronSVG() + '</span>';
  }

  function _spFunnelSVG(active) {
    var c = active ? "#fff" : "currentColor";
    return '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="' + c + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><polygon points="22 3 2 3 10 12.46 10 19 14 21 14 12.46 22 3"/></svg>';
  }
  function _spChevronSVG() {
    return '<svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 9 12 15 18 9"/></svg>';
  }
  function _spCheckSVG() {
    return '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>';
  }
  function _spStarSVG() {
    return '<svg width="13" height="13" viewBox="0 0 24 24" fill="currentColor" stroke="none"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/></svg>';
  }
  function _spCatIcon(label) {
    var map = {
      "All Tools":         '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/></svg>',
      "Edit & Annotate":   '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>',
      "Convert to PDF":    '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="12" y1="18" x2="12" y2="12"/><line x1="9" y1="15" x2="15" y2="15"/></svg>',
      "Convert from PDF":  '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="12" y1="12" x2="12" y2="18"/><polyline points="9 15 12 18 15 15"/></svg>',
      "Organize & Manage": '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="8" y1="6" x2="21" y2="6"/><line x1="8" y1="12" x2="21" y2="12"/><line x1="8" y1="18" x2="21" y2="18"/><line x1="3" y1="6" x2="3.01" y2="6"/><line x1="3" y1="12" x2="3.01" y2="12"/><line x1="3" y1="18" x2="3.01" y2="18"/></svg>',
      "Optimize & Repair": '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="3"/><path d="M19.07 4.93a10 10 0 010 14.14M4.93 4.93a10 10 0 000 14.14"/></svg>',
      "Secure PDF":        '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0110 0v4"/></svg>'
    };
    return map[label] || map["All Tools"];
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
      injectBackButton();
    }
  });
  document.addEventListener("DOMContentLoaded", function () {
    observer.observe(document.body, { childList: true, subtree: false });
  });
})();
