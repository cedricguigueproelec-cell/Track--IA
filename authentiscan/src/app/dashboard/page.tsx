import Link from "next/link";
import { PlusCircle, Gift } from "lucide-react";
import { auth } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import VerdictBadge from "@/components/VerdictBadge";
import { formatDate } from "@/lib/utils";

export default async function DashboardOverviewPage() {
  const session = await auth();
  const userId = (session!.user as { id: string }).id;

  const [user, recent] = await Promise.all([
    prisma.user.findUniqueOrThrow({ where: { id: userId } }),
    prisma.authenticationRequest.findMany({
      where: { userId },
      orderBy: { createdAt: "desc" },
      take: 5,
    }),
  ]);

  const appUrl = process.env.NEXT_PUBLIC_APP_URL ?? "";

  return (
    <div className="mx-auto max-w-4xl">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold">Bonjour {user.name?.split(" ")[0] ?? ""} 👋</h1>
          <p className="mt-1 text-sm text-muted">Prêt à vérifier un nouvel article ?</p>
        </div>
        <Link href="/dashboard/nouveau" className="btn-brand inline-flex items-center gap-2 rounded-xl px-5 py-3 text-sm">
          <PlusCircle size={18} /> Nouvelle analyse
        </Link>
      </div>

      <div className="card mt-8 flex flex-wrap items-center justify-between gap-4 p-6">
        <div className="flex items-center gap-3">
          <span className="flex h-11 w-11 items-center justify-center rounded-xl bg-brand-soft text-brand">
            <Gift size={20} />
          </span>
          <div>
            <p className="font-semibold">Parrainez vos amis</p>
            <p className="text-sm text-muted">Vous et votre filleul recevez 2 analyses offertes.</p>
          </div>
        </div>
        <code className="rounded-lg border border-border bg-surface-2 px-4 py-2 text-sm font-semibold text-brand">
          {appUrl.replace(/^https?:\/\//, "")}/inscription?ref={user.referralCode}
        </code>
      </div>

      <div className="mt-8">
        <div className="flex items-center justify-between">
          <h2 className="font-semibold">Analyses récentes</h2>
          <Link href="/dashboard/historique" className="text-sm text-brand hover:underline">
            Tout voir
          </Link>
        </div>

        {recent.length === 0 ? (
          <div className="card mt-4 p-8 text-center text-sm text-muted">
            Aucune analyse pour le moment. Lancez votre première authentification !
          </div>
        ) : (
          <div className="card mt-4 divide-y divide-border">
            {recent.map((r) => (
              <Link key={r.id} href={`/dashboard/resultat/${r.id}`} className="flex items-center justify-between gap-4 p-4 hover:bg-surface-2">
                <div>
                  <p className="font-medium">{r.itemName || "Article"}</p>
                  <p className="text-xs text-muted">{formatDate(r.createdAt)}</p>
                </div>
                {r.status === "DONE" ? (
                  <VerdictBadge verdict={r.verdict ?? "INDETERMINE"} size="sm" />
                ) : r.status === "ERROR" ? (
                  <span className="text-xs text-danger">Échec</span>
                ) : (
                  <span className="text-xs text-muted">En cours</span>
                )}
              </Link>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
