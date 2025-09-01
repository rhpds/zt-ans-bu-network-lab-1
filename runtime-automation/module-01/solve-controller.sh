#!/bin/bash

# ansible-playbook /tmp/setup-scripts/network-lab-1/solution_challenge_1.yml

tee /home/rhel/solve_challenege_1.yml << EOF
---
- name: solve challenge 1
  hosts: localhost
  gather_facts: false
  become: true
  tasks:

    - name: Create network backup job template
      awx.awx.job_template:
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
        controller_config_file: "/tmp/setup-scripts/controller.cfg"

EOF

sudo chown rhel:rhel /home/rhel/solve_challenege_1.yml

su - rhel -c 'ansible-playbook /home/rhel/solve_challenege_1.yml'