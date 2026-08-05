"use client";

import { useState } from "react";
import { Loader2 } from "lucide-react";

export default function ManageBillingButton() {
  const [loading, setLoading] = useState(false);

  async function handleClick() {
    setLoading(true);
    const res = await fetch("/api/stripe/portal", { method: "POST" });
    const data = await res.json();
    if (data.url) window.location.href = data.url;
    else setLoading(false);
  }

  return (
    <button
      onClick={handleClick}
      disabled={loading}
      className="inline-flex items-center gap-2 rounded-lg border border-border px-4 py-2 text-sm hover:border-brand/50"
    >
      {loading && <Loader2 size={15} className="animate-spin" />}
      Gérer mon abonnement
    </button>
  );
}
