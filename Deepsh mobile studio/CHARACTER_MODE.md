# CHARACTER_MODE.md — [DEPRECATED & REMOVED]

> ⚠️ **REMOVAL NOTICE**: Character Mode has been permanently removed from Deepesh Mobile Studio.
> Due to AI multi-pose inconsistency, uncanny puppet lip-flaps, and visual distortion ("illusion issue"), animated cartoon hosts are strictly eliminated.
> The studio exclusively produces broadcast-grade, high-retention explainers through authentic 2D cinematography:
> 1. Vox Documentary Explainer
> 2. Sticker / Stickman Hybrid
> 3. Hand-Drawn Doodle & Sketchbook
> 4. Suspense Noir / Crime Documentary
> 5. Retro 8-Bit Arcade

---

## 1. When to use the character (director's judgement)

Use it for **~20-35 % of the runtime**, on the lines where a person would naturally speak:

| narration moment | character beat |
|---|---|
| intro / hook ("आज हम जानेंगे...") | walk in, wave, `say` the question |
| an explanation of a key idea ("नेपाल इतना सुंदर क्यों है?") | `presenter` layout: the picture left, host right, `point` on the key word |
| travel / a new place / a journey | `stage` scene: walk through the parallax world, the camera tracks |
| a surprising fact | `react` with `wow`, or `think` before the answer |
| a question to the audience / the outro | face camera, `talk`, `happy` |

Do **not** use it for every scene, for dense data (charts, maps: let the graphics speak), or as a talking head with
nothing beside it.

## 2. Create the character (Google Flow, once per video or series)

Add to `SHOTS.json`:

```json
{"name": "mira", "kind": "character",
 "look": "Mira, a cheerful 10-year-old Nepali girl with a round face, big brown eyes, short black bob hair with a red clip, mustard kurta with small white flowers, blue jeans, red sneakers and a small canvas backpack",
 "personality": "curious, warm, a little cheeky",
 "poses": ["idle", "talk", "blink", "walk1", "walk2", "walk3", "walk4", "point", "wow", "think", "happy"]}
```

`python studio.py prompts` expands this into one prompt per pose. `mira_idle` is the **master**. Every other pose
carries `ref = mira_idle` in ELEMENTS.tsv, so `studio.py generate` sends it **with the master image as a Flow
reference** (same face, hair, outfit, colours, proportions), waiting until the master exists. The usual rate law
still applies: one prompt at a time, paced, stop on unusual activity.

Then `python studio.py key` gives transparent `elements/cut/mira_<pose>.png`.

* Pose vocabulary: `idle talk blink walk1-4 run1 run2 point wow think happy wave sad look hold shrug`. Describe
  anything else in `"pose_notes": {"dance": "..."}`.
* `<pose>_talk` (e.g. `point_talk`) is an optional mouth-open version of any pose, for talking while gesturing.
* All poses are drawn **facing right**. The engine mirrors them when the character faces left.
* Check the set side by side before editing. If one pose drifted (different outfit or face),
  `python studio.py generate --regen mira_wow`.
* Style fit: the default character medium is the modern illustrated storytelling look (clean outlines, big
  expressive eyes, rounded shapes, soft cel shading). A style pack can override it with `prompt.character_medium`.
* Missing poses fall back gracefully (talk → jaw-bob on idle, walk → puppet bob), and `check` lists what is
  missing. With no art at all, a clearly-marked placeholder toon is drawn so previews still work.

Optional per-character settings at the top of EDIT.json:
```json
"cast": {"mira": {"faces": "right", "scale": {"wow": 1.10, "happy": 1.08}}}
```
`scale` corrects poses whose arms go above the head (all poses are normalised to the same body height).

## 3. Put the character on screen (EDIT.json)

```json
{"type": "character", "cast": "mira", "at": "नेपाल", "until": "@09",
 "enter": "walk_in", "from": "right", "x": 0.5, "height": 0.96, "talk": true, "exit": "walk_out",
 "actions": [
   {"at": "सुंदर", "do": "point"},
   {"at": "पहाड़", "do": "walk", "to": 0.8},
   {"at": "वाह",  "do": "react", "pose": "wow"},
   {"at": "देखो", "do": "look", "dir": "left"},
   {"at": "नेपाल", "do": "say", "text": "नेपाल बहुत सुंदर है!", "until": "@08"},
   {"at": "हाँ", "do": "nod"}, {"at": "नहीं", "do": "shake"}, {"at": "उछल", "do": "hop"},
   {"at": "...", "do": "quiet", "until": "..."}]}
```

| field | meaning |
|---|---|
| `enter` | `walk_in` (default) · `run_in` · `pop` · `rise` · `fade` · `none` |
| `from` | side of a walk-in. Default: the frame edge **nearest** the resting spot, so the walk never crosses the text |
| `x` | resting spot inside the `cast` slot (0 = left edge, 1 = right edge; beyond 1 = further along a stage) |
| `talk` | lip-flaps on every spoken word while visible (`false` = silent actor; then use `talk` actions) |
| `exit` | when the item has `until`: `walk_out` · `run_out` · `fade` · `pop` |
| actions | `walk`/`run` (`to`, optional `dur`), any pose name (holds 1.6 s or `until`, then relaxes to idle), `react` (pose + hop), `look`, `nod`, `shake`, `hop`, `say` (speech bubble), `talk` / `quiet` windows |

What the engine adds automatically:
* lip-flaps at ~9 Hz on the exact word timings from WORDS.tsv, mouth closed in the pauses
* blinks every 2.3-4.6 s, gentle breathing (anchored at the feet), a walk bob, squash and stretch on every pose
  change (anticipation and overshoot)
* facing: towards the walking direction, then towards the frame centre (where the story is)
* a soft feathered ground shadow that shrinks and fades during hops
* speech bubbles with a tail pointing at the head, kept inside the frame and above the captions

### Layouts with a `cast` slot

| layout | use |
|---|---|
| `presenter` | documentary beat: tag + title + picture (`left`) and the host on the right |
| `presenter_l` | mirror: host on the left, picture in `right` |
| `stage` | full character scene: tag + `label` + the whole width for the character |

(16:9 and 9:16 both. The cast slot always ends above the caption band.)

## 4. Stage scenes: a living parallax world

```json
{"at": "@12", "layout": "stage", "transition": "whip",
 "stage": {"layers": [{"src": "nepal_sky", "depth": 0.04, "drift": 8},
                      {"src": "nepal_himalaya", "depth": 0.18},
                      {"src": "nepal_village", "depth": 0.55},
                      {"src": "nepal_path", "depth": 1.0}],
           "fg": [{"src": "rhododendron_fg", "depth": 1.45}],
           "track": "mira", "particles": "petals"},
 "items": [{"type": "kicker", "text": "CHAPTER 2 // THE ROAD TO POKHARA"},
           {"type": "character", "cast": "mira", "x": 0.25, "from": "left",
            "actions": [{"at": "रास्ता", "do": "walk", "to": 1.8}, {"at": "झील", "do": "react", "pose": "wow"}]}]}
```

* `depth`: 0 = infinitely far (barely moves), 1 = the ground the character walks on, above 1 = foreground that moves
  faster than the character. `drift` = slow constant motion (clouds) in px/s.
* The camera follows the tracked character with a critically damped spring and a small look-ahead: smooth, never
  jerky, identical in every render chunk.
* `particles`: `petals` · `snow` · `dust` · `fireflies` · `none`.
* Optional per layer: `"h"` (height as a fraction of the frame), `"y"` (top position).
* Layers are mirror-tiled, so a long walk never runs out of world.

Generate the layers with `kind: "layer"` in SHOTS.json (`sky` is a full image, all other depths are wide seamless strips
on magenta, keyed by `studio.py key`):
```json
{"name": "nepal_himalaya", "kind": "layer", "depth": "far", "subject": "snow-capped Himalayan range with the fish-tail peak of Machapuchare", "time": "clear morning"}
```
A missing layer is replaced by a soft procedural stand-in (with a warning) so previews work. Final videos should use
Flow layers.

## 5. Several characters in one scene

Put two (or more) `character` items in the same scene: they share the `cast` slot (they never replace each other),
are automatically drawn smaller so they fit side by side (unless you give `height`), and every speech bubble is
drawn above all actors and the foreground. Give them different `x` (e.g. 0.25 and 0.75). In 9:16 the bubble sits
centred above the speaker's head. Standing spots are clamped so the whole body stays inside the frame.

## 6. QA

`python studio.py check` lists every character (`🙂 mira (n actions)`) and missing poses. Then
`python studio.py still 12.4 13.0 13.6` to look at the walk, and `python studio.py preview` for motion.
`check` also warns about unknown actions/poses (typos), missing pose images and an `until` after the scene's cut.
Checklist: same face and outfit in every pose · feet on the ground line · the walk-in doesn't cross the title ·
the bubble doesn't cover the picture · the character appears in ≤ 35 % of the scenes.
