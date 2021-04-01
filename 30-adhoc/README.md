# ADHOC Ansible commands


## The `ansible` command

The format of the command is:

    ansible [options] {host/group} [--module-name module] [--args module-args ...] [--extra-vars lhs=rhs ...]]


The host/group argument can be a combination of hosts and groups,
separated by commas.  There is no default, but the hosts that should
always be present are `all` and `localhost`.  The host group `all`
would include all hosts and all host groups.

Examples:

    # show accessibility of all hosts
    ansible all -m ansible.builtin.ping

    # show system facts of each host
    ansible lesson_30_adhoc -m ansible.builtin.setup

    # show OS family from facts of each host
    ansible lesson_30_adhoc -m ansible.builtin.setup -a filter=ansible_os_family

## Remote command execution

Ansible as three modes for running arbitrary commands on the hosts.

1. 'ansible.builtin.command' - this is similar to fork/exec, commands are parsed as a string
    and executed as a system call; it does not parse or interpret bash variables
    or symbols
1. 'ansible.builtin.shell' - similar to 'command', but the string _is_ interpreted as a shell
    command, with variable and command interpolation
2. 'ansible.builtin.raw' - similar to 'shell', but is executed directly on the host, without
    Ansible processing or return value interpolation; useful when there is no
    Python interpreter installed remotely - yet.

All three return the stdout and stderr, both as single strings and as lists of lines.

Examples:

    # run a command on each host
    ansible lesson_30_adhoc -a id

    # run a bash command (with glob)
    ansible lesson_30_adhoc -m ansible.builtin.shell -a 'ls -d /proc/[0-9]*/'

## Calling modules

The 'ansible' command uses the same processor that 'ansible-playbook' uses to
call and interpret modules running on the hosts.  The results are returned
and displayed as with a playbook.  Host and group variables are accessible,
but not variables from playbooks or roles.

All the modules callable from a playbook can be executed here.  But some are
fairly useless and others are only useful from adhoc commands.

Examples:

    # install a package (failure - no permissions)
    ansible lesson_30_adhoc -m package -a name=redis
    # install a package becoming root user
    ansible lesson_30_adhoc -b -m package -a name=redis

    # enable service (ubuntu fails)
    ansible lesson_30_adhoc -b -m service -a 'enabled=true name=redis'
    # enable service (redhat fails)
    ansible lesson_30_adhoc -b -m service -a 'enabled=true name=redis-server'


# Common ad-hoc only modules

As mentioned above, some modules are only useful when run from the command-line.

* 'ansible.builtin.ping' - check the accesibility of a host
* 'ansible.builtin.setup' - return the system facts of a host
* 'ansible.builtin.command' - while playbooks can certainly use 'command' or 'shell',
  there is little idempotence with those modules, and so they are discouraged; but
  the ad-hoc commands are a perfect use case.
