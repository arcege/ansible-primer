# Inventories

One of the primary components of Ansible is the set of hosts to operate on,
this is called the inventory.

The `ansible-inventory` command interogate the the inventory files, returning
information from the inventory only, not facts from the hosts themselves.

The inventory does not interogate the hosts, but only has access to the
data in the inventory, and what information the dynamic scripts and plugins
access.  This means that while the inventory may have access to AWS EC2
tags and attributes, it would not have access to what packages, services or
users are on the instances.

## Addressing

Ansible has two names for every host:

* `inventory_hostname` - this is the name used by Ansible on the user side;
  for example, in variables, Jinja2 expressions, output
* `ansible_host` - the value used to connect with the host, there may be
  times when this is the same as `inventory_hostname`, but especially for
  dynamic hosts, it would be a less human-useful value

The human-readable name; notice the label matches the output.

    ansible -i 50-inventory/script.py all -m debug -a var=inventory_hostname

The underlying SSH hostname; notice the output is IP addresses.

    ansible -i 50-inventory/script.py all -m debug -a var=ansible_host

## Hosts and host groups

Hosts are more than just names; there are connection settings and variables.
Different hosts may have diffrent SSH keys, logging into different usernames,
possibly even with different connection mechanisms.

Host groups are a set of hosts, possible with shared connection settings and
variables, but are used to perform tasks and roles on a common set of hosts.

Host groups can also include other host groups, creating a hierarchy of groups.

Additionally, hosts can be in othogonal groups, to allow for accumulation of
settings and variables.  For example, groups by OS type and groups by function,
each giving specific settings not supposed by the other

### Example

The first four commands have a very similar organization, with the same hosts
and groups.  The first two have an `app` group that includes groups while
the next two have an `app` group composed only of hosts.  This could be 'fixed'
with additional coding, but here it is showing the differences in organization.

    ansible-inventory -i 50-inventory/static.ini --graph
    ansible-inventory -i 50-inventory/static.yml --graph
    ansible-inventory -i 50-inventory/docker.yml --graph
    ansible-inventory -i 50-inventory/script.py --graph

This last shows a separate inventory, without a file extension, and with just
a single host.  The Ansible name of the host is 'here', but underneath, it is
just localhost.

    ansible-inventory -i 50-inventory/localhost --graph

### Default groups

There are two implied groups: `all` and `ungrouped`.  The second is not
required to be accurate.  But all hosts and groups should be a member of the
`all` group.  It is useful when wanting to exclude hosts, for example
`all:!group_dns`.

### Usage

The hosts and groups are used by the `ansible` and `ansible-playbook` commands
to determine the set of hosts to perform modules against.

Each command has the `--list-hosts` option, which shows the hosts in each
play that would be included.

    ansible -i 50-inventory/static.yml all --list-hosts
    ansible -i 50-inventory/static.ini all --list-hosts
    ansible -i 50-inventory/docker.yml all --list-hosts
    ansible -i 50-inventory/script.py all --list-hosts
    ansible -i 50-inventory/localhost all --list-hosts

    ansible -i 50-inventory/docker.yml group_webapp:dns01 --list-hosts
    ansible -i 50-inventory/static.yml 'all:!group_database' --list-hosts

## Host and group variables

Variables can be associated with certain host or group.
As with play and role variables and with facts, host and group variables
are accessed through the host.  But the differences is that these values
are divorced from any of the code.

### Inline variables

Inside the inventory files, variables can be defined.  The `install_dir`
variable in `50-inventory/static.yml` shows such a setting.

    ansible -i 50-inventory/static.yml group_webapp -m debug -a var=install_dir

Systems that do not have the variable defined will not be 'defined'.

### `host_vars` and `group_vars`

Alongside the inventory, there could be `host_vars/` and/or `group_vars/`
directories, the contents are yaml files that contain similar variables.
The files would be named by the hostname in `host_vars/` and the group
name in `group_vars/`.

The `--host` option of will show the host and group variables.

    ansible-inventory -i 50-inventory/static.yml --host  webapp1
    ansible-inventory -i 50-inventory/docker.yml --host  webapp1

As the dynamic inventory can interogate more information, that can be
included in the host variables.

### Examples

The `debug` module will emit the value of a variable for us, so we can take
advantage.

Hosts where the variable was not included will be undefined.

    ansible -i 50-inventory/static.yml all -m debug -a var=site

Using different inventory can give different results.

    ansible -i 50-inventory/static.yml all -m debug -a var=port
    ansible -i 50-inventory/static.ini all -m debug -a var=port

The `master` variable is defined for only the `dns11` in `hosts_vars/dns11.yml`.

    ansible -i 50-inventory/static.yml group_dns -m debug -a var=master

The `ns` variable is an inline group variable in `static.yml`.

    ansible -i 50-inventory/static.yml group_dns -m debug -a var=ns
    ansible -i 50-inventory/static.ini group_dns -m debug -a var=ns
    ansible -i 50-inventory/docker.yml group_dns -m debug -a var=ns

### Accessing other hosts variable.

All the host variables are kept in a structure called `hostvars`.  It is a dict
indexed by the host names in the inventory.  Initially, it is the values from the
inline variables, host\_vars and group\_vars.  After execution, it would be merged
with values from the play and roles and command-line options.

    ansible -i 50-inventory/static.yml webapp1 -m debug -a var=hostvars.webapp1
    ansible -i 50-inventory/static.yml webapp1 -m debug -a var=hostvars.dbsvr1
    ansible -i 50-inventory/static.yml localhost -m debug -a var=hostvars

## Types of inventory files

There are different types of inventories.

* ini - the original format, still used and useful for simple subsets as it
  is clear, concise and easily maintained
* yaml - the new standard for static inventories
* host\_list - a comma-separated string of hosts, useful on the command-line;
  e.g. `-i localhost,`
* plugin - included code to generate dynamic inventories
* script - a program that generates JSON of hosts and groups
* constructed - yaml that uses Jinja2/Ansible expressions
* directory - a directory that contains inventory files, combined into a single
  inventory

## Static vs dynamic

Static inventories list the hosts and group and variables associations.  This is not
scalable for cloud resources, but if there are a limited number of resources with
static IP or hostnames, then using a static inventory is sufficient.

Once there are dynamic servers, like in docker, docker compose, swarm, AWS EC2,
Azure VM, GCP instances, then it becomes harder to track them in static inventories.

Older forms of dynamic inventories used scripts (see `script.py`) to return the
host data and list associations.

Newer inventory plugins allow a yaml file to control what and how to populate the
inventory.  For example, getting instances that match a certain tag, grouping based
on another tag.  This is especially useful when working with thousands of instances.

### Inventory plugins

There are a wide range of plugins to get dynamic inventory.  For example, AWS EC2
instances, Azure VMs, Docker containers, Kubernetes containers, Gitlab runners.

A YAML control file will direct the plugin to get and organize the information it needs.

Plugins will generally use external authentication systems that the underlying systems
normally uses, so special set up often 

### Dynamic scripts

As opposed to an inventory plugin, a dynamic script will, generally, explicitly
interogate a single service to access external resources, to populate the hosts.

Two options are required:
* `--list`  - show the group organization of the hosts, optionally, also the host
information is included.
* '--host {hostname}` - show the host information

The result is a JSON object.

## Multiple inventories

Inventories are orgnaized in files and directories.  Individual files would
use a single inventory plugin, depending on the parsed file type.  Directories
can include other inventories, including subdirectories.

Inventories can be organized by environment, for example, by 'dev' or 'prod'.

    ansible-inventory -i 50-inventory --list

## Connection methods

Connection methods are used for connecting the Ansible process with the hosts.
The default is to use SSH (or Paramiko), but the methods used in these lessons are
'local' and 'docker-api'.

The `local` connection method uses fork/exec on the calling server.  The docker API
is used by the 'community.docker.docker_api` connection method.

### Using the `ssh` connection method

The host is expected to have sshd running on it, the public key installed with the
connection user.

    ansible -i 50-inventory/script.py all -a id  # all should fail with connection refused
    ansible -i 50-inventory/docker.yml all -b -m service -a 'name=sshd state=started'  # start sshd
    ansible -i 50-inventory/script.py all -a id  # all should return string from `id(1)`
    ansible -i 50-inventory/script.py all -a 'ls -la .ssh'
