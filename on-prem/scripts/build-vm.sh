#!/usr/bin/env bash
# Build or rebuild a Terraform-managed VM, then configure and verify it. Run on mgmt01.
set -euo pipefail

HOST="${1:?usage: build-vm.sh <host> [--rebuild]}"
REBUILD="${2:-}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ANSIBLE="$ROOT/ansible"
TF="$ROOT/terraform/proxmox"
ADDR="proxmox_virtual_environment_vm.$HOST"
PLAN="$(mktemp --suffix=.tfplan)"
LOG="$(mktemp)"
trap 'rm -f "$PLAN" "$LOG"' EXIT

step() { printf '\n==> %s\n' "$1"; }
fail() { echo "FAIL: $1" >&2; exit 1; }

grep -qs "\"proxmox_virtual_environment_vm\" \"$HOST\"" "$TF"/*.tf || fail "no VM resource named $HOST in $TF"
IP="$(cd "$ANSIBLE" && ansible-inventory --host "$HOST" | python3 -c 'import json,sys; print(json.load(sys.stdin)["ansible_host"])')"

step "Base images"
(cd "$ANSIBLE" && ansible-playbook playbooks/images.yml)

step "Plan"
args=(-out="$PLAN" -input=false -detailed-exitcode)
[[ $REBUILD == --rebuild ]] && args+=(-replace="$ADDR")
rc=0
terraform -chdir="$TF" plan "${args[@]}" || rc=$?
case $rc in
  0) echo "No infrastructure changes." ;;
  2)
    read -rp "Apply this plan? [y/N] " ok
    [[ $ok == [yY] ]] || fail "plan not approved"
    created="$(terraform -chdir="$TF" show -json "$PLAN" | python3 -c 'import json,sys; p=json.load(sys.stdin); print(any(r["address"] == sys.argv[1] and "create" in r["change"]["actions"] for r in p.get("resource_changes", [])))' "$ADDR")"
    terraform -chdir="$TF" apply -input=false "$PLAN"
    if [[ $created == True ]]; then ssh-keygen -R "$IP" >/dev/null 2>&1 || true; fi
    ;;
  *) fail "terraform plan" ;;
esac

step "Configure"
(cd "$ANSIBLE" && ansible-playbook playbooks/site.yml --limit "$HOST" --diff)

step "Idempotency"
(cd "$ANSIBLE" && ansible-playbook playbooks/site.yml --limit "$HOST") | tee "$LOG"
grep -qE "^$HOST +: .*changed=0 " "$LOG" || fail "second run changed something"

step "Drift"
terraform -chdir="$TF" plan -detailed-exitcode -input=false >/dev/null || fail "Terraform reports drift"

step "$HOST built and verified"
