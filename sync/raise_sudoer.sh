#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

NV_SSH_EXTRA_OPTS=(-tt)
fn_nv_ensure_ssh

fn_nv_run_remote_bash_script <<EOF
echo '${DEVICE_PASSWD}' | sudo -S sed -i 's/^Defaults.*use_pty$/#&/' /etc/sudoers

echo '${DEVICE_PASSWD}' | sudo -S sh -c "printf '%s\n' '${DEVICE_USER} ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/${DEVICE_USER}"

echo '${DEVICE_PASSWD}' | sudo -S chmod 440 /etc/sudoers.d/${DEVICE_USER}
EOF
