#!/usr/bin/env python
"""One-shot Character Farm runner — the char-side companion to prop_pull.py. Two modes:

  GENERATE a new rigged character/pet from a prompt (/generate_character):
    conda run -n hunyuan3d python char_pull.py --name frosty --template quadruped \
        --prompt "small fluffy white schnoodle dog, shaggy white fur, friendly cartoon pet"

  RIG an existing uploaded mesh, keeping its geometry+paint (/rig_mesh):
    conda run -n hunyuan3d python char_pull.py --rig docs/nvidia_handoff/frosty_mesh.glb \
        --template quadruped --name frosty

Both land the rigged GLB in the repo and Godot-import it. Dest by template: quadruped → pets,
humanoid (synty_humanoid/realistic_humanoid) → characters. A trailing `_mesh` in the name is
stripped (frosty_mesh → frosty), matching the farm's --commit behaviour.

Templates: quadruped / synty_humanoid / realistic_humanoid / creature. quadruped + synty do the
Blender weight-transfer FIT (named skeleton + grafted clips, paint kept); creature → generic UniRig.

Flags:
  --template T     rig target (default synty_humanoid)
  --seed N         /generate_character seed (default 20; ignored by --rig)
  --ref-count N    reference candidates for /generate_character (default 4)
  --farm-commit    ask the FARM to commit+push (do_commit=True); else download + land locally
  --host URL       Character Farm (default http://192.168.0.62:7860)
  --no-import      skip the Godot reimport step
  --validate       run tests/validate_character.gd on the result (--pet for quadruped)
"""
import argparse, os, shutil, subprocess, sys

PET_TEMPLATES = {"quadruped"}


def repo_root() -> str:
    return subprocess.check_output(["git", "rev-parse", "--show-toplevel"], text=True).strip()


def find_glb(result) -> str | None:
    # /generate_character: (md, gallery, rigged_character_glb, download_glb)
    # /rig_mesh:           (md, ...,     rigged_glb,           download_glb)  — scan from the end
    for item in reversed(result if isinstance(result, (list, tuple)) else [result]):
        p = str(item)
        if p.endswith(".glb") and os.path.exists(p):
            return p
    return None


def dest_for(name: str, template: str, repo: str) -> str:
    stem = name[:-5] if name.endswith("_mesh") else name
    sub = "assets/models/pets" if template in PET_TEMPLATES else "assets/models/characters"
    return os.path.join(repo, sub, stem + ".glb")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--name", help="output character name (stem); required unless --rig implies it")
    ap.add_argument("--prompt", help="prompt for /generate_character")
    ap.add_argument("--rig", help="path to an existing mesh GLB to rig via /rig_mesh")
    ap.add_argument("--template", default="synty_humanoid",
                    choices=["synty_humanoid", "realistic_humanoid", "quadruped", "creature"])
    ap.add_argument("--seed", type=float, default=20)
    ap.add_argument("--ref-count", type=int, default=4, dest="ref_count")
    ap.add_argument("--farm-commit", action="store_true", dest="farm_commit")
    ap.add_argument("--host", default="http://192.168.0.62:7860")
    ap.add_argument("--no-import", action="store_true")
    ap.add_argument("--validate", action="store_true")
    a = ap.parse_args()

    repo = repo_root()
    name = a.name
    if a.rig and not name:
        name = os.path.splitext(os.path.basename(a.rig))[0]
    if not name:
        ap.error("provide --name (and --prompt) to generate, or --rig <mesh.glb>")
    if not a.rig and not a.prompt:
        ap.error("generate mode needs --prompt (or use --rig to rig an existing mesh)")

    from gradio_client import Client, handle_file
    print(f"Character Farm: {a.host}")
    client = Client(a.host)

    if a.rig:
        print(f"→ /rig_mesh  {a.rig}  template={a.template}  name={name}")
        res = client.predict(handle_file(a.rig), a.template, a.farm_commit, api_name="/rig_mesh")
    else:
        print(f"→ /generate_character  {name}  template={a.template}  seed={a.seed}  ref={a.ref_count}")
        res = client.predict(name, a.prompt, a.template, a.seed, a.ref_count, a.farm_commit,
                             api_name="/generate_character")

    if a.farm_commit:
        print("  ✓ farm committed + pushed — run `git pull` to land it")
        return

    glb = find_glb(res)
    if not glb:
        print(f"  !! no GLB returned (first output: {str(res[0])[:200]})")
        sys.exit(1)
    dest = dest_for(name, a.template, repo)
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    shutil.copy(glb, dest)
    print(f"  ✓ landed {os.path.relpath(dest, repo)} ({os.path.getsize(dest) // 1024} KB)")

    if not a.no_import:
        try:
            subprocess.run(["godot", "--headless", "--path", repo, "--import"],
                           cwd=repo, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=180)
            print("  ✓ imported in Godot")
        except Exception as e:
            print(f"  (import skipped: {e})")

    if a.validate:
        cmd = ["godot", "--headless", "-s", "tests/validate_character.gd", "--", dest]
        if a.template in PET_TEMPLATES:
            cmd.append("--pet")
        subprocess.run(cmd, cwd=repo)


if __name__ == "__main__":
    main()
