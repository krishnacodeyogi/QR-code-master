import { useState, useEffect, useRef, useCallback } from "react";
import QRCode from "qrcode";
import { Download, Copy, Wand2, QrCode, ArrowLeftRight } from "lucide-react";
import { useToast } from "@/hooks/use-toast";

type ECLevel = "L" | "M" | "Q" | "H";

export default function QRGenerator() {
  const [text, setText] = useState("");
  const [debouncedText, setDebouncedText] = useState("");
  const [fgColor, setFgColor] = useState("#ffffff");
  const [bgColor, setBgColor] = useState("#1e1b4b");
  const [size, setSize] = useState(250);
  const [ecLevel, setEcLevel] = useState<ECLevel>("M");
  const [hasQR, setHasQR] = useState(false);

  const canvasRef = useRef<HTMLCanvasElement>(null);
  const { toast } = useToast();

  useEffect(() => {
    const timer = setTimeout(() => setDebouncedText(text), 300);
    return () => clearTimeout(timer);
  }, [text]);

  const generateQRCode = useCallback(async () => {
    if (!canvasRef.current) return;
    if (!debouncedText) {
      const ctx = canvasRef.current.getContext("2d");
      if (ctx) ctx.clearRect(0, 0, canvasRef.current.width, canvasRef.current.height);
      setHasQR(false);
      return;
    }
    try {
      await QRCode.toCanvas(canvasRef.current, debouncedText, {
        width: size,
        margin: 2,
        color: { dark: fgColor, light: bgColor },
        errorCorrectionLevel: ecLevel,
      });
      setHasQR(true);
    } catch {
      toast({ title: "Generation failed", description: "Could not generate QR code.", variant: "destructive" });
    }
  }, [debouncedText, fgColor, bgColor, size, ecLevel, toast]);

  useEffect(() => { generateQRCode(); }, [generateQRCode]);

  const handleManualGenerate = () => { setDebouncedText(text); };

  const handleDownload = () => {
    if (!canvasRef.current || !hasQR) return;
    const url = canvasRef.current.toDataURL("image/png");
    const a = document.createElement("a");
    a.href = url;
    a.download = "qr-code.png";
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    toast({ title: "Downloaded", description: "QR code saved as qr-code.png" });
  };

  const handleCopy = () => {
    if (!canvasRef.current || !hasQR) return;
    canvasRef.current.toBlob((blob) => {
      if (!blob) return;
      navigator.clipboard.write([new ClipboardItem({ "image/png": blob })])
        .then(() => toast({ title: "Copied", description: "QR code copied to clipboard." }))
        .catch(() => toast({ title: "Copy failed", description: "Clipboard access denied.", variant: "destructive" }));
    });
  };

  const handleSwapColors = () => {
    const tmp = fgColor;
    setFgColor(bgColor);
    setBgColor(tmp);
  };

  const sizePercent = ((size - 150) / (400 - 150)) * 100;

  return (
    <div className="nebula-bg min-h-screen flex items-center justify-center p-4 sm:p-8 relative overflow-hidden">
      {/* Subtle nebula cloud overlays */}
      <div
        className="pointer-events-none fixed inset-0 z-0"
        style={{
          background: `
            radial-gradient(ellipse 55% 45% at 8% 12%, rgba(112, 36, 196, 0.18) 0%, transparent 65%),
            radial-gradient(ellipse 35% 30% at 2% 2%, rgba(88, 20, 172, 0.22) 0%, transparent 55%),
            radial-gradient(ellipse 45% 35% at 90% 85%, rgba(50, 18, 110, 0.14) 0%, transparent 60%)
          `,
        }}
      />

      <div className="w-full max-w-5xl grid grid-cols-1 lg:grid-cols-12 gap-5 relative z-10">

        {/* ── LEFT PANEL ── */}
        <div className="lg:col-span-7 flex flex-col gap-6 p-7 sm:p-9 rounded-3xl glass-panel glass-panel-hover">

          {/* Header */}
          <div>
            <h1
              className="text-4xl sm:text-5xl font-bold tracking-tight mb-2"
              style={{
                background: "linear-gradient(135deg, #c084fc 0%, #a78bfa 40%, #818cf8 100%)",
                WebkitBackgroundClip: "text",
                WebkitTextFillColor: "transparent",
                backgroundClip: "text",
                filter: "drop-shadow(0 0 18px rgba(192, 132, 252, 0.4))",
              }}
            >
              QR Studio
            </h1>
            <p className="text-sm font-light" style={{ color: "rgba(196, 181, 253, 0.55)" }}>
              Craft precision QR codes instantly.
            </p>
          </div>

          {/* Content textarea */}
          <div className="space-y-2">
            <label
              htmlFor="qr-input"
              className="text-xs font-semibold uppercase tracking-widest"
              style={{ color: "rgba(196, 181, 253, 0.6)" }}
            >
              Content
            </label>
            <div
              className="input-glow rounded-2xl overflow-hidden"
              style={{
                background: "rgba(0, 0, 0, 0.25)",
                border: "1px solid rgba(180, 140, 255, 0.14)",
                boxShadow: "inset 0 2px 8px rgba(0,0,0,0.3), inset 0 1px 0 rgba(255,255,255,0.04)",
              }}
            >
              <textarea
                id="qr-input"
                data-testid="input-qr-content"
                placeholder="Enter URL or text..."
                value={text}
                onChange={(e) => setText(e.target.value)}
                rows={4}
                className="w-full bg-transparent resize-none px-4 pt-4 pb-2 text-sm outline-none"
                style={{
                  color: "rgba(230, 220, 255, 0.9)",
                  fontFamily: "var(--app-font-sans)",
                }}
              />
              <div
                className="px-4 pb-3 text-right text-xs font-mono"
                style={{ color: "rgba(180, 150, 255, 0.35)" }}
              >
                {text.length} characters
              </div>
            </div>
          </div>

          {/* Controls row */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">

            {/* Color pickers */}
            <div className="space-y-4">
              {/* QR Color */}
              <div className="space-y-2">
                <span
                  className="text-xs font-semibold uppercase tracking-widest"
                  style={{ color: "rgba(196, 181, 253, 0.6)" }}
                >
                  QR Color
                </span>
                <div className="color-pill flex items-center gap-3 px-3 py-2 rounded-xl cursor-pointer">
                  <div
                    className="relative w-9 h-9 rounded-full overflow-hidden flex-shrink-0 cursor-pointer"
                    style={{
                      border: "2px solid rgba(200, 170, 255, 0.25)",
                      boxShadow: `0 0 12px ${fgColor}44`,
                    }}
                  >
                    <input
                      type="color"
                      data-testid="input-qr-fg-color"
                      value={fgColor}
                      onChange={(e) => setFgColor(e.target.value)}
                      className="absolute -top-2 -left-2 w-14 h-14 cursor-pointer opacity-0"
                    />
                    <div className="w-full h-full rounded-full" style={{ background: fgColor }} />
                  </div>
                  <span
                    className="text-sm font-mono font-medium uppercase tracking-wider flex-1"
                    style={{ color: "rgba(220, 205, 255, 0.8)" }}
                  >
                    {fgColor}
                  </span>
                </div>
              </div>

              {/* Swap button */}
              <div className="flex justify-start pl-1">
                <button
                  onClick={handleSwapColors}
                  className="swap-icon p-1.5 rounded-lg hover:bg-white/5 transition-colors"
                  title="Swap colors"
                  data-testid="button-swap-colors"
                >
                  <ArrowLeftRight className="w-4 h-4" />
                </button>
              </div>

              {/* Background Color */}
              <div className="space-y-2">
                <span
                  className="text-xs font-semibold uppercase tracking-widest"
                  style={{ color: "rgba(196, 181, 253, 0.6)" }}
                >
                  Background Color
                </span>
                <div className="color-pill flex items-center gap-3 px-3 py-2 rounded-xl cursor-pointer">
                  <div
                    className="relative w-9 h-9 rounded-full overflow-hidden flex-shrink-0"
                    style={{
                      border: "2px solid rgba(200, 170, 255, 0.25)",
                      boxShadow: `0 0 12px ${bgColor}44`,
                    }}
                  >
                    <input
                      type="color"
                      data-testid="input-qr-bg-color"
                      value={bgColor}
                      onChange={(e) => setBgColor(e.target.value)}
                      className="absolute -top-2 -left-2 w-14 h-14 cursor-pointer opacity-0"
                    />
                    <div className="w-full h-full rounded-full" style={{ background: bgColor }} />
                  </div>
                  <span
                    className="text-sm font-mono font-medium uppercase tracking-wider flex-1"
                    style={{ color: "rgba(220, 205, 255, 0.8)" }}
                  >
                    {bgColor}
                  </span>
                </div>
              </div>
            </div>

            {/* Size + EC */}
            <div className="space-y-6">
              {/* Size slider */}
              <div className="space-y-3">
                <div className="flex justify-between items-center">
                  <span
                    className="text-xs font-semibold uppercase tracking-widest"
                    style={{ color: "rgba(196, 181, 253, 0.6)" }}
                  >
                    QR Size
                  </span>
                  <span
                    className="text-sm font-mono font-medium px-2.5 py-0.5 rounded-lg"
                    style={{
                      color: "rgba(196, 181, 253, 0.9)",
                      background: "rgba(124, 58, 237, 0.15)",
                      border: "1px solid rgba(167, 139, 250, 0.2)",
                    }}
                  >
                    {size}px
                  </span>
                </div>

                {/* Custom gradient slider */}
                <div className="relative h-6 flex items-center">
                  {/* Track background */}
                  <div
                    className="absolute w-full h-1.5 rounded-full"
                    style={{
                      background: "rgba(255,255,255,0.08)",
                    }}
                  />
                  {/* Filled track */}
                  <div
                    className="absolute h-1.5 rounded-full"
                    style={{
                      width: `${sizePercent}%`,
                      background: "linear-gradient(90deg, #7c3aed, #8b5cf6, #a78bfa, #c4b5fd)",
                      boxShadow: "0 0 8px rgba(139, 92, 246, 0.5)",
                    }}
                  />
                  {/* Native input overlay */}
                  <input
                    type="range"
                    data-testid="input-qr-size"
                    min={150}
                    max={400}
                    step={50}
                    value={size}
                    onChange={(e) => setSize(Number(e.target.value))}
                    className="absolute w-full h-full opacity-0 cursor-pointer"
                    style={{ zIndex: 10 }}
                  />
                  {/* Thumb */}
                  <div
                    className="absolute w-5 h-5 rounded-full pointer-events-none"
                    style={{
                      left: `calc(${sizePercent}% - ${sizePercent * 0.08}px - 4px)`,
                      background: "linear-gradient(135deg, #c084fc, #7c3aed)",
                      border: "2px solid rgba(255,255,255,0.35)",
                      boxShadow: "0 0 14px rgba(139, 92, 246, 0.7), 0 2px 6px rgba(0,0,0,0.4)",
                      zIndex: 5,
                    }}
                  />
                </div>

                {/* Size labels */}
                <div className="flex justify-between px-0.5">
                  {[150, 200, 250, 300, 350, 400].map((s) => (
                    <button
                      key={s}
                      onClick={() => setSize(s)}
                      className="text-xs font-mono transition-colors"
                      style={{
                        color: size === s
                          ? "rgba(196, 181, 253, 0.9)"
                          : "rgba(180, 150, 255, 0.28)",
                      }}
                    >
                      {s}
                    </button>
                  ))}
                </div>
              </div>

              {/* Error correction */}
              <div className="space-y-2">
                <span
                  className="text-xs font-semibold uppercase tracking-widest"
                  style={{ color: "rgba(196, 181, 253, 0.6)" }}
                >
                  Error Correction
                </span>
                <div className="ec-segment flex rounded-xl p-1 gap-1">
                  {(["L", "M", "Q", "H"] as ECLevel[]).map((lvl) => (
                    <button
                      key={lvl}
                      data-testid={`input-ec-${lvl.toLowerCase()}`}
                      onClick={() => setEcLevel(lvl)}
                      className={`flex-1 py-2 text-sm font-semibold rounded-lg transition-all duration-200 ${
                        ecLevel === lvl ? "ec-item-active" : ""
                      }`}
                      style={
                        ecLevel !== lvl
                          ? { color: "rgba(180, 150, 255, 0.45)" }
                          : undefined
                      }
                    >
                      {lvl}
                    </button>
                  ))}
                </div>
              </div>
            </div>
          </div>

          {/* Generate button */}
          <div className="mt-auto pt-2">
            <button
              data-testid="button-generate"
              onClick={handleManualGenerate}
              className="btn-generate w-full flex items-center justify-center gap-3 py-4 rounded-2xl text-white font-semibold text-base tracking-wide"
            >
              <Wand2 className="w-5 h-5" style={{ filter: "drop-shadow(0 0 6px rgba(255,255,255,0.6))" }} />
              Generate QR Code
            </button>
          </div>
        </div>

        {/* ── RIGHT PANEL ── */}
        <div
          className="lg:col-span-5 flex flex-col p-7 sm:p-8 rounded-3xl glass-panel glass-panel-hover relative overflow-hidden"
        >
          {/* Subtle top glow */}
          <div
            className="absolute top-0 left-0 right-0 h-px pointer-events-none"
            style={{ background: "linear-gradient(90deg, transparent, rgba(200, 160, 255, 0.4), transparent)" }}
          />
          <div
            className="absolute top-0 left-1/2 -translate-x-1/2 w-3/4 h-24 pointer-events-none"
            style={{
              background: "radial-gradient(ellipse at center top, rgba(120, 40, 220, 0.12) 0%, transparent 70%)",
            }}
          />

          {/* Header */}
          <h2
            className="text-sm font-semibold uppercase tracking-widest flex items-center gap-2.5 mb-6"
            style={{ color: "rgba(196, 181, 253, 0.7)" }}
          >
            <QrCode className="w-4 h-4" style={{ color: "rgba(167, 139, 250, 0.8)" }} />
            Preview
          </h2>

          {/* QR Preview area */}
          <div className="flex-1 flex flex-col items-center justify-center min-h-[280px]">
            {hasQR ? (
              <div className="qr-appear flex flex-col items-center gap-4">
                <div
                  className="rounded-2xl overflow-hidden qr-glow-ring"
                  style={{ border: "1px solid rgba(180, 140, 255, 0.15)" }}
                >
                  <canvas
                    ref={canvasRef}
                    data-testid="canvas-qr-preview"
                    style={{ display: "block", width: size, height: size }}
                  />
                </div>
                <div
                  className="text-xs font-mono tracking-widest"
                  style={{ color: "rgba(180, 150, 255, 0.4)" }}
                >
                  {size} × {size} PX
                </div>
              </div>
            ) : (
              <>
                {/* Hidden canvas kept in DOM for generation */}
                <canvas ref={canvasRef} data-testid="canvas-qr-preview" style={{ display: "none" }} />
                <div
                  className="flex flex-col items-center justify-center text-center p-8 rounded-2xl w-full max-w-[260px] aspect-square"
                  style={{
                    background: "rgba(0,0,0,0.18)",
                    border: "1.5px dashed rgba(180, 140, 255, 0.14)",
                  }}
                >
                  <div
                    className="w-14 h-14 rounded-2xl flex items-center justify-center mb-4"
                    style={{
                      background: "rgba(124, 58, 237, 0.1)",
                      border: "1px solid rgba(167, 139, 250, 0.15)",
                    }}
                  >
                    <QrCode className="w-7 h-7" style={{ color: "rgba(167, 139, 250, 0.35)" }} />
                  </div>
                  <p
                    className="text-sm leading-relaxed"
                    style={{ color: "rgba(180, 150, 255, 0.4)" }}
                  >
                    Enter content to generate
                    <br />
                    your QR code.
                  </p>
                </div>
              </>
            )}
          </div>

          {/* Action bar */}
          <div
            className="mt-6 flex gap-3 p-1.5 rounded-2xl"
            style={{
              background: "rgba(0,0,0,0.2)",
              border: "1px solid rgba(180, 140, 255, 0.1)",
            }}
          >
            <button
              data-testid="button-download"
              onClick={handleDownload}
              disabled={!hasQR}
              className="btn-action flex-1 flex items-center justify-center gap-2 py-3 rounded-xl text-sm font-medium"
              style={{ color: "rgba(220, 205, 255, 0.75)" }}
            >
              <Download className="w-4 h-4" />
              Download PNG
            </button>
            <div style={{ width: "1px", background: "rgba(180,140,255,0.1)", margin: "6px 0" }} />
            <button
              data-testid="button-copy"
              onClick={handleCopy}
              disabled={!hasQR}
              className="btn-action flex-1 flex items-center justify-center gap-2 py-3 rounded-xl text-sm font-medium"
              style={{ color: "rgba(220, 205, 255, 0.75)" }}
            >
              <Copy className="w-4 h-4" />
              Copy Image
            </button>
          </div>
        </div>

      </div>
    </div>
  );
}
