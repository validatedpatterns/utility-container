#!/bin/bash
# Wrapper script for ansible-playbook that sets ANSIBLE_STDOUT_CALLBACK when needed
if [ "${ANSIBLE_STDOUT_CALLBACK}" = "null" ]; then
	export ANSIBLE_STDOUT_CALLBACK="rhvp.cluster_utils.readable"
fi
export ANSIBLE_INVENTORY_UNPARSED_WARNING=False
exec /usr/local/bin/ansible-playbook.orig "$@"
