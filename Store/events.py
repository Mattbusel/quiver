"""Quiver In-App Events: the November challenge and the Lock Screen update. Localized, with card art, deep linked.

    python Store/events.py <media dir> [--dry]

Media dir: <key>-card.png (1920x1080) and <key>-details-<locale>.png (1080x1920), from Store/art/event_art.mjs.
Idempotent: reuses an event with the same reference name. No price words (2.3.7 applies to events too).
"""
import json
import sys
import time
from pathlib import Path

import requests

sys.path.insert(0, str(Path(__file__).resolve().parent))
import asc  # noqa: E402

EVENTS = {
    "challenge": {
        "ref": "Quiver Ten X November",
        "badge": "CHALLENGE",
        "deepLink": "quiver://challenge",
        "schedule": {"publishStart": "2026-10-26T14:00:00Z", "eventStart": "2026-11-01T05:00:00Z", "eventEnd": "2026-12-01T04:59:00Z"},
        "copy": {
            "en-US": ("Ten X November", "Put ten arrows in the X this month",
                      "November's archery challenge: ten Xs, any round, any distance. Quiver tracks every one from your score book."),
            "en-GB": ("Ten X November", "Put ten arrows in the X this month",
                      "November's archery challenge: ten Xs, any round, any distance. Quiver tracks every one from your score book."),
            "es-MX": ("Noviembre de diez X", "Mete diez flechas en la X este mes",
                      "El reto de noviembre: diez X en cualquier ronda y distancia. Quiver las cuenta desde tu libreta."),
            "de-DE": ("Zehn X im November", "Zehn Pfeile ins X in diesem Monat",
                      "Die November-Challenge: zehn X, jede Runde, jede Distanz. Quiver zählt jedes aus deinem Schießbuch."),
            "fr-FR": ("Dix X en novembre", "Dix flèches dans le X ce mois-ci",
                      "Le défi de novembre : dix X, toute épreuve, toute distance. Quiver les compte depuis ta feuille."),
            "ja": ("11月のXチャレンジ", "今月、Xに10本入れよう",
                   "11月のアーチェリーチャレンジ:どのラウンドでも、どの距離でも、Xを10本。Quiverがスコアブックから数えます。"),
            "ko": ("11월 X 챌린지", "이번 달 X에 화살 10발",
                   "11월 양궁 챌린지: 어떤 라운드, 어떤 거리든 X 10발. Quiver가 점수 기록장에서 하나하나 셉니다."),
            "zh-Hans": ("十一月十个 X", "这个月射进十支 X",
                        "十一月射箭挑战:任意轮次、任意距离,射进十支 X。Quiver 从你的计分本里逐一统计。"),
        },
    },
    "lock": {
        "ref": "Quiver sight marks on the Lock Screen",
        "badge": "MAJOR_UPDATE",
        "deepLink": "quiver://widgets",
        "schedule": {"publishStart": "2026-10-24T14:00:00Z", "eventStart": "2026-10-27T14:00:00Z", "eventEnd": "2026-11-24T14:00:00Z"},
        "copy": {
            "en-US": ("Sight Marks on the Lock Screen", "Your tape, one glance away",
                      "Widgets for any distance, a Live Activity while you score, and Siri reads your sight mark aloud."),
            "en-GB": ("Sight Marks on the Lock Screen", "Your tape, one glance away",
                      "Widgets for any distance, a Live Activity while you score, and Siri reads your sight mark aloud."),
            "es-MX": ("Marcas en la pantalla bloqueo", "Tu cinta de mira, de un vistazo",
                      "Widgets para cualquier distancia, una Actividad en vivo al puntuar y Siri te dice tu marca."),
            "de-DE": ("Marken im Sperrbildschirm", "Dein Visierband auf einen Blick",
                      "Widgets für jede Distanz, eine Live-Aktivität beim Werten, und Siri sagt dir deine Marke."),
            "fr-FR": ("Repères sur l'écran verrouillé", "Ta bande de viseur en un coup d'œil",
                      "Des widgets pour chaque distance, une Activité en direct et Siri qui te donne ton repère."),
            "ja": ("サイトマークをロック画面に", "テープをひと目で",
                   "どの距離にも使えるウィジェット、採点中のライブアクティビティ、Siriがマークを読み上げます。"),
            "ko": ("잠금 화면의 사이트 마크", "테이프를 한눈에",
                   "모든 거리를 위한 위젯, 채점 중 실시간 현황, Siri가 마크를 읽어 줍니다."),
            "zh-Hans": ("锁定屏幕上的瞄点", "刻度带一眼就看到",
                        "任意距离的小组件,计分时的实时活动,还能让 Siri 读出你的瞄点。"),
        },
    },
}


def main(media: Path, dry: bool):
    for key, e in EVENTS.items():
        for loc, (n, s, l) in e["copy"].items():
            assert len(n) <= 30 and len(s) <= 50 and len(l) <= 120, (key, loc, len(n), len(s), len(l))
            assert "—" not in n + s + l
    if dry:
        print("copy ok"); return
    aid = asc.find_app()["id"]
    terr = [t["id"] for t in asc.call("GET", "/v1/territories", params={"limit": 200})["data"]]
    have = {x["attributes"]["referenceName"]: x for x in asc.call("GET", f"/v1/apps/{aid}/appEvents", params={"limit": 50})["data"]}
    out = {}
    for key, e in EVENTS.items():
        ev = have.get(e["ref"])
        if ev:
            print(key, "reusing", ev["id"], ev["attributes"]["eventState"])
        else:
            made = asc.call("POST", "/v1/appEvents", {"data": {"type": "appEvents", "attributes": {
                "referenceName": e["ref"], "badge": e["badge"], "deepLink": e["deepLink"], "primaryLocale": "en-US", "priority": "HIGH",
                "purpose": "APPROPRIATE_FOR_ALL_USERS", "territorySchedules": [dict(territories=terr, **e["schedule"])]},
                "relationships": {"app": {"data": {"type": "apps", "id": aid}}}}})
            if not made:
                print(key, "create FAILED"); continue
            ev = made["data"]; print(key, "created", ev["id"])
        locs = {x["attributes"]["locale"]: x for x in asc.call("GET", f"/v1/appEvents/{ev['id']}/localizations")["data"]}
        for loc, (n, s, l) in e["copy"].items():
            attrs = {"name": n, "shortDescription": s, "longDescription": l}
            if loc in locs:
                asc.call("PATCH", f"/v1/appEventLocalizations/{locs[loc]['id']}", {"data": {"type": "appEventLocalizations", "id": locs[loc]["id"], "attributes": attrs}})
            else:
                made = asc.call("POST", "/v1/appEventLocalizations", {"data": {"type": "appEventLocalizations", "attributes": dict(locale=loc, **attrs),
                                "relationships": {"appEvent": {"data": {"type": "appEvents", "id": ev["id"]}}}}})
                if not made:
                    print(" l10n", loc, "FAILED"); continue
                locs[loc] = made["data"]
            lid = locs[loc]["id"]
            got = {x["attributes"]["appEventAssetType"] for x in asc.call("GET", f"/v1/appEventLocalizations/{lid}/appEventScreenshots")["data"]}
            det = media / f"{key}-details-{loc}.png"
            if not det.exists():
                det = media / f"{key}-details-en-US.png"
            for kind, f in (("EVENT_CARD", media / f"{key}-card.png"), ("EVENT_DETAILS_PAGE", det)):
                if kind in got:
                    continue
                data = f.read_bytes()
                made = asc.call("POST", "/v1/appEventScreenshots", {"data": {"type": "appEventScreenshots",
                                "attributes": {"fileName": f.name, "fileSize": len(data), "appEventAssetType": kind},
                                "relationships": {"appEventLocalization": {"data": {"type": "appEventLocalizations", "id": lid}}}}})
                if not made:
                    print(" shot", loc, kind, "FAILED"); continue
                made = made["data"]
                for op in made["attributes"]["uploadOperations"]:
                    h = {x["name"]: x["value"] for x in op.get("requestHeaders", [])}
                    requests.request(op["method"], op["url"], headers=h, data=data[op["offset"]: op["offset"] + op["length"]], timeout=120).raise_for_status()
                asc.call("PATCH", f"/v1/appEventScreenshots/{made['id']}", {"data": {"type": "appEventScreenshots", "id": made["id"], "attributes": {"uploaded": True}}})
                print(" uploaded", key, loc, kind)
        time.sleep(4)
        out[key] = asc.call("GET", f"/v1/appEvents/{ev['id']}")["data"]["attributes"]["eventState"] + " " + ev["id"]
    print(json.dumps(out, indent=1))


if __name__ == "__main__":
    main(Path(sys.argv[1]) if len(sys.argv) > 1 else Path("."), "--dry" in sys.argv)
