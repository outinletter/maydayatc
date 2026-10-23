#!/usr/bin/env python3
"""Check shipped UI and lesson translations, optionally inside a built app."""
import argparse
import collections
import json
import pathlib
import plistlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[1]
LANGUAGES = {"ko", "ja", "zh-Hans", "es", "fr", "de", "it", "pt-BR", "ru", "nl"}


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        assert key not in result, f"Duplicate localization key: {key}"
        result[key] = value
    return result


def formats(text):
    return collections.Counter(re.findall(r"%(?:\d+\$)?(lld|@)", text))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--app", type=pathlib.Path)
    args = parser.parse_args()
    strings = json.loads((ROOT / "ios/MaydayATC/Localizable.xcstrings").read_text(),
                         object_pairs_hook=unique_object)["strings"]
    for key, entry in strings.items():
        for language in LANGUAGES:
            unit = entry["localizations"][language]["stringUnit"]
            assert unit["state"] == "translated" and unit["value"].strip(), (key, language)
            assert formats(key) == formats(unit["value"]), (key, language, "format mismatch")
    required = {"pilot", "controller", "PILOT", "ATC · CONTROLLER", "Save recording",
                "Unsave recording", "Reveal pilot response", "Reveal controller response",
                "Hide pilot response", "Hide controller response", "Correct — follows this dialogue",
                "Incorrect — belongs to another turn", "Selected. Explanation shown below.",
                "Select to see this example’s explanation", "Mark as practiced",
                "Practiced — practice again anytime", "Updating content…", "Update content now"}
    calls = r"(?:Text|Section|Button|Label|Toggle|Picker|Link|TextField|ContentUnavailableView|navigationTitle|accessibilityLabel|confirmationDialog|L\.text|L\.format|NSLocalizedString)\(\"([^\"\\]*)\""
    for name in ("MaydayATCApp.swift", "Content.swift"):
        required.update(re.findall(calls, (ROOT / "ios/MaydayATC" / name).read_text()))
    required.discard("Mayday ATC")  # Brand, not translated.
    catalog = json.loads((ROOT / "ios/MaydayATC/catalog.json").read_text())
    for scenario in catalog["scenarios"]:
        required.add(scenario["summary"])
        required.add(scenario["title"].split(" · ")[0])
        for line in scenario["practice"].splitlines():
            text = line.strip()
            if text.startswith("STEP "):
                required.add(text)
            elif text.lower().startswith("explanation:"):
                required.add(text.split(":", 1)[1].strip())
    missing = required - strings.keys()
    assert not missing, f"Untranslated visible text: {sorted(missing)}"
    if args.app:
        with (args.app / "Info.plist").open("rb") as file:
            info = plistlib.load(file)
        assert LANGUAGES <= set(info["CFBundleLocalizations"])
        for language in LANGUAGES:
            with (args.app / f"{language}.lproj/Localizable.strings").open("rb") as file:
                compiled = plistlib.load(file)
            for key, entry in strings.items():
                assert compiled.get(key) == entry["localizations"][language]["stringUnit"]["value"], (language, key)
    print(f"PASS: {len(strings)} keys in all {len(LANGUAGES)} languages; UI, lesson text and format coverage")


if __name__ == "__main__":
    main()
