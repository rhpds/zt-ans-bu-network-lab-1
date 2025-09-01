#!/bin/bash

USER=rhel

# --------------------------------------------------------------
# Host subscription with satellite
# --------------------------------------------------------------
curl -k  -L https://${SATELLITE_URL}/pub/katello-server-ca.crt -o /etc/pki/ca-trust/source/anchors/${SATELLITE_URL}.ca.crt
update-ca-trust
rpm -Uhv https://${SATELLITE_URL}/pub/katello-ca-consumer-latest.noarch.rpm
subscription-manager register --org=${SATELLITE_ORG} --activationkey=${SATELLITE_ACTIVATIONKEY}
setenforce 0

# --------------------------------------------------------------
# Setup Sudoers 
# --------------------------------------------------------------
echo "%rhel ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/rhel_sudoers
chmod 440 /etc/sudoers.d/rhel_sudoers

# --------------------------------------------------------------
# Setup SSH key
# --------------------------------------------------------------
sudo -u rhel mkdir -p /home/rhel/.ssh
sudo -u rhel chmod 700 /home/rhel/.ssh
sudo -u rhel rm -rf /home/rhel/.ssh/id_rsa*
sudo -u rhel ssh-keygen -t rsa -b 4096 -C "rhel@$(hostname)" -f /home/rhel/.ssh/id_rsa -N ""
sudo -u rhel chmod 600 /home/rhel/.ssh/id_rsa*

# --------------------------------------------------------------
# Reconfigure VS codeserver
# --------------------------------------------------------------
systemctl stop firewalld
systemctl stop code-server
mv /home/rhel/.config/code-server/config.yaml /home/rhel/.config/code-server/config.bk.yaml

su - $USER -c 'cat >/home/rhel/.config/code-server/config.yaml << EOF
bind-addr: 0.0.0.0:8080
auth: none
cert: false
EOF'

systemctl start code-server

# --------------------------------------------------------------
# Setup lab assets
# --------------------------------------------------------------
# Write a new playbook to create a template from above playbook
su - $USER -c 'cat > /home/rhel/playbook.yml << EOF
---
- name: snmp ro/rw string configuration
  hosts: cisco
  gather_facts: no

  tasks:

    - name: ensure that the desired snmp strings are present
      cisco.ios.config:
        commands:
          - snmp-server community ansible-public RO
          - snmp-server community ansible-private RW

EOF
cat /home/rhel/playbook.yml'

# Write a new playbook to create a template from above playbook
su - $USER -c 'cat > /home/rhel/debug.yml << EOF
---
- name: print debug
  hosts: localhost
  gather_facts: no
  connection: local

  tasks:

    - name: ensure that the desired snmp strings are present
      ansible.builtin.debug:
        msg: "print to terminal"

EOF
cat /home/rhel/debug.yml'


su - $USER -c 'cat > /home/rhel/hosts << EOF
cisco ansible_connection=network_cli ansible_network_os=ios ansible_become=true ansible_user=admin ansible_password=ansible123!
vscode ansible_user=rhel ansible_password=ansible123!
EOF
cat  /home/rhel/hosts'

# set vscode default settings
su - $USER -c 'cat >/home/$USER/.local/share/code-server/User/settings.json <<EOL
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
  "window.autoDetectColorScheme": true,
  "security.workspace.trust.enabled": false
}
EOL
cat /home/$USER/.local/share/code-server/User/settings.json'

# set ansible-navigator default settings
su - $USER -c 'cat >/home/$USER/ansible-navigator.yml <<EOL
---
ansible-navigator:
  ansible:
    inventories:
    - /home/$USER/hosts
  execution-environment:
    container-engine: podman
    image: ee-supported-rhel8
    enabled: True
    pull-policy: never

  playbook-artifact:
    save-as: /home/rhel/playbook-artifacts/{playbook_name}-artifact-{ts_utc}.json

  logging:
    level: debug

EOL
cat /home/$USER/ansible-navigator.yml'

# Fixes an issue with podman that produces this error: "Error: error creating tmpdir: mkdir /run/user/1000: permission denied"
su - $USER -c 'loginctl enable-linger $USER'

# Creates playbook artifacts dir
su - $USER -c 'mkdir /home/$USER/playbook-artifacts'

# Creates playbook artifacts dir
su - $USER -c 'mkdir /home/$USER/.ssh'

cat >/home/rhel/.ssh/id_rsa <<EOF
-----BEGIN OPENSSH PRIVATE KEY-----
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
-----END OPENSSH PRIVATE KEY-----
EOF

chmod 600 /home/rhel/.ssh/id_rsa

sudo chown rhel:rhel /home/rhel/.ssh/id_rsa


tee /home/rhel/.ssh/config << EOF
Host *
     StrictHostKeyChecking no
     User ansible
EOF

sudo chown rhel:rhel /home/rhel/.ssh/config

tee /home/rhel/ansible.cfg << EOF
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

/usr/local/bin/ansible-playbook /home/rhel/debug.yml
