// App Store screenshots: a headline inked over each raw simulator shot, on kraft paper.
//   node Store/art/frame.mjs <dir of CI shots> [locale: en-US | ja | ko | zh-Hans]
// Writes fastlane/screenshots/en-US/NN_iPhone.png at 1320x2868 (the 6.9" size).
import { chromium } from "file:///C:/Users/Matthew/lastmile/node_modules/playwright/index.mjs";
import { readFileSync, readdirSync, rmSync, mkdirSync } from "fs";

const src = process.argv[2];
const loc = process.argv[3] || "en-US";
const out = `C:/Users/Matthew/quiver/fastlane/screenshots/${loc}`;
// No price, free, discount or subscription words anywhere in these captions (App Review 2.3.7).
const plan = [
  ["scoring", "Tap where<br>it landed.", "Quiver scores every arrow, <b>Xs and all.</b>"],
  ["session", "Your group tells<br>you where to aim.", "Millimetres to move the sight, and <b>the mark fixed for you.</b>"],
  ["widgets", "Your marks on<br>the Lock Screen.", "Widgets, a Live Activity <b>and Siri</b> know your tape."],
  ["tape", "A tape that's<br>right at 80.", "Fitted through <b>the marks you actually shot.</b>"],
  ["print", "Print it<br>true size.", "Cut it out, stick it on. <b>Done.</b>"],
  ["insights", "See where the<br>points go.", "Late ends, consistency, <b>group size over time.</b>"],
  ["range", "A new challenge<br>every month.", "WA, NFAA, Vegas, 3D <b>and practice, in one book.</b>"],
  ["builder", "Build the arrow.", "Weight, balance, <b>FOC and energy</b> on one page."],
  ["bow", "Know your speed<br>and drop.", "Speed, drift and tuning notes <b>for every bow.</b>"],
  ["themes", "Pick your ink.", "Six notebook colours, <b>each with its own icon.</b>"],
];
// Captions for the Japanese, Korean and Simplified Chinese store pages; the app screens themselves stay English.
const L10N = {
  "ja": [
    ["scoring", "当たった場所を<br>タップ。", "Quiverが全部の矢を採点。<b>Xも含めて。</b>"],
    ["session", "グルーピングが<br>狙いを教える。", "サイトを動かす距離をmmで。<b>マークも自動で補正。</b>"],
    ["widgets", "マークを<br>ロック画面に。", "ウィジェット、ライブアクティビティ、<b>Siriにも。</b>"],
    ["tape", "80ヤードでも<br>正確なテープ。", "<b>実際に射ったマーク</b>を通るようにフィット。"],
    ["print", "原寸大で<br>印刷。", "切って貼るだけ。<b>すぐ使える。</b>"],
    ["insights", "点数の行方が<br>見える。", "後半のエンド、安定度、<b>グルーピングの推移。</b>"],
    ["range", "毎月、新しい<br>チャレンジ。", "WA、NFAA、ベガス、3D、<b>練習も1冊に。</b>"],
    ["builder", "矢を組み立てる。", "重さ、バランス、<b>FOCとエネルギー</b>をページに。"],
    ["bow", "スピードと<br>ドロップを知る。", "速度、ドリフト、チューニングメモを<b>弓ごとに。</b>"],
    ["themes", "インクを選ぶ。", "ノートの6色、<b>それぞれ専用アイコン。</b>"],
  ],
  "ko": [
    ["scoring", "맞은 자리를<br>탭하세요.", "Quiver가 모든 화살을 채점, <b>X까지.</b>"],
    ["session", "그룹이 알려 주는<br>조준점.", "사이트 이동 거리를 mm로, <b>마크도 자동 보정.</b>"],
    ["widgets", "마크를<br>잠금 화면에.", "위젯, 실시간 현황, <b>Siri까지.</b>"],
    ["tape", "80야드에서도<br>정확한 테이프.", "<b>실제로 쏜 마크</b>를 지나도록 맞춤."],
    ["print", "실제 크기로<br>인쇄.", "잘라서 붙이면 <b>끝.</b>"],
    ["insights", "점수가 새는 곳이<br>보입니다.", "후반 엔드, 일관성, <b>그룹 크기의 변화.</b>"],
    ["range", "매달 새로운<br>챌린지.", "WA, NFAA, 베가스, 3D, <b>연습까지 한 권에.</b>"],
    ["builder", "화살 만들기.", "무게, 밸런스, <b>FOC와 에너지</b>를 한 페이지에."],
    ["bow", "속도와 낙차를<br>한눈에.", "속도, 편류, 튜닝 메모를 <b>활마다.</b>"],
    ["themes", "잉크 고르기.", "노트 색 6가지, <b>각각 전용 아이콘.</b>"],
  ],
  "zh-Hans": [
    ["scoring", "点一下<br>落点。", "Quiver 为每支箭计分,<b>X 环也算。</b>"],
    ["session", "箭组告诉你<br>该瞄哪里。", "瞄具移动几毫米,<b>瞄点也帮你改好。</b>"],
    ["widgets", "瞄点就在<br>锁定屏幕上。", "小组件、实时活动,<b>还有 Siri。</b>"],
    ["tape", "80 码也准的<br>刻度带。", "按<b>你真正射出的瞄点</b>拟合。"],
    ["print", "按实际尺寸<br>打印。", "剪下来,贴上去,<b>就好了。</b>"],
    ["insights", "看清分数<br>丢在哪里。", "后段组、稳定性,<b>箭组大小的变化。</b>"],
    ["range", "每月一个<br>新挑战。", "WA、NFAA、拉斯维加斯、3D,<b>练习也在同一本。</b>"],
    ["builder", "组装你的箭。", "重量、平衡、<b>FOC 和动能</b>都在页面上。"],
    ["bow", "掌握速度<br>和下坠。", "速度、风偏、调弓笔记,<b>每把弓都有。</b>"],
    ["themes", "选择墨色。", "六种笔记本颜色,<b>各有专属图标。</b>"],
  ],
};
const steps = loc === "en-US" ? plan : L10N[loc];
const cjk = { ja: "Noto Sans JP", ko: "Noto Sans KR", "zh-Hans": "Noto Sans SC" }[loc];
const cjkSerif = { ja: "Noto Serif JP", ko: "Noto Serif KR", "zh-Hans": "Noto Serif SC" }[loc];
const files = readdirSync(src);
rmSync(out, { recursive: true, force: true });
mkdirSync(out, { recursive: true });
const b = await chromium.launch();
const p = await b.newPage({ viewport: { width: 1320, height: 2868 } });
let n = 1;
for (const [key, head, sub] of steps) {
  const f = files.find((x) => x.endsWith(`-${key}.png`));
  if (!f) { console.log("missing", key); continue; }
  const img = readFileSync(`${src}/${f}`).toString("base64");
  await p.setContent(`<!doctype html><html><head>
<link href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,700;9..144,900&family=Inter:wght@600;800&display=block" rel="stylesheet">${cjk ? `
<link href="https://fonts.googleapis.com/css2?family=${cjkSerif.replace(/ /g, "+")}:wght@600;700;900&family=${cjk.replace(/ /g, "+")}:wght@500;600;700;800;900&display=block" rel="stylesheet">` : ""}
<style>
  body{margin:0;width:1320px;height:2868px;overflow:hidden;background:radial-gradient(1400px 1000px at 30% 10%,#e6d6b3,#d9c7a0 60%,#c9b487)}
  .rules{position:absolute;inset:0;background:repeating-linear-gradient(transparent 0 78px,rgba(31,61,43,.10) 78px 80px)}
  .margin{position:absolute;top:0;bottom:0;left:92px;width:3px;background:rgba(184,56,41,.35)}
  .col{position:absolute;left:140px;right:90px;top:170px;display:flex;flex-direction:column}
  h1{margin:0;color:#1f3d2b;font-family:Fraunces,${cjk ? `"${cjkSerif}",` : ""}serif;font-weight:900;font-size:112px;line-height:1.0;letter-spacing:-1px}
  p{margin:30px 0 0;color:rgba(31,61,43,.72);font-family:Inter,${cjk ? `"${cjk}",` : ""}sans-serif;font-weight:600;font-size:48px;line-height:1.22}
  p b{color:#1f3d2b;font-weight:800;background:linear-gradient(transparent 58%,#c6f542 58%)}
  .phone{margin:72px 0 0 -30px;width:1080px;border-radius:120px;padding:22px;background:#1f3d2b;box-shadow:0 50px 120px rgba(31,61,43,.45);transform:rotate(-1.2deg)}
  .phone img{display:block;width:100%;border-radius:100px}
  .tape{position:absolute;width:220px;height:64px;background:rgba(255,255,255,.5);border:1px solid rgba(255,255,255,.7);transform:rotate(-6deg)}
${cjk ? "h1,p{text-wrap:balance}" : ""}</style></head><body><div class="rules"></div><div class="margin"></div>
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
