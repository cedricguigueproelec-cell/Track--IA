import { ShieldCheck, ShieldAlert, ShieldX, ShieldQuestion } from "lucide-react";
import { cn } from "@/lib/utils";

const CONFIG: Record<string, { label: string; icon: typeof ShieldCheck; className: string }> = {
  AUTHENTIQUE: { label: "Probablement authentique", icon: ShieldCheck, className: "bg-success/15 text-success border-success/30" },
  SUSPECT: { label: "Suspect", icon: ShieldAlert, className: "bg-warning/15 text-warning border-warning/30" },
  CONTREFACON: { label: "Probable contrefaçon", icon: ShieldX, className: "bg-danger/15 text-danger border-danger/30" },
  INDETERMINE: { label: "Indéterminé", icon: ShieldQuestion, className: "bg-muted/15 text-muted border-border" },
};

export default function VerdictBadge({ verdict, size = "md" }: { verdict: string; size?: "sm" | "md" }) {
  const cfg = CONFIG[verdict] ?? CONFIG.INDETERMINE;
  const Icon = cfg.icon;
  return (
    <span
      className={cn(
        "inline-flex items-center gap-2 rounded-full border font-semibold",
        cfg.className,
        size === "md" ? "px-4 py-2 text-sm" : "px-2.5 py-1 text-xs"
      )}
    >
      <Icon size={size === "md" ? 18 : 14} />
      {cfg.label}
    </span>
  );
}
