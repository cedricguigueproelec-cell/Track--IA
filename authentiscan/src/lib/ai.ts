import { GoogleGenAI, Type, FinishReason, type Schema } from "@google/genai";

let client: GoogleGenAI | null = null;

function getClient(): GoogleGenAI {
  if (!client) {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      throw new Error(
        "GEMINI_API_KEY manquante. L'IA ne peut pas fonctionner sans clé API valide (voir .env.example)."
      );
    }
    client = new GoogleGenAI({ apiKey });
  }
  return client;
}

export interface AnalysisImageInput {
  /** ex: "logo_etiquette" | "coutures_matiere" | "autre" */
  kind: string;
  /** data URL base64, ex: data:image/jpeg;base64,... */
  dataUrl: string;
}

export interface AnalysisResult {
  verdict: "AUTHENTIQUE" | "SUSPECT" | "CONTREFACON" | "INDETERMINE";
  score: number;
  confidence: "FAIBLE" | "MOYENNE" | "ELEVEE";
  redFlags: string[];
  checklist: { label: string; ok: boolean; note: string }[];
  reasoning: string;
  resalePriceMin?: number;
  resalePriceMax?: number;
  vintedTitle?: string;
  vintedDescription?: string;
}

const IMAGE_KIND_LABELS: Record<string, string> = {
  logo_etiquette: "Étiquette / logo de la marque",
  coutures_matiere: "Coutures / matière / finitions",
  autre: "Autre angle / vue d'ensemble",
};

function parseDataUrl(dataUrl: string): { mediaType: string; base64: string } {
  const match = /^data:(image\/[a-zA-Z+]+);base64,(.+)$/.exec(dataUrl);
  if (!match) throw new Error("Format d'image invalide (data URL attendue).");
  return { mediaType: match[1], base64: match[2] };
}

const SYSTEM_PROMPT = `Tu es un expert en authentification d'articles de mode (maroquinerie, prêt-à-porter, chaussures, accessoires) avec 20 ans d'expérience en contrôle qualité pour des maisons de luxe et des plateformes de revente.

On te fournit des photos d'un article (étiquette/logo, coutures/matière, autres angles) ainsi que son nom/marque déclarés. Ta mission : évaluer la probabilité que l'article soit authentique, en te basant UNIQUEMENT sur des éléments visuels observables (typographie du logo, qualité des coutures, régularité des points, alignement des motifs, qualité des matériaux, présence/format des étiquettes officielles, ferrures, finitions).

Règles strictes :
- Sois honnête sur l'incertitude : si les photos sont insuffisantes ou ambiguës, dis-le (verdict INDETERMINE, confidence FAIBLE) plutôt que d'inventer une certitude.
- Ne donne jamais une garantie à 100%. Ceci est une aide à la décision, pas une expertise légale.
- Base-toi sur des détails précis et vérifiables, jamais de généralités.
- Le format de la réponse est imposé par un schéma JSON strict, contente-toi de remplir les champs.`;

const SNIPER_ADDENDUM = `
Estime aussi un prix de revente Vinted et rédige une annonce, uniquement si l'article semble authentique ou probablement authentique (score >= 40). Si le score est inférieur à 40, laisse ces champs à null.`;

const BASE_SCHEMA_PROPERTIES: Record<string, Schema> = {
  verdict: {
    type: Type.STRING,
    enum: ["AUTHENTIQUE", "SUSPECT", "CONTREFACON", "INDETERMINE"],
    description: "Verdict global sur l'authenticité de l'article.",
  },
  score: {
    type: Type.INTEGER,
    description: "Probabilité d'authenticité, entier de 0 à 100.",
  },
  confidence: {
    type: Type.STRING,
    enum: ["FAIBLE", "MOYENNE", "ELEVEE"],
    description: "Confiance dans le verdict, selon la qualité/suffisance des photos.",
  },
  redFlags: {
    type: Type.ARRAY,
    items: { type: Type.STRING },
    description: "Points de vigilance ou anomalies détectées. Liste vide si aucun.",
  },
  checklist: {
    type: Type.ARRAY,
    description:
      "4 à 6 points vérifiés (logo, coutures, matière, étiquette, ferrures/quincaillerie, finitions) — uniquement ceux visibles sur les photos fournies.",
    items: {
      type: Type.OBJECT,
      properties: {
        label: { type: Type.STRING },
        ok: { type: Type.BOOLEAN },
        note: { type: Type.STRING },
      },
      required: ["label", "ok", "note"],
    },
  },
  reasoning: {
    type: Type.STRING,
    description: "Explication synthétique en français, 3 à 5 phrases.",
  },
};

const RESALE_SCHEMA_PROPERTIES: Record<string, Schema> = {
  resalePriceMin: {
    type: Type.NUMBER,
    nullable: true,
    description: "Estimation basse du prix de revente Vinted en euros, ou null si score < 40.",
  },
  resalePriceMax: {
    type: Type.NUMBER,
    nullable: true,
    description: "Estimation haute du prix de revente Vinted en euros, ou null si score < 40.",
  },
  vintedTitle: {
    type: Type.STRING,
    nullable: true,
    description: "Titre d'annonce Vinted optimisé, percutant, max 70 caractères, ou null si score < 40.",
  },
  vintedDescription: {
    type: Type.STRING,
    nullable: true,
    description:
      "Description Vinted prête à publier (état, matière, mesures, points forts, mots-clés SEO, ton vendeur engageant, emojis sobres, 100-200 mots), ou null si score < 40.",
  },
};

function buildResponseSchema(includeResaleAnalysis: boolean): Schema {
  const properties = includeResaleAnalysis
    ? { ...BASE_SCHEMA_PROPERTIES, ...RESALE_SCHEMA_PROPERTIES }
    : BASE_SCHEMA_PROPERTIES;

  return {
    type: Type.OBJECT,
    properties,
    required: ["verdict", "score", "confidence", "redFlags", "checklist", "reasoning"],
  };
}

function buildContentParts(
  itemName: string | undefined,
  brand: string | undefined,
  images: AnalysisImageInput[]
) {
  const parts: ({ text: string } | { inlineData: { mimeType: string; data: string } })[] = [];

  const intro = [
    itemName ? `Article déclaré : ${itemName}` : null,
    brand ? `Marque déclarée : ${brand}` : null,
    `Nombre de photos fournies : ${images.length}`,
  ]
    .filter(Boolean)
    .join("\n");

  parts.push({ text: intro });

  for (const img of images) {
    const { mediaType, base64 } = parseDataUrl(img.dataUrl);
    parts.push({ text: `Photo suivante : ${IMAGE_KIND_LABELS[img.kind] ?? img.kind}` });
    parts.push({ inlineData: { mimeType: mediaType, data: base64 } });
  }

  return parts;
}

function extractJson(text: string): unknown {
  const start = text.indexOf("{");
  const end = text.lastIndexOf("}");
  if (start === -1 || end === -1) throw new Error("Réponse IA sans JSON exploitable.");
  return JSON.parse(text.slice(start, end + 1));
}

const FINISH_REASON_MESSAGES: Partial<Record<FinishReason, string>> = {
  [FinishReason.SAFETY]: "L'analyse a été bloquée par les filtres de sécurité de l'IA. Réessayez avec d'autres photos.",
  [FinishReason.MAX_TOKENS]: "La réponse de l'IA a été coupée (trop longue). Réessayez.",
  [FinishReason.RECITATION]: "L'analyse a été bloquée (contenu potentiellement protégé détecté). Réessayez avec d'autres photos.",
  [FinishReason.PROHIBITED_CONTENT]: "L'analyse a été bloquée par les filtres de sécurité de l'IA. Réessayez avec d'autres photos.",
};

export async function analyzeAuthenticity(params: {
  itemName?: string;
  brand?: string;
  images: AnalysisImageInput[];
  includeResaleAnalysis: boolean;
}): Promise<AnalysisResult> {
  const { itemName, brand, images, includeResaleAnalysis } = params;
  if (images.length === 0) throw new Error("Au moins une photo est requise.");

  const genAI = getClient();
  const model = process.env.GEMINI_MODEL || "gemini-flash-latest";

  let response;
  try {
    response = await genAI.models.generateContent({
      model,
      contents: [{ role: "user", parts: buildContentParts(itemName, brand, images) }],
      config: {
        systemInstruction: SYSTEM_PROMPT + (includeResaleAnalysis ? SNIPER_ADDENDUM : ""),
        maxOutputTokens: 4096,
        responseMimeType: "application/json",
        responseSchema: buildResponseSchema(includeResaleAnalysis),
      },
    });
  } catch (err) {
    const status = (err as { status?: number })?.status;
    if (status === 429) {
      throw new Error("Trop de demandes en même temps sur le tier gratuit de l'IA. Réessayez dans une minute.");
    }
    if (status === 503) {
      throw new Error("Le service IA est momentanément surchargé. Réessayez dans quelques instants.");
    }
    throw err;
  }

  const finishReason = response.candidates?.[0]?.finishReason;
  const text = response.text;

  if (!text) {
    const knownMessage = finishReason && FINISH_REASON_MESSAGES[finishReason];
    throw new Error(knownMessage ?? `Réponse IA vide (finishReason: ${finishReason ?? "inconnu"}).`);
  }

  const parsed = extractJson(text) as AnalysisResult;

  if (!parsed.verdict || typeof parsed.score !== "number") {
    throw new Error("Réponse IA malformée.");
  }

  return {
    verdict: parsed.verdict,
    score: Math.max(0, Math.min(100, Math.round(parsed.score))),
    confidence: parsed.confidence ?? "MOYENNE",
    redFlags: Array.isArray(parsed.redFlags) ? parsed.redFlags : [],
    checklist: Array.isArray(parsed.checklist) ? parsed.checklist : [],
    reasoning: parsed.reasoning ?? "",
    resalePriceMin: includeResaleAnalysis ? parsed.resalePriceMin ?? undefined : undefined,
    resalePriceMax: includeResaleAnalysis ? parsed.resalePriceMax ?? undefined : undefined,
    vintedTitle: includeResaleAnalysis ? parsed.vintedTitle ?? undefined : undefined,
    vintedDescription: includeResaleAnalysis ? parsed.vintedDescription ?? undefined : undefined,
  };
}
