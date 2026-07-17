# Setup — FINAL version (follow this one)

Your actual layout:
- **Home Ubuntu:** personal machine only → repo lives in `~/Documents`, simple global identity
- **WSL:** two identities on one machine → repo lives in `~/p`, automatic separation

GitHub repo already exists (empty). Ignore all command boxes on the GitHub page — this guide replaces them.

---

# SESSION 1 — Home Ubuntu (~30–40 min, do tonight)

### 1. Basics
```bash
sudo apt update
sudo apt install -y git curl
```

### 2. Identity (simple — whole machine is personal)
```bash
git config --global user.name "hsinjlee"
git config --global user.email "rlee4408@gmail.com"
```

### 3. SSH key → GitHub
```bash
ssh-keygen -t ed25519 -C "rlee4408@gmail.com" -f ~/.ssh/id_ed25519_hsinjlee
# press Enter twice (no passphrase)
cat ~/.ssh/id_ed25519_hsinjlee.pub
```
Copy the printed line. In the browser: github.com → avatar → **Settings** → **SSH and GPG keys** → **New SSH key** → Title: `home-ubuntu` → paste → **Add SSH key**.

Then create the SSH shortcut and test it:
```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
cat >> ~/.ssh/config <<'EOF'
Host github.com-hsinjlee
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_hsinjlee
    IdentitiesOnly yes
EOF
chmod 600 ~/.ssh/config

ssh -T git@github.com-hsinjlee
```
✅ Must say: `Hi hsinjlee! You've successfully authenticated...`
(Note: the address uses `github.com-hsinjlee` — the shortcut you just made — not plain `github.com`. Same everywhere below.)

### 4. Clone into Documents
```bash
cd ~/Documents
git clone git@github.com-hsinjlee:hsinjlee/edge-physical-ai-pipeline.git
cd edge-physical-ai-pipeline
```
("empty repository" warning is normal.)
✅ `git config user.email` prints `rlee4408@gmail.com`

### 5. Build the skeleton (paste each block as-is)
Folders:
```bash
mkdir -p firmware/stm32_actuation firmware/esp32_sensor \
         ros2_ws/src perception/models perception/benchmarks \
         policy/lerobot policy/export sim/usd sim/isaac_lab \
         docs scripts docker
find firmware ros2_ws perception policy sim docs docker -type d -exec touch {}/.gitkeep \;
```

.gitignore:
```bash
cat > .gitignore <<'EOF'
build/
install/
log/
*.engine
*.plan
datasets/
*.mp4
__pycache__/
*.pyc
.venv/
firmware/**/build/
*.elf
*.bin
*.hex
.vscode/
EOF
```

README:
```bash
cat > README.md <<'EOF'
# Edge Physical AI Pipeline

End-to-end miniature Physical AI stack:
**ESP32/STM32 (micro-ROS) → Jetson Orin Nano (TensorRT INT8) → ROS 2 → learned policy → real actuators**,
with an Isaac Sim / OpenUSD digital twin.

> Status: setting up. See BUILD_PLAN.md.

## Phases
1. micro-ROS sensor node → Jetson TensorRT inference → ROS 2 topics
2. Camera + quantized perception (detection, monocular depth), INT8/FP16 benchmark report
3. Learned policy on Orin driving physical servos; Isaac Lab sim-to-real via OpenUSD

## Hardware
Jetson Orin Nano · STM32F429ZI · ESP32 · USB camera · hobby servos · RTX 4060 (training)
EOF
```

Identity safety hook (does nothing at home — it ships to the WSL machine, where Session 2 installs it):
```bash
cat > scripts/install-hooks.sh <<'EOF'
#!/bin/sh
hook=".git/hooks/pre-commit"
cat > "$hook" <<'HOOK'
#!/bin/sh
email=$(git config user.email)
case "$email" in
  *redacted*|*Redacted*) echo "BLOCKED: work email on personal repo"; exit 1;;
esac
HOOK
chmod +x "$hook"
echo "hook installed"
EOF
chmod +x scripts/install-hooks.sh
```

Copy in the plan files downloaded from the chat (adjust path if they're elsewhere):
```bash
cp ~/Downloads/BUILD_PLAN*.md .
```

### 6. First push
```bash
git add -A
git commit -m "repo skeleton: structure, plans, gitignore"
git push -u origin main
```
✅ `git log --format='%an <%ae>' -1` prints `hsinjlee <rlee4408@gmail.com>`
✅ Refresh the GitHub page — README shows, commit author is **hsinjlee**.

### 7. Topics (the gear icon appears now that the repo isn't empty)
On the repo page: ⚙️ next to **About** → add topics:
`ros2` `micro-ros` `tensorrt` `jetson` `embedded` `robotics` `physical-ai` `stm32` `esp32` `edge-ai`

### 8. Claude Code
```bash
npm install -g @anthropic-ai/claude-code    # check docs.claude.com if this fails
cd ~/Documents/edge-physical-ai-pipeline
claude
```
Run `/init` inside it, exit, then:
```bash
cat >> CLAUDE.md <<'EOF'

## Standing rules (do not remove)
- Git identity: hsinjlee <rlee4408@gmail.com> ONLY. Never suggest --global git config
  changes on the WSL machine.
- WSL is SOFTWARE-ONLY: no flashing, USB, or camera there. Hardware happens on
  home Ubuntu and the Jetson only.
- I hand-write: micro-ROS node lifecycle/QoS, TensorRT INT8 calibration, policy inference
  loop, safety/watchdog. Claude Code writes: CMake/package.xml, launch files, Dockerfiles,
  benchmark/plotting scripts, docs drafts.
- Never commit *.engine, datasets/, or video files.
EOF
git add CLAUDE.md && git commit -m "claude code context + rules" && git push
```

**Session 1 done. The repo is real, and home is fully connected.**

---

# SESSION 2 — WSL (~20 min)

The WSL machine has BOTH identities, so here we use `~/p` + automatic separation.
Everything under `~/p/` commits as hsinjlee; everything else (e.g. `~/projects`) stays redacted.

```bash
# 1. basics
sudo apt update && sudo apt install -y git curl

# 2. identity autopilot for ~/p (does NOT touch your work git config)
cat > ~/.gitconfig-hsinjlee <<'EOF'
[user]
    name = hsinjlee
    email = rlee4408@gmail.com
EOF
git config --global includeIf.gitdir:~/p/.path ~/.gitconfig-hsinjlee

# 3. new SSH key for this machine (keys don't travel between machines)
ssh-keygen -t ed25519 -C "rlee4408@gmail.com" -f ~/.ssh/id_ed25519_hsinjlee
cat ~/.ssh/id_ed25519_hsinjlee.pub
#    → add on GitHub (incognito browser, signed in as hsinjlee), title: wsl

# 4. SSH shortcut
mkdir -p ~/.ssh && chmod 700 ~/.ssh
cat >> ~/.ssh/config <<'EOF'
Host github.com-hsinjlee
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_hsinjlee
    IdentitiesOnly yes
EOF
chmod 600 ~/.ssh/config
ssh -T git@github.com-hsinjlee        # ✅ must greet: Hi hsinjlee!

# 5. clone into ~/p + install the safety hook
cd ~/p
git clone git@github.com-hsinjlee:hsinjlee/edge-physical-ai-pipeline.git
cd edge-physical-ai-pipeline
./scripts/install-hooks.sh            # ✅ prints: hook installed

# 6. verify BOTH identities on this machine
git config user.email                  # ✅ rlee4408@gmail.com
cd ~/projects/<any-work-repo> && git config user.email   # ✅ redacted@example.com
```

Install Claude Code the same way as Session 1 step 8 — it reads the committed CLAUDE.md automatically, no reconfiguration. WSL done.

---

# LATER — install only when Phase 1 actually needs it

Not setup work — do these the day the build plan calls for them:
- **Home:** `nvidia-smi` check, ARM toolchain (`gcc-arm-none-eabi openocd stlink-tools`), LeRobot venv, Jetson SSH, STM32 blink test
- **Both machines:** Docker + `docker/Dockerfile.dev` for ROS 2 (a good first Claude Code task)
- **Shopping:** USB webcam (~NT$500–1,500), 2× hobby servos + pan-tilt (~NT$300–800)

# DAILY RULE (both machines, forever)
Sit down → `git pull --rebase`. Stand up → `git add -A && git commit -m "wip" && git push`.
