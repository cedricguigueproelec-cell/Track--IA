"use client";

import { useState } from "react";
import { ChevronDown } from "lucide-react";
import { cn } from "@/lib/utils";

const FAQS = [
  {
    q: "L'IA garantit-elle à 100% qu'un article est authentique ?",
    a: "Non, et personne ne peut le garantir sur photo à 100%. AuthentiScan vous donne une réponse claire (oui/non) et un niveau de confiance basés sur l'analyse visuelle de dizaines de détails. C'est un outil d'aide à la décision très fiable pour repérer les incohérences, pas une expertise légale.",
  },
  {
    q: "Quelles photos dois-je fournir ?",
    a: "Idéalement : une photo nette de l'étiquette/logo, une photo des coutures ou de la matière, et une vue d'ensemble de l'article. Plus vos photos sont précises et bien éclairées, plus le rapport est fiable.",
  },
  {
    q: "Puis-je changer de forfait ou résilier à tout moment ?",
    a: "Oui. Vous pouvez changer de forfait ou résilier en un clic depuis votre tableau de bord, sans engagement ni frais cachés.",
  },
  {
    q: "Que se passe-t-il si je dépasse mon quota ?",
    a: "Vous pouvez passer au forfait supérieur à tout moment, ou attendre le renouvellement de votre quota. Les filleuls et parrains reçoivent aussi des analyses bonus offertes.",
  },
  {
    q: "Le forfait SNIPER, c'est quoi en plus ?",
    a: "En plus de l'authentification, l'IA estime une fourchette de prix de revente sur Vinted et rédige une annonce complète et optimisée (titre + description) prête à publier.",
  },
  {
    q: "Est-ce que ça marche pour toutes les marques et tous les articles ?",
    a: "Oui, l'IA n'est pas limitée à une liste de marques : vêtements, chaussures, maroquinerie, accessoires — tant que vous fournissez des photos exploitables.",
  },
];

export default function FAQ() {
  const [openIndex, setOpenIndex] = useState<number | null>(0);

  return (
    <section id="faq" className="px-4 py-20 sm:px-6">
      <div className="mx-auto max-w-3xl">
        <h2 className="text-center text-3xl font-bold tracking-tight sm:text-4xl">Questions fréquentes</h2>

        <div className="mt-10 space-y-3">
          {FAQS.map((item, i) => (
            <div key={item.q} className="card overflow-hidden">
              <button
                onClick={() => setOpenIndex(openIndex === i ? null : i)}
                className="flex w-full items-center justify-between gap-4 p-5 text-left"
              >
                <span className="font-medium">{item.q}</span>
                <ChevronDown
                  size={18}
                  className={cn("shrink-0 text-muted transition-transform", openIndex === i && "rotate-180 text-brand")}
                />
              </button>
              {openIndex === i && <p className="px-5 pb-5 text-sm leading-relaxed text-muted">{item.a}</p>}
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
