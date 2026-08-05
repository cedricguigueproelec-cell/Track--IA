"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { signOut } from "next-auth/react";
import {
  ScanSearch,
  LayoutDashboard,
  PlusCircle,
  History,
  CreditCard,
  LogOut,
  Menu,
} from "lucide-react";
import { useState } from "react";
import { cn } from "@/lib/utils";

const NAV = [
  { href: "/dashboard", label: "Vue d'ensemble", icon: LayoutDashboard },
  { href: "/dashboard/nouveau", label: "Nouvelle analyse", icon: PlusCircle },
  { href: "/dashboard/historique", label: "Historique", icon: History },
  { href: "/dashboard/facturation", label: "Facturation", icon: CreditCard },
];

export default function DashboardShell({
  children,
  userName,
  quota,
}: {
  children: React.ReactNode;
  userName: string;
  quota: { plan: string; used: number; limit: number; remaining: number; period: string };
}) {
  const pathname = usePathname();
  const [mobileOpen, setMobileOpen] = useState(false);

  const SidebarContent = (
    <div className="flex h-full flex-col">
      <Link href="/" className="flex items-center gap-2 px-5 py-5 font-semibold">
        <span className="flex h-8 w-8 items-center justify-center rounded-lg bg-brand-soft text-brand">
          <ScanSearch size={18} />
        </span>
        Authenti<span className="text-brand">Scan</span>
      </Link>

      <nav className="flex-1 space-y-1 px-3">
        {NAV.map((item) => {
          const active = pathname === item.href;
          return (
            <Link
              key={item.href}
              href={item.href}
              onClick={() => setMobileOpen(false)}
              className={cn(
                "flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm transition",
                active ? "bg-brand-soft text-brand" : "text-muted hover:bg-surface-2 hover:text-foreground"
              )}
            >
              <item.icon size={18} />
              {item.label}
            </Link>
          );
        })}
      </nav>

      <div className="mx-3 mb-3 rounded-xl border border-border bg-surface-2 p-4">
        <p className="text-xs text-muted">Forfait {quota.plan}</p>
        <p className="mt-1 text-sm font-medium">
          {quota.remaining} analyse{quota.remaining > 1 ? "s" : ""} restante{quota.remaining > 1 ? "s" : ""}
        </p>
        <div className="mt-2 h-1.5 w-full overflow-hidden rounded-full bg-border">
          <div
            className="h-full bg-brand"
            style={{ width: `${quota.limit > 0 ? Math.min(100, (quota.used / quota.limit) * 100) : 0}%` }}
          />
        </div>
        <p className="mt-1.5 text-[11px] text-muted">
          {quota.used}/{quota.limit} ce {quota.period}
        </p>
        <Link href="/dashboard/facturation" className="mt-3 block text-center text-xs font-semibold text-brand hover:underline">
          Changer de forfait
        </Link>
      </div>

      <div className="flex items-center justify-between border-t border-border px-5 py-4">
        <span className="truncate text-sm text-muted">{userName}</span>
        <button onClick={() => signOut({ callbackUrl: "/" })} className="text-muted hover:text-danger" aria-label="Déconnexion">
          <LogOut size={18} />
        </button>
      </div>
    </div>
  );

  return (
    <div className="flex min-h-screen">
      <aside className="hidden w-64 shrink-0 border-r border-border bg-surface/40 md:block">{SidebarContent}</aside>

      {mobileOpen && (
        <div className="fixed inset-0 z-50 flex md:hidden">
          <div className="w-64 bg-background border-r border-border">{SidebarContent}</div>
          <div className="flex-1 bg-black/60" onClick={() => setMobileOpen(false)} />
        </div>
      )}

      <div className="flex min-w-0 flex-1 flex-col">
        <header className="flex items-center justify-between border-b border-border px-4 py-3 md:hidden">
          <span className="font-semibold">
            Authenti<span className="text-brand">Scan</span>
          </span>
          <button onClick={() => setMobileOpen(true)}>
            <Menu size={22} />
          </button>
        </header>
        <main className="flex-1 px-4 py-8 sm:px-8">{children}</main>
      </div>
    </div>
  );
}
