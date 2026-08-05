import { NextResponse } from "next/server";
import { z } from "zod";
import { auth } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import { checkAndConsumeQuota, refundQuota } from "@/lib/quota";
import { analyzeAuthenticity } from "@/lib/ai";
import { PLANS, type PlanId } from "@/lib/plans";

const schema = z.object({
  itemName: z.string().max(120).optional(),
  brand: z.string().max(80).optional(),
  images: z
    .array(
      z.object({
        kind: z.string(),
        dataUrl: z.string().startsWith("data:image/"),
      })
    )
    .min(1, "Au moins une photo est requise.")
    .max(6, "6 photos maximum par analyse."),
});

const MAX_IMAGE_BYTES = 8 * 1024 * 1024; // ~8 Mo par photo (avant encodage base64)

export async function POST(req: Request) {
  const session = await auth();
  if (!session?.user) {
    return NextResponse.json({ error: "Non authentifié." }, { status: 401 });
  }
  const userId = (session.user as { id: string }).id;

  const body = await req.json().catch(() => null);
  const parsed = schema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json({ error: parsed.error.issues[0]?.message ?? "Requête invalide." }, { status: 400 });
  }

  for (const img of parsed.data.images) {
    const approxBytes = (img.dataUrl.length * 3) / 4;
    if (approxBytes > MAX_IMAGE_BYTES) {
      return NextResponse.json({ error: "Une photo dépasse la taille maximale autorisée (8 Mo)." }, { status: 413 });
    }
  }

  const quota = await checkAndConsumeQuota(userId);
  if (!quota.allowed) {
    return NextResponse.json(
      { error: `Quota atteint (${quota.limit}/${quota.period}). Passez à un forfait supérieur pour continuer.` },
      { status: 429 }
    );
  }

  const user = await prisma.user.findUniqueOrThrow({ where: { id: userId } });
  const plan = PLANS[user.plan as PlanId] ?? PLANS.FREE;

  const request = await prisma.authenticationRequest.create({
    data: {
      userId,
      itemName: parsed.data.itemName,
      brand: parsed.data.brand,
      imageCount: parsed.data.images.length,
      status: "PENDING",
    },
  });

  try {
    const result = await analyzeAuthenticity({
      itemName: parsed.data.itemName,
      brand: parsed.data.brand,
      images: parsed.data.images,
      includeResaleAnalysis: plan.hasResaleAnalysis,
    });

    await prisma.authenticationRequest.update({
      where: { id: request.id },
      data: {
        status: "DONE",
        verdict: result.verdict,
        score: result.score,
        confidence: result.confidence,
        redFlags: JSON.stringify(result.redFlags),
        checklist: JSON.stringify(result.checklist),
        reasoning: result.reasoning,
        resalePriceMin: result.resalePriceMin,
        resalePriceMax: result.resalePriceMax,
        vintedTitle: result.vintedTitle,
        vintedDescription: result.vintedDescription,
      },
    });

    return NextResponse.json({ id: request.id });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Erreur inconnue lors de l'analyse.";
    await Promise.all([
      prisma.authenticationRequest.update({
        where: { id: request.id },
        data: { status: "ERROR", errorMessage: message },
      }),
      refundQuota(userId, quota),
    ]);
    return NextResponse.json({ error: `L'analyse a échoué : ${message}` }, { status: 502 });
  }
}
