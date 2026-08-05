"use client";

import { useRef, useState } from "react";
import { Camera, X, Loader2 } from "lucide-react";

const MAX_DIMENSION = 1600;
const JPEG_QUALITY = 0.82;

async function compressToDataUrl(file: File): Promise<string> {
  const bitmap = await createImageBitmap(file);
  const scale = Math.min(1, MAX_DIMENSION / Math.max(bitmap.width, bitmap.height));
  const width = Math.round(bitmap.width * scale);
  const height = Math.round(bitmap.height * scale);

  const canvas = document.createElement("canvas");
  canvas.width = width;
  canvas.height = height;
  const ctx = canvas.getContext("2d");
  if (!ctx) throw new Error("Compression d'image impossible.");
  ctx.drawImage(bitmap, 0, 0, width, height);

  return canvas.toDataURL("image/jpeg", JPEG_QUALITY);
}

export default function ImageSlot({
  label,
  hint,
  required,
  value,
  onChange,
}: {
  label: string;
  hint: string;
  required?: boolean;
  value: string | null;
  onChange: (dataUrl: string | null) => void;
}) {
  const inputRef = useRef<HTMLInputElement>(null);
  const [compressing, setCompressing] = useState(false);

  async function handleFile(file: File | undefined) {
    if (!file) return;
    if (!file.type.startsWith("image/")) return;
    setCompressing(true);
    try {
      const dataUrl = await compressToDataUrl(file);
      onChange(dataUrl);
    } finally {
      setCompressing(false);
    }
  }

  return (
    <div>
      <label className="mb-1.5 flex items-center gap-1.5 text-sm font-medium">
        {label} {required && <span className="text-brand">*</span>}
      </label>
      <p className="mb-2 text-xs text-muted">{hint}</p>

      <input
        ref={inputRef}
        type="file"
        accept="image/*"
        className="hidden"
        onChange={(e) => handleFile(e.target.files?.[0])}
      />

      {value ? (
        <div className="relative">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src={value} alt={label} className="h-44 w-full rounded-xl border border-border object-cover" />
          <button
            type="button"
            onClick={() => onChange(null)}
            className="absolute right-2 top-2 rounded-full bg-black/70 p-1.5 text-white hover:bg-black"
          >
            <X size={14} />
          </button>
        </div>
      ) : (
        <button
          type="button"
          disabled={compressing}
          onClick={() => inputRef.current?.click()}
          className="flex h-44 w-full flex-col items-center justify-center gap-2 rounded-xl border border-dashed border-border bg-surface-2 text-muted transition hover:border-brand/50 hover:text-brand disabled:opacity-60"
        >
          {compressing ? <Loader2 size={26} className="animate-spin" /> : <Camera size={26} />}
          <span className="text-sm">{compressing ? "Traitement..." : "Ajouter une photo"}</span>
        </button>
      )}
    </div>
  );
}
