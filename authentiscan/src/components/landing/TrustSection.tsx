import { Lock, Cpu, Clock, Ban } from "lucide-react";

const POINTS = [
  {
    icon: Cpu,
    title: "IA multimodale de pointe",
    text: "L'analyse s'appuie sur les modèles Claude d'Anthropic, entraînés à repérer des détails visuels fins (typographie, coutures, textures).",
  },
  {
    icon: Clock,
    title: "Disponible H24, 7j/7",
    text: "Aucun serveur à gérer de votre côté : l'IA répond automatiquement, day ou night, week-end compris.",
  },
  {
    icon: Lock,
    title: "Vos données, protégées",
    text: "Vos photos servent uniquement à générer votre rapport. Vous gardez le contrôle et pouvez supprimer votre historique à tout moment.",
  },
  {
    icon: Ban,
    title: "Sans engagement",
    text: "Changez de forfait ou résiliez en un clic depuis votre tableau de bord, à tout moment.",
  },
];

export default function TrustSection() {
  return (
    <section className="border-y border-border bg-surface/30 px-4 py-16 sm:px-6">
      <div className="mx-auto max-w-6xl">
        <div className="grid gap-8 sm:grid-cols-2 lg:grid-cols-4">
          {POINTS.map((p) => (
            <div key={p.title}>
              <div className="mb-3 flex h-10 w-10 items-center justify-center rounded-xl bg-brand-soft text-brand">
                <p.icon size={20} />
              </div>
              <h3 className="font-semibold">{p.title}</h3>
              <p className="mt-1.5 text-sm text-muted">{p.text}</p>
            </div>
          ))}
        </div>

        <div className="mt-10 rounded-xl border border-border bg-surface p-5 text-sm text-muted">
          <strong className="text-foreground">Bon à savoir :</strong> l&apos;IA fournit une aide à la décision basée
          sur une analyse visuelle poussée — pas une expertise juridique. Sur les articles à forte valeur, elle
          reste un excellent premier filtre avant une expertise physique si besoin.
        </div>
      </div>
    </section>
  );
}
