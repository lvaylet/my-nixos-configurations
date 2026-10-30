# Quickstart & Validation Guide: Enable Python 3 Script Execution for n8n Code Nodes on Homelab

**Branch**: `016-add-n8n-python3` | **Date**: 2026-10-15 | **Spec**: [spec.md](spec.md)

This guide provides step-by-step commands to validate the configuration locally, deploy it to `homelab`, and verify end-to-end Python 3 execution both on the `homelab` host and inside n8n `Code` nodes.

---

## 1. Local Static Analysis & Flake Evaluation

From the repository root on your development machine:

```sh
# 1. Format all Nix files with Alejandra
just fmt

# 2. Run static linters (deadnix + statix)
just lint

# 3. Verify homelab configuration evaluates cleanly with Python 3 and n8n-runners
nix eval .#nixosConfigurations.homelab.config.system.build.toplevel.drvPath

# 4. Run full hermetic flake checks and secret scanners
just check
```

**Expected Outcome**: All commands exit with code `0` and zero warnings or errors.

---

## 2. Safe Remote Activation Test & Deployment to `homelab`

Test and deploy the updated configuration to `homelab`:

```sh
# Temporarily activate and test on homelab without modifying bootloader entries:
just test configuration="homelab" target="homelab"

# Permanently switch homelab to the new generation:
just switch configuration="homelab" target="homelab"
```

---

## 3. Verify Python 3 and Task Runner Services on `homelab`

Connect to `homelab` over SSH (`ssh laurent@homelab`) and verify both the host Python 3 installation and the `n8n` + `n8n-runners` containers (commands below are identical in both **Bash** and **Fish**):

```sh
# 1. Verify Python 3 is installed on the homelab host (FR-001)
python3 --version

# 2. Verify both podman-n8n and podman-n8n-runners services are active (FR-006)
scs podman-n8n podman-n8n-runners

# 3. Inspect n8n-runners logs to confirm registration with the n8n task broker
logs podman-n8n-runners -n 30
```

**Expected Outcome**:

- `python3 --version` prints `Python 3.x.y`.
- Both `podman-n8n.service` and `podman-n8n-runners.service` report `active (running)`.
- `podman-n8n-runners` logs confirm that the JavaScript and Python task runners registered successfully with the task broker at `http://n8n:5679`.

---

## 4. Verify Python 3 Execution Inside an n8n `Code` Node

1. Open `https://n8n.homelab.vaylet.fr` in your browser.
2. Create a test workflow with a **Manual Trigger** connected to a **Code** node.
3. In the **Code** node settings:
   - Set **Language** to **Python (Native)**.
   - Set **Mode** to **Run Once for All Items**.
   - Paste the following Python 3 script (testing standard library imports `datetime`, `json`, `re`, and timezone alignment):

     ```python
     import datetime
     import json
     import re
     import sys

     now = datetime.datetime.now().isoformat()
     cleaned = re.sub(r"\s+", "-", "Homelab Python 3 Runner OK")

     return [
         {
             "json": {
                 "status": cleaned,
                 "python_version": sys.version.split()[0],
                 "timestamp": now,
                 "input_count": len(_items),
             }
         }
     ]
     ```

4. Click **Test step** (or **Execute step**).

**Expected Outcome**:

- The node executes within 2 seconds without any `"Python 3 is missing from this system"` error (`SC-001`, `SC-002`).
- The output JSON item contains `"status": "Homelab-Python-3-Runner-OK"`, `"python_version": "3.13.x"`, and a `"timestamp"` matching `Europe/Paris` local time.
