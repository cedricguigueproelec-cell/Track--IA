import { NextResponse } from "next/server";
import bcrypt from "bcryptjs";
import { z } from "zod";
import { prisma } from "@/lib/prisma";
import { generateReferralCode } from "@/lib/utils";

const schema = z.object({
  name: z.string().min(1).max(80),
  email: z.string().email(),
  password: z.string().min(8).max(128),
  referralCode: z.string().trim().optional(),
});

export async function POST(req: Request) {
  const body = await req.json().catch(() => null);
  const parsed = schema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json({ error: "Formulaire invalide." }, { status: 400 });
  }

  const { name, password } = parsed.data;
  const email = parsed.data.email.toLowerCase().trim();

  const existing = await prisma.user.findUnique({ where: { email } });
  if (existing) {
    return NextResponse.json({ error: "Un compte existe déjà avec cet email." }, { status: 409 });
  }

  let referredBy: { id: string } | null = null;
  if (parsed.data.referralCode) {
    referredBy = await prisma.user.findUnique({
      where: { referralCode: parsed.data.referralCode.toUpperCase() },
      select: { id: true },
    });
  }

  const passwordHash = await bcrypt.hash(password, 12);

  let referralCode = generateReferralCode();
  for (let i = 0; i < 5; i++) {
    const clash = await prisma.user.findUnique({ where: { referralCode } });
    if (!clash) break;
    referralCode = generateReferralCode();
  }

  const user = await prisma.user.create({
    data: {
      name,
      email,
      passwordHash,
      referralCode,
      referredById: referredBy?.id,
      // Le parrain ET le filleul reçoivent 2 authentifications bonus.
      referralBonus: referredBy ? 2 : 0,
    },
  });

  if (referredBy) {
    await prisma.user.update({
      where: { id: referredBy.id },
      data: { referralBonus: { increment: 2 } },
    });
  }

  return NextResponse.json({ id: user.id, email: user.email });
}
