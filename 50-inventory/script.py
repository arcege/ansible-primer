#!/usr/bin/env python3
"""Dynamic inventory from docker with ssh connection plugin.

Inspect the running docker containers, creating an inventory
from that.

* A group are created from the container 'group' label (`add_list_metadata`)
* A ssh connection values (`add_ssh_config`)
* Normalized Docker inventory 'variables' (`normalize_docker_structure`)

Using standard dynamic inventory interface:
* `--list` - show group structure, with '_meta' host vars
* `--host` - show host variables

The SSH private key is in `setup/ssh-key`.  The public key is
installed via `setup/Dockerfile` to ~docker/.ssh/authorized_keys`.
"""

import json
import subprocess
import sys


def empty():
    """Return an empty inventory."""
    return {'_meta': {'hostvars': {}}}


def normalize_hostname(host):
    """Return without leading slash."""
    return host.lstrip('/')


def inspect():
    """Return the docker inspect json as a list."""
    cont_out = subprocess.check_output(
        ('docker', 'ps', '-q'),
    )
    containers = tuple(cont_out.decode('utf-8').rstrip().split('\n'))
    inspected = subprocess.check_output(
        ('docker', 'inspect') + containers
    )
    hostlist = json.loads(inspected)
    assert isinstance(hostlist, list)
    return hostlist


def add_ssh_config(host):
    """Modify the dict to add SSH specific values."""
    # each of these are standard Ansible variables
    host['ansible_host'] = host['NetworkSettings']['IPAddress']
    host['ansible_ssh_user'] = 'docker'
    host['ansible_ssh_port'] = '22'
    host['ansible_ssh_private_key_file'] = 'setup/ssh-key'
    host['ansible_ssh_common_args'] = '-o IdentitiesOnly=yes'


def normalize_docker_structure(host):
    """Converge names to 'docker_' + key.lower()."""
    new = {}
    for key, data in host.items():
        #print(key, data)
        if key.startswith('ansible_'):
            new[key] = data
        else:
            newkey = f'docker_{key.lower()}'
            new[newkey] = data
    return new


def add_list_metadata(inventory, hostlist):
    """Add _meta section to the inventory."""
    meta = inventory['_meta']
    for host in hostlist:
        hostname = normalize_hostname(host['Name'])
        for groupname in determine_groups(host):
            group = inventory.get(groupname, {'hosts': []})
            group['hosts'].append(hostname)
            group['hosts'].sort()
            inventory[groupname] = group
        meta['hostvars'][hostname] = normalize_docker_structure(host)


def add_app_group(inventory):
    """Determine the list of hosts in the 'app' group."""
    app = inventory.get('app', {'hosts': []})
    for groupname in ('group_database', 'group_webapp'):
        if groupname in inventory:
            for hostname in inventory[groupname]['hosts']:
                if hostname not in app:
                    app['hosts'].append(hostname)
    app['hosts'].sort()
    inventory['app'] = app


def determine_groups(host):
    """Return a list of the group names that the host should be a member of."""
    groups = []
    labels = host['Config']['Labels']
    for label in labels:
        if label == 'group':
            groups.append('group_{}'.format(labels[label]))
    return groups


def main():
    """The main routine."""
    inventory = empty()
    hostlist = inspect()
    for host in hostlist:
        add_ssh_config(host)

    add_list_metadata(inventory, hostlist)
    add_app_group(inventory)
    if sys.argv[1] == '--list':
        result = inventory
    elif sys.argv[1] == '--host':
        result = inventory['_meta']['hostvars'][sys.argv[2]]
    json.dump(result, sys.stdout)


if __name__ == '__main__':
    main()
