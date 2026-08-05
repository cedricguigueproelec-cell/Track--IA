import { Camera, ScanSearch, FileCheck2 } from "lucide-react";

const STEPS = [
  {
    icon: Camera,
    title: "1. Prenez vos photos",
    text: "Étiquette / logo, coutures ou matière, et une vue d'ensemble. Plus les photos sont nettes et proches, plus l'analyse est fiable.",
  },
  {
    icon: ScanSearch,
    title: "2. L'IA analyse chaque détail",
    text: "Typographie du logo, régularité des coutures, qualité des matériaux, ferrures, format de l'étiquette : l'IA croise des dizaines de points de contrôle.",
  },
  {
    icon: FileCheck2,
    title: "3. Recevez votre rapport",
    text: "Réponse claire (oui ou non), niveau de confiance et points de vigilance détaillés. Avec le forfait SNIPER : prix de revente + annonce Vinted prête à publier.",
  },
];

export default function HowItWorks() {
  return (
    <section id="comment-ca-marche" className="px-4 py-20 sm:px-6">
      <div className="mx-auto max-w-6xl">
        <div className="mx-auto max-w-2xl text-center">
          <h2 className="text-3xl font-bold tracking-tight sm:text-4xl">Comment ça marche</h2>
          <p className="mt-3 text-muted">Trois étapes, zéro expertise nécessaire.</p>
        </div>

        <div className="mt-14 grid gap-6 md:grid-cols-3">
          {STEPS.map((step) => (
            <div key={step.title} className="card p-6">
              <div className="mb-4 flex h-11 w-11 items-center justify-center rounded-xl bg-brand-soft text-brand">
                <step.icon size={22} />
              </div>
              <h3 className="text-lg font-semibold">{step.title}</h3>
              <p className="mt-2 text-sm leading-relaxed text-muted">{step.text}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
