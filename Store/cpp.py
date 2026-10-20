"""Quiver Custom Product Pages: three audiences, each with its own screenshot order, promo text and keywords.

    python Store/cpp.py create      make the pages (idempotent by name), upload screenshots, set keywords where the API allows
    python Store/cpp.py status
    python Store/cpp.py submit      add each page version to the open review submission (with the app version)

Screenshots come from fastlane/screenshots/en-US (the framed store set, no price words).
"""
import hashlib
import sys
import time
from pathlib import Path

import requests

sys.path.insert(0, str(Path(__file__).resolve().parent))
import asc  # noqa: E402

APP = "6814263466"
SHOTS = Path(__file__).resolve().parent.parent / "fastlane" / "screenshots" / "en-US"
# Store set order: 01 scoring, 02 session, 03 widgets, 04 tape, 05 print, 06 insights, 07 range, 08 builder, 09 bow, 10 themes
PAGES = [
    {"name": "Bowhunting", "shots": [4, 3, 5, 8, 9, 2],
     "promo": "Your sight mark for any ranged distance, right on the Lock Screen. A tape printed true size, and an arrow sheet with FOC and kinetic energy for deer and elk.",
     "keywords": "bowhunting,elk,deer,hunting,broadhead,kinetic energy,momentum,rangefinder,whitetail,treestand,pins"},
    {"name": "Target and indoor", "shots": [1, 2, 6, 7, 3, 4],
     "promo": "Score WA 18 m, NFAA 300 and Vegas rounds by tapping the face. Quiver reads your group, moves your sight in millimetres and shows where the points go.",
     "keywords": "target,indoor,vegas,nfaa,olympic,league,scoresheet,x count,club,tournament,coach"},
    {"name": "3D and field", "shots": [7, 3, 4, 1, 9, 10],
     "promo": "Walk a 3D course with your marks on the Lock Screen. Read the mark for any distance, score 12, 11, 10, 8, 5 in a tap, and take on a new challenge every month.",
     "keywords": "3d,field,course,walk back,unknown distance,league,shoot,woods,ranging,challenge"},
]


def pages():
    got = asc.call("GET", f"/v1/apps/{APP}/appCustomProductPages", params={"limit": 50}) or {"data": []}
    return {p["attributes"]["name"]: p for p in got["data"]}


def upload_set(lid: str, files):
    sets = asc.call("GET", f"/v1/appCustomProductPageLocalizations/{lid}/appScreenshotSets") or {"data": []}
    sset = next((s for s in sets["data"] if s["attributes"]["screenshotDisplayType"] == "APP_IPHONE_67"), None)
    if sset:
        cur = asc.call("GET", f"/v1/appScreenshotSets/{sset['id']}/appScreenshots") or {"data": []}
        if len(cur["data"]) == len(files):
            print("  screenshots already there"); return
        for s in cur["data"]:
            asc.call("DELETE", f"/v1/appScreenshots/{s['id']}")
    else:
        sset = asc.call("POST", "/v1/appScreenshotSets", {"data": {"type": "appScreenshotSets", "attributes": {"screenshotDisplayType": "APP_IPHONE_67"},
                        "relationships": {"appCustomProductPageLocalization": {"data": {"type": "appCustomProductPageLocalizations", "id": lid}}}}})["data"]
    for f in files:
        data = f.read_bytes()
        made = asc.call("POST", "/v1/appScreenshots", {"data": {"type": "appScreenshots", "attributes": {"fileName": f.name, "fileSize": len(data)},
                        "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": sset["id"]}}}}})["data"]
        for op in made["attributes"]["uploadOperations"]:
            h = {x["name"]: x["value"] for x in op.get("requestHeaders", [])}
            requests.request(op["method"], op["url"], headers=h, data=data[op["offset"]: op["offset"] + op["length"]], timeout=120).raise_for_status()
        asc.call("PATCH", f"/v1/appScreenshots/{made['id']}", {"data": {"type": "appScreenshots", "id": made["id"],
                 "attributes": {"uploaded": True, "sourceFileChecksum": hashlib.md5(data).hexdigest()}}})
        print("  uploaded", f.name)


def create():
    have = pages()
    files = sorted(SHOTS.glob("*.png"))
    for pg in PAGES:
        p = have.get(pg["name"])
        if not p:
            made = asc.call("POST", "/v1/appCustomProductPages", {
                "data": {"type": "appCustomProductPages", "attributes": {"name": pg["name"]},
                         "relationships": {"app": {"data": {"type": "apps", "id": APP}},
                                           "appCustomProductPageVersions": {"data": [{"type": "appCustomProductPageVersions", "id": "${v}"}]}}},
                "included": [
                    {"type": "appCustomProductPageVersions", "id": "${v}",
                     "relationships": {"appCustomProductPageLocalizations": {"data": [{"type": "appCustomProductPageLocalizations", "id": "${l}"}]}}},
                    {"type": "appCustomProductPageLocalizations", "id": "${l}", "attributes": {"locale": "en-US", "promotionalText": pg["promo"]}},
                ]})
            if not made:
                print(pg["name"], "create FAILED"); continue
            p = made["data"]
            print(pg["name"], "created", p["id"])
        vers = asc.call("GET", f"/v1/appCustomProductPages/{p['id']}/appCustomProductPageVersions") or {"data": []}
        v = vers["data"][0]
        locs = asc.call("GET", f"/v1/appCustomProductPageVersions/{v['id']}/appCustomProductPageLocalizations")["data"]
        loc = next(x for x in locs if x["attributes"]["locale"] == "en-US")
        asc.call("PATCH", f"/v1/appCustomProductPageLocalizations/{loc['id']}", {"data": {"type": "appCustomProductPageLocalizations", "id": loc["id"],
                 "attributes": {"promotionalText": pg["promo"]}}})
        print(" ", pg["name"], "version", v["id"], v["attributes"].get("state"), "url", p["attributes"].get("url"))
        upload_set(loc["id"], [files[i - 1] for i in pg["shots"]])
        keywords(loc["id"], pg["keywords"])


def keywords(lid: str, kw: str):
    """Custom product page search keywords (2025 feature). Tried through the API; reported if Apple refuses."""
    r = asc.call("PATCH", f"/v1/appCustomProductPageLocalizations/{lid}", {"data": {"type": "appCustomProductPageLocalizations", "id": lid,
                 "attributes": {"searchKeywords": kw}}}, quiet=True)
    if r:
        print("  keywords set (attribute)"); return
    words = [w.strip() for w in kw.split(",") if w.strip()]
    r = asc.call("POST", f"/v1/appCustomProductPageLocalizations/{lid}/relationships/searchKeywords",
                 {"data": [{"type": "appKeywords", "id": w} for w in words]}, quiet=True)
    print("  keywords", "set (relationship)" if r is not None else "NOT available through the API")


def status():
    for name, p in pages().items():
        vers = asc.call("GET", f"/v1/appCustomProductPages/{p['id']}/appCustomProductPageVersions")["data"]
        print(name, p["id"], p["attributes"].get("url"), [(v["id"], v["attributes"].get("state")) for v in vers])


def submit():
    subs = asc.call("GET", "/v1/reviewSubmissions", params={"filter[app]": APP, "filter[state]": "READY_FOR_REVIEW,WAITING_FOR_REVIEW", "filter[platform]": "IOS"})
    if not subs or not subs["data"]:
        print("no open review submission"); return
    sid = subs["data"][0]["id"]
    for name, p in pages().items():
        v = asc.call("GET", f"/v1/appCustomProductPages/{p['id']}/appCustomProductPageVersions")["data"][0]
        r = asc.call("POST", "/v1/reviewSubmissionItems", {"data": {"type": "reviewSubmissionItems", "relationships": {
            "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": sid}},
            "appCustomProductPageVersion": {"data": {"type": "appCustomProductPageVersions", "id": v["id"]}}}}})
        print(name, "added to", sid if r else "FAILED")


if __name__ == "__main__":
    {"create": create, "status": status, "submit": submit}.get(sys.argv[1] if len(sys.argv) > 1 else "status", lambda: sys.exit(__doc__))()
