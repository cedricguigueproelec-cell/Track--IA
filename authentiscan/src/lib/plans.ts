export type PlanId = "FREE" | "STARTER" | "EXPERT" | "SNIPER";

export interface PlanConfig {
  id: PlanId;
  name: string;
  tagline: string;
  price: number; // EUR
  period: "mois";
  quota: number;
  quotaPeriod: "mois" | "jour";
  hasResaleAnalysis: boolean;
  hasVintedListing: boolean;
  hasPriority: boolean;
  stripeEnvKey?: "STRIPE_PRICE_STARTER" | "STRIPE_PRICE_EXPERT" | "STRIPE_PRICE_SNIPER";
  highlight?: boolean;
  features: string[];
}

export const PLANS: Record<PlanId, PlanConfig> = {
  FREE: {
    id: "FREE",
    name: "Découverte",
    tagline: "3 authentifications offertes, sans CB",
    price: 0,
    period: "mois",
    quota: 3,
    quotaPeriod: "mois",
    hasResaleAnalysis: false,
    hasVintedListing: false,
    hasPriority: false,
    features: [
      "3 authentifications offertes à vie",
      "Analyse IA du logo, étiquette et matière",
      "Verdict + score de fiabilité",
    ],
  },
  STARTER: {
    id: "STARTER",
    name: "STARTER",
    tagline: "Pour vérifier vos achats et petites reventes",
    price: 5.99,
    period: "mois",
    quota: 20,
    quotaPeriod: "mois",
    hasResaleAnalysis: false,
    hasVintedListing: false,
    hasPriority: false,
    stripeEnvKey: "STRIPE_PRICE_STARTER",
    features: [
      "20 authentifications par mois",
      "Analyse IA logo / couture / matière / étiquette",
      "Verdict détaillé + points de vigilance",
      "Historique illimité",
      "Support par email",
    ],
  },
  EXPERT: {
    id: "EXPERT",
    name: "EXPERT",
    tagline: "Pour les revendeurs réguliers",
    price: 9.99,
    period: "mois",
    quota: 100,
    quotaPeriod: "mois",
    hasResaleAnalysis: false,
    hasVintedListing: false,
    hasPriority: true,
    stripeEnvKey: "STRIPE_PRICE_EXPERT",
    highlight: true,
    features: [
      "100 authentifications par mois",
      "Tout STARTER inclus",
      "Analyse prioritaire (file d'attente accélérée)",
      "Export PDF du rapport d'authentification",
      "Support prioritaire",
    ],
  },
  SNIPER: {
    id: "SNIPER",
    name: "SNIPER",
    tagline: "Pour les pros du dressing qui veulent scaler",
    price: 15.99,
    period: "mois",
    quota: 100,
    quotaPeriod: "jour",
    hasResaleAnalysis: true,
    hasVintedListing: true,
    hasPriority: true,
    stripeEnvKey: "STRIPE_PRICE_SNIPER",
    features: [
      "100 authentifications PAR JOUR",
      "Tout EXPERT inclus",
      "Estimation du prix de revente Vinted",
      "Annonce Vinted 100% rédigée et optimisée par l'IA",
      "Badge \"Certifié authentique\" partageable",
      "Accès anticipé aux nouvelles fonctionnalités",
    ],
  },
};

export const PAID_PLAN_ORDER: PlanId[] = ["STARTER", "EXPERT", "SNIPER"];

export function formatPrice(price: number): string {
  return price.toLocaleString("fr-FR", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

export function planIdFromStripePriceId(priceId: string): PlanId | null {
  for (const id of PAID_PLAN_ORDER) {
    const plan = PLANS[id];
    if (plan.stripeEnvKey && process.env[plan.stripeEnvKey] === priceId) return id;
  }
  return null;
}
