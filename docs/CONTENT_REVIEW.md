# Content review before publication

The weekly workflow and administrator runs prepare a candidate artifact. They never push unreviewed lessons into the public app feed. App users download only the catalog committed to main.

The developer is a pilot and owns the concept of this independent product. The collection script uses internal text patterns for fictional exercises. Those exercise patterns are not a commercial app template or an app generation service. Do not represent these exercises as video transcripts or as individually verified real events.

Before publication, the developer must download the candidate artifact from the GitHub Actions run and review every added lesson and reference:

1. Check the title, channel and availability of the external source link.
2. Check that the fictional scenario and every speaker turn are coherent and distinct from existing material. Replace repetitive generic text with a purposeful lesson or omit it.
3. Review both pilot and controller exercises in the app. Confirm that each question has two distinct choices and that the keyed answer is the next response in the supplied lesson.
4. Correct unclear or misleading terminology. These are language comprehension exercises, not a substitute for official operational training.
5. Replace both catalog copies together, run the content validator and Swift content tests, and inspect the diff. Commit the approved copies to main only after the checks pass.

No collected candidate is published merely because the scheduled job succeeds. Record the reviewer, date, changed lesson IDs and corrections in the publication commit or review notes. Do not describe a completed editorial review until it has actually occurred.
