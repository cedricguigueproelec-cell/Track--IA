import { GoogleGenAI } from "@google/genai";

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
- Réponds UNIQUEMENT avec un objet JSON valide, sans texte autour, correspondant exactement à ce schéma :

{
  "verdict": "AUTHENTIQUE" | "SUSPECT" | "CONTREFACON" | "INDETERMINE",
  "score": <entier 0-100, probabilité d'authenticité>,
  "confidence": "FAIBLE" | "MOYENNE" | "ELEVEE",
  "redFlags": [<string, points de vigilance ou anomalies détectées, liste vide si aucun>],
  "checklist": [{"label": string, "ok": boolean, "note": string}, ...] (4 à 6 points vérifiés : logo, coutures, matière, étiquette, ferrures/quincaillerie, finitions - uniquement ceux visibles sur les photos fournies),
  "reasoning": <string, explication synthétique en français, 3-5 phrases>
}`;

const SNIPER_ADDENDUM = `
En plus du JSON ci-dessus, si et seulement si l'article semble authentique ou probablement authentique (score >= 40), ajoute aussi ces champs au même objet JSON :
{
  ...
  "resalePriceMin": <nombre, estimation basse du prix de revente sur Vinted en euros pour cet état/cette marque>,
  "resalePriceMax": <nombre, estimation haute>,
  "vintedTitle": <string, titre d'annonce Vinted optimisé, percutant, avec mots-clés recherchés, max 70 caractères>,
  "vintedDescription": <string, description complète prête à publier sur Vinted : état, matière, mesures utiles, points forts, mots-clés SEO Vinted, ton vendeur engageant, emojis sobres, 100-200 mots>
}
Si le score est inférieur à 40, mets ces 4 champs à null.`;

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

  const response = await genAI.models.generateContent({
    model,
    contents: [{ role: "user", parts: buildContentParts(itemName, brand, images) }],
    config: {
      systemInstruction: SYSTEM_PROMPT + (includeResaleAnalysis ? SNIPER_ADDENDUM : ""),
      maxOutputTokens: 1500,
    },
  });

  const text = response.text;
  if (!text) throw new Error("Réponse IA vide.");

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
