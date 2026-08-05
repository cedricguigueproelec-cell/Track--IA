export default function AnswerCircle({ authentic }: { authentic: boolean }) {
  const color = authentic ? "var(--success)" : "var(--danger)";

  return (
    <div
      className="flex h-40 w-40 shrink-0 flex-col items-center justify-center rounded-full border-4"
      style={{ borderColor: color }}
    >
      <span className="text-4xl font-extrabold" style={{ color }}>
        {authentic ? "OUI" : "NON"}
      </span>
      <span className="mt-1 text-xs text-muted">authentique ?</span>
    </div>
  );
}
