# Phreatic

Phreatic is a hydration keeper for people who forget to drink until a headache arrives. The well starts full at wake and drains in real time. A sip stems the ebb. Staying above the stave is the day.

## Architecture

Continuous-drain projection. `WellLevel` is never stored. The file on disk holds wake volume plus append-only `Sip` and `Activity` events. Each frame (and each 1 Hz tick of `DrawDownClock`) recomputes the table from body mass, elapsed waking minutes, and overlapping activity windows. The stave at 30 percent of the daily goal partitions Safe from Ebb. A downward crossing writes an `EbbMark`. An upward crossing writes a `StemMark`. Both are idempotent.

This pattern fits the product because the home verb is stem-the-ebb, not fill-a-vessel. A stored level would drift from the clock. A three-state fold would hide the falling table. Recomputing from events keeps every past day byte-for-byte reproducible and lets the view read one struct.

## The ebb-drain well

Drain is `min(bodyKg × 0.4, dailyGoal ÷ wakingMinutes)` millilitres per waking minute, so the body coefficient is a ceiling and an untouched day reaches empty at the sleep hour. Activity doubles that rate for 60 minutes. Overlaps extend the window; they do not stack past 2×. History counts stave-hold days (zero EbbMarks after wake).

## Art

Style: 16 bit pixel art on mixed-media paper grain. Ordered Bayer dither, hard 1 px outline, no type in the sprites. Asset generation is a later step. Image sets are named from the specification (`phr_` prefix). Runtime water uses vendored `OrderedDither` so the table still reads as pixel art before the cutouts land.

## Why this is not a repeat

Castellum fills an empty weir from the bottom. Phreatic inverts the direction: the well starts full and the fight is against a line that keeps falling. There is no tab bar. History and Settings arrive as sheets over the locked well.

## Build

```bash
cd Phreatic
xcodegen generate
xcodebuild -scheme Phreatic -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
```

Launch arguments after onboarding: `-ReviewScreen today`, `-ReviewScreen log`, `-ReviewScreen goals`, plus `intake` and `ebb`.
