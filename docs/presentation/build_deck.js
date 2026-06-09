// Builds the Qalam course-demo presentation (Hebrew, RTL) as a .pptx.
// Run: node build_deck.js   ->  Qalam_Demo_HE.pptx
//
// Required structure (course brief):
//   1. App name + team members
//   2. Short explanation about the app
//   3. Main sprint stories
//   4..n. Screenshots of REAL implemented screens (placeholders here)
//   last. Problems / challenges
//
// Brand tokens come from docs/design/kit (lib/theme/colors.dart):
//   parchment #FAF6EE · ink-teal #168A8F · deep-ink #0E5B5F
//   gold #F2A60C · coral #FF8A6B · ink-charcoal #222A2E · slate #5C6B70

const Pptx = require("pptxgenjs");
const pptx = new Pptx();

pptx.defineLayout({ name: "W", width: 13.333, height: 7.5 });
pptx.layout = "W";
pptx.rtlMode = true;
pptx.author = "Qalam Team";
pptx.title = "Qalam — Demo";

// --- palette ---
const C = {
  parchment: "FAF6EE",
  parchmentDeep: "F3ECDC",
  parchmentEdge: "E8DFC9",
  inkTeal: "168A8F",
  deepInk: "0E5B5F",
  gold: "F2A60C",
  coral: "FF8A6B",
  fg: "222A2E",
  slate: "5C6B70",
  white: "FFFFFF",
  aquaEdge: "D6E8E8",
};
const FONT = "Arial"; // universally available with full Hebrew glyph coverage

const W = 13.333,
  H = 7.5;

// ---- helpers -------------------------------------------------------------
function bg(slide, color = C.parchment) {
  slide.background = { color };
}
// thin teal accent bar down the right edge (RTL "spine")
function spine(slide) {
  slide.addShape(pptx.ShapeType.rect, {
    x: W - 0.22,
    y: 0,
    w: 0.22,
    h: H,
    fill: { color: C.inkTeal },
    line: { type: "none" },
  });
}
function footer(slide, n) {
  slide.addText("Qalam · قلم", {
    x: 0.4,
    y: H - 0.5,
    w: 4,
    h: 0.35,
    fontFace: FONT,
    fontSize: 10,
    color: C.slate,
    align: "left",
    rtlMode: false,
  });
  slide.addText(String(n), {
    x: W - 1.3,
    y: H - 0.5,
    w: 0.9,
    h: 0.35,
    fontFace: FONT,
    fontSize: 10,
    color: C.slate,
    align: "right",
  });
}
function title(slide, text) {
  slide.addText(text, {
    x: 0.6,
    y: 0.45,
    w: W - 1.4,
    h: 0.95,
    fontFace: FONT,
    fontSize: 30,
    bold: true,
    color: C.deepInk,
    align: "right",
    rtlMode: true,
  });
  // underline accent
  slide.addShape(pptx.ShapeType.rect, {
    x: W - 4.0,
    y: 1.42,
    w: 3.4,
    h: 0.06,
    fill: { color: C.gold },
    line: { type: "none" },
  });
}

// =========================================================================
// SLIDE 1 — Title: app name + team
// =========================================================================
(() => {
  const s = pptx.addSlide();
  bg(s, C.deepInk);
  // big parchment panel
  s.addShape(pptx.ShapeType.roundRect, {
    x: 0.7,
    y: 0.7,
    w: W - 1.4,
    h: H - 1.4,
    rectRadius: 0.25,
    fill: { color: C.parchment },
    line: { type: "none" },
  });
  // Arabic + Latin name
  s.addText("قلم", {
    x: 0.7,
    y: 1.0,
    w: W - 1.4,
    h: 1.6,
    fontFace: FONT,
    fontSize: 96,
    bold: true,
    color: C.inkTeal,
    align: "center",
    rtlMode: true,
  });
  s.addText("Qalam", {
    x: 0.7,
    y: 2.7,
    w: W - 1.4,
    h: 0.7,
    fontFace: FONT,
    fontSize: 30,
    color: C.deepInk,
    align: "center",
    charSpacing: 6,
    rtlMode: false,
  });
  s.addText("ערבית אמיתית. לא משחק.", {
    x: 0.7,
    y: 3.45,
    w: W - 1.4,
    h: 0.6,
    fontFace: FONT,
    fontSize: 22,
    italic: true,
    color: C.coral,
    align: "center",
    rtlMode: true,
  });
  s.addText("אפליקציה ללימוד כתיבת ערבית בכתב יד לילדים — אנדרואיד, טאבלט", {
    x: 0.7,
    y: 4.05,
    w: W - 1.4,
    h: 0.5,
    fontFace: FONT,
    fontSize: 16,
    color: C.slate,
    align: "center",
    rtlMode: true,
  });
  // team block
  s.addText(
    [
      { text: "חברי הצוות:  ", options: { bold: true, color: C.deepInk } },
      {
        text: "‹הוסיפו כאן את שמות חברי הצוות›",
        options: { color: C.coral, bold: true },
      },
    ],
    {
      x: 1.5,
      y: 4.95,
      w: W - 3.0,
      h: 0.5,
      fontFace: FONT,
      fontSize: 18,
      align: "center",
      rtlMode: true,
    }
  );
  s.addText("236272 · פיתוח לאנדרואיד · אביב 2025/26   |   הדגמת התקדמות · 01/06/2026", {
    x: 0.7,
    y: 5.55,
    w: W - 1.4,
    h: 0.45,
    fontFace: FONT,
    fontSize: 14,
    color: C.slate,
    align: "center",
    rtlMode: true,
  });
})();

// =========================================================================
// SLIDE 2 — About the app
// =========================================================================
(() => {
  const s = pptx.addSlide();
  bg(s);
  spine(s);
  title(s, "מה זאת Qalam?");
  s.addText(
    "כמעט כל אפליקציה ללימוד ערבית מלמדת אותה כשפה זרה — בחירה מרובה, מקלדת, הקשה על תשובה. " +
      "אף אחת לא מלמדת ילד לכתוב את האותיות ביד — וזה בדיוק מה שמקבע את השפה.",
    {
      x: 0.6,
      y: 1.7,
      w: W - 1.4,
      h: 0.95,
      fontFace: FONT,
      fontSize: 17,
      color: C.fg,
      align: "right",
      rtlMode: true,
      lineSpacingMultiple: 1.15,
    }
  );
  const bullets = [
    "קהל יעד: ילדים ששומעים ערבית בבית אך עדיין אינם קוראים/כותבים (heritage learners).",
    "הלולאה: אות מקווקוות מופיעה ← הילד מעתיק בעט סטיילוס ← האפליקציה מנקדת את המשיכות על המכשיר ← משוב מיידי וספציפי. ושוב.",
    "מימין-לשמאל, ללא צבירת נקודות, ללא דמויות משחק. כוכב = סימן שליטה אמיתי, לא ניקוד.",
    "ניקוד כתב היד: Google ML Kit Digital Ink — על המכשיר, ללא הלוך-ושוב לרשת.",
    "המתחרה האמיתי הוא מורה פרטי ב-60$ לשעה — Qalam הוא המורה הסבלני שזמין ב-21:00 ביום שלישי.",
  ];
  s.addText(
    bullets.map((t) => ({
      text: t,
      options: { bullet: { code: "2022", indent: 18 }, rtlMode: true },
    })),
    {
      x: 0.6,
      y: 2.75,
      w: W - 1.4,
      h: 3.9,
      fontFace: FONT,
      fontSize: 16,
      color: C.fg,
      align: "right",
      rtlMode: true,
      paraSpaceAfter: 10,
      lineSpacingMultiple: 1.1,
    }
  );
  footer(s, 2);
})();

// =========================================================================
// SLIDE 3 — Sprint stories
// =========================================================================
(() => {
  const s = pptx.addSlide();
  bg(s);
  spine(s);
  title(s, "ספרינט 1 — לולאת הלמידה המרכזית");
  const stories = [
    ["S1-01", "ילד", "לפתוח את האפליקציה ולראות מיד את שיעור היום מוכן — בלי לנווט."],
    ["S1-04", "ילד", "לצפות באנימציה של סדר המשיכות הנכון לפני כתיבת האות."],
    ["S1-05", "ילד", "להעתיק אותיות עם הסטיילוס ולקבל משוב מיידי על הצורה וסדר המשיכות."],
    ["S1-09", "ילד", "השיעור הבא נפתח רק אחרי שעברתי את הנוכחי — תמיד בונים על יסוד מוצק."],
    ["S1-10", "ילד", "לקבל כוכב בסיום שיעור — אישור שקט על שליטה, לא צבירת ניקוד."],
    ["S1-02", "הורה", "ליצור פרופיל לילד עם שם וכיתה, כדי שהאפליקציה תכין את תוכנית הלימוד הנכונה."],
  ];
  let y = 1.75;
  const rowH = 0.82;
  stories.forEach(([id, who, txt], i) => {
    s.addShape(pptx.ShapeType.roundRect, {
      x: 0.6,
      y,
      w: W - 1.4,
      h: rowH - 0.12,
      rectRadius: 0.08,
      fill: { color: i % 2 ? C.parchmentDeep : C.white },
      line: { color: C.aquaEdge, width: 0.75 },
    });
    // id chip (left edge in RTL layout sits visually right)
    s.addText(id, {
      x: W - 2.05,
      y: y + 0.06,
      w: 1.35,
      h: rowH - 0.24,
      fontFace: FONT,
      fontSize: 13,
      bold: true,
      color: C.white,
      fill: { color: C.inkTeal },
      align: "center",
      valign: "middle",
      rtlMode: false,
    });
    s.addText(
      [
        { text: `(${who}) `, options: { color: C.gold, bold: true } },
        { text: txt, options: { color: C.fg } },
      ],
      {
        x: 0.75,
        y: y + 0.04,
        w: W - 3.0,
        h: rowH - 0.2,
        fontFace: FONT,
        fontSize: 14,
        align: "right",
        valign: "middle",
        rtlMode: true,
      }
    );
    y += rowH;
  });
  s.addText("מתוך docs/USER_STORIES.md — ספרינט 1 = מיילסטון v1 (מקומי, על-המכשיר, ללא חשבון).", {
    x: 0.6,
    y: y + 0.05,
    w: W - 1.4,
    h: 0.35,
    fontFace: FONT,
    fontSize: 11,
    italic: true,
    color: C.slate,
    align: "right",
    rtlMode: true,
  });
  footer(s, 3);
})();

// =========================================================================
// SLIDES 4-6 — Screenshot placeholders (REAL screens to be dropped in)
// =========================================================================
const shots = [
  {
    n: 4,
    heading: "מסך הבית (Home)",
    cap: "לוגו قلم בראש, שיעור היום, וכפתור התחלה אחד. מימין-לשמאל; ה-chrome נשאר LTR, התוכן הערבי הוא 'אי' RTL.",
    status: "ממומש · פאזה 1",
  },
  {
    n: 5,
    heading: "מסך התרגול (Practice / Trace)",
    cap: "קנבס כתיבה — 'כתוב כאן'. הילד מעתיק את האות בעט; לכידת המשיכות פעילה (ספייק ML Kit). כפתור ניקוי עם אישור.",
    status: "ממומש · פאזה 1 (ספייק)",
  },
  {
    n: 6,
    heading: "מסך ההגדרות (Settings)",
    cap: "שלד ההגדרות: קול · יד ימין/שמאל · אזור הורים. מאשר שהניווט והשמירה המקומית עובדים.",
    status: "ממומש · פאזה 1",
  },
];
shots.forEach(({ n, heading, cap, status }) => {
  const s = pptx.addSlide();
  bg(s);
  spine(s);
  title(s, `מסכים שמומשו — ${heading}`);

  // tablet-landscape placeholder frame (16:10-ish)
  const fw = 7.4,
    fh = 4.4,
    fx = (W - fw) / 2 - 0.1,
    fy = 1.75;
  s.addShape(pptx.ShapeType.roundRect, {
    x: fx,
    y: fy,
    w: fw,
    h: fh,
    rectRadius: 0.12,
    fill: { color: C.parchmentDeep },
    line: { color: C.inkTeal, width: 2, dashType: "dash" },
  });
  s.addText("🖼  ‹צילום מסך אמיתי כאן›", {
    x: fx,
    y: fy + fh / 2 - 0.55,
    w: fw,
    h: 0.7,
    fontFace: FONT,
    fontSize: 22,
    bold: true,
    color: C.inkTeal,
    align: "center",
    rtlMode: true,
  });
  s.addText("(החליפו את התיבה הזו בצילום מסך מהמכשיר/אמולטור)", {
    x: fx,
    y: fy + fh / 2 + 0.15,
    w: fw,
    h: 0.5,
    fontFace: FONT,
    fontSize: 13,
    color: C.slate,
    align: "center",
    rtlMode: true,
  });
  // status chip
  s.addText(status, {
    x: fx + fw - 2.7,
    y: fy + 0.15,
    w: 2.5,
    h: 0.4,
    fontFace: FONT,
    fontSize: 12,
    bold: true,
    color: C.white,
    fill: { color: C.gold },
    align: "center",
    valign: "middle",
    rtlMode: true,
  });
  // caption
  s.addText(cap, {
    x: 0.9,
    y: fy + fh + 0.2,
    w: W - 1.8,
    h: 0.8,
    fontFace: FONT,
    fontSize: 14,
    color: C.fg,
    align: "center",
    rtlMode: true,
    lineSpacingMultiple: 1.1,
  });
  footer(s, n);
});

// =========================================================================
// SLIDE 7 — Challenge 1: recognizing ink / writing
// =========================================================================
(() => {
  const s = pptx.addSlide();
  bg(s);
  spine(s);
  title(s, "אתגר 1 — איך בכלל מזהים כתיבה ודיו?");
  s.addText(
    "השאלה הראשונה והקריטית בפרויקט (R1) — היא חסמה את כל השאר: איך לוכדים ומזהים את מה שהילד כותב על המסך?",
    {
      x: 0.6,
      y: 1.7,
      w: W - 1.4,
      h: 0.8,
      fontFace: FONT,
      fontSize: 16,
      color: C.fg,
      align: "right",
      rtlMode: true,
      lineSpacingMultiple: 1.1,
    }
  );
  s.addText("בדקנו כמה גישות בפועל:", {
    x: 0.6,
    y: 2.55,
    w: W - 1.4,
    h: 0.4,
    fontFace: FONT,
    fontSize: 15,
    bold: true,
    color: C.deepInk,
    align: "right",
    rtlMode: true,
  });
  const tested = [
    "Google ML Kit Digital Ink — זיהוי דיו על המכשיר",
    "OCR / טרנספורמר (TrOCR) — על המכשיר מול שרת, ולטנסי",
    "מסווג TFLite מותאם אישית, מאומן על אותיות תוכנית הלימוד",
    "בדיקה גאומטרית טהורה — השוואת המשיכות לקו-ייחוס",
  ];
  s.addText(
    tested.map((t) => ({
      text: t,
      options: { bullet: { code: "2022", indent: 18 }, rtlMode: true },
    })),
    {
      x: 0.6,
      y: 2.95,
      w: W - 1.4,
      h: 1.9,
      fontFace: FONT,
      fontSize: 15,
      color: C.fg,
      align: "right",
      rtlMode: true,
      paraSpaceAfter: 8,
    }
  );
  // landing decision banner
  s.addShape(pptx.ShapeType.roundRect, {
    x: 0.6,
    y: 4.95,
    w: W - 1.4,
    h: 1.6,
    rectRadius: 0.1,
    fill: { color: C.parchmentDeep },
    line: { color: C.inkTeal, width: 1.25 },
  });
  s.addText(
    [
      {
        text: "נחתנו על Google ML Kit Digital Ink",
        options: { bold: true, color: C.deepInk, fontSize: 17 },
      },
      {
        text: " — על המכשיר, ללא הלוך-ושוב לרשת, עם תמיכה אמיתית בערבית.\n",
        options: { color: C.fg, fontSize: 15 },
      },
      {
        text: "אבל התובנה המרכזית: ML Kit אומר ",
        options: { color: C.fg, fontSize: 15 },
      },
      { text: "איזו", options: { bold: true, italic: true, color: C.coral, fontSize: 15 } },
      {
        text: " אות נכתבה — לא ",
        options: { color: C.fg, fontSize: 15 },
      },
      { text: "איך", options: { bold: true, italic: true, color: C.coral, fontSize: 15 } },
      {
        text: " נכתבה (סדר משיכות, כיוון, צורה). וה‏'איך' הוא כל העניין בלימוד כתיבה ביד.  →  אתגר 2",
        options: { color: C.fg, fontSize: 15 },
      },
    ],
    {
      x: 0.85,
      y: 5.1,
      w: W - 1.9,
      h: 1.3,
      fontFace: FONT,
      align: "right",
      rtlMode: true,
      valign: "middle",
      lineSpacingMultiple: 1.12,
    }
  );
  footer(s, 7);
})();

// =========================================================================
// SLIDE 8 — Challenge 2: scoring letter shape + stroke order
// =========================================================================
(() => {
  const s = pptx.addSlide();
  bg(s);
  spine(s);
  title(s, "אתגר 2 — לזהות את צורת האות וסדר המשיכות");
  s.addText(
    "כי ML Kit לא מנקד את ה‏'איך', אנחנו בונים מנקד גאומטרי משלנו: הוא משווה את משיכות הילד לקו-ייחוס (centerline) של כל אות — הקו שהעט אמור לעבור עליו.",
    {
      x: 0.6,
      y: 1.7,
      w: W - 1.4,
      h: 1.0,
      fontFace: FONT,
      fontSize: 16,
      color: C.fg,
      align: "right",
      rtlMode: true,
      lineSpacingMultiple: 1.15,
    }
  );
  const pts = [
    [
      "הבאג שתפסנו:",
      "קו-הייחוס הראשון שלנו היה המתאר (outline) של האות מהפונט — הצללית החיצונית — ולא קו-המרכז שהעט עובר עליו. זה שיבש גם את הניקוד וגם את אנימציית 'תראה אותי כותב'.",
    ],
    [
      "התיקון:",
      "פאזה דחופה (02.1) — כתבנו מחדש את האותיות כקווי-מרכז פתוחים (באישור המומחית), בנינו מסך authoring בתוך האפליקציה, והוספנו validator אוטומטי שמונע מהבאג לחזור.",
    ],
    [
      "השורה התחתונה:",
      "המנקד הגאומטרי הוא ה-risk הגבוה ביותר בפרויקט — ML Kit לא נותן אותו — ולכן בנינו אותו בעצמנו ובידדנו אותו.",
    ],
  ];
  let y = 2.85;
  pts.forEach(([h, b]) => {
    s.addShape(pptx.ShapeType.rect, {
      x: W - 0.85,
      y: y + 0.05,
      w: 0.12,
      h: 1.0,
      fill: { color: C.coral },
      line: { type: "none" },
    });
    s.addText(
      [
        { text: h + "  ", options: { bold: true, fontSize: 16, color: C.deepInk } },
        { text: b, options: { fontSize: 14, color: C.fg } },
      ],
      {
        x: 0.6,
        y,
        w: W - 1.75,
        h: 1.15,
        fontFace: FONT,
        align: "right",
        rtlMode: true,
        lineSpacingMultiple: 1.1,
        valign: "top",
      }
    );
    y += 1.2;
  });
  footer(s, 8);
})();

// ---- write --------------------------------------------------------------
pptx
  .writeFile({ fileName: "Qalam_Demo_HE.pptx" })
  .then((f) => console.log("WROTE:", f))
  .catch((e) => {
    console.error(e);
    process.exit(1);
  });
