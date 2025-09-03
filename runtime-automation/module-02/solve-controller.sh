#!/bin/bash

# ansible-playbook /tmp/setup-scripts/network-lab-1/solution_challenge_2.yml

cat > /tmp/setup-scripts/solve_challenege_2.yml << EOF
---
- name: solve challenge 2
  hosts: localhost
  connection: local
  collections:
    - ansible.controller
  vars:
    aap_hostname: localhost
    aap_username: admin
    aap_password: ansible123!
    aap_validate_certs: false
  tasks:

    - name: Create network backup job template
      ansible.controller.job_template:
        name: "Network Automation - Backup"
        job_type: "run"
        organization: "Default"
        inventory: Network Inventory
        project: "Network Toolkit"
        playbook: "playbooks/network_backup.yml"
        credentials:
          - "Network Credential"
          - "AAP controller credential"
        state: "present"
        extra_vars:
          restore_inventory: "Network Inventory"
          restore_project: "Network Toolkit"
          restores_playbook: "playbooks/network_restore.yml"
          restore_credential: "Network Credential"
        controller_username: "{{ aap_username }}"
        controller_password: "{{ aap_password }}"
        controller_host: "https://{{ aap_hostname }}"
        validate_certs: "{{ aap_validate_certs }}" 

    - name: Launch Network Automation - Backup
      ansible.controller.job_launch:
        job_template: "Network Automation - Backup"
        controller_username: "{{ aap_username }}"
        controller_password: "{{ aap_password }}"
        controller_host: "https://{{ aap_hostname }}"
        validate_certs: "{{ aap_validate_certs }}"
      register: job

EOF
sudo su - -c "ANSIBLE_COLLECTIONS_PATH=/root/.ansible/collections/ansible_collections/ /usr/bin/ansible-playbook /tmp/setup-scripts/solve_challenege_2.yml"
