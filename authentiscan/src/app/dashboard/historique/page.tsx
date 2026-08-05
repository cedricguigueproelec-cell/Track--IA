import Link from "next/link";
import { auth } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import VerdictBadge from "@/components/VerdictBadge";
import { formatDate } from "@/lib/utils";

export default async function HistoriquePage() {
  const session = await auth();
  const userId = (session!.user as { id: string }).id;

  const requests = await prisma.authenticationRequest.findMany({
    where: { userId },
    orderBy: { createdAt: "desc" },
  });

  return (
    <div className="mx-auto max-w-4xl">
      <h1 className="text-2xl font-bold">Historique</h1>
      <p className="mt-1 text-sm text-muted">{requests.length} analyse{requests.length > 1 ? "s" : ""} au total.</p>

      {requests.length === 0 ? (
        <div className="card mt-6 p-8 text-center text-sm text-muted">Aucune analyse pour le moment.</div>
      ) : (
        <div className="card mt-6 divide-y divide-border">
          {requests.map((r) => (
            <Link key={r.id} href={`/dashboard/resultat/${r.id}`} className="flex items-center justify-between gap-4 p-4 hover:bg-surface-2">
              <div>
                <p className="font-medium">{r.itemName || "Article"}</p>
                <p className="text-xs text-muted">
                  {r.brand ? `${r.brand} · ` : ""}
                  {formatDate(r.createdAt)}
                </p>
              </div>
              {r.status === "DONE" ? (
                <div className="flex items-center gap-3">
                  {r.score != null && <span className="text-sm text-muted">{r.score}/100</span>}
                  <VerdictBadge verdict={r.verdict ?? "INDETERMINE"} size="sm" />
                </div>
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
  );
}
