# Learning Roadmap — Getting More Out of Claude

Things worth learning offline that directly improve how well you and Claude work together on this project.

---

## 1. Git Basics (High Priority)

Right now Claude makes changes and you trust they're correct. With Git you can see exactly what changed, undo anything, and experiment safely.

**Learn:**
- `git status` / `git diff` — see what changed before accepting it
- `git add` / `git commit` — checkpoint your work
- `git log` — review history
- `git checkout <file>` — undo a specific file change
- `git stash` — shelve work-in-progress temporarily

**Why it matters with Claude:** Claude edits multiple files at once. Being able to `git diff` before committing means you review changes rather than just trust them. If something breaks after a Claude session you can pinpoint exactly what changed.

**Resource:** [Git - The Simple Guide](https://rogerdudler.github.io/git-guide/) — 10 minute read.

---

## 2. Reading GDScript (Medium Priority)

You don't need to write GDScript from scratch — Claude does that. But being able to *read* it means you can spot obvious mistakes, understand what a script does, and ask better follow-up questions.

**Learn to recognize:**
- `func`, `var`, `const`, `@export`, `@onready` — the basic building blocks
- Signals: `signal foo` / `foo.connect(callable)` / `emit_signal`
- The FSM pattern: `enum State {}` + `match _state`
- How `_ready()`, `_process(delta)`, `_physics_process(delta)` work

**Why it matters with Claude:** When Claude generates a 200-line script you can skim it and ask "why is `_process` used here instead of `_physics_process`?" rather than accepting it blindly.

**Resource:** [GDScript basics — official Godot docs](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html)

---

## 3. Prompt Engineering

How you phrase a request has a large effect on the quality of Claude's response.

**Learn:**
- **Be specific about constraints first.** "Edit only `enemy.gd`, don't touch anything else" is better than "fix the enemy."
- **Give context Claude can't see.** "This script runs 60×/sec" or "this is called from three places" changes the answer.
- **Ask for options before implementation.** "What are two ways to approach X? Don't write code yet." Saves you from accepting the first idea.
- **Correct mid-task.** Claude doesn't know it's going wrong unless you say so. "Stop — the approach is wrong because..." works.
- **Use scope words.** "Minimal change," "don't refactor," "just the one function" prevent Claude from over-engineering.

**Resource:** Anthropic's [prompt engineering guide](https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/overview)

---

## 4. Stable Diffusion / ComfyUI Fundamentals

You're now running a full local SD pipeline. Understanding the knobs means you can fix bad results yourself without asking Claude every time.

**Learn:**
- **CFG scale** — how strongly the image follows the prompt. 6–8 is normal; higher = more literal but more artifacts.
- **Sampling steps** — more steps = more refined, slower. 20–30 is the sweet spot.
- **Sampler types** — `dpmpp_2m` + `karras` is stable and fast; `euler_ancestral` is more creative/chaotic.
- **LoRA strength** — how hard the style LoRA pushes. 0.5–0.75 blends it in; >0.9 can break anatomy.
- **Negative prompts** — what to exclude. This is often more powerful than the positive prompt for fixing issues.
- **Seeds** — same seed + same prompt = same image. Use this for consistency.
- **img2img** — generate based on an existing image. Essential for animation consistency (use frame 0 as the reference for all subsequent frames).

**Why it matters:** Right now every frame is generated independently so characters look different between frames. `img2img` with a reference image is how you fix that.

**Resource:** [Stable Diffusion Art — Beginner's Guide](https://stable-diffusion-art.com/beginners-guide/)

---

## 5. Python Basics

The sprite generators (`gen_quinn.py`, `gen_erin.py`, etc.) are plain Python. Knowing the basics means you can tweak them yourself.

**Learn:**
- Functions, loops, lists, dictionaries
- `PIL` / `Pillow` image operations: `Image.new()`, `ImageDraw.rectangle()`, `.paste()`, `.resize()`
- How to run a Python script and read a traceback

**Why it matters with Claude:** Right now if a sprite row looks wrong you have to describe it to Claude. If you can read the code you can say "line 94, the coat polygon coordinates are wrong" and Claude fixes it in one shot instead of three.

**Resource:** [Python in 100 Seconds](https://www.youtube.com/watch?v=x7X9w_GIm1s) for overview, then [Automate the Boring Stuff with Python](https://automatetheboringstuff.com/) (free) for practical grounding.

---

## 6. Pixel Art Fundamentals

Understanding pixel art principles helps you give better art direction to Claude and to Stable Diffusion.

**Learn:**
- **Palette discipline** — limiting to 16 colors creates visual cohesion. Learn why the PICO-8 palette works.
- **Readability at small sizes** — silhouette is everything at 32×32. If the outline doesn't tell the story, nothing inside it does.
- **Hue shifting** — shadows shift toward cooler/complementary hues rather than just darkening. One reason AI-generated sprites look flat.
- **Animation arcs** — walk cycles, anticipation, follow-through. Even 4 frames can feel alive with correct timing.

**Why it matters:** When you look at a generated frame and something feels "off," knowing these principles lets you name what's wrong ("the shadow is just a darker version of the base color, it needs a hue shift") rather than just saying "it looks bad."

**Resource:** [Aseprite pixel art tutorials](https://www.aseprite.org/docs/) and the [Lospec palette guide](https://lospec.com/pixel-art-resources).

---

## 7. Godot Scene / Node Mental Model

Claude manipulates `.tscn` files and node trees constantly. Understanding the model means you can spot when Claude does something structurally wrong.

**Learn:**
- Node hierarchy — every node has a parent; `get_node()` / `$NodeName` navigate it
- Scene instancing — a `.tscn` can be instanced into another scene
- The difference between `Area2D`, `StaticBody2D`, `CharacterBody2D`, `Node2D`
- Signals vs direct calls — why the game uses signals everywhere
- What `@export` does and how it shows up in the Inspector

**Resource:** [Your First 2D Game — official Godot tutorial](https://docs.godotengine.org/en/stable/getting_started/first_2d_game/index.html) — do this once and the whole codebase will make more sense.

---

## 8. How to Review Claude's Work

A meta-skill: knowing *how* to check whether Claude's output is correct.

**Habits to build:**
- **Boot check every time.** Run `godot --headless --path . --quit-after 200` after any code change. If it exits cleanly, no parse errors.
- **Read diffs, not just files.** `git diff` shows only what changed. Reading the full file obscures the change.
- **Test the thing it touched.** If Claude edited enemy patrol logic, actually walk past a guard in-game.
- **Ask "what could go wrong?"** before accepting a change. Claude is confident even when wrong.
- **Check signal connections.** The most common Claude mistake is wiring signals to functions that don't exist or have the wrong signature.

---

## Quick Reference: Asking Claude Better Questions

| Instead of… | Try… |
|---|---|
| "Fix the bug" | "The enemy doesn't patrol. Here's the relevant function: [paste]. What's wrong?" |
| "Add sprites" | "Edit only `player.gd`. Add a `_play_directional()` function that…" |
| "Make it better" | "The walk animation looks stiff. What are two specific changes to the leg phase array that would improve it?" |
| "Why doesn't this work?" | "This crashes with: `[paste error]`. The crash is in `enemy.gd:45`. What's wrong?" |
| "Do the next thing" | "The next task is X. Before writing code, tell me your plan in 3 bullet points." |
