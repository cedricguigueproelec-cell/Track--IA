"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Loader2, ScanSearch, AlertTriangle } from "lucide-react";
import ImageSlot from "@/components/dashboard/ImageSlot";

export default function NouvelleAnalysePage() {
  const router = useRouter();
  const [itemName, setItemName] = useState("");
  const [brand, setBrand] = useState("");
  const [logo, setLogo] = useState<string | null>(null);
  const [coutures, setCoutures] = useState<string | null>(null);
  const [autre, setAutre] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const images = [
    logo && { kind: "logo_etiquette", dataUrl: logo },
    coutures && { kind: "coutures_matiere", dataUrl: coutures },
    autre && { kind: "autre", dataUrl: autre },
  ].filter(Boolean) as { kind: string; dataUrl: string }[];

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);

    if (images.length === 0) {
      setError("Ajoutez au moins une photo (idéalement l'étiquette/logo).");
      return;
    }

    setLoading(true);
    try {
      const res = await fetch("/api/analyze", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ itemName: itemName || undefined, brand: brand || undefined, images }),
      });
      const data = await res.json();
      if (!res.ok) {
        setError(data.error ?? "Une erreur est survenue.");
        setLoading(false);
        return;
      }
      router.push(`/dashboard/resultat/${data.id}`);
    } catch {
      setError("Erreur réseau, réessayez.");
      setLoading(false);
    }
  }

  return (
    <div className="mx-auto max-w-2xl">
      <h1 className="text-2xl font-bold">Nouvelle authentification</h1>
      <p className="mt-1 text-sm text-muted">
        Plus vos photos sont nettes et rapprochées, plus l&apos;analyse est fiable.
      </p>

      <form onSubmit={handleSubmit} className="mt-8 space-y-6">
        <div className="grid gap-4 sm:grid-cols-2">
          <div>
            <label className="mb-1.5 block text-sm text-muted">Article (optionnel)</label>
            <input
              value={itemName}
              onChange={(e) => setItemName(e.target.value)}
              className="w-full rounded-lg border border-border bg-surface-2 px-3.5 py-2.5 outline-none focus:border-brand"
              placeholder="Ex : Sac bandoulière"
            />
          </div>
          <div>
            <label className="mb-1.5 block text-sm text-muted">Marque déclarée (optionnel)</label>
            <input
              value={brand}
              onChange={(e) => setBrand(e.target.value)}
              className="w-full rounded-lg border border-border bg-surface-2 px-3.5 py-2.5 outline-none focus:border-brand"
              placeholder="Ex : Ralph Lauren"
            />
          </div>
        </div>

        <div className="grid gap-4 sm:grid-cols-3">
          <ImageSlot
            label="Étiquette / logo"
            hint="Le point le plus important"
            required
            value={logo}
            onChange={setLogo}
          />
          <ImageSlot
            label="Coutures / matière"
            hint="Zoom sur les finitions"
            value={coutures}
            onChange={setCoutures}
          />
          <ImageSlot label="Autre angle" hint="Vue d'ensemble de l'article" value={autre} onChange={setAutre} />
        </div>

        {error && (
          <div className="flex items-start gap-2 rounded-lg border border-danger/30 bg-danger/10 p-3 text-sm text-danger">
            <AlertTriangle size={16} className="mt-0.5 shrink-0" />
            {error}
          </div>
        )}

        <button
          disabled={loading}
          className="btn-brand flex w-full items-center justify-center gap-2 rounded-xl py-3.5 text-sm sm:w-auto sm:px-8"
        >
          {loading ? <Loader2 size={18} className="animate-spin" /> : <ScanSearch size={18} />}
          {loading ? "Analyse en cours..." : "Lancer l'analyse IA"}
        </button>
      </form>
    </div>
  );
}
