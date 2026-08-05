"use client";

import { useState } from "react";
import Link from "next/link";
import { Check } from "lucide-react";
import { PAID_PLAN_ORDER, PLANS, formatPrice } from "@/lib/plans";
import { cn } from "@/lib/utils";

export default function Pricing({ compact = false }: { compact?: boolean }) {
  const [annual, setAnnual] = useState(false);

  return (
    <section id="tarifs" className="px-4 py-20 sm:px-6">
      <div className="mx-auto max-w-6xl">
        {!compact && (
          <div className="mx-auto max-w-2xl text-center">
            <h2 className="text-3xl font-bold tracking-tight sm:text-4xl">Des forfaits simples, sans surprise</h2>
            <p className="mt-3 text-muted">Changez ou résiliez à tout moment, en un clic depuis votre tableau de bord.</p>
          </div>
        )}

        <div className="mt-8 flex items-center justify-center gap-3">
          <span className={cn("text-sm", !annual ? "text-foreground" : "text-muted")}>Mensuel</span>
          <button
            onClick={() => setAnnual((a) => !a)}
            className="relative h-7 w-13 rounded-full border border-border bg-surface transition"
            style={{ width: "52px" }}
            aria-label="Basculer facturation annuelle"
          >
            <span
              className={cn(
                "absolute top-0.5 h-5 w-5 rounded-full bg-brand transition-all",
                annual ? "left-[28px]" : "left-0.5"
              )}
            />
          </button>
          <span className={cn("text-sm", annual ? "text-foreground" : "text-muted")}>
            Annuel <span className="text-brand">— 2 mois offerts</span>
          </span>
        </div>

        <div className="mt-10 grid gap-6 md:grid-cols-3">
          {PAID_PLAN_ORDER.map((id) => {
            const plan = PLANS[id];
            const displayPrice = annual ? (plan.price * 10) / 12 : plan.price;
            return (
              <div
                key={plan.id}
                className={cn(
                  "card relative flex flex-col p-7",
                  plan.highlight && "border-brand/60 shadow-[0_0_40px_rgba(20,224,196,0.12)]"
                )}
              >
                {plan.highlight && (
                  <span className="absolute -top-3 left-1/2 -translate-x-1/2 rounded-full bg-brand px-3 py-1 text-xs font-semibold text-[#04110d]">
                    Le plus choisi
                  </span>
                )}

                <h3 className="text-xl font-bold">{plan.name}</h3>
                <p className="mt-1 text-sm text-muted">{plan.tagline}</p>

                <div className="mt-5 flex items-baseline gap-1">
                  <span className="text-4xl font-bold">{formatPrice(displayPrice)}€</span>
                  <span className="text-muted">/mois</span>
                </div>
                {annual && (
                  <p className="mt-1 text-xs text-muted">Facturé {formatPrice(plan.price * 10)}€ / an</p>
                )}

                <p className="mt-4 inline-flex w-fit items-center rounded-lg bg-brand-soft px-3 py-1.5 text-sm font-medium text-brand">
                  {plan.quota} authentifications / {plan.quotaPeriod}
                </p>

                <ul className="mt-6 flex-1 space-y-3">
                  {plan.features.map((f) => (
                    <li key={f} className="flex items-start gap-2 text-sm text-muted">
                      <Check size={16} className="mt-0.5 shrink-0 text-brand" />
                      <span>{f}</span>
                    </li>
                  ))}
                </ul>

                <Link
                  href={`/inscription?plan=${plan.id}`}
                  className={cn(
                    "mt-7 rounded-xl px-5 py-3 text-center text-sm font-semibold",
                    plan.highlight ? "btn-brand" : "border border-border hover:border-brand/50"
                  )}
                >
                  Choisir {plan.name}
                </Link>
              </div>
            );
          })}
        </div>

        <p className="mt-8 text-center text-sm text-muted">
          Pas encore sûr ? <Link href="/inscription" className="text-brand hover:underline">3 authentifications sont offertes</Link>,
          sans carte bancaire. Parrainez un ami : vous recevez chacun des analyses bonus gratuites.
        </p>
      </div>
    </section>
  );
}
