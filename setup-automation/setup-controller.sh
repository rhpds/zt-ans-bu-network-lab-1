#!/bin/bash

USER=rhel

## --------------------------------------------------------------
## Create sudoers using playbook
## --------------------------------------------------------------
cat > /tmp/create_sudoers_user.yml << EOF
---
- name: Setup sudoers
  hosts: localhost
  become: true
  gather_facts: false
  vars:
    ansible_become_password: ansible123!
  tasks:
    - name: Create sudo file
      copy:
        dest: /etc/sudoers.d/rhel_sudoers
        content: "%rhel ALL=(ALL:ALL) NOPASSWD:ALL"
        owner: root
        group: root
        mode: 0440
EOF
/usr/bin/ansible-playbook /tmp/create_sudoers_user.yml
# remove seetup playbook
rm /tmp/create_sudoers_user.yml

# --------------------------------------------------------------
# Setup lab assets
# --------------------------------------------------------------
# Write a new playbook to create a template from above playbook
cat > /home/rhel/playbook.yml << EOF
---
- name: setup controller for network use cases
  hosts: localhost
  gather_facts: true
  become: true
  vars:

    username: admin
    admin_password: ansible123!

  tasks:

    - name: ensure controller is online and working
      uri:
        url: https://localhost/api/v2/ping/
        method: GET
        user: "{{ username }}"
        password: "{{ admin_password }}"
        validate_certs: false
        force_basic_auth: true
      register: controller_online
      until: controller_online is success
      delay: 3
      retries: 5

    - name: create inventory
      awx.awx.inventory:
        name: "Network Inventory"
        organization: "Default"
        controller_username: "{{ username }}"
        controller_password: "{{ admin_password }}"
        controller_host: "https://{{ ansible_host }}"
        validate_certs: false      
      register: workshop_inventory
      until: workshop_inventory is success
      delay: 3
      retries: 5

    - name: Add cisco host
      awx.awx.host:
        name: cisco
        description: "ios-xe csr running on GCP"
        inventory: "Network Inventory"
        state: present
        controller_username: "{{ username }}"
        controller_password: "{{ admin_password }}"
        controller_host: "https://{{ ansible_host }}"
        validate_certs: false      
        variables:
            ansible_network_os: ios
            ansible_user: ansible
            ansible_connection: network_cli
            ansible_become: true
            ansible_become_method: enable

    - name: Add backup server host
      awx.awx.host:
        name: "backup-server"
        description: "this server is where we backup network configuration"
        inventory: "Network Inventory"
        state: present
        controller_username: "{{ username }}"
        controller_password: "{{ admin_password }}"
        controller_host: "https://{{ ansible_host }}"
        validate_certs: false      
        variables:
            note: in production these passwords would be encrypted in vault
            ansible_user: rhel
            ansible_password: ansible123!
            ansible_host: "{{ ansible_default_ipv4.address }}"
            ansible_become_password: ansible123!

    - name: Add group
      awx.awx.group:
        name: "network"
        description: "Network Group"
        inventory: "Network Inventory"
        state: present
        validate_certs: false      
        hosts:
          - cisco
        controller_username: "{{ username }}"
        controller_password: "{{ admin_password }}"
        controller_host: "https://{{ ansible_host }}"

    - name: Add network machine credential
      awx.awx.credential:
        name: "Network Credential"
        organization: "Default"
        credential_type: Machine
        controller_username: "{{ username }}"
        controller_password: "{{ admin_password }}"
        controller_host: "https://{{ ansible_host }}"
        validate_certs: false      
        inputs:
          ssh_key_data: "{{ lookup('file', '/root/.ssh/private_key') }}"

    - name: Add controller credential
      awx.awx.credential:
        name: "AAP controller credential"
        organization: "Default"
        credential_type: Red Hat Ansible Automation Platform
        controller_username: "{{ username }}"
        controller_password: "{{ admin_password }}"
        controller_host: "https://{{ ansible_host }}"
        validate_certs: false      
        inputs:
          host: "{{ ansible_default_ipv4.address }}"
          password: "ansible123!"
          username: "admin"
          verify_ssl: false

    - name: Add project
      awx.awx.project:
        name: "Network Toolkit"
        scm_url: "https://github.com/network-automation/toolkit"
        scm_type: git
        organization: "Default"
        scm_update_on_launch: False
        scm_update_cache_timeout: 60
        controller_username: "{{ username }}"
        controller_password: "{{ admin_password }}"
        controller_host: "https://{{ ansible_host }}"
        validate_certs: false

    - name: Add EE to the controller instance
      awx.awx.execution_environment:
        name: "network workshop execution environment"
        image: "quay.io/acme_corp/network-ee:aap24b"
        validate_certs: false
        controller_username: "{{ username }}"
        controller_password: "{{ admin_password }}"
        controller_host: "https://{{ ansible_host }}"

EOF
cat /home/rhel/playbook.yml
# /usr/bin/ansible-playbook /home/rhel/playbook.yml

# --------------------------------------------------------------
# set ansible-navigator default settings
# --------------------------------------------------------------
cat >/home/$USER/ansible-navigator.yml <<EOL
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
# set environment
# --------------------------------------------------------------
# Fixes an issue with podman that produces this error: "Error: error creating tmpdir: mkdir /run/user/1000: permission denied"
loginctl enable-linger $USER

# Creates playbook artifacts dir
mkdir /home/$USER/playbook-artifacts


# --------------------------------------------------------------
# configure ssh
# --------------------------------------------------------------
# Creates ssh dir
mkdir /home/$USER/.ssh

tee /home/rhel/.ssh/config << EOF
Host *
     StrictHostKeyChecking no
     User ansible
EOF


# --------------------------------------------------------------
# create ansible.cfg
# --------------------------------------------------------------
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


