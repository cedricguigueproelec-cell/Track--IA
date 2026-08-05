"use client";

import { useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { Loader2, ScanSearch, AlertTriangle, Timer } from "lucide-react";
import ImageSlot from "@/components/dashboard/ImageSlot";

const COOLDOWN_KEY = "authentiscan:cooldownUntil";
const COOLDOWN_MS = 5 * 60 * 1000;
const PROGRESS_TIME_CONSTANT_MS = 4000;

function formatCountdown(ms: number): string {
  const totalSeconds = Math.max(0, Math.ceil(ms / 1000));
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  return `${minutes}:${seconds.toString().padStart(2, "0")}`;
}

export default function NouvelleAnalysePage() {
  const router = useRouter();
  const [itemName, setItemName] = useState("");
  const [brand, setBrand] = useState("");
  const [logo, setLogo] = useState<string | null>(null);
  const [coutures, setCoutures] = useState<string | null>(null);
  const [autre, setAutre] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [progress, setProgress] = useState(0);
  const [cooldownUntil, setCooldownUntil] = useState<number | null>(null);
  const [nowTick, setNowTick] = useState(() => Date.now());
  const progressTimerRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const images = [
    logo && { kind: "logo_etiquette", dataUrl: logo },
    coutures && { kind: "coutures_matiere", dataUrl: coutures },
    autre && { kind: "autre", dataUrl: autre },
  ].filter(Boolean) as { kind: string; dataUrl: string }[];

  useEffect(() => {
    const stored = Number(localStorage.getItem(COOLDOWN_KEY));
    if (stored && stored > Date.now()) setCooldownUntil(stored);
  }, []);

  useEffect(() => {
    if (!cooldownUntil) return;
    const interval = setInterval(() => {
      const now = Date.now();
      setNowTick(now);
      if (now >= cooldownUntil) {
        localStorage.removeItem(COOLDOWN_KEY);
        setCooldownUntil(null);
      }
    }, 1000);
    return () => clearInterval(interval);
  }, [cooldownUntil]);

  useEffect(() => {
    return () => {
      if (progressTimerRef.current) clearInterval(progressTimerRef.current);
    };
  }, []);

  const cooldownRemaining = cooldownUntil ? cooldownUntil - nowTick : 0;
  const onCooldown = cooldownUntil !== null && cooldownRemaining > 0;

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);

    if (onCooldown) return;

    if (images.length === 0) {
      setError("Ajoutez au moins une photo (idéalement l'étiquette/logo).");
      return;
    }

    setLoading(true);
    setProgress(2);
    const start = Date.now();
    progressTimerRef.current = setInterval(() => {
      const elapsed = Date.now() - start;
      const pct = 100 * (1 - Math.exp(-elapsed / PROGRESS_TIME_CONSTANT_MS));
      setProgress(Math.min(92, pct));
    }, 150);

    try {
      const res = await fetch("/api/analyze", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ itemName: itemName || undefined, brand: brand || undefined, images }),
      });
      const data = await res.json();
      if (progressTimerRef.current) clearInterval(progressTimerRef.current);

      if (!res.ok) {
        setError(data.error ?? "Une erreur est survenue.");
        setLoading(false);
        setProgress(0);
        return;
      }

      setProgress(100);
      const until = Date.now() + COOLDOWN_MS;
      localStorage.setItem(COOLDOWN_KEY, String(until));
      setCooldownUntil(until);

      setTimeout(() => router.push(`/dashboard/resultat/${data.id}`), 350);
    } catch {
      if (progressTimerRef.current) clearInterval(progressTimerRef.current);
      setError("Erreur réseau, réessayez.");
      setLoading(false);
      setProgress(0);
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

        {loading && (
          <div>
            <div className="h-2 w-full overflow-hidden rounded-full bg-surface-2">
              <div
                className="h-full rounded-full bg-brand transition-[width] duration-150 ease-out"
                style={{ width: `${progress}%` }}
              />
            </div>
            <p className="mt-1.5 text-xs text-muted">Analyse IA en cours... {Math.round(progress)}%</p>
          </div>
        )}

        {onCooldown && (
          <div className="flex items-center gap-2 rounded-lg border border-border bg-surface-2 p-3 text-sm text-muted">
            <Timer size={16} className="shrink-0" />
            Prochaine analyse possible dans {formatCountdown(cooldownRemaining)}
          </div>
        )}

        <button
          disabled={loading || onCooldown}
          className="btn-brand flex w-full items-center justify-center gap-2 rounded-xl py-3.5 text-sm sm:w-auto sm:px-8 disabled:cursor-not-allowed disabled:opacity-60"
        >
          {loading ? <Loader2 size={18} className="animate-spin" /> : <ScanSearch size={18} />}
          {loading
            ? "Analyse en cours..."
            : onCooldown
              ? `Patientez ${formatCountdown(cooldownRemaining)}`
              : "Lancer l'analyse IA"}
        </button>
      </form>
    </div>
  );
}
