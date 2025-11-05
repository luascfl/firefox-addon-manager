#!/usr/bin/env bash
set -euo pipefail

# Optional argument: path to the prepared XPI package
XPI_SRC="${1:-$HOME/Downloads/addon-manager/addon-manager-firefox.xpi}"

if [[ ! -f "$XPI_SRC" ]]; then
  echo "XPI not found at: $XPI_SRC" >&2
  exit 1
fi

declare -A seen_realpath=()
declare -a browser_execs=()
declare -a browser_names=()
declare -a browser_realpaths=()

add_browser() {
  local exec_path="$1"
  local browser_name="$2"
  [[ -x "$exec_path" ]] || return
  local real_path
  real_path=$(readlink -f "$exec_path")
  if [[ -n "${seen_realpath[$real_path]:-}" ]]; then
    return
  fi
  seen_realpath["$real_path"]=1
  if [[ -z "$browser_name" ]]; then
    if [[ "$real_path" == *librewolf* ]]; then
      browser_name="librewolf"
    else
      browser_name="firefox"
    fi
  fi
  browser_execs+=("$exec_path")
  browser_names+=("$browser_name")
  browser_realpaths+=("$real_path")
}

while IFS= read -r path; do
  add_browser "$path" "firefox"
done < <(command -v -a firefox 2>/dev/null || true)

while IFS= read -r path; do
  add_browser "$path" "librewolf"
done < <(command -v -a librewolf 2>/dev/null || true)

for candidate in \
  /usr/lib/firefox/firefox /usr/lib/firefox/firefox.sh \
  /usr/lib64/firefox/firefox /snap/bin/firefox \
  /usr/lib/librewolf/librewolf /opt/librewolf/librewolf \
  /usr/share/librewolf/librewolf
do
  [[ -e "$candidate" ]] && add_browser "$candidate" ""
done

if [[ ${#browser_execs[@]} -eq 0 ]]; then
  echo "No Firefox or LibreWolf installations were found." >&2
  exit 1
fi

echo "Detected browser installations:"
declare -a display_options=()
for idx in "${!browser_execs[@]}"; do
  exec_path="${browser_execs[$idx]}"
  real_path="${browser_realpaths[$idx]}"
  browser_name="${browser_names[$idx]}"
  if ! version=$("$exec_path" --version 2>/dev/null | head -n 1); then
    version="Unknown version"
  fi
  version=${version//$'\n'/ }
  display_options+=("$((idx + 1))). $version [$browser_name] (exec: $exec_path -> $real_path)")
  echo "${display_options[-1]}"
done

echo
while true; do
  read -rp "Select the browser to manage (1-${#browser_execs[@]}): " selection
  if [[ "$selection" =~ ^[0-9]+$ ]] && (( selection >= 1 && selection <= ${#browser_execs[@]} )); then
    selected_index=$((selection - 1))
    break
  fi
  echo "Invalid selection. Please enter a number between 1 and ${#browser_execs[@]}."
done

BROWSER_BIN="${browser_execs[$selected_index]}"
BROWSER_NAME="${browser_names[$selected_index]}"
REAL_BIN="${browser_realpaths[$selected_index]}"

if ! BROWSER_VERSION=$("$BROWSER_BIN" --version 2>/dev/null | head -n 1); then
  BROWSER_VERSION="Unknown version"
fi
echo
echo "Chosen browser:"
echo "  $BROWSER_VERSION"
echo "  Executable: $BROWSER_BIN"
echo "  Real path : $REAL_BIN"
echo

case "$REAL_BIN" in
  /snap/firefox/*)
    POLICY_DIR="/var/snap/firefox/common/policies"
    INSTALL_DIR="/var/snap/firefox/common/managed-extensions"
    ;;
  *)
    INSTALL_DIR="/opt/firefox-policies"
    if [[ "$BROWSER_NAME" == "librewolf" ]]; then
      if [[ -d /usr/share/librewolf/distribution ]]; then
        POLICY_DIR="/usr/share/librewolf/distribution"
      else
        POLICY_DIR="/usr/lib/librewolf/distribution"
      fi
    else
      if [[ -d /usr/lib/firefox/distribution ]]; then
        POLICY_DIR="/usr/lib/firefox/distribution"
      elif [[ -d /usr/share/firefox/distribution ]]; then
        POLICY_DIR="/usr/share/firefox/distribution"
      else
        POLICY_DIR="/usr/lib/firefox/distribution"
      fi
    fi
    ;;
esac

POLICY_JSON="$POLICY_DIR/policies.json"
POLICY_TMP=$(mktemp)
INSTALL_TARGET="$INSTALL_DIR/addon-manager-firefox.xpi"
INSTALL_URL="file://${INSTALL_TARGET}"

echo "Applying policy to $BROWSER_VERSION"
echo "Binary path         : $REAL_BIN"
echo "Policy directory    : $POLICY_DIR"
echo "Managed XPI location: $INSTALL_TARGET"
echo

sudo install -d -m 755 "$POLICY_DIR"
sudo install -d -m 755 "$INSTALL_DIR"
sudo install -m 644 "$XPI_SRC" "$INSTALL_TARGET"

export POLICY_JSON POLICY_TMP INSTALL_URL
python3 <<'PY'
import json
import os
import sys

policy_path = os.environ["POLICY_JSON"]
tmp_path = os.environ["POLICY_TMP"]
install_url = os.environ["INSTALL_URL"]
addon_id = "addon-manager@luascfl"

data = {"policies": {}}
if os.path.exists(policy_path):
    try:
        with open(policy_path, "r", encoding="utf-8") as fh:
            existing = json.load(fh)
        if isinstance(existing, dict):
            data = existing
        else:
            print(f"Existing {policy_path} does not contain a JSON object at the top level.", file=sys.stderr)
            sys.exit(1)
    except json.JSONDecodeError as exc:
        print(f"Existing {policy_path} is not valid JSON: {exc}", file=sys.stderr)
        sys.exit(1)

policies = data.setdefault("policies", {})
ext_settings = policies.setdefault("ExtensionSettings", {})
ext_settings[addon_id] = {
    "installation_mode": "force_installed",
    "install_url": install_url,
    "updates_disabled": False,
}
wildcard = ext_settings.get("*")
if isinstance(wildcard, dict):
    wildcard.setdefault("installation_mode", "allowed")
else:
    ext_settings["*"] = {"installation_mode": "allowed"}

with open(tmp_path, "w", encoding="utf-8") as fh:
    json.dump(data, fh, indent=2, sort_keys=True)
    fh.write("\n")
PY

sudo mv "$POLICY_TMP" "$POLICY_JSON"
sudo chmod 644 "$POLICY_JSON"

echo "Policy written to $POLICY_JSON"
echo "Restart $BROWSER_NAME and open about:policies → Active to confirm it loaded."
