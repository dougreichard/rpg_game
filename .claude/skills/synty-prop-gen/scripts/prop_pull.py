#!/usr/bin/env python
"""One-shot Prop Farm runner — generate a prop on the 3090 service and land it in the repo,
ready to wire. Collapses generate -> download -> place -> Godot-import into ONE command (so
there's no multi-step confirmation dance).

Run with the env that has gradio_client (e.g. the Mac's hunyuan3d env):
  conda run -n hunyuan3d python prop_pull.py --name tuning_bench --height 2.25 \
      --prompt "a sturdy wooden carpenter's workbench, dark walnut top, steel rods, brass tools"

PRESETS — reproducibility: ../prop_presets.json holds each prop's canonical recipe
(prompt/seed/track/angle/height). If you omit --prompt and the --name matches a preset, that
recipe is used verbatim — so `prop_pull.py --name tuning_bench` reproduces the known-good
inputs (prompt drift was why a re-roll looked "over-decimated" / less detailed). Any flag you
pass explicitly overrides the preset. Add a prop to prop_presets.json once it looks right.

Common flags:
  --track painted|flat   (default painted; painted = diffuse texture, flat = grey low-poly)
  --height M             real-world bbox height in metres → GLB ships true-sized, wire scale 1.0
  --seed N  --angle D    base seed / dissolve angle (defaults 11 / 6)
  --ref-count N          reference candidates the server best-picks (default 6; 1 = reproduce a pinned seed)
  --pin                  write the winning chosen_seed (+ ref_count 1) back into prop_presets.json
  --style IMG            optional style-reference image (IPAdapter set-consistency)
  --commit               git add + commit + push the landed GLB (else leave it for review)
  --host URL             Prop Farm (default http://192.168.0.62:7860)
  --no-import            skip the Godot reimport step

Several props in one go: --batch props.json  where props.json is a list of arg dicts, e.g.
  [{"name":"table_saw","height":1.4,"prompt":"..."}, {"name":"dock_crane","height":12,"prompt":"..."}]
batch shares one Client connection and applies the top-level flags as defaults.
"""
import argparse, json, os, shutil, subprocess, sys


def repo_root() -> str:
    return subprocess.check_output(["git", "rev-parse", "--show-toplevel"], text=True).strip()


def find_glb(result) -> str | None:
    # /generate returns (markdown, gallery, model3d_path, download_glb_path)
    for idx in (3, 2):
        if idx < len(result) and result[idx] and str(result[idx]).endswith(".glb"):
            p = str(result[idx])
            if os.path.exists(p):
                return p
    return None


def pin_preset(path: str, name: str, job: dict, chosen_seed: int) -> None:
    """Record the winning recipe in prop_presets.json: seed = chosen_seed, ref_count = 1, so a
    later run reproduces this exact reference fast (no re-search). Preserves the _* doc keys."""
    data = json.load(open(path)) if os.path.exists(path) else {}
    data[name] = {
        "prompt": job["prompt"], "seed": int(chosen_seed),
        "track": job.get("track", "painted"), "angle": job.get("angle", 6),
        "height": job.get("height", 1.0), "poly": job.get("poly", 4000),
        "ref_count": 1,
    }
    with open(path, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")


def generate(client, job: dict, repo: str, do_import: bool, do_commit: bool, pin_path: str = "") -> bool:
    name = job["name"]
    style = None
    if job.get("style"):
        from gradio_client import handle_file
        style = handle_file(job["style"])
    rc = int(job.get("ref_count", 6))
    print(f"→ [{job.get('track','painted')}] {name}  h={job.get('height',1.0)}m  seed={job.get('seed',11)}  ref_count={rc}")
    res = client.predict(
        name, job["prompt"], job.get("seed", 11), job.get("track", "painted"),
        job.get("angle", 6), job.get("height", 1.0), job.get("poly", 4000),
        rc, style, False,
        job.get("texture_mode", "diffuse_matte"), job.get("remesh_preset", "custom"),
        api_name="/generate",
    )
    glb = find_glb(res)
    if not glb:
        print(f"  !! no GLB returned for {name} (first output: {str(res[0])[:160]})")
        return False
    dest = os.path.join(repo, "assets/models/props", name + ".glb")
    shutil.copy(glb, dest)
    print(f"  ✓ landed {os.path.relpath(dest, repo)} ({os.path.getsize(dest) // 1024} KB)")

    # chosen_seed (5th output): the winning reference seed from the server's candidate search.
    chosen = int(res[4]) if len(res) > 4 and res[4] is not None else None
    if chosen is not None:
        print(f"  chosen_seed = {chosen}")
        if pin_path:
            pin_preset(pin_path, name, job, chosen)
            print(f"  ✓ pinned seed {chosen} (+ ref_count 1) into prop_presets.json")

    if do_import:
        try:
            subprocess.run(["godot", "--headless", "--path", repo, "--import"],
                           cwd=repo, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=180)
            print("  ✓ imported in Godot")
        except Exception as e:
            print(f"  (import skipped: {e})")

    if do_commit:
        rel = os.path.relpath(dest, repo)
        subprocess.run(["git", "-C", repo, "add", rel, rel + ".import"])
        msg = f"Prop: {name} (Prop Farm {job.get('track','painted')}, {job.get('height',1.0)}m, scale 1.0)"
        subprocess.run(["git", "-C", repo, "commit", "-q", "-m", msg])
        subprocess.run(["git", "-C", repo, "push", "origin", "main"])
        print("  ✓ committed + pushed")
    else:
        print(f'  → wire it: prop("res://assets/models/props/{name}.glb", POS, yaw)   # real-sized, scale 1.0')
    return True


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--name"); ap.add_argument("--prompt")
    ap.add_argument("--height", type=float, default=1.0)
    ap.add_argument("--poly", type=int, default=4000,
                    help="painted pre-paint remesh tri budget (set-dressing ~1500-2500, hero ~4000-6000)")
    ap.add_argument("--track", default="painted", choices=["painted", "flat"])
    ap.add_argument("--seed", type=float, default=11)
    ap.add_argument("--angle", type=float, default=6)
    ap.add_argument("--ref-count", type=int, default=6, dest="ref_count",
                    help="reference candidates the server searches (best-pick); pass 1 with a pinned seed to reproduce")
    ap.add_argument("--style", default=None)
    ap.add_argument("--batch", default="", help="JSON file: list of per-prop arg dicts")
    ap.add_argument("--host", default="http://192.168.0.62:7860")
    ap.add_argument("--commit", action="store_true")
    ap.add_argument("--pin", action="store_true",
                    help="write the winning chosen_seed (+ ref_count 1) back into prop_presets.json")
    ap.add_argument("--no-import", action="store_true")
    a = ap.parse_args()

    repo = repo_root()
    # canonical recipes (avoids prompt drift — the cause of "why did the mesh change")
    presets_path = os.path.join(os.path.dirname(__file__), "..", "prop_presets.json")
    presets = {}
    if os.path.exists(presets_path):
        presets = {k: v for k, v in json.load(open(presets_path)).items() if not k.startswith("_")}

    defaults = {"track": a.track, "seed": a.seed, "angle": a.angle, "height": a.height,
                "poly": a.poly, "ref_count": a.ref_count, "style": a.style}
    # only treat a flag as an override if it was actually passed (else fall back to preset).
    # normalise dashes→underscores so --ref-count maps to the ref_count key (was a silent bug).
    passed = {x.lstrip("-").split("=")[0].replace("-", "_") for x in sys.argv[1:]}
    overrides = {k: v for k, v in defaults.items() if k in passed}

    def build(spec: dict) -> dict:
        j = dict(presets.get(spec.get("name", ""), {}))   # preset base (if any)
        j.update(spec)                                     # explicit values (prompt, name, ...)
        for k, v in defaults.items():                      # fill any still-missing with defaults
            j.setdefault(k, v)
        j.update(overrides)                                # CLI flags win
        return j

    if a.batch:
        jobs = [build(p) for p in json.load(open(a.batch))]
    else:
        if not a.name:
            ap.error("provide --name (+ --prompt, or a matching preset) or --batch")
        spec = {"name": a.name}
        if a.prompt:
            spec["prompt"] = a.prompt
        jobs = [build(spec)]
        if "prompt" not in jobs[0]:
            ap.error(f"no --prompt and no preset for '{a.name}' in prop_presets.json")
        if a.name in presets and not a.prompt:
            print(f"(using preset recipe for '{a.name}')")

    from gradio_client import Client
    print(f"Prop Farm: {a.host}  ({len(jobs)} prop(s))")
    client = Client(a.host)
    pin_path = os.path.abspath(presets_path) if a.pin else ""
    ok = sum(generate(client, j, repo, not a.no_import, a.commit, pin_path) for j in jobs)
    print(f"\ndone: {ok}/{len(jobs)} landed")
    sys.exit(0 if ok == len(jobs) else 1)


if __name__ == "__main__":
    main()
