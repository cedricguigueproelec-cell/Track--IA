"use client";

import { useRef } from "react";
import { Camera, X } from "lucide-react";

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

  function handleFile(file: File | undefined) {
    if (!file) return;
    if (!file.type.startsWith("image/")) return;
    const reader = new FileReader();
    reader.onload = () => onChange(reader.result as string);
    reader.readAsDataURL(file);
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
        capture="environment"
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
          onClick={() => inputRef.current?.click()}
          className="flex h-44 w-full flex-col items-center justify-center gap-2 rounded-xl border border-dashed border-border bg-surface-2 text-muted transition hover:border-brand/50 hover:text-brand"
        >
          <Camera size={26} />
          <span className="text-sm">Ajouter une photo</span>
        </button>
      )}
    </div>
  );
}
