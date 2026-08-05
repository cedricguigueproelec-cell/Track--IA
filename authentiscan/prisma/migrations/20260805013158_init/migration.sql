-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "email" TEXT NOT NULL,
    "passwordHash" TEXT NOT NULL,
    "name" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "plan" TEXT NOT NULL DEFAULT 'FREE',
    "stripeCustomerId" TEXT,
    "stripeSubscriptionId" TEXT,
    "stripeCurrentPeriodEnd" DATETIME,
    "monthlyUsageCount" INTEGER NOT NULL DEFAULT 0,
    "monthlyResetAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "dailyUsageCount" INTEGER NOT NULL DEFAULT 0,
    "dailyResetAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "freeTrialUsed" INTEGER NOT NULL DEFAULT 0,
    "freeTrialLimit" INTEGER NOT NULL DEFAULT 3,
    "referralCode" TEXT NOT NULL,
    "referredById" TEXT,
    "referralBonus" INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT "User_referredById_fkey" FOREIGN KEY ("referredById") REFERENCES "User" ("id") ON DELETE SET NULL ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "AuthenticationRequest" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "userId" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "itemName" TEXT,
    "brand" TEXT,
    "imageCount" INTEGER NOT NULL DEFAULT 0,
    "status" TEXT NOT NULL DEFAULT 'PENDING',
    "verdict" TEXT,
    "score" INTEGER,
    "confidence" TEXT,
    "redFlags" TEXT,
    "checklist" TEXT,
    "reasoning" TEXT,
    "resalePriceMin" REAL,
    "resalePriceMax" REAL,
    "vintedTitle" TEXT,
    "vintedDescription" TEXT,
    "errorMessage" TEXT,
    CONSTRAINT "AuthenticationRequest_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE UNIQUE INDEX "User_stripeCustomerId_key" ON "User"("stripeCustomerId");

-- CreateIndex
CREATE UNIQUE INDEX "User_stripeSubscriptionId_key" ON "User"("stripeSubscriptionId");

-- CreateIndex
CREATE UNIQUE INDEX "User_referralCode_key" ON "User"("referralCode");
