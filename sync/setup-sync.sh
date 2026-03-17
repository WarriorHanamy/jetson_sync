#!/usr/bin/env bash
#
# Setup lsyncd auto-sync service for zuanfeng-deploy
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

CONFIG_DIR="${HOME}/.config/zuanfeng-sync"
SERVICE_NAME="zuanfeng-sync"

fn_nv_load_env
DEFAULT_DEVICE_IP="${DEVICE_IP}"
DEFAULT_DEVICE_USER="${DEVICE_USER}"
DEFAULT_SSH_KEY="${SSH_KEY}"
DEFAULT_SOURCE_FOLDER="${SOURCE_FOLDER}"
DEFAULT_DEVICE_TARGET_FOLDER="${DEVICE_TARGET_FOLDER}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

check_lsyncd() {
    if ! command -v lsyncd &>/dev/null; then
        log_warn "lsyncd not found. Installing..."
        sudo apt update && sudo apt install -y lsyncd
        log_info "lsyncd installed"
    else
        log_info "lsyncd already installed: $(lsyncd --version 2>&1 | head -1)"
    fi
}

check_ssh() {
    log_step "Testing SSH connection to ${DEVICE_USER}@${DEVICE_IP}..."
    if [[ ! -f "${SSH_KEY}" ]]; then
        log_error "SSH key not found: ${SSH_KEY}"
        return 1
    fi
    NV_SSH_EXTRA_OPTS=(-o BatchMode=yes -o ConnectTimeout=5)
    fn_nv_reset_ssh
    fn_nv_ensure_ssh
    if ! fn_nv_check_ssh; then
        log_warn "Cannot connect to ${DEVICE_USER}@${DEVICE_IP}, copying SSH key..."
        "${SCRIPT_DIR}/copy_ssh_key.sh"
        fn_nv_reset_ssh
        fn_nv_ensure_ssh
        if ! fn_nv_check_ssh; then
            log_error "SSH key copy succeeded but still cannot connect"
            return 1
        fi
    fi
    log_info "SSH connection OK"
}

ensure_sudoer() {
    log_step "Checking passwordless sudo..."
    NV_SSH_EXTRA_OPTS=(-o BatchMode=yes -o ConnectTimeout=5)
    fn_nv_reset_ssh
    fn_nv_ensure_ssh
    if "${SSH_CMD[@]}" "sudo -n true" 2>/dev/null; then
        log_info "Passwordless sudo already enabled"
        return 0
    fi
    log_warn "Passwordless sudo not enabled, running raise_sudoer.sh..."
    "${SCRIPT_DIR}/raise_sudoer.sh"
    fn_nv_reset_ssh
    fn_nv_ensure_ssh
    if ! "${SSH_CMD[@]}" "sudo -n true" 2>/dev/null; then
        log_error "Failed to enable passwordless sudo"
        return 1
    fi
    log_info "Passwordless sudo enabled"
}

ensure_remote_dir() {
    log_step "Ensuring remote directory exists..."
    NV_SSH_EXTRA_OPTS=(-o BatchMode=yes -o ConnectTimeout=5)
    fn_nv_reset_ssh
    fn_nv_ensure_ssh
    "${SSH_CMD[@]}" "mkdir -p ${DEVICE_TARGET_FOLDER}"
    log_info "Remote directory ready: ${DEVICE_TARGET_FOLDER}"
}

create_config_dir() {
    log_step "Creating config directory..."
    mkdir -p "$CONFIG_DIR"
}

generate_env_file() {
    log_step "Generating environment file..."
    cat > "${CONFIG_DIR}/env" << EOF
DEVICE_IP=${DEVICE_IP}
DEVICE_USER=${DEVICE_USER}
SSH_KEY=${SSH_KEY}
SOURCE_FOLDER=${SOURCE_FOLDER}
DEVICE_TARGET_FOLDER=${DEVICE_TARGET_FOLDER}
EOF
    log_info "Environment file: ${CONFIG_DIR}/env"
}

generate_lsyncd_config() {
    log_step "Generating lsyncd configuration..."
    cp "${SCRIPT_DIR}/lsyncd.conf.lua" "${CONFIG_DIR}/lsyncd.conf.lua"
    log_info "lsyncd config: ${CONFIG_DIR}/lsyncd.conf.lua"
}

install_systemd_service() {
    log_step "Installing systemd user service..."
    local service_dir="${HOME}/.config/systemd/user"
    mkdir -p "$service_dir"
    cp "${SCRIPT_DIR}/${SERVICE_NAME}.service" "${service_dir}/"
    systemctl --user daemon-reload
    log_info "Service installed: ${service_dir}/${SERVICE_NAME}.service"
}

enable_service() {
    log_step "Enabling and starting service..."
    systemctl --user enable "${SERVICE_NAME}"
    systemctl --user start "${SERVICE_NAME}"
    sleep 1
    if systemctl --user is-active --quiet "${SERVICE_NAME}"; then
        log_info "Service started successfully"
    else
        log_error "Service failed to start. Check logs: journalctl --user -u ${SERVICE_NAME}"
        return 1
    fi
}

show_status() {
    echo ""
    echo "=========================================="
    echo -e "${GREEN}Zuanfeng Auto-Sync Setup Complete${NC}"
    echo "=========================================="
    echo ""
    systemctl --user status "${SERVICE_NAME}" --no-pager || true
    echo ""
    echo "Commands:"
    echo "  Stop:     systemctl --user stop ${SERVICE_NAME}"
    echo "  Restart:  systemctl --user restart ${SERVICE_NAME}"
    echo "  Logs:     tail -f /tmp/zuanfeng-sync.log"
    echo "  Config:   ${CONFIG_DIR}/env"
    echo ""
}

show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Setup lsyncd auto-sync service for zuanfeng-deploy.

Options:
    -h, --help                     Show this help message
    --device-ip IP                 Override DEVICE_IP
    --device-user USER             Override DEVICE_USER
    --ssh-key PATH                 Override SSH_KEY
    --source-folder PATH           Override SOURCE_FOLDER
    --device-target-folder PATH    Override DEVICE_TARGET_FOLDER
    --uninstall                    Remove the sync service
EOF
}

uninstall() {
    log_step "Uninstalling zuanfeng-sync service..."
    systemctl --user stop "${SERVICE_NAME}" 2>/dev/null || true
    systemctl --user disable "${SERVICE_NAME}" 2>/dev/null || true
    rm -f "${HOME}/.config/systemd/user/${SERVICE_NAME}.service"
    systemctl --user daemon-reload
    log_info "Service uninstalled"
    log_info "Config directory preserved: ${CONFIG_DIR}"
    log_info "To fully remove: rm -rf ${CONFIG_DIR}"
}

main() {
    local do_uninstall=0

    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            --device-ip)
                DEVICE_IP="$2"
                shift 2
                ;;
            --device-user)
                DEVICE_USER="$2"
                shift 2
                ;;
            --ssh-key)
                SSH_KEY="$2"
                shift 2
                ;;
            --source-folder)
                SOURCE_FOLDER="$2"
                shift 2
                ;;
            --device-target-folder)
                DEVICE_TARGET_FOLDER="$2"
                shift 2
                ;;
            --uninstall)
                do_uninstall=1
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    if [[ "$do_uninstall" -eq 1 ]]; then
        uninstall
        exit 0
    fi

    fn_nv_reset_ssh
    echo "Source: ${SOURCE_FOLDER}"
    echo "Target: ${DEVICE_USER}@${DEVICE_IP}:${DEVICE_TARGET_FOLDER}"
    echo ""

    check_lsyncd
    check_ssh
    ensure_sudoer
    ensure_remote_dir
    create_config_dir
    generate_env_file
    generate_lsyncd_config
    install_systemd_service
    enable_service
    show_status
}

main "$@"
