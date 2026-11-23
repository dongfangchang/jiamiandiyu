# v0.85.0 Integration report

## 2026-11-23 User-supplied Moretti illustration

User approved the supplied image. Installed the first diary leaf only. Original 1536x2048 retained; runtime 1260x1770, centered crop of about 2.54% per side, no recoloring. Source and hashes: art/production/v0.85.0/moretti_source.json.

Godot 4.7.2 import succeeded. V085: 21 checks; V055: 59 checks. GPU capture succeeded; current evidence: .tools/ui-captures/v085_user_moretti_diary.png. New first-leaf art is visibly loaded.

Visual limits: existing illumination makes the neutral image strongly orange; paper has procedural ruled texture; seal, candle and ink props remain placeholders. This verifies integration, not final art acceptance. Priorities: paper 2048 square, wood 2048 square, three transparent seals 512 square. Leather/spine/page edges and props are optional additions. Lighting, text size and camera need UI tuning, not a single baked background. Seven other diary illustrations remain pending. Version stays in progress; no push.

## 2026-11-23 Desk material sample

Preserved all three supplied images; normalized paper and wood to 2048 square without geometric stretching. Original 1536x2048 sources retained. Reproducible preparation script and source hashes recorded under art/production/v0.85.0. Edge-only cosine blending gives zero opposite-edge difference; inspected both 2x2 repeats with no hard seams. These are user-supplied materials, not generated assets or licensed stock. Candle image is reference for a modeled prop, not an alpha sprite.

UI owns stage, lighting, page/prop geometry and interaction verification. This is the requested single-leaf sample; seven scene illustrations and three seals remain pending. No gameplay/storage changes, no API call, no release/push.

Final integration review: corrected the yellow blank under-leaf exposed during a turn to the same paper stock; raised header, swipe hint and close-bookmark contrast. Independently inspected idle and mid-flip GPU captures. V083=21, V055=59, V085=21 pass (101 total); import and capture exit 0, no ERROR/FAIL matches. Logs: .tools/v083_diary_desk_p0_final.log, .tools/v055_diary_chapter_final.log, .tools/v085_diary_art_final.log, .tools/v085_desk_final_import.log, .tools/v085_desk_final_capture.log. Evidence .tools/ui-captures/v085_desk_material_idle.png and v085_desk_material_flip.png. Stage uses curved leaves and a turned-profile candleholder; seals and quill/inkwell remain simplified. This is a single-leaf preview, not final acceptance of the complete v0.85 asset set.

## User review — stop this visual pass

User requested wrapping up because the result is unsatisfactory. Stop further visual iteration and generation. Preserve source assets and local implementation for review; do not mark the desk art accepted or the version complete. Automated regressions passed, but that is not artistic acceptance. No commit or push performed. Main remaining visual mismatch: simplified modeled props and book do not yet match the illustration's realism and atmosphere.
