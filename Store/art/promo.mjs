// 1024x1024 promoted-purchase images for Quiver Plus (no text, no price): a target face on kraft with an
// arrow in the X and a sparkle; the yearly one in gold fletching, the monthly in chartreuse.
//   node Store/art/promo.mjs <out dir>
import { chromium } from "file:///C:/Users/Matthew/lastmile/node_modules/playwright/index.mjs";
import { mkdirSync } from "fs";
const out = process.argv[2];
mkdirSync(out, { recursive: true });
const b = await chromium.launch();
const p = await b.newPage({ viewport: { width: 1024, height: 1024 } });
for (const [name, fl, ink] of [["plus-yearly", "#ffd23f", "#1f3d2b"], ["plus-monthly", "#9edb24", "#1f3d2b"]]) {
  const rings = [["#ffffff", 1], ["#ffffff", .9], ["#1f1f1f", .8], ["#1f1f1f", .7], ["#2e8cd9", .6], ["#2e8cd9", .5], ["#dc3330", .4], ["#dc3330", .3], ["#fad633", .2], ["#fad633", .1]]
    .map(([c, f]) => `<circle cx="512" cy="540" r="${330 * f}" fill="${c}" stroke="rgba(0,0,0,.25)" stroke-width="2"/>`).join("");
  await p.setContent(`<body style="margin:0"><div style="width:1024px;height:1024px;background:radial-gradient(circle at 30% 20%,#e6d6b3,#d9c7a0 60%,#c9b487);position:relative;overflow:hidden">
    <svg width="1024" height="1024" viewBox="0 0 1024 1024" style="position:absolute;inset:0">
      <g opacity=".12">${Array.from({ length: 18 }, (_, i) => `<line x1="0" x2="1024" y1="${i * 60}" y2="${i * 60}" stroke="${ink}" stroke-width="2"/>`).join("")}</g>
      <line x1="90" x2="90" y1="0" y2="1024" stroke="rgba(184,56,41,.35)" stroke-width="3"/>
      <g filter="drop-shadow(0 18px 30px rgba(31,61,43,.35))">${rings}</g>
      <g transform="rotate(-35 512 540)">
        <rect x="512" y="532" width="440" height="16" rx="6" fill="${ink}"/>
        <path d="M900 540 L1000 480 L960 540 L1000 600 Z" fill="${fl}"/>
        <path d="M850 540 L950 480 L910 540 L950 600 Z" fill="${fl}"/>
      </g>
      <g transform="translate(790 190)" fill="${fl}" stroke="${ink}" stroke-width="8" stroke-linejoin="round">
        <path d="M0 -110 L26 -26 L110 0 L26 26 L0 110 L-26 26 L-110 0 L-26 -26 Z"/>
      </g>
      <g transform="translate(700 330) scale(.45)" fill="${fl}" stroke="${ink}" stroke-width="12" stroke-linejoin="round">
        <path d="M0 -110 L26 -26 L110 0 L26 26 L0 110 L-26 26 L-110 0 L-26 -26 Z"/>
      </g>
    </svg></div></body>`);
  await p.screenshot({ path: `${out}/${name}.png`, clip: { x: 0, y: 0, width: 1024, height: 1024 } });
  console.log("wrote", name);
}
await b.close();
