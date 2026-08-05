import Link from "next/link";
import { ShieldCheck, Sparkles, Zap } from "lucide-react";

export default function Hero() {
  return (
    <section className="relative overflow-hidden px-4 pt-20 pb-16 sm:px-6 sm:pt-28">
      <div className="mx-auto max-w-4xl text-center">
        <div className="mx-auto mb-6 inline-flex items-center gap-2 rounded-full border border-border bg-surface px-4 py-1.5 text-xs text-muted">
          <Sparkles size={14} className="text-brand" />
          Nouveau · IA disponible 24h/24, 7j/7
        </div>

        <h1 className="text-4xl font-bold tracking-tight sm:text-6xl">
          Un doute sur un article ?
          <br />
          <span className="glow-text text-brand">L&apos;IA vérifie en 20 secondes.</span>
        </h1>

        <p className="mx-auto mt-6 max-w-2xl text-lg text-muted">
          Prenez en photo le logo, l&apos;étiquette et les coutures de n&apos;importe quel article de mode.
          Notre IA les analyse et vous répond clairement par oui ou par non, avec les points de
          vigilance à l&apos;appui — avant d&apos;acheter ou de vendre.
        </p>

        <div className="mt-8 flex flex-col items-center justify-center gap-3 sm:flex-row">
          <Link href="/inscription" className="btn-brand w-full rounded-xl px-6 py-3.5 text-center text-base sm:w-auto">
            Tester gratuitement — 3 analyses offertes
          </Link>
          <Link
            href="/tarifs"
            className="w-full rounded-xl border border-border px-6 py-3.5 text-center text-base text-foreground hover:border-brand/50 sm:w-auto"
          >
            Voir les forfaits
          </Link>
        </div>

        <p className="mt-4 text-xs text-muted">Sans carte bancaire. Résiliable en un clic.</p>

        <div className="mx-auto mt-12 flex max-w-xl flex-wrap items-center justify-center gap-x-8 gap-y-3 text-sm text-muted">
          <span className="inline-flex items-center gap-1.5"><ShieldCheck size={16} className="text-brand" /> Analyse multi-points</span>
          <span className="inline-flex items-center gap-1.5"><Zap size={16} className="text-brand" /> Résultat en ~20 s</span>
          <span className="inline-flex items-center gap-1.5"><Sparkles size={16} className="text-brand" /> Toutes marques, tous articles</span>
        </div>
      </div>

      <div className="pointer-events-none absolute inset-x-0 top-0 -z-10 h-[600px] bg-[radial-gradient(ellipse_60%_50%_at_50%_0%,rgba(20,224,196,0.15),transparent)]" />
    </section>
  );
}
