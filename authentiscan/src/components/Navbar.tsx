"use client";

import Link from "next/link";
import { useState } from "react";
import { useSession, signOut } from "next-auth/react";
import { ScanSearch, Menu, X } from "lucide-react";

const LINKS = [
  { href: "/#comment-ca-marche", label: "Comment ça marche" },
  { href: "/tarifs", label: "Tarifs" },
  { href: "/#faq", label: "FAQ" },
];

export default function Navbar() {
  const { status } = useSession();
  const [open, setOpen] = useState(false);

  return (
    <header className="sticky top-0 z-50 border-b border-border/80 bg-background/80 backdrop-blur-md">
      <div className="mx-auto flex max-w-6xl items-center justify-between px-4 py-3 sm:px-6">
        <Link href="/" className="flex items-center gap-2 font-semibold tracking-tight">
          <span className="flex h-8 w-8 items-center justify-center rounded-lg bg-brand-soft text-brand">
            <ScanSearch size={18} />
          </span>
          <span className="text-lg">
            Authenti<span className="text-brand">Scan</span>
          </span>
        </Link>

        <nav className="hidden items-center gap-8 md:flex">
          {LINKS.map((l) => (
            <Link key={l.href} href={l.href} className="text-sm text-muted transition hover:text-foreground">
              {l.label}
            </Link>
          ))}
        </nav>

        <div className="hidden items-center gap-3 md:flex">
          {status === "authenticated" ? (
            <>
              <Link href="/dashboard" className="text-sm text-muted hover:text-foreground">
                Tableau de bord
              </Link>
              <button
                onClick={() => signOut({ callbackUrl: "/" })}
                className="rounded-lg border border-border px-4 py-2 text-sm hover:border-brand/50"
              >
                Déconnexion
              </button>
            </>
          ) : (
            <>
              <Link href="/connexion" className="text-sm text-muted hover:text-foreground">
                Connexion
              </Link>
              <Link href="/inscription" className="btn-brand rounded-lg px-4 py-2 text-sm">
                Commencer gratuitement
              </Link>
            </>
          )}
        </div>

        <button className="md:hidden" onClick={() => setOpen((o) => !o)} aria-label="Menu">
          {open ? <X size={22} /> : <Menu size={22} />}
        </button>
      </div>

      {open && (
        <div className="border-t border-border px-4 py-4 md:hidden">
          <div className="flex flex-col gap-4">
            {LINKS.map((l) => (
              <Link key={l.href} href={l.href} onClick={() => setOpen(false)} className="text-sm text-muted">
                {l.label}
              </Link>
            ))}
            <div className="mt-2 flex flex-col gap-2 border-t border-border pt-4">
              {status === "authenticated" ? (
                <>
                  <Link href="/dashboard" className="text-sm">
                    Tableau de bord
                  </Link>
                  <button onClick={() => signOut({ callbackUrl: "/" })} className="text-left text-sm text-muted">
                    Déconnexion
                  </button>
                </>
              ) : (
                <>
                  <Link href="/connexion" className="text-sm text-muted">
                    Connexion
                  </Link>
                  <Link href="/inscription" className="btn-brand rounded-lg px-4 py-2 text-center text-sm">
                    Commencer gratuitement
                  </Link>
                </>
              )}
            </div>
          </div>
        </div>
      )}
    </header>
  );
}
