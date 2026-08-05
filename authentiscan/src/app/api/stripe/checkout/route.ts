import { NextResponse } from "next/server";
import { z } from "zod";
import { auth } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import { getStripe } from "@/lib/stripe";
import { PLANS, PAID_PLAN_ORDER, type PlanId } from "@/lib/plans";

const schema = z.object({ plan: z.enum(["STARTER", "EXPERT", "SNIPER"]) });

export async function POST(req: Request) {
  const session = await auth();
  if (!session?.user) return NextResponse.json({ error: "Non authentifié." }, { status: 401 });

  const body = await req.json().catch(() => null);
  const parsed = schema.safeParse(body);
  if (!parsed.success) return NextResponse.json({ error: "Forfait invalide." }, { status: 400 });

  const planId = parsed.data.plan as (typeof PAID_PLAN_ORDER)[number];
  const plan = PLANS[planId as PlanId];
  const priceId = plan.stripeEnvKey ? process.env[plan.stripeEnvKey] : undefined;
  if (!priceId) {
    return NextResponse.json(
      { error: "Ce forfait n'est pas encore configuré côté paiement (STRIPE_PRICE_* manquant)." },
      { status: 500 }
    );
  }

  const userId = (session.user as { id: string }).id;
  const user = await prisma.user.findUniqueOrThrow({ where: { id: userId } });
  const stripe = getStripe();
  const appUrl = process.env.NEXT_PUBLIC_APP_URL ?? new URL(req.url).origin;

  let customerId = user.stripeCustomerId ?? undefined;
  if (!customerId) {
    const customer = await stripe.customers.create({ email: user.email, name: user.name ?? undefined });
    customerId = customer.id;
    await prisma.user.update({ where: { id: user.id }, data: { stripeCustomerId: customerId } });
  }

  const checkoutSession = await stripe.checkout.sessions.create({
    mode: "subscription",
    customer: customerId,
    line_items: [{ price: priceId, quantity: 1 }],
    success_url: `${appUrl}/dashboard/facturation?success=1`,
    cancel_url: `${appUrl}/dashboard/facturation?canceled=1`,
    client_reference_id: user.id,
    metadata: { userId: user.id, plan: planId },
    subscription_data: { metadata: { userId: user.id, plan: planId } },
  });

  return NextResponse.json({ url: checkoutSession.url });
}
