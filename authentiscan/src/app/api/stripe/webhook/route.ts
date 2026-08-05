import { NextResponse } from "next/server";
import type Stripe from "stripe";
import { getStripe } from "@/lib/stripe";
import { prisma } from "@/lib/prisma";
import { planIdFromStripePriceId } from "@/lib/plans";

// Le webhook doit fonctionner tout seul, sans intervention humaine : c'est lui
// qui garde le plan/quota de chaque utilisateur synchronisé avec Stripe 24/7.
export async function POST(req: Request) {
  const signature = req.headers.get("stripe-signature");
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;
  if (!signature || !webhookSecret) {
    return NextResponse.json({ error: "Webhook non configuré." }, { status: 500 });
  }

  const rawBody = await req.text();
  const stripe = getStripe();

  let event: Stripe.Event;
  try {
    event = stripe.webhooks.constructEvent(rawBody, signature, webhookSecret);
  } catch {
    return NextResponse.json({ error: "Signature invalide." }, { status: 400 });
  }

  switch (event.type) {
    case "checkout.session.completed": {
      const checkoutSession = event.data.object as Stripe.Checkout.Session;
      const userId = checkoutSession.metadata?.userId ?? checkoutSession.client_reference_id;
      const subscriptionId =
        typeof checkoutSession.subscription === "string" ? checkoutSession.subscription : checkoutSession.subscription?.id;
      if (userId && subscriptionId) {
        const subscription = await stripe.subscriptions.retrieve(subscriptionId);
        await syncSubscription(userId, subscription);
      }
      break;
    }
    case "customer.subscription.updated": {
      const subscription = event.data.object as Stripe.Subscription;
      const userId = subscription.metadata?.userId;
      if (userId) await syncSubscription(userId, subscription);
      break;
    }
    case "customer.subscription.deleted": {
      const subscription = event.data.object as Stripe.Subscription;
      const userId = subscription.metadata?.userId;
      if (userId) {
        await prisma.user.updateMany({
          where: { id: userId },
          data: { plan: "FREE", stripeSubscriptionId: null, stripeCurrentPeriodEnd: null },
        });
      }
      break;
    }
    default:
      break;
  }

  return NextResponse.json({ received: true });
}

async function syncSubscription(userId: string, subscription: Stripe.Subscription) {
  const priceId = subscription.items.data[0]?.price.id;
  const planId = priceId ? planIdFromStripePriceId(priceId) : null;
  if (!planId) return;

  const periodEndTs = subscription.items.data[0]?.current_period_end;

  const now = new Date();
  const nextDay = new Date(now);
  nextDay.setHours(24, 0, 0, 0);
  const nextMonth = new Date(now.getFullYear(), now.getMonth() + 1, 1);

  await prisma.user.update({
    where: { id: userId },
    data: {
      plan: subscription.status === "active" || subscription.status === "trialing" ? planId : "FREE",
      stripeSubscriptionId: subscription.id,
      stripeCurrentPeriodEnd: periodEndTs ? new Date(periodEndTs * 1000) : null,
      // Reset des compteurs : l'utilisateur démarre son nouveau plan avec son quota complet.
      monthlyUsageCount: 0,
      monthlyResetAt: nextMonth,
      dailyUsageCount: 0,
      dailyResetAt: nextDay,
    },
  });
}
