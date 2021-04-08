# Debugging Ansible playbooks

Note: this lesson will tend to use the SSH connections more than the native docker.
There are shadow inventory entries for the docker containers, all starting with "s-",
with the SSH connection method.  Meaning that 'debugging-svr1' and 's-debugging-svr1'
are the same host, but using different connection plugins.

## Ping

The `ping` module will do nothing more than attempt to connect to the host and get
a "pong" message back.  This makes for a good diagnostics tool for detecting issues.

## Verbosity

The `--verbose` option will show increasing internal states dealing with
the tasks.  The option can appear multiple times, so it is often useful
to use `-vv` or `-vvv`.

As the verbosity increases, actions like the ssh command used and the module
arguments passed can be shown more explicitly.

### `no_log`

At times, the output of a task may be very large and that output would
be uninteresting.  The `no_log` task attribute would prevent such output
in verbose mode.

The task below may return 500 or 1 million values.  We wouldn't care about
the logged output, only the result in the `company_ids.results` register value.
However, with an optional `debug` task, the files could be saved locally.

    - name: Really big command looking for the result
      run_once: true
      no_log: false
      community.postgresql.postgresql_query:
        query: "SELECT name FROM users"
      register: db_usernames

    - name: Save usernames to a file only when debugging
      delegate_to: localhost
      tags:
        - never
        - debug
      ansible.builtin.copy:
        content: "{{ db_usernames | join('\n') }}\n"
        dest: "/tmp/db_usernames.txt"

The `no_log` task attribute is also useful for security.  To prevent a
task from inadvertently emitting a password, token or other secret.

## Check mode

The `--check` option tells Ansible to run the modules in what is called
"check mode." It is a dry-run for the task: act like the module would
perform to get to the desired state and return the appopriate states
('changed', 'failed', 'skipped', etc.) and return any information it
may have, like the stat(2) information of a file.

Not all modules honor check mode, it may be difficult to perform a dry-run
operation, for example a POST to a REST API.  Even fewer modules, like `command`,
running in check mode does not make sense.  For those, it is often useful to
toggle the check mode state of the task based on the execution check mode.

    - name: Remove from the load-balancer
      when: not ansible_check_mode
      ansible.builtin.command: "lbapp remove {{ ansible_host | quote }}"

### Always run in check mode

There are times when calling the `command` module, for example, might never
change the system, but its result is required for later tasks, even in check mode.
In this situation the `check_mode` task attribute could be set to `false`.  Ansible
relies on the developer to ensure that changes are not made.

## Diff

Many modules will calculate the difference between the initial and desired state.
For example, when starting a service, it would show if the service needed to be
restarted or if it was already running.

When used with `--check` this can be a good, real dry run operation.

There are situations where diff may give too much output.  For those tasks, diff
can be disabled.

    - name: A lot of changes
      when: nologin.stat.exists
      diff: false
      ansible.builtin.replace:
        path: /etc/my-really-long-passwd-file
        regexp: ":/bin/false$"
        replace: ":/usr/sbin/nologin"

# Common problems

Most problems deal with how Ansible connects with the hosts or how variables
and filters are interacting with tasks, roles and other variables.

## Connection issues

Include `-vvv` to see the SSH command command being used for each task.  Running
this from the shell can help determine issues with unreachable servers.

If there is a problem with a single server, it can help to call the `ping` adhoc
module against that server or group.

    ansible group_ssh_svrs --one-line -m ping

From there, you can determine the connection string with `-vvv` for a specific host.

    ansible -vvv s-debugging-svr5  -m ping
    ssh -vv -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o setup/ssh-key docker@172.17.0.2 uptime  # one of the suceessful hosts
    ssh -vv -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i setup/ssh-key docker@172.17.0.6 uptime  # use the IP from the ping command

There may be situations where the connection string may be different between
`ansible` and `ansible-playbook`, but adhoc ping is a good starting place.

In the case of svr5, the sshd service is disabled and not started.  Log into the server manually and start the service.

    docker exec debugging-svr5 sudo systemctl start sshd
    ansible s-debugging-svr5 -m ping

## Remote user

Espectially with cloud system, ensure that the connection user is correct.  With
ssh, this would be the `ansible_ssh_user`.

    ansible s-debugging-svr4 -m ping

This may need to be changed for some hosts.  That can be handled as a host var.

    echo ansible_ssh_user: ansible > inventory/host_vars/s-debugging-svr3.yml
    ansible s-debugging-svr4  -m ping

## Python executable

Ansible runs with Python on both the control host (where `ansible` or `ansible-playbook` is run) and the target hosts.  A common misconception is that Ansible needs to be installed on the target hosts.  In fact, only Python needs to be installed.

However, on a system where Python is not installed, this could lead to problems.

    ansible s-debugging-svr3 -m ping

From an earlier less, the `raw` module does _not_ use Python to execute the commands.  This allows Ansible to install Python - without Python.

    ansible s-debugging-svr3 -m raw -a 'sudo apt-get install -y python3-minimal'
    ansible s-debugging-svr3 -m ping

