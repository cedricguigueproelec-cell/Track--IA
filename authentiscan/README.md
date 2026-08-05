# AuthentiScan

Site + logiciel d'authentification d'articles de mode par IA : le client
prend en photo l'étiquette/logo, les coutures/matière et éventuellement une
autre vue de l'article, et l'IA renvoie un verdict, un score de fiabilité et
les points de vigilance. 3 forfaits (STARTER / EXPERT / SNIPER), essai
gratuit sans CB, parrainage, certificat partageable.

> ⚠️ **Important** : l'analyse est une aide à la décision basée sur une
> analyse visuelle par IA (Gemini, Google). Aucune IA ne peut garantir
> l'authenticité d'un article à 100 % sur simple photo — c'est assumé et
> affiché honnêtement partout dans le produit (landing, FAQ, résultats,
> certificat). Ne présentez jamais le service comme une garantie légale.

## Stack technique

- **Next.js 16** (App Router, Turbopack) + TypeScript + Tailwind CSS 4
- **Prisma** + SQLite en dev (bascule Postgres en une ligne pour la prod)
- **NextAuth v5** (credentials + JWT)
- **Google Gemini SDK** (`@google/genai`) — moteur d'analyse vision
- **Stripe** — abonnements, webhook, portail de facturation

## Démarrage en local

```bash
npm install
cp .env.example .env      # puis éditez .env (voir ci-dessous)
npx prisma migrate dev    # crée prisma/dev.db
npm run dev
```

Ouvrez [http://localhost:3000](http://localhost:3000).

Pour que l'authentification IA fonctionne réellement en local, renseignez
`GEMINI_API_KEY` dans `.env` (clé gratuite sur
[Google AI Studio](https://aistudio.google.com/apikey), aucune carte
bancaire requise). Sans clé, le reste du site (inscription,
tableau de bord, tarifs, facturation) fonctionne normalement ; seule
l'analyse elle-même renverra une erreur claire (et ne décompte jamais de
crédit dans ce cas — voir `lib/quota.ts` → `refundQuota`).

**Important — variables `NEXT_PUBLIC_*`** : elles sont figées dans le build
au moment de `next build` (comportement standard Next.js), pas relues au
démarrage du serveur. Si vous changez `NEXT_PUBLIC_APP_URL`, relancez un
build (`npm run build`) avant de redémarrer.

## Déploiement en production (24h/24, 7j/7, sans intervention)

Le site est un service web classique : une fois déployé, l'IA répond à
chaque requête HTTP entrante, jour et nuit, sans processus à surveiller ni
tâche cron à maintenir (les quotas jour/mois se réinitialisent tout seuls,
voir `lib/quota.ts`). Stack recommandée, 100 % gratuite pour démarrer :

1. **Hébergement** : [Vercel](https://vercel.com) (ou tout hébergeur
   Node.js compatible Next.js). Connectez le repo, définissez le
   sous-dossier `authentiscan` comme racine du projet.
2. **Base de données** : Postgres managé (ex. [Neon](https://neon.tech) ou
   [Supabase](https://supabase.com), plan gratuit suffisant pour démarrer).
   - Dans `prisma/schema.prisma`, changez `provider = "sqlite"` en
     `provider = "postgresql"`.
   - Renseignez `DATABASE_URL` avec l'URL Postgres fournie.
   - Lancez `npx prisma migrate deploy` (en CI/CD ou manuellement) pour
     appliquer le schéma.
3. **IA** : créez une clé gratuite sur
   [Google AI Studio](https://aistudio.google.com/apikey) (aucune carte
   bancaire requise, le tier gratuit n'expire pas), renseignez
   `GEMINI_API_KEY`. C'est cette clé, seule, qui fait tourner l'IA en
   continu — aucun serveur GPU à gérer. Le tier gratuit est limité en
   requêtes/minute ; si le volume grossit, activez la facturation sur le
   même projet Google Cloud sans changer de code.
4. **Paiements** : créez un compte [Stripe](https://dashboard.stripe.com),
   créez 3 Prix récurrents mensuels (5,99€ / 9,99€ / 15,99€) et reportez
   leurs `price_id` dans `STRIPE_PRICE_STARTER` / `STRIPE_PRICE_EXPERT` /
   `STRIPE_PRICE_SNIPER`. Configurez un webhook Stripe pointant vers
   `https://votre-domaine/api/stripe/webhook` (événements : `checkout.session.completed`,
   `customer.subscription.updated`, `customer.subscription.deleted`), et
   copiez son secret dans `STRIPE_WEBHOOK_SECRET`.
5. **Auth** : générez un secret (`openssl rand -base64 32`) pour `AUTH_SECRET`,
   renseignez `NEXTAUTH_URL` et `NEXT_PUBLIC_APP_URL` avec votre domaine
   final, et mettez `AUTH_TRUST_HOST=true` si vous déployez derrière un
   proxy/reverse-proxy (recommandé par défaut).
6. Déployez. Le site tourne alors en continu, indépendamment, tant que
   l'hébergeur et les clés API sont actifs — aucune intervention manuelle
   n'est nécessaire pour que l'IA continue de répondre.

Toutes les variables sont listées avec leur usage dans `.env.example`.

## Fonctionnement du produit

- **Analyse** (`src/lib/ai.ts`) : envoie les photos à Gemini (vision) avec
  un prompt d'expert authentification, qui répond en JSON structuré
  (verdict, score, confiance, points de vigilance, checklist, raisonnement
  — et pour SNIPER, fourchette de prix de revente Vinted + annonce prête à
  publier).
- **Quotas** (`src/lib/quota.ts`) : compteurs jour/mois auto-réinitialisés
  à la demande (pas de cron nécessaire), remboursés automatiquement en cas
  d'échec technique de l'IA.
- **Croissance** : essai gratuit sans CB (3 analyses), programme de
  parrainage (crédits bonus des deux côtés), certificat d'authentification
  partageable (`/certificat/[id]`, page publique, effet viral), tarif
  annuel avec 2 mois offerts.

## Personnalisation attendue avant mise en ligne

- Remplacez le nom "AuthentiScan" si vous préférez une autre marque.
- Ajustez les textes légaux (CGU/CGV, politique de confidentialité) dans
  `src/components/Footer.tsx` — actuellement des placeholders.
- Le design reprend l'esprit sombre/turquoise des outils Vinted premium
  (type V-TOOLS) mais avec une identité propre : pas de logo ni de charte
  copiés, pour éviter tout problème de propriété intellectuelle.
