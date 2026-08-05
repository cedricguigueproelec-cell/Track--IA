import type { Metadata } from "next";
import Pricing from "@/components/landing/Pricing";
import FAQ from "@/components/landing/FAQ";

export const metadata: Metadata = {
  title: "Tarifs — AuthentiScan",
  description: "STARTER, EXPERT, SNIPER : choisissez le forfait d'authentification IA adapté à votre usage.",
};

export default function TarifsPage() {
  return (
    <div className="pt-12">
      <div className="mx-auto max-w-2xl px-4 text-center sm:px-6">
        <h1 className="text-4xl font-bold tracking-tight">Des forfaits pensés pour chaque usage</h1>
        <p className="mt-3 text-muted">De l&apos;acheteur occasionnel au revendeur professionnel.</p>
      </div>
      <Pricing />
      <FAQ />
    </div>
  );
}
