#!/usr/bin/env bash
set -euo pipefail
# KStudio runtime setup - first-time Termux bootstrap + per-language toolchains
# Usage: bash install.sh [--all] [--lang python|node|rust|go|java|kotlin|c|cpp|dart|html|bash|php]
detect() {
  if command -v termux-info >/dev/null 2>&1; then echo termux
  elif [ "$(uname -s)" = "Darwin" ]; then echo macos
  else echo linux; fi
}
PLATFORM=$(detect)
echo "[KStudio] platform=$PLATFORM"
BASE="nodejs git curl netcat-openbsd python openjdk-17 ripgrep openssh"

setup_base() {
  if [ "$PLATFORM" = "termux" ]; then
    pkg update -y || true
    # shellcheck disable=SC2086
    pkg install -y $BASE
    termux-setup-storage 2>/dev/null || true
  elif [ "$PLATFORM" = "linux" ]; then
    sudo apt-get update -y || true
    sudo apt-get install -y nodejs npm git curl netcat-openbsd python3 python3-pip openjdk-17-jdk ripgrep
  elif [ "$PLATFORM" = "macos" ]; then
    brew install node git curl netcat python openjdk@17 ripgrep || true
  fi
  pip install --user git-pnp 2>/dev/null || pip3 install --user git-pnp 2>/dev/null || true
  mkdir -p ~/.kstudio ~/KStudioProjects
}

setup_lang() {
  case "$1" in
    python) pkg install -y python pyright 2>/dev/null || sudo apt-get install -y python3 pyright 2>/dev/null || true
      pip install --upgrade pyright debugpy ruff 2>/dev/null || pip3 install --upgrade pyright debugpy ruff 2>/dev/null || true ;;
    node) pkg install -y nodejs 2>/dev/null || true
      npm i -g typescript typescript-language-server vscode-langservers-extracted 2>/dev/null || sudo npm i -g typescript typescript-language-server 2>/dev/null || true ;;
    rust) pkg install -y rust rust-analyzer lldb 2>/dev/null || sudo apt-get install -y rustc cargo rust-analyzer 2>/dev/null || true ;;
    go) pkg install -y golang gopls dlv 2>/dev/null || sudo apt-get install -y golang gopls 2>/dev/null || true ;;
    java) pkg install -y openjdk-17 jdtls 2>/dev/null || sudo apt-get install -y openjdk-17-jdk 2>/dev/null || true ;;
    kotlin) pkg install -y kotlin kotlin-language-server openjdk-17 2>/dev/null || sudo apt-get install -y kotlin 2>/dev/null || true ;;
    c|cpp) pkg install -y clang clangd make gdb 2>/dev/null || sudo apt-get install -y clang clangd make gdb 2>/dev/null || true ;;
    dart) pkg install -y dart 2>/dev/null || true; echo "flutter: install SDK manually, then flutter doctor" ;;
    html) npm i -g vscode-langservers-extracted 2>/dev/null || true ;;
    bash) pkg install -y bash shellcheck 2>/dev/null || true; npm i -g bash-language-server 2>/dev/null || true ;;
    php) pkg install -y php 2>/dev/null || sudo apt-get install -y php 2>/dev/null || true; npm i -g intelephense 2>/dev/null || true ;;
  esac
}

setup_ksterm() {
  REPO="${KSTUDIO_REPO:-Nudoleda/kstudio-setup}" # public installer repo (app source stays private)
  KSTERM_JAR="$HOME/.kstudio/ksterm.jar"
  if [ ! -f "$KSTERM_JAR" ]; then
    echo "[KStudio] downloading ksterm.jar"
    curl -fL -o "$KSTERM_JAR" "https://github.com/$REPO/releases/latest/download/ksterm.jar" \
      || echo "manual: build :ksterm:fatJar and copy ksterm.jar to ~/.kstudio/"
  fi
  if [ ! -f ~/.kstudio/token ]; then head -c 32 /dev/urandom | base64 > ~/.kstudio/token; fi
  export KSTERM_TOKEN=$(cat ~/.kstudio/token); export KSTERM_PORT=8767
  cp ./ksterm/ks-exthost.js ~/.kstudio/ks-exthost.js 2>/dev/null || \
    curl -fsSL "https://raw.githubusercontent.com/$REPO/main/ksterm/ks-exthost.js" -o ~/.kstudio/ks-exthost.js 2>/dev/null || true
  # 'ksterm' launcher on PATH — type ksterm in Termux, exactly like dsterm
  BIN_DIR="$PREFIX/bin"
  if [ "$PLATFORM" = "linux" ]; then BIN_DIR="$HOME/.local/bin"; mkdir -p "$BIN_DIR"; fi
  if [ "$PLATFORM" = "macos" ]; then BIN_DIR="/usr/local/bin"; fi
  cat > "$BIN_DIR/ksterm" <<'EOF'
#!/usr/bin/env bash
# KStudio bridge server — usage: ksterm  (then Verify in the app)
if pgrep -f ksterm.jar >/dev/null 2>&1; then
  echo "[KStudio] ksterm already running on port ${KSTERM_PORT:-8767} — open the app and Verify."
  exit 0
fi
export KSTERM_TOKEN="$(cat ~/.kstudio/token 2>/dev/null)"
export KSTERM_PORT="${KSTERM_PORT:-8767}"
exec java -jar ~/.kstudio/ksterm.jar "$@"
EOF
  chmod +x "$BIN_DIR/ksterm" 2>/dev/null || sudo cp "$BIN_DIR/ksterm" /usr/local/bin/ksterm 2>/dev/null || true
  echo "[KStudio] starting ksterm..."
  pkill -f ksterm.jar 2>/dev/null || true
  nohup java -jar "$KSTERM_JAR" >/dev/null 2>&1 &
  sleep 1
}

case "${1:-}" in
  --lang) setup_base; setup_lang "${2:-python}"; setup_ksterm ;;
  --all) setup_base; for l in python node rust go java kotlin c cpp dart html bash php; do setup_lang "$l"; done; setup_ksterm ;;
  *) setup_base; setup_ksterm ;;
esac
node --version 2>/dev/null || true; git --version 2>/dev/null || true; java -version 2>/dev/null || true
echo "[KStudio] done. Type: ksterm   (starts the bridge, like dsterm)"
echo "[KStudio] then in the app tap Verify setup. Your token: $(cat ~/.kstudio/token)"
echo "[KStudio] Open KStudio app: Projects -> Support -> Check support. Missing items offer Yes/No auto-install."
