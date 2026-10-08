// The four ink-theme icons: the Quiver arrow on kraft in each theme's ink and fletching.
// Writes Resources/Assets.xcassets/AppIcon-<Name>.appiconset.
import { chromium } from "file:///C:/Users/Matthew/lastmile/node_modules/playwright/index.mjs";
import { mkdirSync, writeFileSync } from "fs";
const themes = { Blaze: ["#26262a", "#ff7a1a"], Navy: ["#1b2a4a", "#ffd23f"], Oxblood: ["#4a1a1c", "#7cc6f2"], Timber: ["#3b2a1a", "#ff5fa2"] };
const root = "C:/Users/Matthew/quiver/Resources/Assets.xcassets";
const b = await chromium.launch();
const p = await b.newPage({ viewport: { width: 1024, height: 1024 } });
for (const [name, [ink, fl]] of Object.entries(themes)) {
  await p.setContent(`<body style="margin:0"><div style="width:1024px;height:1024px;background:radial-gradient(circle at 30% 20%,#e6d6b3,#d9c7a0 60%,#c9b487);position:relative;overflow:hidden">
    <svg width="1024" height="1024" viewBox="0 0 1024 1024" style="position:absolute;inset:0">
      <g transform="rotate(-38 512 512)">
        <rect x="150" y="497" width="700" height="30" rx="8" fill="${ink}"/>
        <path d="M850 470 L960 512 L850 554 Z" fill="${ink}"/>
        <path d="M150 512 L60 440 L120 512 L60 584 Z" fill="${fl}"/>
        <path d="M230 512 L140 440 L200 512 L140 584 Z" fill="${fl}"/>
        <path d="M310 512 L220 440 L280 512 L220 584 Z" fill="${ink}"/>
      </g>
      <circle cx="512" cy="512" r="430" fill="none" stroke="${ink}" stroke-width="6" stroke-dasharray="14 18" opacity=".55"/>
    </svg></div></body>`);
  const dir = `${root}/AppIcon-${name}.appiconset`;
  mkdirSync(dir, { recursive: true });
  await p.screenshot({ path: `${dir}/icon-1024.png`, clip: { x: 0, y: 0, width: 1024, height: 1024 } });
  writeFileSync(`${dir}/Contents.json`, JSON.stringify({ images: [{ filename: "icon-1024.png", idiom: "universal", platform: "ios", size: "1024x1024" }], info: { author: "xcode", version: 1 } }, null, 2));
  console.log("wrote", name);
}
await b.close();
