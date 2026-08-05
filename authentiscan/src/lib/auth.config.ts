import type { NextAuthConfig } from "next-auth";

/**
 * Config "edge-safe" partagée entre le middleware (léger, sans Prisma/bcrypt)
 * et la config complète (lib/auth.ts, utilisée côté serveur Node).
 */
export const authConfig: NextAuthConfig = {
  session: { strategy: "jwt" },
  pages: { signIn: "/connexion" },
  providers: [],
  callbacks: {
    async jwt({ token, user }) {
      if (user?.id) token.uid = user.id;
      return token;
    },
    async session({ session, token }) {
      if (session.user && token.uid) {
        (session.user as { id?: string }).id = token.uid as string;
      }
      return session;
    },
  },
};
