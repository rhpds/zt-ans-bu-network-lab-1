#!/bin/bash

USER=rhel

# --------------------------------------------------------------
# Reconfigure code-server
# --------------------------------------------------------------
sudo su - -c 'systemctl stop firewalld'
sudo su - -c 'systemctl stop code-server'
mv /home/rhel/.config/code-server/config.yaml /home/rhel/.config/code-server/config.bk.yaml

cat >/home/rhel/.config/code-server/config.yaml << EOF
bind-addr: 0.0.0.0:8080
auth: none
cert: false
disable-update-check: true
EOF

cat >/home/$USER/.local/share/code-server/User/settings.json <<EOL
{
  "git.ignoreLegacyWarning": true,
  "window.menuBarVisibility": "visible",
  "git.enableSmartCommit": true,
  "workbench.tips.enabled": false,
  "workbench.startupEditor": "readme",
  "telemetry.enableTelemetry": false,
  "search.smartCase": true,
  "git.confirmSync": false,
  "workbench.colorTheme": "Solarized Dark",
  "update.showReleaseNotes": false,
  "update.mode": "none",
  "ansible.ansibleLint.enabled": false,
  "ansible.ansible.useFullyQualifiedCollectionNames": true,
  "files.associations": {
      "*.yml": "ansible",
      "*.yaml": "ansible"
  },
  "files.exclude": {
    "**/.*": true
  },
  "files.watcherExclude": {
    "**": true
  },
  "files.watcherExclude": {
    "**": true
  },
  "security.workspace.trust.enabled": false,
  "redhat.telemetry.enabled": false,
  "ansibleLint.enabled": false,
  "ansible.validation.lint.enabled": false,
  "ansible.validation.enabled": false,
  "ansible.lightspeed.enabled": false,
  "ansible.lightspeed.suggestions.enabled": false
  "python.useEnvironmentsExtension": false
}
EOL
cat /home/$USER/.local/share/code-server/User/settings.json

sudo su - -c 'systemctl start code-server'


# --------------------------------------------------------------
# set ansible-navigator default settings
# --------------------------------------------------------------
cat >/home/$USER/ansible-navigator.yml <<EOL
---
ansible-navigator:
  ansible:
    inventory:
      entries:
        - /home/rhel/hosts
  execution-environment:
    container-engine: podman
    enabled: true
    image: quay.io/acme_corp/network-ee
    pull:
      policy: missing
  logging:
    level: debug
  playbook-artifact:
    save-as: /home/rhel/playbook-artifacts/{playbook_name}-artifact-{time_stamp}.json

EOL
cat /home/$USER/ansible-navigator.yml

# --------------------------------------------------------------
# create inventory hosts file
# --------------------------------------------------------------
cat > /home/rhel/hosts << EOF
cisco ansible_connection=network_cli ansible_network_os=ios ansible_become=true ansible_user=admin ansible_password=ansible123!
vscode ansible_user=rhel ansible_password=ansible123!
EOF
cat  /home/rhel/hosts

# --------------------------------------------------------------
# create ansible.cfg
# --------------------------------------------------------------
cat > /home/rhel/ansible.cfg << EOF
[defaults]
# stdout_callback = yaml
connection = smart
timeout = 60
deprecation_warnings = False
action_warnings = False
system_warnings = False
host_key_checking = False
collections_on_ansible_version_mismatch = ignore
retry_files_enabled = False
interpreter_python = auto_silent
[persistent_connection]
connect_timeout = 200
command_timeout = 200
EOF
cat /home/rhel/ansible.cfg


# --------------------------------------------------------------
# set environment
# --------------------------------------------------------------
# Fixes an issue with podman that produces this error: "Error: error creating tmpdir: mkdir /run/user/1000: permission denied"
sudo su - -c 'loginctl enable-linger $USER'

# Creates playbook artifacts dir
mkdir /home/$USER/playbook-artifacts

# --------------------------------------------------------------
# configure ssh
# --------------------------------------------------------------
mkdir /home/$USER/.ssh
cat >/home/rhel/.ssh/config << EOF
Host *
     StrictHostKeyChecking no
     User ansible
EOF
cat /home/rhel/.ssh/config


exit 0