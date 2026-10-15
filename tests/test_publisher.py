import importlib.util
import json
import pathlib
import unittest
from unittest.mock import patch

ROOT = pathlib.Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("publisher", ROOT / "scripts/collect-content.py")
publisher = importlib.util.module_from_spec(spec)
spec.loader.exec_module(publisher)


class PublisherTests(unittest.TestCase):
    def setUp(self):
        self.catalog = json.loads((ROOT / "content/catalog.json").read_text())
        self.sources = {"maxNewVideos": 1, "maxPublishedVideos": 80}
        self.candidate = {"id": "newvideo123", "title": "Engine failure emergency", "publishedAt": "2026-10-15T00:00:00Z"}

    def metadata(self, _):
        return {"title": self.candidate["title"], "author_name": "Test channel"}

    def test_adds_linked_fictional_lesson_without_changing_input(self):
        updated, count = publisher.update_catalog(self.catalog, [self.candidate], self.sources, self.metadata)
        self.assertEqual(count, 1)
        self.assertEqual(updated["revision"], self.catalog["revision"] + 1)
        video = updated["references"][0]
        lesson = next(s for s in updated["scenarios"] if s["id"] == video["lessonId"])
        self.assertEqual(video["category"], "engine")
        self.assertIn("not extracted speech", lesson["summary"])
        self.assertEqual([x["from"] for x in lesson["dialogue"]], ["PILOT", "ATC"] * 3)
        self.assertFalse(any(v["id"] == self.candidate["id"] for v in self.catalog["references"]))
        again, count = publisher.update_catalog(updated, [self.candidate], self.sources, self.metadata)
        self.assertEqual(count, 0)
        self.assertEqual(again, updated)

    def test_unrelated_content_is_ignored(self):
        self.candidate["title"] = "My favorite holiday"
        updated, count = publisher.update_catalog(self.catalog, [self.candidate], self.sources, self.metadata)
        self.assertEqual(count, 0)
        self.assertEqual(updated, self.catalog)

    def test_failure_does_not_publish(self):
        before = json.dumps(self.catalog)
        def fail(_):
            raise RuntimeError("network unavailable")
        with self.assertRaises(RuntimeError):
            publisher.update_catalog(self.catalog, [self.candidate], self.sources, fail)
        self.assertEqual(json.dumps(self.catalog), before)

    def test_feed_supports_youtube_root_id_and_verifies_entry_owner(self):
        channel = "UC" + "a" * 22
        xml = f'''<feed xmlns="http://www.w3.org/2005/Atom" xmlns:yt="http://www.youtube.com/xml/schemas/2015">
        <yt:channelId>{channel[2:]}</yt:channelId><entry><yt:channelId>{channel}</yt:channelId>
        <yt:videoId>newvideo123</yt:videoId><title>Engine failure emergency</title>
        <published>2026-10-15T00:00:00Z</published></entry></feed>'''
        sources = {"channels": [{"id": channel, "name": "Test"}]}
        with patch.object(publisher, "fetch", return_value=xml.encode()):
            self.assertEqual(len(publisher.collect(sources)), 1)
        bad = xml.replace(f"<yt:channelId>{channel}</yt:channelId>", "<yt:channelId>wrong</yt:channelId>")
        with patch.object(publisher, "fetch", return_value=bad.encode()):
            with self.assertRaises(RuntimeError):
                publisher.collect(sources)

    def test_retention_removes_orphaned_generated_lessons(self):
        first, _ = publisher.update_catalog(self.catalog, [self.candidate], self.sources, self.metadata)
        old_id = first["references"][0]["lessonId"]
        self.sources["maxPublishedVideos"] = 1
        self.candidate["id"] = "nextvideo12"
        updated, _ = publisher.update_catalog(first, [self.candidate], self.sources, self.metadata)
        self.assertEqual(len(updated["references"]), 1)
        self.assertFalse(any(s["id"] == old_id for s in updated["scenarios"]))


if __name__ == "__main__":
    unittest.main()
