import { CheckCircle2 } from "lucide-react";
import { auth } from "@/lib/auth";
import { getQuotaSnapshot } from "@/lib/quota";
import { PAID_PLAN_ORDER, PLANS, formatPrice, type PlanId } from "@/lib/plans";
import { cn } from "@/lib/utils";
import PlanButton from "@/components/dashboard/PlanButton";
import ManageBillingButton from "@/components/dashboard/ManageBillingButton";

export default async function FacturationPage(props: PageProps<"/dashboard/facturation">) {
  const searchParams = await props.searchParams;
  const session = await auth();
  const userId = (session!.user as { id: string }).id;
  const quota = await getQuotaSnapshot(userId);

  return (
    <div className="mx-auto max-w-4xl">
      <h1 className="text-2xl font-bold">Facturation</h1>

      {searchParams?.success && (
        <div className="mt-4 flex items-center gap-2 rounded-lg border border-success/30 bg-success/10 p-3 text-sm text-success">
          <CheckCircle2 size={16} /> Paiement confirmé, votre forfait est actif.
        </div>
      )}

      <div className="card mt-6 flex flex-wrap items-center justify-between gap-4 p-6">
        <div>
          <p className="text-sm text-muted">Forfait actuel</p>
          <p className="text-xl font-bold">{quota.plan.name}</p>
          <p className="mt-1 text-sm text-muted">
            {quota.used}/{quota.limit} utilisées ce {quota.plan.quotaPeriod}
            {quota.bonus > 0 && ` · +${quota.bonus} bonus`}
          </p>
        </div>
        {quota.plan.id !== "FREE" && <ManageBillingButton />}
      </div>

      <div className="mt-8 grid gap-6 md:grid-cols-3">
        {PAID_PLAN_ORDER.map((id) => {
          const plan = PLANS[id as PlanId];
          const isCurrent = quota.plan.id === id;
          return (
            <div key={id} className={cn("card flex flex-col p-6", plan.highlight && !isCurrent && "border-brand/50")}>
              <h3 className="font-bold">{plan.name}</h3>
              <p className="mt-1 text-sm text-muted">{plan.tagline}</p>
              <p className="mt-4 text-3xl font-bold">
                {formatPrice(plan.price)}€<span className="text-sm font-normal text-muted">/mois</span>
              </p>
              <p className="mt-2 text-sm text-brand">
                {plan.quota} authentifications / {plan.quotaPeriod}
              </p>
              <ul className="mt-4 flex-1 space-y-2">
                {plan.features.map((f) => (
                  <li key={f} className="text-xs text-muted">• {f}</li>
                ))}
              </ul>
              <div className="mt-5">
                {isCurrent ? (
                  <span className="block rounded-lg border border-brand/40 bg-brand-soft py-2.5 text-center text-sm font-semibold text-brand">
                    Forfait actuel
                  </span>
                ) : (
                  <PlanButton plan={id as PlanId} label={`Passer à ${plan.name}`} variant={plan.highlight ? "brand" : "default"} />
                )}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
