import Link from "next/link";
import { ScanSearch } from "lucide-react";

export default function Footer() {
  return (
    <footer className="border-t border-border bg-surface/40">
      <div className="mx-auto max-w-6xl px-4 py-12 sm:px-6">
        <div className="grid gap-10 sm:grid-cols-2 md:grid-cols-4">
          <div>
            <div className="flex items-center gap-2 font-semibold">
              <span className="flex h-7 w-7 items-center justify-center rounded-lg bg-brand-soft text-brand">
                <ScanSearch size={16} />
              </span>
              Authenti<span className="text-brand">Scan</span>
            </div>
            <p className="mt-3 text-sm text-muted">
              L&apos;authentification de mode par IA, disponible 24h/24 et 7j/7.
            </p>
          </div>

          <div>
            <h4 className="text-sm font-semibold text-foreground">Produit</h4>
            <ul className="mt-3 space-y-2 text-sm text-muted">
              <li><Link href="/#comment-ca-marche" className="hover:text-brand">Comment ça marche</Link></li>
              <li><Link href="/tarifs" className="hover:text-brand">Tarifs</Link></li>
              <li><Link href="/#faq" className="hover:text-brand">FAQ</Link></li>
              <li><Link href="/inscription" className="hover:text-brand">Essai gratuit</Link></li>
            </ul>
          </div>

          <div>
            <h4 className="text-sm font-semibold text-foreground">Compte</h4>
            <ul className="mt-3 space-y-2 text-sm text-muted">
              <li><Link href="/connexion" className="hover:text-brand">Connexion</Link></li>
              <li><Link href="/dashboard/facturation" className="hover:text-brand">Facturation</Link></li>
              <li><Link href="/dashboard" className="hover:text-brand">Tableau de bord</Link></li>
            </ul>
          </div>

          <div>
            <h4 className="text-sm font-semibold text-foreground">Légal</h4>
            <ul className="mt-3 space-y-2 text-sm text-muted">
              <li>CGU / CGV</li>
              <li>Politique de confidentialité</li>
              <li>Contact : contact@authentiscan.app</li>
            </ul>
          </div>
        </div>

        <div className="mt-10 border-t border-border pt-6 text-xs text-muted">
          <p>
            © {new Date().getFullYear()} AuthentiScan. Les résultats fournis par l&apos;IA sont une aide à la
            décision basée sur une analyse visuelle et ne constituent pas une expertise légale ou une garantie
            d&apos;authenticité à 100 %. AuthentiScan n&apos;est affilié à aucune des marques mentionnées à titre
            d&apos;exemple, ni à Vinted.
          </p>
        </div>
      </div>
    </footer>
  );
}
