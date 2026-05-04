Think of this app less like a “fitness tracker” and more like a **training diary that quietly enforces good decision-making**. The main problem you’re solving isn’t storage—it’s friction. If logging interrupts the flow after a hard climbing session, the system fails no matter how sophisticated it is.

So the design goal is simple: **you should be able to finish a climbing session, open the app, and capture everything important in under a minute without thinking.**

---

## Core mental model: “Session-first design”

Everything revolves around a single idea: a *session is the unit of truth*.

You don’t enter “exercises” or “metrics” in isolation. You always answer:

> What did I do today, and how did my body respond?

Each session is just a structured snapshot of reality. The structure changes depending on the day, but the philosophy stays the same.

This is important because it mirrors how fatigue actually works in climbing—it accumulates across sessions, not exercises.

---

## Home screen: minimal and directive

The home screen should feel almost empty. That’s intentional.

You see one dominant action: **Start today’s session**.

Below that, there’s only subtle feedback from the past:

* your last heavy finger load
* your last pull-up performance
* a small note like “last session: high finger fatigue” or “strong performance trend”

Nothing else competes for attention. The goal is to remove decision fatigue before training even begins.

---

## Session creation: guided, not open-ended

When you start a session, you’re not faced with a blank form. Instead, the app already assumes context based on the day.

A Monday session feels like entering a “strength room”: it expects finger loading and pulling work. A Friday session feels more endurance-oriented. Climbing days are even simpler—they focus on performance outcomes, not structured sets.

But crucially, you are never forced into complexity. You can always strip things down and only log the essentials.

The experience should feel like:

> “Here’s your training structure. Just confirm what actually happened.”

Not:

> “Fill in this form.”

---

## Logging philosophy: performance over precision

For finger training, the app doesn’t care about perfect scientific detail. It cares about **consistency of measurement over time**.

So instead of encouraging over-precision, it focuses on stable anchors:

* same edge sizes reused repeatedly
* weight added or reduced
* perceived effort (RPE)
* clean vs failed execution

The key insight is that climbing improvement shows up as:

* slightly higher load at same perceived effort
* same load feeling easier
* fewer failed attempts

The app is designed to make those shifts visible without requiring analysis.

---

## Core training integration: deliberately light

Front lever and core work are treated differently from finger or pulling strength.

They are not “main events” in the system—they are **background signals of body control**.

So instead of structured workouts, core work exists as small embedded “movement moments” inside rest periods or between sets.

The UI reflects this subtly: it never pushes core work as a block you complete. It’s more like:

> “During this rest period, do something light if you want.”

This matters because it prevents a common failure mode in climbers: turning accessory work into hidden fatigue.

The app is intentionally biased against overtraining.

---

## Data model: everything collapses into one story per session

Under the hood, each session is a single narrative object. It contains:

* finger load exposure
* pulling intensity
* optional core activation
* climbing performance output
* body state (fatigue + finger sensitivity)

But the user never sees it as a “database of metrics.”

They see it as:

> “What happened to me today?”

That narrative structure is what makes long-term comparison meaningful.

---

## Progress view: intentionally boring

The progress screen should not feel like an analytics dashboard.

It should feel like confirmation.

You’re not trying to “explore insights.” You’re just checking whether the direction is correct.

So instead of many graphs, you only see a few stable trends:

* finger strength trend over time
* pulling strength trend
* climbing output trend

What matters is not complexity, but **directionality**. You’re looking for slope, not detail.

If the slopes are all slowly rising, the system is working. If one rises while another drops, that signals imbalance (fatigue, overreach, or poor recovery).

---

## The real design constraint: honesty over motivation

Most fitness apps are designed to motivate. This one should be designed to **prevent self-deception**.

That means:

* no inflated summaries
* no artificial “badges”
* no reward loops

Instead, the app quietly forces consistency:

* if you trained poorly, it shows it
* if fatigue is rising, it shows it
* if progress stalls, it doesn’t hide it

This is especially important for climbing because progress is nonlinear and easy to misinterpret subjectively.

---

## What makes this app actually useful

The real value isn’t tracking—it’s **comparison across identical stress points**.

After a few weeks, you can answer questions like:

* “Did +20 kg on max hangs used to feel like RPE 9, but now feel like 7?”
* “Am I climbing harder problems with fewer attempts?”
* “Is Friday endurance work making Monday strength worse?”

That’s the actual intelligence layer. Everything else is just data capture.

---

## If you build only one thing well

Build this extremely well:

> Fast session entry + consistent repeatability of metrics

If you get that right, everything else (charts, insights, progression) naturally becomes meaningful.

If you don’t, even the best analytics won’t matter because the data will be noisy.

---

If you want, I can next help you design the **exact UI flow screen-by-screen (like a product wireframe in words)** or define the **decision rules the app uses to detect progress vs fatigue imbalance**.
