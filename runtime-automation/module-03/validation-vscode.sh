#!/bin/bash

tee /home/rhel/check_challenege_2.yml << EOF
---
- name: snmp ro/rw string configuration
  hosts: cisco
  gather_facts: no

  tasks:

    - name: ensure that the desired snmp strings are present
      check_mode: True
      cisco.ios.config:
        commands:
          - snmp-server community ansible-public RO
          - snmp-server community ansible-private RW
          - snmp-server community ansible-test RO
      register: snmpstatus

    - name: run commnad to tell instruqt what to do
      ansible.builtin.fail:
        msg: "SNMP configuration was not applied - please try again or use SKIP"
      when: snmpstatus.changed == True
EOF

sudo chown rhel:rhel /home/rhel/check_challenege_2.yml

su - rhel -c 'ansible-navigator run /home/rhel/check_challenege_2.yml --mode stdout'

if [ $? -eq 0 ]; then
    echo OK
else
    echo "SNMP configuration was not applied - please try again or use SKIP"
fi