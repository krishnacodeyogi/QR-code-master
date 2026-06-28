import React, { useState, useEffect, useRef, useCallback } from "react";
import QRCode from "qrcode";
import { Download, Copy, Wand2, QrCode } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Slider } from "@/components/ui/slider";
import { ToggleGroup, ToggleGroupItem } from "@/components/ui/toggle-group";
import { useToast } from "@/hooks/use-toast";

export default function QRGenerator() {
  const [text, setText] = useState("");
  const [debouncedText, setDebouncedText] = useState("");
  const [fgColor, setFgColor] = useState("#ffffff");
  const [bgColor, setBgColor] = useState("#1e1b4b");
  const [size, setSize] = useState(250);
  const [ecLevel, setEcLevel] = useState<"L" | "M" | "Q" | "H">("M");
  
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const { toast } = useToast();

  // Debounce input text
  useEffect(() => {
    const timer = setTimeout(() => {
      setDebouncedText(text);
    }, 300);
    return () => clearTimeout(timer);
  }, [text]);

  const generateQRCode = useCallback(async () => {
    if (!canvasRef.current) return;
    
    try {
      if (!debouncedText) {
        // Clear canvas if empty text
        const ctx = canvasRef.current.getContext('2d');
        if (ctx) {
          ctx.clearRect(0, 0, canvasRef.current.width, canvasRef.current.height);
        }
        return;
      }

      await QRCode.toCanvas(canvasRef.current, debouncedText, {
        width: size,
        margin: 2,
        color: {
          dark: fgColor,
          light: bgColor,
        },
        errorCorrectionLevel: ecLevel,
      });
    } catch (err) {
      console.error(err);
      toast({
        title: "Generation failed",
        description: "Could not generate QR code.",
        variant: "destructive"
      });
    }
  }, [debouncedText, fgColor, bgColor, size, ecLevel, toast]);

  useEffect(() => {
    generateQRCode();
  }, [generateQRCode]);

  const handleManualGenerate = () => {
    setDebouncedText(text);
    generateQRCode();
  };

  const handleDownload = () => {
    if (!canvasRef.current || !debouncedText) return;
    
    const url = canvasRef.current.toDataURL("image/png");
    const link = document.createElement("a");
    link.href = url;
    link.download = "qr-code.png";
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    
    toast({
      title: "Downloaded!",
      description: "QR code saved to your device.",
    });
  };

  const handleCopy = () => {
    if (!canvasRef.current || !debouncedText) return;
    
    canvasRef.current.toBlob((blob) => {
      if (!blob) return;
      try {
        navigator.clipboard.write([
          new ClipboardItem({ 'image/png': blob })
        ]);
        toast({
          title: "Copied!",
          description: "QR code copied to clipboard.",
        });
      } catch (err) {
        toast({
          title: "Copy failed",
          description: "Could not copy to clipboard.",
          variant: "destructive"
        });
      }
    });
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#1a0533] via-[#0f172a] to-[#1e1b4b] flex items-center justify-center p-4 sm:p-8 font-sans">
      <div className="w-full max-w-5xl grid grid-cols-1 lg:grid-cols-12 gap-6 relative z-10">
        
        {/* Left Panel: Controls */}
        <div className="lg:col-span-7 flex flex-col gap-6 p-6 sm:p-8 rounded-3xl bg-white/5 backdrop-blur-xl border border-white/10 shadow-2xl">
          <div>
            <h1 className="text-3xl sm:text-4xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-purple-400 to-indigo-400 mb-2 tracking-tight">
              QR Studio
            </h1>
            <p className="text-white/60 text-sm">Craft precision QR codes instantly.</p>
          </div>

          <div className="space-y-2">
            <Label htmlFor="qr-input" className="text-white/80">Content</Label>
            <Textarea
              id="qr-input"
              data-testid="input-qr-content"
              placeholder="Enter URL or text..."
              value={text}
              onChange={(e) => setText(e.target.value)}
              className="resize-none h-24 bg-black/20 border-white/10 text-white placeholder:text-white/30 focus-visible:ring-purple-500/50 rounded-xl"
            />
            <div className="text-right text-xs text-white/40">
              {text.length} characters
            </div>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
            <div className="space-y-4">
              <div className="space-y-2">
                <Label className="text-white/80">QR Color</Label>
                <div className="flex items-center gap-3">
                  <div className="relative w-10 h-10 rounded-full overflow-hidden border border-white/20 shadow-inner flex-shrink-0 cursor-pointer">
                    <input
                      type="color"
                      data-testid="input-qr-fg-color"
                      value={fgColor}
                      onChange={(e) => setFgColor(e.target.value)}
                      className="absolute -top-2 -left-2 w-14 h-14 cursor-pointer"
                    />
                  </div>
                  <div className="text-sm text-white/70 uppercase font-mono">{fgColor}</div>
                </div>
              </div>
              
              <div className="space-y-2">
                <Label className="text-white/80">Background Color</Label>
                <div className="flex items-center gap-3">
                  <div className="relative w-10 h-10 rounded-full overflow-hidden border border-white/20 shadow-inner flex-shrink-0 cursor-pointer">
                    <input
                      type="color"
                      data-testid="input-qr-bg-color"
                      value={bgColor}
                      onChange={(e) => setBgColor(e.target.value)}
                      className="absolute -top-2 -left-2 w-14 h-14 cursor-pointer"
                    />
                  </div>
                  <div className="text-sm text-white/70 uppercase font-mono">{bgColor}</div>
                </div>
              </div>
            </div>

            <div className="space-y-6">
              <div className="space-y-4">
                <div className="flex justify-between items-center">
                  <Label className="text-white/80">QR Size</Label>
                  <span className="text-xs text-white/50 font-mono">{size}px</span>
                </div>
                <Slider
                  data-testid="input-qr-size"
                  value={[size]}
                  onValueChange={(vals) => setSize(vals[0])}
                  min={150}
                  max={400}
                  step={50}
                  className="[&_[role=slider]]:bg-purple-400 [&_[role=slider]]:border-none"
                />
              </div>

              <div className="space-y-2">
                <Label className="text-white/80">Error Correction</Label>
                <ToggleGroup 
                  type="single" 
                  value={ecLevel} 
                  onValueChange={(v: any) => v && setEcLevel(v)}
                  className="justify-start bg-black/20 p-1 rounded-lg border border-white/5"
                >
                  <ToggleGroupItem data-testid="input-ec-l" value="L" className="data-[state=on]:bg-purple-500/20 data-[state=on]:text-purple-300 text-white/60">L</ToggleGroupItem>
                  <ToggleGroupItem data-testid="input-ec-m" value="M" className="data-[state=on]:bg-purple-500/20 data-[state=on]:text-purple-300 text-white/60">M</ToggleGroupItem>
                  <ToggleGroupItem data-testid="input-ec-q" value="Q" className="data-[state=on]:bg-purple-500/20 data-[state=on]:text-purple-300 text-white/60">Q</ToggleGroupItem>
                  <ToggleGroupItem data-testid="input-ec-h" value="H" className="data-[state=on]:bg-purple-500/20 data-[state=on]:text-purple-300 text-white/60">H</ToggleGroupItem>
                </ToggleGroup>
              </div>
            </div>
          </div>

          <div className="mt-auto pt-6 flex flex-col sm:flex-row gap-3">
            <Button
              data-testid="button-generate"
              onClick={handleManualGenerate}
              className="flex-1 bg-gradient-to-r from-purple-600 to-indigo-600 hover:from-purple-500 hover:to-indigo-500 text-white shadow-[0_0_20px_rgba(147,51,234,0.3)] hover:shadow-[0_0_30px_rgba(147,51,234,0.5)] transition-all duration-300 rounded-xl py-6"
            >
              <Wand2 className="mr-2 h-5 w-5" />
              Generate QR Code
            </Button>
          </div>
        </div>

        {/* Right Panel: Preview */}
        <div className="lg:col-span-5 flex flex-col p-6 sm:p-8 rounded-3xl bg-white/5 backdrop-blur-xl border border-white/10 shadow-2xl relative overflow-hidden group">
          <div className="absolute inset-0 bg-gradient-to-b from-purple-500/5 to-transparent pointer-events-none" />
          
          <h2 className="text-lg font-medium text-white/80 mb-6 flex items-center gap-2">
            <QrCode className="w-5 h-5 text-purple-400" /> Preview
          </h2>

          <div className="flex-1 flex flex-col items-center justify-center relative min-h-[300px]">
            {debouncedText ? (
              <div className="relative group transition-all duration-500 animate-in fade-in zoom-in-95">
                <div className="absolute -inset-4 bg-gradient-to-r from-purple-500/20 to-indigo-500/20 blur-xl rounded-full opacity-0 group-hover:opacity-100 transition-opacity duration-500" />
                <canvas 
                  ref={canvasRef} 
                  data-testid="canvas-qr-preview"
                  className="rounded-xl shadow-2xl relative z-10"
                  style={{ width: size, height: size }}
                />
              </div>
            ) : (
              <div className="flex flex-col items-center justify-center text-center p-8 rounded-2xl border border-dashed border-white/10 bg-white/5 w-full max-w-[280px] aspect-square">
                <QrCode className="w-12 h-12 text-white/20 mb-4" />
                <p className="text-white/40 text-sm">Enter content to generate<br/>your QR code.</p>
              </div>
            )}
            
            {debouncedText && (
              <div className="mt-8 text-center">
                <span className="text-white/40 font-mono text-xs tracking-wider">{size} × {size} PX</span>
              </div>
            )}
          </div>

          <div className="mt-6 flex flex-col sm:flex-row gap-3">
            <Button
              variant="outline"
              data-testid="button-download"
              onClick={handleDownload}
              disabled={!debouncedText}
              className="flex-1 border-white/10 bg-black/20 hover:bg-white/10 text-white hover:text-white rounded-xl"
            >
              <Download className="mr-2 h-4 w-4" />
              Download PNG
            </Button>
            <Button
              variant="outline"
              data-testid="button-copy"
              onClick={handleCopy}
              disabled={!debouncedText}
              className="flex-1 border-white/10 bg-black/20 hover:bg-white/10 text-white hover:text-white rounded-xl"
            >
              <Copy className="mr-2 h-4 w-4" />
              Copy Image
            </Button>
          </div>
        </div>

      </div>
    </div>
  );
}
