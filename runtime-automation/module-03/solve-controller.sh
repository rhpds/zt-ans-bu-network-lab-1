#!/bin/bash

# cat > /tmp/setup-scripts/solve_challenege_3.yml << EOF
# - name: solve challenge 3
#   hosts: localhost
#   connection: local
#   gather_facts: false
#   collections:
#     - ansible.controller
#   vars:
#     aap_hostname: localhost
#     aap_username: admin
#     aap_password: ansible123!
#     aap_validate_certs: false
#   tasks:
#     - name: Launch Network Automation - Restore
#       ansible.controller.job_launch:
#         job_template: "Network Automation - Restore"
#         controller_username: "{{ aap_username }}"
#         controller_password: "{{ aap_password }}"
#         controller_host: "https://{{ aap_hostname }}"
#         validate_certs: "{{ aap_validate_certs }}"
#       register: job

# EOF
# sudo su - -c "ANSIBLE_COLLECTIONS_PATH=/root/.ansible/collections/ansible_collections/ /usr/bin/ansible-playbook /tmp/setup-scripts/solve_challenege_3.yml"
