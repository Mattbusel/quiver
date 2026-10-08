// App Store screenshots: a headline inked over each raw simulator shot, on kraft paper.
//   node Store/art/frame.mjs <dir of CI shots>
// Writes fastlane/screenshots/en-US/NN_iPhone.png at 1320x2868 (the 6.9" size).
import { chromium } from "file:///C:/Users/Matthew/lastmile/node_modules/playwright/index.mjs";
import { readFileSync, readdirSync, rmSync, mkdirSync } from "fs";

const src = process.argv[2];
const out = "C:/Users/Matthew/quiver/fastlane/screenshots/en-US";
const plan = [
  ["scoring", "Tap where<br>it landed.", "Quiver scores every arrow, <b>Xs and all.</b>"],
  ["session", "Your group tells<br>you where to aim.", "Millimetres to move the sight, and <b>the mark fixed for you.</b>"],
  ["tape", "A sight tape that's<br>right at 80 yards.", "Fitted through <b>the marks you actually shot.</b>"],
  ["print", "Printed at<br>true size.", "Cut it, stick it on. <b>One tape is 99 cents.</b>"],
  ["range", "Every round,<br>in one score book.", "WA, NFAA, Vegas, 3D or <b>open practice.</b>"],
  ["builder", "Build the arrow.", "Weight, balance, <b>FOC and energy</b> on the page."],
  ["bow", "Know your speed<br>and your drop.", "Speed, drift, tuning notes <b>for every bow.</b>"],
  ["themes", "Pick your ink.", "Four notebook colours, <b>each with its own icon.</b>"],
  ["paywall", "Pro is one payment.<br>No subscription.", "The score book is <b>free forever.</b>"],
];
const files = readdirSync(src);
rmSync(out, { recursive: true, force: true });
mkdirSync(out, { recursive: true });
const b = await chromium.launch();
const p = await b.newPage({ viewport: { width: 1320, height: 2868 } });
let n = 1;
for (const [key, head, sub] of plan) {
  const f = files.find((x) => x.endsWith(`-${key}.png`));
  if (!f) { console.log("missing", key); continue; }
  const img = readFileSync(`${src}/${f}`).toString("base64");
  await p.setContent(`<!doctype html><html><head>
<link href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,700;9..144,900&family=Inter:wght@600;800&display=block" rel="stylesheet">
<style>
  body{margin:0;width:1320px;height:2868px;overflow:hidden;background:radial-gradient(1400px 1000px at 30% 10%,#e6d6b3,#d9c7a0 60%,#c9b487)}
  .rules{position:absolute;inset:0;background:repeating-linear-gradient(transparent 0 78px,rgba(31,61,43,.10) 78px 80px)}
  .margin{position:absolute;top:0;bottom:0;left:92px;width:3px;background:rgba(184,56,41,.35)}
  .col{position:absolute;left:140px;right:90px;top:170px;display:flex;flex-direction:column}
  h1{margin:0;color:#1f3d2b;font-family:Fraunces,serif;font-weight:900;font-size:112px;line-height:1.0;letter-spacing:-1px}
  p{margin:30px 0 0;color:rgba(31,61,43,.72);font-family:Inter,sans-serif;font-weight:600;font-size:48px;line-height:1.22}
  p b{color:#1f3d2b;font-weight:800;background:linear-gradient(transparent 58%,#c6f542 58%)}
  .phone{margin:72px 0 0 -30px;width:1080px;border-radius:120px;padding:22px;background:#1f3d2b;box-shadow:0 50px 120px rgba(31,61,43,.45);transform:rotate(-1.2deg)}
  .phone img{display:block;width:100%;border-radius:100px}
  .tape{position:absolute;width:220px;height:64px;background:rgba(255,255,255,.5);border:1px solid rgba(255,255,255,.7);transform:rotate(-6deg)}
</style></head><body><div class="rules"></div><div class="margin"></div>
<div class="col"><h1>${head}</h1><p>${sub}</p>
<div class="phone"><img src="data:image/png;base64,${img}"></div></div>
<div class="tape" style="left:560px;top:${head.includes("<br>") ? 655 : 545}px"></div>
</body></html>`);
  await p.evaluate(() => document.fonts.ready);
  await p.waitForTimeout(300);
  const name = `${String(n).padStart(2, "0")}_iPhone.png`;
  await p.screenshot({ path: `${out}/${name}`, clip: { x: 0, y: 0, width: 1320, height: 2868 } });
  console.log("wrote", name, key);
  n++;
}
await b.close();
