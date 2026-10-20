// In-App Event art: a 1920x1080 card per event (three raw app screens on kraft, no text: the App Store draws
// the event name over it) and a 1080x1920 details image per locale (that locale's framed screenshot).
//   node Store/art/event_art.mjs <dir of raw CI shots> <out dir>
import { chromium } from "file:///C:/Users/Matthew/lastmile/node_modules/playwright/index.mjs";
import { readFileSync, readdirSync, mkdirSync, existsSync } from "fs";

const [raw, out] = process.argv.slice(2);
const EVENTS = {
  challenge: { shots: ["scoring", "range", "session"], detail: "07_iPhone.png" },
  lock: { shots: ["tape", "widgets", "scoring"], detail: "03_iPhone.png" },
};
mkdirSync(out, { recursive: true });
const files = readdirSync(raw).filter((f) => f.endsWith(".png"));
const b64 = (p) => readFileSync(p).toString("base64");
const b = await chromium.launch();
const card = await b.newPage({ viewport: { width: 1920, height: 1080 } });
const det = await b.newPage({ viewport: { width: 1080, height: 1920 } });
const bg = "radial-gradient(1200px 800px at 50% 30%,#e6d6b3,#d9c7a0 60%,#c9b487)";
for (const [key, e] of Object.entries(EVENTS)) {
  const phones = e.shots.map((k, i) => {
    const f = files.find((x) => x.endsWith(`-${k}.png`));
    return `<div class="ph p${i}"><img src="data:image/png;base64,${b64(`${raw}/${f}`)}"></div>`;
  }).join("");
  await card.setContent(`<!doctype html><html><head><style>
    body{margin:0;width:1920px;height:1080px;overflow:hidden;background:${bg}}
    .rules{position:absolute;inset:0;background:repeating-linear-gradient(transparent 0 58px,rgba(31,61,43,.10) 58px 60px)}
    .ph{position:absolute;top:120px;width:430px;border-radius:64px;padding:14px;background:#1f3d2b;box-shadow:0 40px 110px rgba(31,61,43,.5)}
    .ph img{display:block;width:100%;border-radius:52px}
    .p0{left:310px;transform:rotate(-7deg) translateY(60px)} .p1{left:745px;z-index:2;top:80px} .p2{left:1180px;transform:rotate(7deg) translateY(60px)}
  </style></head><body><div class="rules"></div>${phones}</body></html>`);
  await card.waitForTimeout(300);
  await card.screenshot({ path: `${out}/${key}-card.png`, clip: { x: 0, y: 0, width: 1920, height: 1080 } });
  for (const loc of ["en-US", "ja", "ko", "zh-Hans"]) {
    const f = `C:/Users/Matthew/quiver/fastlane/screenshots/${loc}/${e.detail}`;
    if (!existsSync(f)) continue;
    await det.setContent(`<!doctype html><html><body style="margin:0;width:1080px;height:1920px;overflow:hidden;background:${bg};display:flex;align-items:center;justify-content:center">
      <img style="height:1920px" src="data:image/png;base64,${b64(f)}"></body></html>`);
    await det.waitForTimeout(200);
    await det.screenshot({ path: `${out}/${key}-details-${loc}.png`, clip: { x: 0, y: 0, width: 1080, height: 1920 } });
  }
  console.log("event art", key);
}
await b.close();
