# Playbooks

For most provisioning, playbooks will be the starting place for all
Ansible work.  Playbooks give the what, which, when and where.

_Playbooks_ are YAML files that contain plays, plays then contain tasks
or roles.

_Hosts_ and _Hostgroups_ are Ansible perorms the plays, tasks and roles against.
Hostnames are arbitrary in the _inventory_, but keeping them different from the
real hostname can lead to confusion.  Groups allow for not just organizing the
plays, but also setting variables - one group may use port 8888 while another uses
8889.

_Plays_ are a collection of tasks and roles to be performed on a set
of hosts.  You can have multiple plays inside a playbook.

_Tasks_ are descrete operations to be performed on a host.  Tasks call
a module, but also define conditionals, loops, metadata and more.

_Roles_ are the equivalent of a Chef recipe or a functional procedure.
They are composed of tasks, variables, handlers, templates and files.
They can be called multiple times with different imputs.

_Variables_ are storage locations for data.  There are two types of
variables, global and host specific.

---
Author's note: There is little point to the playbooks as a whole, except to show
various parts of the playbook and how they work together.

---

### Names

With the exception of handlers, the name of playbooks, plays and tasks are _only_
for human consumption.  It can be any string with any content.  It can also include
(templated) variables.  The name can help more correctly identify the task being
performed, especially when there are multiple in succession.  Otherwise tasks are

The `notify` task attribute must match the name of a handler.  This is the only
time the `name` attribute is required.

### Hosts

The `hosts` is a sequence of hosts or groups.  Seperation delimitors are semi-colons,
commas and exclaimation points.  Semi-colons and commas are equivalent.  An
exclaimation point excludes hosts from the sequence.  For example:

   firewalls,load-balancers:!debian

This would be all the firewall and load-balancer hosts, except the hosts in the debian
group.

### Tasks

The `tasks` is a list of tasks.  At a minimum, a task needs to specify a module name
that would be called.  Modules will have attributes and the task may have attributes
itself.

Attributes of the module are defined with the modules and are specific to each. There
some standard attributes that are common, but are not required.  The most common is
`state` with the disposition of either 'present' or 'absent'.

#### Progression

Tasks step through the list in sequence.  When a host fails in a task, then that host does
not progress.  A play ends when the end is reached or all hosts have failed.

Tasks are 'changed', 'skipped', 'failed' or 'ok', per host.

In the `flow.yml` playbook, with the "Who am i" and "Run grep" tasks, there are `changed_when` attributes set to false, meaning that the 'changed' condition will never be true for each host on those tasks.
In the `plays.yml` playbook, the 'Force python3 to be installed' task uses the output of the program to determine if the result is 'changed'.

#### Task attributes

Modifiers to the tasks include progression disposition, privilege escalation, workflow.

Generally, most hosts are not being accessed through an account with direct 'root'
privileges.  The `become` attribute is, usually, an implicit `sudo` call.  So,
`become: true` will run the tasks with elevated privileges.

Other attributes like `when` and `loop` (or `with_*`) handle flow control.

### Modules

A module is an atomic operation executed on a host.  It will have inputs, passed to the
remote execution, and the output is available as a structure through _registers_.
Registers are just variables with additional metadata about the task.  Like other
registers are per host.

### Facts

At the begining of each play, Ansible probes each host in the play for _facts_.  Facts
are discoverable values.  The standard facts include, the hostname, networking,
OS metadata, storage, memory, etc.  This is handle implicitly using the `setup` module.

See the adhoc lesson for more information.

### Connections

Ansible uses connection plugins to connect with a host.  The default connection is
'ssh', generally using the SSH agent.  There are other connection plugins, like
'local' and 'docker'.

The 'ssh' connection plugin uses SSH public keys on the remote hosts and the private
keys locally.

The local calling server would normally use 'ssh', but using 'local' connection would spawn
modules using fork/exec.  See the `inventory/localhost` file.

Note: the hosts in these lessons are Docker containers and use the 'docker' plugin.  The
localhost uses the 'local' plugin.
