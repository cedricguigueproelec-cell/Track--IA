import Link from "next/link";
import { notFound } from "next/navigation";
import { AlertTriangle, ExternalLink, PlusCircle } from "lucide-react";
import { auth } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import VerdictBadge from "@/components/VerdictBadge";
import AnswerCircle from "@/components/AnswerCircle";
import CopyButton from "@/components/dashboard/CopyButton";
import { formatDate } from "@/lib/utils";

export default async function ResultatPage(props: PageProps<"/dashboard/resultat/[id]">) {
  const { id } = await props.params;
  const session = await auth();
  const userId = (session!.user as { id: string }).id;

  const request = await prisma.authenticationRequest.findUnique({ where: { id } });
  if (!request || request.userId !== userId) notFound();

  if (request.status === "ERROR") {
    return (
      <div className="mx-auto max-w-xl text-center">
        <AlertTriangle className="mx-auto text-danger" size={40} />
        <h1 className="mt-4 text-xl font-bold">L&apos;analyse a échoué</h1>
        <p className="mt-2 text-sm text-muted">{request.errorMessage}</p>
        <p className="mt-1 text-xs text-muted">Aucun crédit n&apos;a été décompté pour cette tentative.</p>
        <Link href="/dashboard/nouveau" className="btn-brand mt-6 inline-block rounded-xl px-6 py-3 text-sm">
          Réessayer
        </Link>
      </div>
    );
  }

  const redFlags: string[] = request.redFlags ? JSON.parse(request.redFlags) : [];
  const checklist: { label: string; ok: boolean; note: string }[] = request.checklist ? JSON.parse(request.checklist) : [];

  return (
    <div className="mx-auto max-w-3xl">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <p className="text-xs text-muted">{formatDate(request.createdAt)}</p>
          <h1 className="text-2xl font-bold">{request.itemName || "Article analysé"}</h1>
          {request.brand && <p className="text-sm text-muted">Marque déclarée : {request.brand}</p>}
        </div>
        <Link href="/dashboard/nouveau" className="inline-flex items-center gap-2 rounded-lg border border-border px-4 py-2 text-sm hover:border-brand/50">
          <PlusCircle size={16} /> Nouvelle analyse
        </Link>
      </div>

      <div className="card mt-6 flex flex-col items-center gap-6 p-8 text-center sm:flex-row sm:text-left">
        <AnswerCircle authentic={request.verdict === "AUTHENTIQUE"} />
        <div>
          <VerdictBadge verdict={request.verdict ?? "INDETERMINE"} />
          <p className="mt-3 text-sm text-muted">
            Niveau de confiance : <span className="font-medium text-foreground">{request.confidence}</span>
          </p>
          <p className="mt-3 max-w-lg text-sm leading-relaxed text-muted">{request.reasoning}</p>
        </div>
      </div>

      {redFlags.length > 0 && (
        <div className="card mt-6 p-6">
          <h2 className="flex items-center gap-2 font-semibold text-warning">
            <AlertTriangle size={18} /> Points de vigilance
          </h2>
          <ul className="mt-3 space-y-2">
            {redFlags.map((f, i) => (
              <li key={i} className="text-sm text-muted">• {f}</li>
            ))}
          </ul>
        </div>
      )}

      {checklist.length > 0 && (
        <div className="card mt-6 p-6">
          <h2 className="font-semibold">Points vérifiés</h2>
          <ul className="mt-3 space-y-3">
            {checklist.map((c, i) => (
              <li key={i} className="flex items-start gap-3 text-sm">
                <span className={c.ok ? "text-success" : "text-danger"}>{c.ok ? "✓" : "✕"}</span>
                <span>
                  <span className="font-medium">{c.label}</span>
                  <span className="text-muted"> — {c.note}</span>
                </span>
              </li>
            ))}
          </ul>
        </div>
      )}

      {(request.resalePriceMin || request.vintedDescription) && (
        <div className="card mt-6 p-6">
          <h2 className="flex items-center gap-2 font-semibold text-brand">Bonus SNIPER</h2>

          {request.resalePriceMin != null && request.resalePriceMax != null && (
            <p className="mt-3 text-sm">
              Estimation de revente Vinted :{" "}
              <span className="font-semibold">
                {request.resalePriceMin}€ – {request.resalePriceMax}€
              </span>
            </p>
          )}

          {request.vintedDescription && (
            <div className="mt-4 rounded-xl border border-border bg-surface-2 p-4">
              <div className="flex items-center justify-between gap-3">
                <p className="text-sm font-medium">{request.vintedTitle}</p>
                <CopyButton text={`${request.vintedTitle}\n\n${request.vintedDescription}`} label="Copier l'annonce" />
              </div>
              <p className="mt-2 whitespace-pre-line text-sm text-muted">{request.vintedDescription}</p>
            </div>
          )}
        </div>
      )}

      <div className="mt-6 flex flex-wrap items-center gap-3">
        <Link
          href={`/certificat/${request.id}`}
          target="_blank"
          className="inline-flex items-center gap-2 rounded-lg border border-border px-4 py-2 text-sm hover:border-brand/50"
        >
          <ExternalLink size={16} /> Voir le certificat partageable
        </Link>
        <CopyButton text={`${process.env.NEXT_PUBLIC_APP_URL ?? ""}/certificat/${request.id}`} label="Copier le lien" />
      </div>
    </div>
  );
}
