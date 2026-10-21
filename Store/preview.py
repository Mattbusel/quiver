"""Upload the App Preview video to the 6.9" (IPHONE_67) preview set of a version, for the given locales.

    python Store/preview.py <version> <mp4> [locale ...]      default locales: every localization on the version
    python Store/preview.py <version> --status
"""
import hashlib
import sys
import time
from pathlib import Path

import requests

sys.path.insert(0, str(Path(__file__).resolve().parent))
import asc  # noqa: E402


def locs(version: str):
    app = asc.find_app()
    v = asc.call("GET", f"/v1/apps/{app['id']}/appStoreVersions", params={"filter[versionString]": version})["data"][0]
    return asc.call("GET", f"/v1/appStoreVersions/{v['id']}/appStoreVersionLocalizations", params={"limit": 50})["data"]


def preview_set(lid: str):
    sets = asc.call("GET", f"/v1/appStoreVersionLocalizations/{lid}/appPreviewSets")["data"]
    s = next((x for x in sets if x["attributes"]["previewType"] == "IPHONE_67"), None)
    if not s:
        s = asc.call("POST", "/v1/appPreviewSets", {"data": {"type": "appPreviewSets", "attributes": {"previewType": "IPHONE_67"},
                     "relationships": {"appStoreVersionLocalization": {"data": {"type": "appStoreVersionLocalizations", "id": lid}}}}})["data"]
    return s


def upload(version: str, mp4: str, only):
    data = Path(mp4).read_bytes()
    for l in locs(version):
        loc = l["attributes"]["locale"]
        if only and loc not in only:
            continue
        s = preview_set(l["id"])
        for p in asc.call("GET", f"/v1/appPreviewSets/{s['id']}/appPreviews")["data"]:
            asc.call("DELETE", f"/v1/appPreviews/{p['id']}")
        made = asc.call("POST", "/v1/appPreviews", {"data": {"type": "appPreviews",
                        "attributes": {"fileName": Path(mp4).name, "fileSize": len(data), "mimeType": "video/mp4", "previewFrameTimeCode": "00:00:06:00"},
                        "relationships": {"appPreviewSet": {"data": {"type": "appPreviewSets", "id": s["id"]}}}}})
        if not made:
            print(loc, "reserve FAILED"); continue
        pid = made["data"]["id"]
        for op in made["data"]["attributes"]["uploadOperations"]:
            h = {x["name"]: x["value"] for x in op.get("requestHeaders", [])}
            requests.request(op["method"], op["url"], headers=h, data=data[op["offset"]: op["offset"] + op["length"]], timeout=300).raise_for_status()
        r = asc.call("PATCH", f"/v1/appPreviews/{pid}", {"data": {"type": "appPreviews", "id": pid,
                     "attributes": {"uploaded": True, "sourceFileChecksum": hashlib.md5(data).hexdigest()}}})
        print(loc, "preview uploaded" if r else "commit FAILED")


def status(version: str):
    for l in locs(version):
        s = preview_set(l["id"])
        ps = asc.call("GET", f"/v1/appPreviewSets/{s['id']}/appPreviews")["data"]
        print(l["attributes"]["locale"], [(p["attributes"].get("assetDeliveryState") or {}).get("state") for p in ps])


if __name__ == "__main__":
    if "--status" in sys.argv:
        status(sys.argv[1])
    else:
        upload(sys.argv[1], sys.argv[2], sys.argv[3:])
