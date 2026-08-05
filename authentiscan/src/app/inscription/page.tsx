"use client";

import { useState, Suspense } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import Link from "next/link";
import { signIn } from "next-auth/react";
import AuthCard from "@/components/AuthCard";
import { Loader2 } from "lucide-react";

function InscriptionForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const plan = searchParams.get("plan");

  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [referralCode, setReferralCode] = useState(searchParams.get("ref") ?? "");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setLoading(true);

    try {
      const res = await fetch("/api/signup", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name, email, password, referralCode: referralCode || undefined }),
      });
      const data = await res.json();
      if (!res.ok) {
        setError(data.error ?? "Une erreur est survenue.");
        setLoading(false);
        return;
      }

      const signInRes = await signIn("credentials", { email, password, redirect: false });
      if (signInRes?.error) {
        setError("Compte créé, mais la connexion automatique a échoué. Essayez de vous connecter.");
        setLoading(false);
        return;
      }

      router.push(plan ? `/dashboard/facturation?plan=${plan}` : "/dashboard");
      router.refresh();
    } catch {
      setError("Une erreur réseau est survenue.");
      setLoading(false);
    }
  }

  return (
    <AuthCard
      title="Créer votre compte"
      subtitle="3 authentifications offertes, sans carte bancaire."
      footer={
        <>
          Déjà un compte ?{" "}
          <Link href="/connexion" className="text-brand hover:underline">
            Connectez-vous
          </Link>
        </>
      }
    >
      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label className="mb-1.5 block text-sm text-muted">Nom</label>
          <input
            required
            value={name}
            onChange={(e) => setName(e.target.value)}
            className="w-full rounded-lg border border-border bg-surface-2 px-3.5 py-2.5 outline-none focus:border-brand"
            placeholder="Votre nom"
          />
        </div>
        <div>
          <label className="mb-1.5 block text-sm text-muted">Email</label>
          <input
            required
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className="w-full rounded-lg border border-border bg-surface-2 px-3.5 py-2.5 outline-none focus:border-brand"
            placeholder="vous@exemple.com"
          />
        </div>
        <div>
          <label className="mb-1.5 block text-sm text-muted">Mot de passe</label>
          <input
            required
            minLength={8}
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            className="w-full rounded-lg border border-border bg-surface-2 px-3.5 py-2.5 outline-none focus:border-brand"
            placeholder="8 caractères minimum"
          />
        </div>
        <div>
          <label className="mb-1.5 block text-sm text-muted">Code de parrainage (optionnel)</label>
          <input
            value={referralCode}
            onChange={(e) => setReferralCode(e.target.value.toUpperCase())}
            className="w-full rounded-lg border border-border bg-surface-2 px-3.5 py-2.5 uppercase outline-none focus:border-brand"
            placeholder="ABCD123"
          />
        </div>

        {error && <p className="text-sm text-danger">{error}</p>}

        <button disabled={loading} className="btn-brand flex w-full items-center justify-center gap-2 rounded-lg py-3 text-sm">
          {loading && <Loader2 size={16} className="animate-spin" />}
          Créer mon compte
        </button>
      </form>
    </AuthCard>
  );
}

export default function InscriptionPage() {
  return (
    <Suspense>
      <InscriptionForm />
    </Suspense>
  );
}
