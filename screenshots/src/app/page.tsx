"use client";

import { useEffect, useRef, useState, useCallback } from "react";
import { toPng } from "html-to-image";

// ─── Canvas dimensions ────────────────────────────────────────────────────────
const W = 1320;
const H = 2868;

// ─── iPhone mockup measurements ───────────────────────────────────────────────
const MK_W = 1022;
const MK_H = 2082;
const SC_L = (52 / MK_W) * 100;
const SC_T = (46 / MK_H) * 100;
const SC_W = (918 / MK_W) * 100;
const SC_H = (1990 / MK_H) * 100;
const SC_RX = (126 / 918) * 100;
const SC_RY = (126 / 1990) * 100;

// ─── Export sizes ─────────────────────────────────────────────────────────────
const SIZES = [
  { label: '6.9"', w: 1320, h: 2868 },
  { label: '6.5"', w: 1284, h: 2778 },
  { label: '6.3"', w: 1206, h: 2622 },
  { label: '6.1"', w: 1125, h: 2436 },
] as const;

// ─── 2-color palette ──────────────────────────────────────────────────────────
const BLUE = "#0149E1";
const WHITE = "#FFFFFF";

// ─── Phone mockup ─────────────────────────────────────────────────────────────
function Phone({ src, style }: { src: string; style?: React.CSSProperties }) {
  return (
    <div style={{ aspectRatio: `${MK_W}/${MK_H}`, position: "relative", ...style }}>
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img src="/mockup.png" alt="" draggable={false}
        style={{ display: "block", width: "100%", height: "100%" }} />
      <div style={{
        position: "absolute", left: `${SC_L}%`, top: `${SC_T}%`,
        width: `${SC_W}%`, height: `${SC_H}%`,
        borderRadius: `${SC_RX}% / ${SC_RY}%`, overflow: "hidden", zIndex: 10,
      }}>
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src={src} alt="" draggable={false}
          style={{ display: "block", width: "100%", height: "100%", objectFit: "cover", objectPosition: "top" }} />
      </div>
    </div>
  );
}

// ─── Caption ─────────────────────────────────────────────────────────────────
function Caption({
  label, headline, subtext, onBlue, align = "left", style,
}: {
  label: string;
  headline: React.ReactNode;
  subtext?: string;
  onBlue?: boolean;
  align?: "left" | "center";
  style?: React.CSSProperties;
}) {
  const fg = onBlue ? WHITE : BLUE;
  const muted = onBlue ? "rgba(255,255,255,0.6)" : "rgba(1,73,225,0.55)";
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: W * 0.016, textAlign: align, alignItems: align === "center" ? "center" : "flex-start", ...style }}>
      <div style={{ fontSize: W * 0.026, fontWeight: 700, letterSpacing: "0.12em", textTransform: "uppercase", color: muted }}>
        {label}
      </div>
      <div style={{ fontSize: W * 0.093, fontWeight: 900, lineHeight: 0.95, color: fg, letterSpacing: "-0.03em" }}>
        {headline}
      </div>
      {subtext && (
        <div style={{ fontSize: W * 0.029, fontWeight: 500, color: muted, marginTop: W * 0.006 }}>
          {subtext}
        </div>
      )}
    </div>
  );
}

// ─── Slide 1 — Hero (blue bg) ─────────────────────────────────────────────────
function Slide1() {
  return (
    <div style={{ width: W, height: H, background: BLUE, position: "relative", overflow: "hidden", fontFamily: "Inter, sans-serif" }}>
      {/* Decorative circles */}
      <div style={{ position: "absolute", top: -W * 0.35, right: -W * 0.25, width: W * 0.95, height: W * 0.95, borderRadius: "50%", background: "rgba(255,255,255,0.07)" }} />
      <div style={{ position: "absolute", top: -W * 0.1, right: -W * 0.05, width: W * 0.45, height: W * 0.45, borderRadius: "50%", background: "rgba(255,255,255,0.06)" }} />
      <div style={{ position: "absolute", bottom: H * 0.18, left: -W * 0.3, width: W * 0.65, height: W * 0.65, borderRadius: "50%", background: "rgba(255,255,255,0.04)" }} />

      {/* App icon */}
      <div style={{ position: "absolute", top: H * 0.065, left: 0, right: 0, display: "flex", justifyContent: "center" }}>
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src="/app-icon.png" alt="HP Smart Printer"
          style={{ width: W * 0.2, height: W * 0.2, borderRadius: W * 0.045, boxShadow: "0 16px 56px rgba(0,0,0,0.3)" }} />
      </div>

      {/* Caption */}
      <Caption
        label="HP Smart Printer"
        headline={<>Print anything.<br />Instantly.</>}
        subtext="Wi-Fi · AirPrint · PDF · Scan · Free"
        onBlue align="center"
        style={{ position: "absolute", top: H * 0.285, left: W * 0.07, right: W * 0.07 }}
      />

      {/* Phone */}
      <Phone src="/screenshots/home.png"
        style={{ position: "absolute", bottom: -H * 0.04, left: "50%", transform: "translateX(-50%)", width: W * 0.84 }} />
    </div>
  );
}

// ─── Slide 2 — PDF Tools (white bg) ──────────────────────────────────────────
function Slide2() {
  return (
    <div style={{ width: W, height: H, background: WHITE, position: "relative", overflow: "hidden", fontFamily: "Inter, sans-serif" }}>
      {/* Blue corner fill */}
      <div style={{ position: "absolute", top: 0, left: 0, right: 0, height: H * 0.52, background: BLUE }} />

      {/* Decorative circle on blue section */}
      <div style={{ position: "absolute", top: -W * 0.3, right: -W * 0.2, width: W * 0.85, height: W * 0.85, borderRadius: "50%", background: "rgba(255,255,255,0.07)" }} />

      {/* Phone first — floating elements rendered after sit on top */}
      <Phone src="/screenshots/pdf-tools.png"
        style={{ position: "absolute", bottom: -H * 0.03, left: "50%", transform: "translateX(-50%)", width: W * 0.82 }} />

      {/* Caption */}
      <Caption
        label="PDF Tools"
        headline={<>99+ tools.<br />All in one.</>}
        subtext="Merge · Split · OCR · Sign · Convert"
        onBlue align="center"
        style={{ position: "absolute", top: H * 0.07, left: W * 0.07, right: W * 0.07, zIndex: 20 }}
      />

      {/* Floating tool pills */}
      {[
        { label: "Merge PDF", x: W * 0.04, y: H * 0.33, rot: -6 },
        { label: "OCR Text", x: W * 0.62, y: H * 0.29, rot: 5 },
        { label: "Sign PDF", x: W * 0.66, y: H * 0.44, rot: -3 },
        { label: "Compress", x: W * 0.02, y: H * 0.46, rot: 4 },
      ].map(b => (
        <div key={b.label} style={{
          position: "absolute", left: b.x, top: b.y, zIndex: 20,
          background: "rgba(255,255,255,0.15)", border: "1px solid rgba(255,255,255,0.3)",
          borderRadius: W * 0.025, padding: `${W * 0.02}px ${W * 0.036}px`,
          fontSize: W * 0.032, fontWeight: 700, color: WHITE, transform: `rotate(${b.rot}deg)`,
        }}>
          {b.label}
        </div>
      ))}
    </div>
  );
}

// ─── Slide 3 — Forms (blue bg) ────────────────────────────────────────────────
function Slide3() {
  return (
    <div style={{ width: W, height: H, background: BLUE, position: "relative", overflow: "hidden", fontFamily: "Inter, sans-serif" }}>
      {/* Circles */}
      <div style={{ position: "absolute", top: -W * 0.25, left: -W * 0.25, width: W * 0.8, height: W * 0.8, borderRadius: "50%", background: "rgba(255,255,255,0.06)" }} />
      <div style={{ position: "absolute", bottom: H * 0.3, right: -W * 0.15, width: W * 0.55, height: W * 0.55, borderRadius: "50%", background: "rgba(255,255,255,0.04)" }} />

      {/* Phone first */}
      <Phone src="/screenshots/forms.png"
        style={{ position: "absolute", bottom: -H * 0.04, left: "-5%", width: W * 0.78, transform: "rotate(2deg) translateY(2%)" }} />

      {/* Caption */}
      <Caption
        label="Official Forms"
        headline={<>Every form.<br />Print-ready.</>}
        subtext="Tax · Legal · HR · Medical · Government"
        onBlue align="left"
        style={{ position: "absolute", top: H * 0.07, left: W * 0.08, right: W * 0.08, zIndex: 20 }}
      />

      {/* Floating form labels */}
      {[
        { label: "W-9 Tax Form", x: W * 0.56, y: H * 0.29, rot: 5 },
        { label: "Lease Agreement", x: W * 0.54, y: H * 0.43, rot: -3 },
        { label: "I-9 Employment", x: W * 0.58, y: H * 0.57, rot: 4 },
      ].map(c => (
        <div key={c.label} style={{
          position: "absolute", left: c.x, top: c.y, zIndex: 20,
          background: "rgba(255,255,255,0.14)", borderRadius: W * 0.028,
          padding: `${W * 0.022}px ${W * 0.038}px`,
          border: "1px solid rgba(255,255,255,0.25)",
          transform: `rotate(${c.rot}deg)`,
          fontSize: W * 0.033, fontWeight: 700, color: WHITE, whiteSpace: "nowrap",
        }}>
          {c.label}
        </div>
      ))}
    </div>
  );
}

// ─── Slide 4 — Printables (white bg) ─────────────────────────────────────────
function Slide4() {
  return (
    <div style={{ width: W, height: H, background: WHITE, position: "relative", overflow: "hidden", fontFamily: "Inter, sans-serif" }}>
      {/* Blue bottom fill */}
      <div style={{ position: "absolute", bottom: 0, left: 0, right: 0, height: H * 0.5, background: BLUE }} />

      {/* Circle on blue section */}
      <div style={{ position: "absolute", bottom: H * 0.1, right: -W * 0.2, width: W * 0.7, height: W * 0.7, borderRadius: "50%", background: "rgba(255,255,255,0.05)" }} />

      {/* Phone first */}
      <Phone src="/screenshots/printables.png"
        style={{ position: "absolute", bottom: -H * 0.03, right: "-3%", width: W * 0.82, transform: "rotate(-2deg) translateY(1%)" }} />

      {/* Caption */}
      <Caption
        label="Printables"
        headline={<>397 templates.<br />Print any.</>}
        subtext="22 categories · Art · Holiday · Invitations"
        align="center"
        style={{ position: "absolute", top: H * 0.07, left: W * 0.07, right: W * 0.07, zIndex: 20 }}
      />

      {/* Category pills */}
      <div style={{ position: "absolute", top: H * 0.33, left: W * 0.07, right: W * 0.07, zIndex: 20, display: "flex", flexWrap: "wrap", gap: W * 0.022, justifyContent: "center" }}>
        {["Invitations", "Holiday", "Art", "Birthday", "Baby Shower", "Coloring"].map(cat => (
          <div key={cat} style={{ background: BLUE, color: WHITE, borderRadius: W * 0.025, padding: `${W * 0.016}px ${W * 0.032}px`, fontSize: W * 0.03, fontWeight: 700 }}>
            {cat}
          </div>
        ))}
      </div>
    </div>
  );
}

// ─── Slide 5 — Quick Print (blue bg) ─────────────────────────────────────────
function Slide5() {
  return (
    <div style={{ width: W, height: H, background: BLUE, position: "relative", overflow: "hidden", fontFamily: "Inter, sans-serif" }}>
      {/* Circles */}
      <div style={{ position: "absolute", top: -W * 0.3, right: -W * 0.2, width: W * 0.9, height: W * 0.9, borderRadius: "50%", background: "rgba(255,255,255,0.06)" }} />
      <div style={{ position: "absolute", bottom: H * 0.2, left: -W * 0.25, width: W * 0.6, height: W * 0.6, borderRadius: "50%", background: "rgba(255,255,255,0.04)" }} />

      {/* Phone first */}
      <Phone src="/screenshots/home.png"
        style={{ position: "absolute", bottom: -H * 0.05, left: "-8%", width: W * 0.72, transform: "rotate(-2deg)" }} />

      {/* Caption */}
      <Caption
        label="Quick Print"
        headline={<>Print files.<br />Zero effort.</>}
        subtext="PDF · DOCX · JPG · Wi-Fi · AirPrint"
        onBlue align="left"
        style={{ position: "absolute", top: H * 0.07, left: W * 0.08, right: W * 0.08, zIndex: 20 }}
      />

      {/* Step indicators */}
      {[
        { num: "1", label: "Choose your file", y: H * 0.38 },
        { num: "2", label: "Select your printer", y: H * 0.47 },
        { num: "3", label: "Print instantly", y: H * 0.56 },
      ].map(s => (
        <div key={s.num} style={{ position: "absolute", left: W * 0.52, top: s.y, zIndex: 20, display: "flex", alignItems: "center", gap: W * 0.025 }}>
          <div style={{ width: W * 0.072, height: W * 0.072, borderRadius: "50%", background: WHITE, display: "flex", alignItems: "center", justifyContent: "center", fontSize: W * 0.033, fontWeight: 900, color: BLUE, flexShrink: 0 }}>
            {s.num}
          </div>
          <div style={{ fontSize: W * 0.034, fontWeight: 600, color: WHITE }}>
            {s.label}
          </div>
        </div>
      ))}
    </div>
  );
}

// ─── Slide registry ───────────────────────────────────────────────────────────
const SLIDES = [
  { id: "01-hero", label: "Hero", component: Slide1 },
  { id: "02-pdf-tools", label: "PDF Tools", component: Slide2 },
  { id: "03-forms", label: "Forms", component: Slide3 },
  { id: "04-printables", label: "Printables", component: Slide4 },
  { id: "05-quick-print", label: "Quick Print", component: Slide5 },
];

// ─── Preview card ─────────────────────────────────────────────────────────────
function ScreenshotPreview({
  slide,
  onRef,
  onExport,
  isExporting,
}: {
  slide: (typeof SLIDES)[0];
  onRef: (el: HTMLDivElement | null) => void;
  onExport: () => void;
  isExporting: boolean;
}) {
  const containerRef = useRef<HTMLDivElement>(null);
  const [scale, setScale] = useState(1);

  useEffect(() => {
    const el = containerRef.current;
    if (!el) return;
    const ro = new ResizeObserver(([entry]) => {
      const { width } = entry.contentRect;
      setScale(width / W);
    });
    ro.observe(el);
    return () => ro.disconnect();
  }, []);

  const SlideComponent = slide.component;

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 8, alignItems: "center" }}>
      {/* Preview */}
      <div
        ref={containerRef}
        onClick={onExport}
        title="Click to export"
        style={{ width: "100%", aspectRatio: `${W}/${H}`, position: "relative", overflow: "hidden", borderRadius: 12, boxShadow: "0 4px 24px rgba(0,0,0,0.22)", cursor: "pointer" }}
      >
        <div style={{ position: "absolute", top: 0, left: 0, width: W, height: H, transformOrigin: "top left", transform: `scale(${scale})` }}>
          <SlideComponent />
        </div>
        {isExporting && (
          <div style={{ position: "absolute", inset: 0, background: "rgba(1,73,225,0.35)", display: "flex", alignItems: "center", justifyContent: "center" }}>
            <div style={{ color: "#fff", fontWeight: 700, fontSize: 14, background: "rgba(0,0,0,0.55)", padding: "6px 14px", borderRadius: 8 }}>Exporting…</div>
          </div>
        )}
      </div>

      {/* Offscreen render — ref is a callback so it reliably wires to the DOM element */}
      <div
        ref={onRef}
        style={{ position: "absolute", left: -9999, top: 0, width: W, height: H, fontFamily: "Inter, sans-serif", pointerEvents: "none" }}
      >
        <SlideComponent />
      </div>

      <div style={{ fontSize: 12, fontWeight: 600, color: "#9CA3AF" }}>{slide.label}</div>
    </div>
  );
}

// ─── Main page ────────────────────────────────────────────────────────────────
export default function ScreenshotsPage() {
  const [sizeIdx, setSizeIdx] = useState(0);
  const [exportingIdx, setExportingIdx] = useState<number | null>(null);
  const exportRefs = useRef<(HTMLDivElement | null)[]>([]);

  const exportSlide = useCallback(async (idx: number, size: (typeof SIZES)[number]) => {
    const el = exportRefs.current[idx];
    if (!el) return;
    setExportingIdx(idx);

    // Move on-screen so browser renders images
    el.style.left = "0px";
    el.style.zIndex = "-1";

    const opts = { width: W, height: H, pixelRatio: 1, cacheBust: true };
    await toPng(el, opts); // warm-up pass
    const dataUrl = await toPng(el, opts); // clean pass

    el.style.left = "-9999px";
    el.style.zIndex = "";

    // Scale to target resolution
    const img = new Image();
    img.src = dataUrl;
    await new Promise(r => { img.onload = r; });
    const canvas = document.createElement("canvas");
    canvas.width = size.w;
    canvas.height = size.h;
    canvas.getContext("2d")!.drawImage(img, 0, 0, size.w, size.h);

    const a = document.createElement("a");
    a.href = canvas.toDataURL("image/png");
    a.download = `${SLIDES[idx].id}-${size.label.replace(/"/g, "in")}-${size.w}x${size.h}.png`;
    a.click();
    setExportingIdx(null);
  }, []);

  const exportAll = useCallback(async () => {
    const size = SIZES[sizeIdx];
    for (let i = 0; i < SLIDES.length; i++) {
      await exportSlide(i, size);
      await new Promise(r => setTimeout(r, 400));
    }
  }, [sizeIdx, exportSlide]);

  return (
    <div style={{ minHeight: "100vh", background: "#111827", fontFamily: "Inter, sans-serif" }}>
      {/* Toolbar */}
      <div style={{ position: "sticky", top: 0, zIndex: 100, background: "#1F2937", borderBottom: "1px solid #374151", padding: "12px 24px", display: "flex", alignItems: "center", gap: 16, flexWrap: "wrap" }}>
        <span style={{ color: "#fff", fontWeight: 700, fontSize: 15 }}>HP Smart Printer · Screenshots</span>
        <div style={{ flex: 1 }} />
        <select
          value={sizeIdx}
          onChange={e => setSizeIdx(Number(e.target.value))}
          style={{ background: "#374151", color: "#fff", border: "1px solid #4B5563", borderRadius: 8, padding: "6px 12px", fontSize: 13, fontWeight: 600 }}
        >
          {SIZES.map((s, i) => (
            <option key={s.label} value={i}>{s.label} — {s.w}×{s.h}</option>
          ))}
        </select>
        <button
          onClick={exportAll}
          style={{ background: BLUE, color: WHITE, border: "none", borderRadius: 8, padding: "8px 20px", fontSize: 13, fontWeight: 700, cursor: "pointer" }}
        >
          Export All ({SIZES[sizeIdx].label})
        </button>
      </div>

      {/* Grid */}
      <div style={{ padding: 24, display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(220px, 1fr))", gap: 24 }}>
        {SLIDES.map((slide, i) => (
          <ScreenshotPreview
            key={slide.id}
            slide={slide}
            onRef={(el) => { exportRefs.current[i] = el; }}
            onExport={() => exportSlide(i, SIZES[sizeIdx])}
            isExporting={exportingIdx === i}
          />
        ))}
      </div>

      <div style={{ padding: "0 24px 32px", color: "#6B7280", fontSize: 12 }}>
        Click any slide to export individually · Export All downloads all 5
      </div>
    </div>
  );
}
