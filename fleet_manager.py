"""Fleet Manager: cross-platform interactive hardening & deployment helper.

This script recreates the functionality of the original fleet.sh bash script in
Python to increase portability across Unix-like systems and provide clearer
logging and error handling. It manages configuration, onboarding, deployment,
and rollback tasks for Ansible-driven hardening.
"""
from __future__ import annotations

import json
import os
import platform
import shutil
import subprocess
import sys
from dataclasses import dataclass
from getpass import getpass
from pathlib import Path
from typing import Dict, List

CONFIG_FILE = Path.cwd() / ".fleet_config.json"
PROJECT_DIR = Path.cwd() / "ansible-hardening-fleet"


class Colors:
    BLUE = "\033[0;34m"
    GREEN = "\033[0;32m"
    RED = "\033[0;31m"
    YELLOW = "\033[1;33m"
    RESET = "\033[0m"

    @staticmethod
    def wrap(text: str, color: str) -> str:
        return f"{color}{text}{Colors.RESET}"


# -- LOGGING HELPERS --

def log_info(message: str) -> None:
    print(f"{Colors.wrap('[INFO]', Colors.BLUE)} {message}")


def log_success(message: str) -> None:
    print(f"{Colors.wrap('[OK]', Colors.GREEN)} {message}")


def log_warn(message: str) -> None:
    print(f"{Colors.wrap('[WARN]', Colors.YELLOW)} {message}")


def log_error(message: str) -> None:
    print(f"{Colors.wrap('[ERROR]', Colors.RED)} {message}")


@dataclass
class FleetConfig:
    ansible_pub_key: str
    ts_auth_key: str

    @classmethod
    def load(cls) -> "FleetConfig":
        if CONFIG_FILE.exists():
            with CONFIG_FILE.open("r", encoding="utf-8") as config_fp:
                raw = json.load(config_fp)
                return cls(
                    ansible_pub_key=raw.get("ansible_pub_key", ""),
                    ts_auth_key=raw.get("ts_auth_key", ""),
                )

        log_warn("No configuration found. Running first-time setup.")
        ensure_ssh_key()
        ansible_pub_key = (Path.home() / ".ssh" / "id_ed25519.pub").read_text("utf-8").strip()
        ts_auth_key = prompt_secret("Enter your Tailscale auth key (tskey-auth-...): ")

        config = cls(ansible_pub_key=ansible_pub_key, ts_auth_key=ts_auth_key)
        config.save()
        log_success(f"Configuration written to {CONFIG_FILE}")
        return config

    def save(self) -> None:
        CONFIG_FILE.write_text(
            json.dumps(
                {"ansible_pub_key": self.ansible_pub_key, "ts_auth_key": self.ts_auth_key},
                indent=2,
            )
            + "\n",
            encoding="utf-8",
        )


# -- CORE HELPERS --

def prompt_secret(prompt: str) -> str:
    value = getpass(prompt)
    while not value.strip():
        log_error("A value is required.")
        value = getpass(prompt)
    return value


def ensure_ssh_key() -> None:
    ssh_dir = Path.home() / ".ssh"
    ssh_key = ssh_dir / "id_ed25519"
    ssh_pub = ssh_dir / "id_ed25519.pub"

    if ssh_pub.exists():
        return

    log_warn("No SSH key found. Generating a new ed25519 key pair...")
    ssh_dir.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        ["ssh-keygen", "-t", "ed25519", "-f", str(ssh_key), "-N", ""],
        check=True,
    )
    log_success(f"SSH key created at {ssh_key}")


def check_dependencies() -> None:
    required_commands: Dict[str, str] = {
        "ansible": "Ansible (ansible)",
        "sshpass": "sshpass",
        "git": "git",
        "curl": "curl",
        "python3": "Python 3",
    }
    missing: List[str] = [label for cmd, label in required_commands.items() if shutil.which(cmd) is None]
    if missing:
        log_error("Missing dependencies: " + ", ".join(missing))
        if platform.system() == "Windows":
            log_warn("Install the dependencies via WSL or your package manager before continuing.")
        else:
            log_warn("Try: sudo apt-get update && sudo apt-get install -y ansible sshpass git curl python3")
        sys.exit(1)


# -- TASKS --

def init_project() -> None:
    if PROJECT_DIR.exists():
        log_info(f"Using existing project directory: {PROJECT_DIR}")
        return

    log_error("Project directory not found. Run your installation bootstrap to provision it.")
    sys.exit(1)


def run_remote_onboarding(config: FleetConfig) -> None:
    target_ip = input("Enter the IP address of the target server: ").strip()
    if not target_ip:
        log_error("Target IP is required.")
        return

    remote_pass = prompt_secret(f"Root password for {target_ip}: ")
    log_info(f"Starting onboarding for {target_ip}...")

    ssh_cmd = [
        "sshpass",
        "-p",
        remote_pass,
        "ssh",
        "-o",
        "StrictHostKeyChecking=no",
        "-t",
        f"root@{target_ip}",
        "bash -s",
    ]

    onboarding_script = f"""
set -e
export DEBIAN_FRONTEND=noninteractive

apt-get update -qq >/dev/null
apt-get install -y python3 sshpass curl >/dev/null

if ! id "ansible_svc" >/dev/null 2>&1; then
  useradd -m -s /bin/bash ansible_svc
  echo "ansible_svc ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ansible_init
  chmod 0440 /etc/sudoers.d/ansible_init
fi

mkdir -p /home/ansible_svc/.ssh
echo "{config.ansible_pub_key}" > /home/ansible_svc/.ssh/authorized_keys
chown -R ansible_svc:ansible_svc /home/ansible_svc/.ssh
chmod 700 /home/ansible_svc/.ssh
chmod 600 /home/ansible_svc/.ssh/authorized_keys

if ! command -v tailscale >/dev/null 2>&1; then
  curl -fsSL https://tailscale.com/install.sh | sh
fi
if ! tailscale status >/dev/null 2>&1; then
  tailscale up --auth-key="{config.ts_auth_key}" --ssh --accept-routes --hostname="svr-$(hostname)"
fi
""".strip()

    subprocess.run(["ssh-keygen", "-R", target_ip], check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    try:
        subprocess.run(ssh_cmd, input=onboarding_script, text=True, check=True)
    except subprocess.CalledProcessError as exc:
        log_error(f"Onboarding failed: {exc}")
        return

    log_success("Onboarding completed. Verify the new Tailscale IP and add it to your inventory.")


def run_ansible_playbook(playbook: str) -> None:
    init_project()
    inventory = PROJECT_DIR / "inventory" / "staging" / "hosts.yml"
    if not inventory.exists():
        log_error(f"Inventory file not found at {inventory}")
        return

    cmd = ["ansible-playbook", "-i", str(inventory), str(PROJECT_DIR / "playbooks" / playbook)]
    try:
        subprocess.run(cmd, check=True)
        log_success(f"Playbook '{playbook}' completed successfully.")
    except subprocess.CalledProcessError as exc:
        log_error(f"Playbook execution failed: {exc}")


def edit_inventory() -> None:
    init_project()
    inventory = PROJECT_DIR / "inventory" / "staging" / "hosts.yml"
    editor = os.environ.get("EDITOR") or ("nano" if platform.system() != "Windows" else "notepad")
    log_info(f"Opening inventory with {editor}...")
    subprocess.run([editor, str(inventory)])


def reset_config() -> None:
    if CONFIG_FILE.exists():
        CONFIG_FILE.unlink()
        log_success("Configuration cleared. Restart the script to reconfigure.")
    else:
        log_warn("No configuration file to remove.")


def main() -> None:
    check_dependencies()
    config = FleetConfig.load()

    actions = {
        "1": ("Onboard new server (Root -> Ansible + Tailscale)", lambda: run_remote_onboarding(config)),
        "2": ("Run hardening (Ansible deploy)", lambda: run_ansible_playbook("site.yml")),
        "3": ("Update inventory", edit_inventory),
        "4": ("Emergency rollback", lambda: run_ansible_playbook("rollback.yml")),
        "5": ("Reset config (delete keys)", reset_config),
        "0": ("Exit", lambda: sys.exit(0)),
    }

    while True:
        print(f"\n{Colors.wrap('=== FLEET COMMANDER ===', Colors.BLUE)}")
        for key, (desc, _) in actions.items():
            print(f"{key}. {desc}")

        choice = input("Choice: ").strip()
        action = actions.get(choice)
        if action:
            action[1]()
        else:
            log_warn("Invalid choice. Please try again.")


if __name__ == "__main__":
    main()
