"""Public YouTube feeds -> verified metadata -> fictional English exercises.

No API keys, model calls, transcript downloads, or app-triggered workflows.
"""
import argparse
import copy
import hashlib
import json
import pathlib
import re
import time
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from datetime import datetime, timezone

ROOT = pathlib.Path(__file__).resolve().parents[1]
NS = {"a": "http://www.w3.org/2005/Atom", "yt": "http://www.youtube.com/xml/schemas/2015"}
TOPICS = [
    ("medical", r"medical|hypoxi|unconscious|incapacitat", "a medical situation on board"),
    ("fire", r"fire|smoke", "a smoke or fire indication"),
    ("bird", r"bird.strike|bird.hit", "a suspected bird strike"),
    ("hydraulic", r"hydraulic", "a hydraulic system indication"),
    ("fuel", r"fuel", "a fuel-related concern"),
    ("gear", r"landing.gear|gear.fail|gear.issue|gear.problem", "a landing gear indication"),
    ("pressurization", r"pressuri|decompress", "a pressurization concern"),
    ("weather", r"windshear|wind.shear|storm|turbulence|weather", "unfavorable weather"),
    ("engine", r"engine|power.loss|loss.of.power", "an engine-related indication"),
]


def fetch(url):
    request = urllib.request.Request(url)
    for attempt in range(3):
        try:
            with urllib.request.urlopen(request, timeout=20) as response:
                data = response.read(2_000_001)
            if len(data) > 2_000_000:
                raise ValueError("Source response exceeds limit")
            return data
        except (urllib.error.URLError, TimeoutError):
            if attempt == 2:
                raise
            time.sleep(attempt + 1)


def classify(title):
    if not re.search(r"mayday|emergency|pan.?pan|fail|fire|smoke|bird.strike|hydraulic|fuel|pressuri|decompress|windshear|wind.shear", title, re.I):
        return None
    for category, pattern, problem in TOPICS:
        if re.search(pattern, title, re.I):
            return category, problem
    return "etc", "an unexpected aircraft situation"


def exercise(video, category, problem, base):
    """Compose original fictional text; never claim to transcribe the source."""
    lesson_id = "video-" + hashlib.sha256(video["id"].encode()).hexdigest()[:16]
    callsign = "Training " + str(100 + int(hashlib.sha256(video["id"].encode()).hexdigest()[:4], 16) % 900)
    dialogue = [
        {"from": "PILOT", "msg": f"{callsign}, we are dealing with {problem}. We request assistance."},
        {"from": "ATC", "msg": f"{callsign}, understood. State the assistance you require when ready."},
        {"from": "PILOT", "msg": f"{callsign}, we need time to assess the situation. Please stand by for our intentions."},
        {"from": "ATC", "msg": f"{callsign}, understood. Advise when you are ready to continue."},
        {"from": "PILOT", "msg": f"{callsign}, please repeat the last information slowly so we can confirm our understanding."},
        {"from": "ATC", "msg": f"{callsign}, I will repeat the information. Confirm that you understand before proceeding."},
    ]
    practice = "STEP 1: Fictional conversation\n" + "\n".join(x["from"] + ": " + x["msg"] for x in dialogue)
    practice += ("\n\nSTEP 2: Clear language\nOriginal: We have a problem.\n"
                 f"Corrected: We are dealing with {problem} and request assistance.\n"
                 "Explanation: State the topic clearly, then make an explicit request. These words are an invented language exercise, not operational instructions.\n\n"
                 "STEP 3: Alternative expression\nAlternative: Please repeat the last message slowly. We would like to confirm our understanding.")
    lesson = {
        "id": lesson_id, "title": (base["title"] + " · " + callsign)[:120],
        "summary": "Fictional language practice inspired by the topic of the linked video. This dialogue is newly composed from a reviewed template, not extracted speech or a transcript. No facts about the actual flight are asserted.",
        "pilotRoles": list(base["pilotRoles"]), "atcRoles": list(base["atcRoles"]),
        "dialogue": dialogue, "practice": practice,
    }
    return lesson


def collect(sources):
    candidates = []
    failures = []
    for channel in sources["channels"]:
        if not re.fullmatch(r"UC[A-Za-z0-9_-]{22}", channel["id"]):
            raise ValueError("Invalid channel ID")
        try:
            tree = ET.fromstring(fetch("https://www.youtube.com/feeds/videos.xml?channel_id=" + channel["id"]))
            if tree.findtext("yt:channelId", namespaces=NS) not in [channel["id"], channel["id"][2:]]:
                raise ValueError("Channel identity mismatch")
            for entry in tree.findall("a:entry", NS):
                video_id = entry.findtext("yt:videoId", namespaces=NS) or ""
                title = entry.findtext("a:title", namespaces=NS) or ""
                if entry.findtext("yt:channelId", namespaces=NS) != channel["id"]:
                    raise ValueError("Video channel identity mismatch")
                if re.fullmatch(r"[A-Za-z0-9_-]{11}", video_id) and classify(title):
                    candidates.append({"id": video_id, "title": title,
                                       "publishedAt": entry.findtext("a:published", namespaces=NS) or "",
                                       "channelId": channel["id"]})
        except Exception as error:
            failures.append(channel["name"] + ": " + str(error))
    if failures:
        # All-or-nothing publication: do not publish a misleading partial refresh.
        raise RuntimeError("Channel fetch failed: " + "; ".join(failures))
    return sorted(candidates, key=lambda v: v["publishedAt"], reverse=True)


def update_catalog(catalog, candidates, sources, verify):
    result = copy.deepcopy(catalog)
    known = {v["id"] for v in result["references"]}
    bases = {s["id"]: s for s in result["scenarios"] if not s["id"].startswith("video-")}
    new = []
    for video in candidates:
        if video["id"] in known:
            continue
        metadata = verify(video)
        topic = classify(metadata["title"])
        if topic is None:
            continue
        category, problem = topic
        lesson = exercise(video, category, problem, bases[category])
        result["scenarios"].append(lesson)
        new.append({"id": video["id"], "title": metadata["title"][:200], "channel": metadata["author_name"][:120],
                    "category": category, "lessonId": lesson["id"], "publishedAt": video["publishedAt"]})
        known.add(video["id"])
        if len(new) >= sources["maxNewVideos"]:
            break
    if not new:
        return result, 0
    result["references"] = (new + result["references"])[:sources["maxPublishedVideos"]]
    attached = {v.get("lessonId") for v in result["references"]}
    result["scenarios"] = [s for s in result["scenarios"] if not s["id"].startswith("video-") or s["id"] in attached]
    result["revision"] += 1
    result["updatedAt"] = datetime.now(timezone.utc).isoformat()
    return result, len(new)


def verify(video):
    url = "https://www.youtube.com/oembed?format=json&url=" + urllib.parse.quote("https://www.youtube.com/watch?v=" + video["id"], safe="")
    data = json.loads(fetch(url))
    if data.get("provider_name") != "YouTube" or not data.get("author_name") or not data.get("title"):
        raise ValueError("Invalid YouTube metadata")
    return data


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    sources = json.loads((ROOT / "content/sources.json").read_text())
    if not 1 <= sources["maxNewVideos"] <= 10 or not 1 <= sources["maxPublishedVideos"] <= 80:
        raise ValueError("Invalid collection limits")
    current = json.loads((ROOT / "content/catalog.json").read_text())
    updated, count = update_catalog(current, collect(sources), sources, verify)
    payload = (json.dumps(updated, ensure_ascii=False, indent=2) + "\n").encode()
    if len(payload) > 1_000_000:
        raise ValueError("Catalog exceeds app size limit")
    print(f"Verified {count} new videos; content revision {updated['revision']}")
    if count and not args.dry_run:
        for path in [ROOT / "content/catalog.json", ROOT / "ios/MaydayATC/catalog.json"]:
            temporary = path.with_suffix(".tmp")
            temporary.write_bytes(payload)
            temporary.replace(path)


if __name__ == "__main__":
    main()
