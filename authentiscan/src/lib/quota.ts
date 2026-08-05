import { prisma } from "@/lib/prisma";
import { PLANS, type PlanId } from "@/lib/plans";
import type { User } from "@prisma/client";

function startOfNextDay(from: Date): Date {
  const d = new Date(from);
  d.setHours(24, 0, 0, 0);
  return d;
}

function startOfNextMonth(from: Date): Date {
  return new Date(from.getFullYear(), from.getMonth() + 1, 1);
}

/**
 * Remet à zéro les compteurs jour/mois si la fenêtre est dépassée.
 * Appelé à chaque requête d'analyse : rend l'IA "autonome", sans cron externe.
 */
async function ensureFreshCounters(user: User): Promise<User> {
  const now = new Date();
  const data: Record<string, unknown> = {};

  if (now >= user.dailyResetAt) {
    data.dailyUsageCount = 0;
    data.dailyResetAt = startOfNextDay(now);
  }
  if (now >= user.monthlyResetAt) {
    data.monthlyUsageCount = 0;
    data.monthlyResetAt = startOfNextMonth(now);
  }

  if (Object.keys(data).length === 0) return user;

  return prisma.user.update({ where: { id: user.id }, data });
}

export interface QuotaStatus {
  allowed: boolean;
  remaining: number;
  limit: number;
  period: "jour" | "mois";
  usingBonus: boolean;
}

export async function checkAndConsumeQuota(userId: string): Promise<QuotaStatus> {
  let user = await prisma.user.findUniqueOrThrow({ where: { id: userId } });
  user = await ensureFreshCounters(user);

  const plan = PLANS[user.plan as PlanId] ?? PLANS.FREE;

  // Plan gratuit : quota "à vie", pas de reset périodique.
  if (plan.id === "FREE") {
    const remaining = plan.quota - user.freeTrialUsed;
    if (remaining > 0) {
      await prisma.user.update({ where: { id: userId }, data: { freeTrialUsed: { increment: 1 } } });
      return { allowed: true, remaining: remaining - 1, limit: plan.quota, period: "mois", usingBonus: false };
    }
    if (user.referralBonus > 0) {
      await prisma.user.update({ where: { id: userId }, data: { referralBonus: { decrement: 1 } } });
      return { allowed: true, remaining: user.referralBonus - 1, limit: plan.quota, period: "mois", usingBonus: true };
    }
    return { allowed: false, remaining: 0, limit: plan.quota, period: "mois", usingBonus: false };
  }

  const used = plan.quotaPeriod === "jour" ? user.dailyUsageCount : user.monthlyUsageCount;
  if (used < plan.quota) {
    await prisma.user.update({
      where: { id: userId },
      data:
        plan.quotaPeriod === "jour"
          ? { dailyUsageCount: { increment: 1 } }
          : { monthlyUsageCount: { increment: 1 } },
    });
    return { allowed: true, remaining: plan.quota - used - 1, limit: plan.quota, period: plan.quotaPeriod, usingBonus: false };
  }

  if (user.referralBonus > 0) {
    await prisma.user.update({ where: { id: userId }, data: { referralBonus: { decrement: 1 } } });
    return { allowed: true, remaining: user.referralBonus - 1, limit: plan.quota, period: plan.quotaPeriod, usingBonus: true };
  }

  return { allowed: false, remaining: 0, limit: plan.quota, period: plan.quotaPeriod, usingBonus: false };
}

/**
 * Recrédite le quota consommé si l'analyse IA échoue derrière — l'utilisateur
 * ne doit jamais perdre un crédit pour une erreur technique.
 */
export async function refundQuota(userId: string, status: QuotaStatus): Promise<void> {
  const user = await prisma.user.findUniqueOrThrow({ where: { id: userId } });
  const plan = PLANS[user.plan as PlanId] ?? PLANS.FREE;

  if (status.usingBonus) {
    await prisma.user.update({ where: { id: userId }, data: { referralBonus: { increment: 1 } } });
    return;
  }

  if (plan.id === "FREE") {
    await prisma.user.update({ where: { id: userId }, data: { freeTrialUsed: { decrement: 1 } } });
    return;
  }

  await prisma.user.update({
    where: { id: userId },
    data:
      plan.quotaPeriod === "jour" ? { dailyUsageCount: { decrement: 1 } } : { monthlyUsageCount: { decrement: 1 } },
  });
}

export async function getQuotaSnapshot(userId: string) {
  let user = await prisma.user.findUniqueOrThrow({ where: { id: userId } });
  user = await ensureFreshCounters(user);
  const plan = PLANS[user.plan as PlanId] ?? PLANS.FREE;

  const used =
    plan.id === "FREE" ? user.freeTrialUsed : plan.quotaPeriod === "jour" ? user.dailyUsageCount : user.monthlyUsageCount;

  return {
    plan,
    used,
    limit: plan.quota,
    remaining: Math.max(0, plan.quota - used) + user.referralBonus,
    bonus: user.referralBonus,
    resetAt: plan.quotaPeriod === "jour" ? user.dailyResetAt : user.monthlyResetAt,
  };
}
