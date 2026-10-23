# iPhone and App Store languages

English is the source and fallback language. The app also supports Korean, Japanese, Simplified Chinese, Spanish, French, German, Italian, Brazilian Portuguese, Russian and Dutch. iOS preferred app language selects the interface; no user records are changed when the language changes.

`ios/MaydayATC/Localizable.xcstrings` contains the translated interface, progress formats, role names, lesson topic names, summaries, reflection explanations, privacy notice and answer feedback. Aviation dialogue, original/revised English response examples, credited YouTube titles and channel names remain in their original English.

The bundled lessons and the publisher's common lesson headings, summaries and explanations have translations. Unrecognized future source text falls back to its original English. New guidance must receive translations before editorial publication; both validation workflows check this coverage. Dialogue identifiers and saved progress remain independent of displayed translations.

Run `python3 scripts/validate-localization.py` to check all ten translations, visible source text, lesson guidance and format arguments. Pass `--app /absolute/path/MaydayATC.app` to verify the actual compiled language resources. The physical-device `testLocalizedScreenshots` captures the same study flow in English and all ten translations.

`APP_STORE_LOCALIZATIONS.json` contains separate product-page descriptions, promotional text, keywords and subtitles. These metadata localizations must be saved in App Store Connect separately from the compiled app languages. Screenshot capture, screenshot upload, build upload, draft build selection and review submission are distinct steps.
