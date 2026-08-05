import Link from "next/link";

export default function CTASection() {
  return (
    <section className="px-4 pb-24 sm:px-6">
      <div className="mx-auto max-w-4xl rounded-3xl border border-brand/30 bg-[radial-gradient(ellipse_100%_100%_at_50%_0%,rgba(20,224,196,0.14),transparent)] p-10 text-center sm:p-16">
        <h2 className="text-3xl font-bold tracking-tight sm:text-4xl">Prêt à vérifier votre premier article ?</h2>
        <p className="mx-auto mt-3 max-w-xl text-muted">
          3 authentifications offertes, sans carte bancaire. Résultat en moins d&apos;une minute.
        </p>
        <Link href="/inscription" className="btn-brand mt-8 inline-block rounded-xl px-8 py-3.5 text-base">
          Commencer gratuitement
        </Link>
      </div>
    </section>
  );
}
