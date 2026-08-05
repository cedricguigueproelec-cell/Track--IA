import Link from "next/link";
import { notFound } from "next/navigation";
import { ScanSearch } from "lucide-react";
import { prisma } from "@/lib/prisma";
import VerdictBadge from "@/components/VerdictBadge";
import AnswerCircle from "@/components/AnswerCircle";
import { formatDate } from "@/lib/utils";

export default async function CertificatPage(props: PageProps<"/certificat/[id]">) {
  const { id } = await props.params;

  const request = await prisma.authenticationRequest.findUnique({
    where: { id },
    select: {
      id: true,
      itemName: true,
      brand: true,
      verdict: true,
      confidence: true,
      status: true,
      createdAt: true,
    },
  });

  if (!request || request.status !== "DONE") notFound();

  return (
    <div className="flex min-h-screen flex-col items-center justify-center px-4 py-16">
      <Link href="/" className="mb-8 flex items-center gap-2 font-semibold">
        <span className="flex h-8 w-8 items-center justify-center rounded-lg bg-brand-soft text-brand">
          <ScanSearch size={18} />
        </span>
        Authenti<span className="text-brand">Scan</span>
      </Link>

      <div className="card w-full max-w-md p-8 text-center">
        <p className="text-xs uppercase tracking-wider text-muted">Certificat d&apos;analyse IA</p>
        <h1 className="mt-2 text-xl font-bold">{request.itemName || "Article"}</h1>
        {request.brand && <p className="text-sm text-muted">{request.brand}</p>}

        <div className="mt-6 flex justify-center">
          <AnswerCircle authentic={request.verdict === "AUTHENTIQUE"} />
        </div>

        <div className="mt-4 flex justify-center">
          <VerdictBadge verdict={request.verdict ?? "INDETERMINE"} />
        </div>

        <p className="mt-4 text-xs text-muted">Analysé le {formatDate(request.createdAt)} · confiance {request.confidence}</p>

        <div className="mt-6 rounded-lg border border-border bg-surface-2 p-3 text-xs text-muted">
          Ce certificat est une aide à la décision basée sur une analyse visuelle par IA, pas une expertise
          légale garantie à 100%.
        </div>
      </div>

      <Link href="/inscription" className="btn-brand mt-8 rounded-xl px-6 py-3 text-sm">
        Vérifier gratuitement mon propre article
      </Link>
    </div>
  );
}
