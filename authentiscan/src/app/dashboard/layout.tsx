import { redirect } from "next/navigation";
import { auth } from "@/lib/auth";
import { getQuotaSnapshot } from "@/lib/quota";
import DashboardShell from "@/components/dashboard/DashboardShell";

export default async function DashboardLayout({ children }: { children: React.ReactNode }) {
  const session = await auth();
  if (!session?.user) redirect("/connexion");

  const userId = (session.user as { id: string }).id;
  const quota = await getQuotaSnapshot(userId);

  return (
    <DashboardShell
      userName={session.user.name ?? session.user.email ?? "Mon compte"}
      quota={{ plan: quota.plan.name, used: quota.used, limit: quota.limit, remaining: quota.remaining, period: quota.plan.quotaPeriod }}
    >
      {children}
    </DashboardShell>
  );
}
