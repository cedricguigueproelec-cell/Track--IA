"use client";

import { useState } from "react";
import { Loader2 } from "lucide-react";
import type { PlanId } from "@/lib/plans";

export default function PlanButton({
  plan,
  label,
  variant = "default",
}: {
  plan: PlanId;
  label: string;
  variant?: "default" | "brand";
}) {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleClick() {
    setLoading(true);
    setError(null);
    try {
      const res = await fetch("/api/stripe/checkout", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ plan }),
      });
      const data = await res.json();
      if (!res.ok || !data.url) {
        setError(data.error ?? "Impossible de lancer le paiement.");
        setLoading(false);
        return;
      }
      window.location.href = data.url;
    } catch {
      setError("Erreur réseau.");
      setLoading(false);
    }
  }

  return (
    <div>
      <button
        onClick={handleClick}
        disabled={loading}
        className={`flex w-full items-center justify-center gap-2 rounded-lg px-4 py-2.5 text-sm font-semibold ${
          variant === "brand" ? "btn-brand" : "border border-border hover:border-brand/50"
        }`}
      >
        {loading && <Loader2 size={15} className="animate-spin" />}
        {label}
      </button>
      {error && <p className="mt-1.5 text-xs text-danger">{error}</p>}
    </div>
  );
}
