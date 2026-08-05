"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { signIn } from "next-auth/react";
import AuthCard from "@/components/AuthCard";
import { Loader2 } from "lucide-react";

export default function ConnexionPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setLoading(true);

    const res = await signIn("credentials", { email, password, redirect: false });
    if (res?.error) {
      setError("Email ou mot de passe incorrect.");
      setLoading(false);
      return;
    }

    router.push("/dashboard");
    router.refresh();
  }

  return (
    <AuthCard
      title="Bon retour"
      subtitle="Connectez-vous à votre compte AuthentiScan."
      footer={
        <>
          Pas encore de compte ?{" "}
          <Link href="/inscription" className="text-brand hover:underline">
            Inscrivez-vous gratuitement
          </Link>
        </>
      }
    >
      <form onSubmit={handleSubmit} className="space-y-4">
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
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            className="w-full rounded-lg border border-border bg-surface-2 px-3.5 py-2.5 outline-none focus:border-brand"
            placeholder="••••••••"
          />
        </div>

        {error && <p className="text-sm text-danger">{error}</p>}

        <button disabled={loading} className="btn-brand flex w-full items-center justify-center gap-2 rounded-lg py-3 text-sm">
          {loading && <Loader2 size={16} className="animate-spin" />}
          Se connecter
        </button>
      </form>
    </AuthCard>
  );
}
