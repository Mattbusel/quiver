"""Quiver Plus: the auto-renewable subscription group, its two products, prices, trial, screenshots, promo images.

    python Store/subs.py create                  group + group localizations + both products (idempotent)
    python Store/subs.py prices                  price in every territory (equalized from the US price)
    python Store/subs.py trial                   1-week free trial on the yearly plan
    python Store/subs.py shot <png>              App Review screenshot on both products
    python Store/subs.py image <id-suffix> <png> 1024x1024 promo image on a subscription (monthly | yearly)
    python Store/subs.py promote                 promoted purchases: yearly, monthly (+ inks in iap images)
    python Store/subs.py status
"""
import hashlib
import sys
from pathlib import Path

import requests

sys.path.insert(0, str(Path(__file__).resolve().parent))
import asc  # noqa: E402

APP = "6814263466"
GROUP = "Quiver Plus"
BASE = "com.mattbusel.quiver.plus."
NOTE = ("Auto-renewable subscription, group Quiver Plus. Open the Sight tape tab and tap 'See Plus' on the Quiver Plus card "
        "(or Range tab > Insights card). The paywall shows both plans with price, period, the 1-week free trial on the "
        "yearly plan, auto-renew terms, Terms of Use (Apple standard EULA) and Privacy links, Restore Purchases and a "
        "Manage subscription link. Plus includes everything in Quiver Pro (one-time $3.99, still sold) and adds: every ink "
        "theme while subscribed, 5 scorecard poster credits every month, a bonus monthly challenge, the Insights page "
        "(fatigue across ends, consistency, group size, per-distance averages) and iCloud backup of setups, marks and rounds.")
PRODUCTS = [
    # suffix, period, ref name, display name, description (45 max), US price, level
    ("monthly", "ONE_MONTH", "Quiver Plus Monthly", "Quiver Plus, Monthly", "Insights, iCloud, all inks, monthly posters", "2.99", 2),
    ("yearly", "ONE_YEAR", "Quiver Plus Yearly", "Quiver Plus, Yearly", "Insights, iCloud, all inks, monthly posters", "14.99", 1),
]
GROUP_L10N = {
    "en-US": "Quiver Plus", "en-GB": "Quiver Plus", "en-AU": "Quiver Plus", "en-CA": "Quiver Plus",
    "es-MX": "Quiver Plus", "es-ES": "Quiver Plus", "de-DE": "Quiver Plus", "fr-FR": "Quiver Plus", "pt-BR": "Quiver Plus",
    "it": "Quiver Plus", "ja": "Quiver Plus", "ko": "Quiver Plus", "zh-Hans": "Quiver Plus",
}
SUB_L10N = {
    # locale: {suffix: (name, description)}
    "en-US": {"monthly": ("Quiver Plus, Monthly", "Insights, iCloud, all inks, monthly posters"),
              "yearly": ("Quiver Plus, Yearly", "Insights, iCloud, all inks, monthly posters")},
    "en-GB": {"monthly": ("Quiver Plus, Monthly", "Insights, iCloud, all inks, monthly posters"),
              "yearly": ("Quiver Plus, Yearly", "Insights, iCloud, all inks, monthly posters")},
    "en-AU": {"monthly": ("Quiver Plus, Monthly", "Insights, iCloud, all inks, monthly posters"),
              "yearly": ("Quiver Plus, Yearly", "Insights, iCloud, all inks, monthly posters")},
    "en-CA": {"monthly": ("Quiver Plus, Monthly", "Insights, iCloud, all inks, monthly posters"),
              "yearly": ("Quiver Plus, Yearly", "Insights, iCloud, all inks, monthly posters")},
    "es-MX": {"monthly": ("Quiver Plus, mensual", "Análisis, iCloud, todas las tintas, pósters"),
              "yearly": ("Quiver Plus, anual", "Análisis, iCloud, todas las tintas, pósters")},
    "es-ES": {"monthly": ("Quiver Plus, mensual", "Análisis, iCloud, todas las tintas, pósters"),
              "yearly": ("Quiver Plus, anual", "Análisis, iCloud, todas las tintas, pósters")},
    "de-DE": {"monthly": ("Quiver Plus, monatlich", "Analysen, iCloud, alle Tinten, Poster"),
              "yearly": ("Quiver Plus, jährlich", "Analysen, iCloud, alle Tinten, Poster")},
    "fr-FR": {"monthly": ("Quiver Plus, mensuel", "Analyses, iCloud, toutes les encres, posters"),
              "yearly": ("Quiver Plus, annuel", "Analyses, iCloud, toutes les encres, posters")},
    "pt-BR": {"monthly": ("Quiver Plus, mensal", "Análises, iCloud, todas as tintas, pôsteres"),
              "yearly": ("Quiver Plus, anual", "Análises, iCloud, todas as tintas, pôsteres")},
    "it": {"monthly": ("Quiver Plus, mensile", "Analisi, iCloud, tutti gli inchiostri, poster"),
           "yearly": ("Quiver Plus, annuale", "Analisi, iCloud, tutti gli inchiostri, poster")},
    "ja": {"monthly": ("Quiver Plus 月額", "分析、iCloud、全インク、毎月のポスター"),
           "yearly": ("Quiver Plus 年額", "分析、iCloud、全インク、毎月のポスター")},
    "ko": {"monthly": ("Quiver Plus 월간", "분석, iCloud, 모든 잉크, 매월 포스터"),
           "yearly": ("Quiver Plus 연간", "분석, iCloud, 모든 잉크, 매월 포스터")},
    "zh-Hans": {"monthly": ("Quiver Plus 月度", "数据分析、iCloud、全部墨色、每月海报"),
                "yearly": ("Quiver Plus 年度", "数据分析、iCloud、全部墨色、每月海报")},
}


def group():
    got = asc.call("GET", f"/v1/apps/{APP}/subscriptionGroups", params={"limit": 50})
    for g in (got or {}).get("data", []):
        if g["attributes"]["referenceName"] == GROUP:
            return g
    made = asc.call("POST", "/v1/subscriptionGroups", {"data": {"type": "subscriptionGroups", "attributes": {"referenceName": GROUP},
                    "relationships": {"app": {"data": {"type": "apps", "id": APP}}}}})
    print("group", "created" if made else "FAILED")
    return made and made["data"]


def subs(gid):
    got = asc.call("GET", f"/v1/subscriptionGroups/{gid}/subscriptions", params={"limit": 50}) or {"data": []}
    return {d["attributes"]["productId"]: d for d in got["data"]}


def create():
    g = group()
    if not g:
        return
    gid = g["id"]
    print("group", gid)
    have = {l["attributes"]["locale"] for l in (asc.call("GET", f"/v1/subscriptionGroups/{gid}/subscriptionGroupLocalizations") or {"data": []})["data"]}
    for loc, name in GROUP_L10N.items():
        if loc in have:
            continue
        r = asc.call("POST", "/v1/subscriptionGroupLocalizations", {"data": {"type": "subscriptionGroupLocalizations",
                     "attributes": {"locale": loc, "name": name, "customAppName": "Quiver"},
                     "relationships": {"subscriptionGroup": {"data": {"type": "subscriptionGroups", "id": gid}}}}})
        print(f"  group l10n {loc}", "ok" if r else "FAILED")
    existing = subs(gid)
    for suffix, period, ref, _, _, _, level in PRODUCTS:
        pid = BASE + suffix
        s = existing.get(pid)
        if not s:
            made = asc.call("POST", "/v1/subscriptions", {"data": {"type": "subscriptions", "attributes": {
                "name": ref, "productId": pid, "familySharable": True, "subscriptionPeriod": period, "reviewNote": NOTE, "groupLevel": level},
                "relationships": {"group": {"data": {"type": "subscriptionGroups", "id": gid}}}}})
            if not made:
                print(pid, "create FAILED"); continue
            s = made["data"]
        sid = s["id"]
        print(pid, sid, s["attributes"].get("state"))
        have = {l["attributes"]["locale"] for l in (asc.call("GET", f"/v1/subscriptions/{sid}/subscriptionLocalizations") or {"data": []})["data"]}
        for loc, m in SUB_L10N.items():
            if loc in have:
                continue
            name, desc = m[suffix]
            r = asc.call("POST", "/v1/subscriptionLocalizations", {"data": {"type": "subscriptionLocalizations",
                         "attributes": {"locale": loc, "name": name, "description": desc},
                         "relationships": {"subscription": {"data": {"type": "subscriptions", "id": sid}}}}})
            print(f"  l10n {loc}", "ok" if r else "FAILED")
        av = asc.call("GET", f"/v1/subscriptions/{sid}/subscriptionAvailability", quiet=True)
        if not av or not av.get("data"):
            terr = [t["id"] for t in asc.call("GET", "/v1/territories", params={"limit": 200})["data"]]
            r = asc.call("POST", "/v1/subscriptionAvailabilities", {"data": {"type": "subscriptionAvailabilities",
                         "attributes": {"availableInNewTerritories": True},
                         "relationships": {"subscription": {"data": {"type": "subscriptions", "id": sid}},
                                           "availableTerritories": {"data": [{"type": "territories", "id": t} for t in terr]}}}})
            print("  availability", f"{len(terr)} territories" if r else "FAILED")


def prices():
    g = group()
    for suffix, _, _, _, _, usd, _ in PRODUCTS:
        s = subs(g["id"]).get(BASE + suffix)
        if not s:
            continue
        sid = s["id"]
        cur = asc.call("GET", f"/v1/subscriptions/{sid}/prices", params={"limit": 200, "include": "territory"}) or {"data": []}
        done = {d["relationships"]["territory"]["data"]["id"] for d in cur["data"] if d.get("relationships", {}).get("territory", {}).get("data")}
        pts = asc.call("GET", f"/v1/subscriptions/{sid}/pricePoints", params={"filter[territory]": "USA", "limit": 200})
        nxt = pts
        us = None
        while nxt and not us:
            us = next((d for d in nxt["data"] if d["attributes"]["customerPrice"] == usd), None)
            link = nxt.get("links", {}).get("next")
            nxt = asc.call("GET", link) if (link and not us) else None
        if not us:
            print(suffix, "no US price point", usd); continue
        eq = [(us["id"], "USA")]
        url = f"/v1/subscriptionPricePoints/{us['id']}/equalizations"
        params = {"limit": 200, "include": "territory"}
        while url:
            r = asc.call("GET", url, params=params)
            params = None
            for d in r["data"]:
                eq.append((d["id"], d["relationships"]["territory"]["data"]["id"]))
            url = r.get("links", {}).get("next")
        ok = bad = 0
        for ppid, terr in eq:
            if terr in done:
                continue
            r = asc.call("POST", "/v1/subscriptionPrices", {"data": {"type": "subscriptionPrices",
                         "attributes": {"startDate": None, "preserveCurrentPrice": False},
                         "relationships": {"subscription": {"data": {"type": "subscriptions", "id": sid}},
                                           "subscriptionPricePoint": {"data": {"type": "subscriptionPricePoints", "id": ppid}},
                                           "territory": {"data": {"type": "territories", "id": terr}}}}}, quiet=ok + bad > 3)
            ok, bad = (ok + 1, bad) if r else (ok, bad + 1)
        print(f"{suffix}: {len(done)} already, {ok} set, {bad} failed, of {len(eq)}")


def trial():
    g = group()
    s = subs(g["id"]).get(BASE + "yearly")
    have = asc.call("GET", f"/v1/subscriptions/{s['id']}/introductoryOffers", params={"limit": 200}) or {"data": []}
    if have["data"]:
        print("yearly already has", len(have["data"]), "intro offers"); return
    terr = [t["id"] for t in asc.call("GET", "/v1/territories", params={"limit": 200})["data"]]
    ok = 0
    for t in terr:
        r = asc.call("POST", "/v1/subscriptionIntroductoryOffers", {"data": {"type": "subscriptionIntroductoryOffers",
                     "attributes": {"duration": "ONE_WEEK", "offerMode": "FREE_TRIAL", "numberOfPeriods": 1},
                     "relationships": {"subscription": {"data": {"type": "subscriptions", "id": s["id"]}},
                                       "territory": {"data": {"type": "territories", "id": t}}}}}, quiet=ok > 0)
        ok += 1 if r else 0
    print(f"trial: {ok}/{len(terr)} territories")


def _upload(kind: str, rel: str, rel_type: str, rid: str, png: str):
    data = Path(png).read_bytes()
    made = asc.call("POST", f"/v1/{kind}", {"data": {"type": kind, "attributes": {"fileName": Path(png).name, "fileSize": len(data)},
                    "relationships": {rel: {"data": {"type": rel_type, "id": rid}}}}})
    if not made:
        return False
    oid = made["data"]["id"]
    for op in made["data"]["attributes"]["uploadOperations"]:
        headers = {h["name"]: h["value"] for h in op.get("requestHeaders", [])}
        requests.request(op["method"], op["url"], headers=headers, data=data[op["offset"]: op["offset"] + op["length"]], timeout=120).raise_for_status()
    return bool(asc.call("PATCH", f"/v1/{kind}/{oid}", {"data": {"type": kind, "id": oid,
                         "attributes": {"uploaded": True, "sourceFileChecksum": hashlib.md5(data).hexdigest()}}}))


def shot(png: str):
    g = group()
    for pid, s in subs(g["id"]).items():
        cur = asc.call("GET", f"/v1/subscriptions/{s['id']}/appStoreReviewScreenshot", quiet=True)
        if cur and cur.get("data"):
            asc.call("DELETE", f"/v1/subscriptionAppStoreReviewScreenshots/{cur['data']['id']}")
        print(pid, "review shot", "ok" if _upload("subscriptionAppStoreReviewScreenshots", "subscription", "subscriptions", s["id"], png) else "FAILED")


def image(suffix: str, png: str):
    g = group()
    s = subs(g["id"])[BASE + suffix]
    cur = asc.call("GET", f"/v1/subscriptions/{s['id']}/images", quiet=True) or {"data": []}
    for d in cur["data"]:
        asc.call("DELETE", f"/v1/subscriptionImages/{d['id']}")
    print(suffix, "promo image", "ok" if _upload("subscriptionImages", "subscription", "subscriptions", s["id"], png) else "FAILED")


def iap_image(product_id: str, png: str):
    import iap2
    it = iap2.find(product_id)
    cur = asc.call("GET", f"/v2/inAppPurchases/{it['id']}/images", quiet=True) or {"data": []}
    for d in cur["data"]:
        asc.call("DELETE", f"/v1/inAppPurchaseImages/{d['id']}")
    print(product_id, "promo image", "ok" if _upload("inAppPurchaseImages", "inAppPurchase", "inAppPurchases", it["id"], png) else "FAILED")


def promote():
    """Promoted purchases on the product page, in this order: yearly, monthly, then any IAP ids given."""
    g = group()
    ss = subs(g["id"])
    have = asc.call("GET", f"/v1/apps/{APP}/promotedPurchases", params={"limit": 50, "include": "subscription,inAppPurchaseV2"}) or {"data": []}
    print("existing promoted:", len(have["data"]))
    ids = []
    for suffix in ["yearly", "monthly"]:
        s = ss.get(BASE + suffix)
        r = asc.call("POST", "/v1/promotedPurchases", {"data": {"type": "promotedPurchases",
                     "attributes": {"visibleForAllUsers": True, "enabled": True},
                     "relationships": {"app": {"data": {"type": "apps", "id": APP}},
                                       "subscription": {"data": {"type": "subscriptions", "id": s["id"]}}}}})
        print(suffix, "promoted", "ok" if r else "FAILED")
        if r:
            ids.append(r["data"]["id"])
    import iap2
    for pid in sys.argv[2:]:
        it = iap2.find(pid)
        r = it and asc.call("POST", "/v1/promotedPurchases", {"data": {"type": "promotedPurchases",
                            "attributes": {"visibleForAllUsers": True, "enabled": True},
                            "relationships": {"app": {"data": {"type": "apps", "id": APP}},
                                              "inAppPurchaseV2": {"data": {"type": "inAppPurchases", "id": it["id"]}}}}})
        print(pid, "promoted", "ok" if r else "FAILED")


def status():
    g = group()
    if not g:
        return
    print("group", g["id"], g["attributes"])
    for pid, s in subs(g["id"]).items():
        a = s["attributes"]
        print(pid, s["id"], a.get("state"), a.get("subscriptionPeriod"), "level", a.get("groupLevel"))


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "status"
    if cmd == "shot":
        shot(sys.argv[2])
    elif cmd == "image":
        image(sys.argv[2], sys.argv[3])
    elif cmd == "iap-image":
        iap_image(sys.argv[2], sys.argv[3])
    else:
        {"create": create, "prices": prices, "trial": trial, "promote": promote, "status": status}.get(cmd, lambda: sys.exit(__doc__))()
