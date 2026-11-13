---
name: reel-check
description: فحص ريلز — score an Instagram/TikTok reel out of 100 before posting and show where viewers will keep watching or swipe away. Use when the user sends a reel file or link and says «افحص», «فحص ريل», «بينتشر؟», or asks to check a video before posting. Free: uses ffmpeg plus Claude's own look at the frames, no paid service.
---

# فحص ريل

1. Measure (link or local file) with `measure.ps1` from this skill's folder (needs ffmpeg on PATH, and yt-dlp for links; install them first if missing):
   `powershell -ExecutionPolicy Bypass -File "<this skill folder>\measure.ps1" -Video "<file or link>" -Out "<scratchpad>\reel-check"`
   A link given to this skill is only analysed, not copied to the flash.
2. Read `hook.jpg` (first 3 s) and `full.jpg` (1 frame per second).
3. Score each part, then add them up to a total out of 100:

| Part | Max | What earns it |
|---|---|---|
| Hook (0–3 s) | 30 | Something moves or text lands in the first second; a clear promise or question; no logo/black/slow intro |
| Pace | 20 | A cut or big visual change every 1.5–3 s (`beats_per_10s` ≈ 3–6); nothing frozen longer than ~2 s (`longest_still_s`) |
| Text on screen | 15 | Big, readable on a phone, inside the safe area (not the bottom 20% or right edge), Arabic letters joined correctly |
| Audio | 15 | Voice or music from 0 s; loudness about -14 LUFS (−16 to −10 is fine); no silence over 0.5 s except on purpose |
| Payoff / story | 10 | Delivers what the hook promised before the halfway point; ends on a strong frame |
| CTA & loop | 10 | One clear ask (comment word, follow, save); the last frame flows back into the first |

4. Build a second-by-second retention guess: for each 3-second block give an estimated % still watching (start at 100%) and mark the blocks where people likely swipe, with the reason.
5. Reply in Levantine Arabic: the total (≥85 بينتشر, 70–84 متوسط, <70 بيقلبوه), the table of parts, the retention blocks, and the top 3 fixes in order of impact, each one concrete ("قصّ أول 1.2 ثانية", not "حسّن الهوك").

Say plainly that the score is an estimate from the video itself, not a prediction from Instagram data.
