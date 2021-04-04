# Limiting execution

To avoid resourse starvation, Ansible executes hosts in batches.

If, for example, there are 6 hosts in a node pool, for a rolling
update, we only want a third to be changed at one time

## Limit hosts

The `ansible` and `ansible-playbook` commands both have a `--limit` option
which runs the tasks on a subset of the hosts, but host or host group.

This is not the same as limiting the number of workers (see batching below)
but limits the overall hosts to perform on based.

Limits work on hosts, groups, patterns or a combination.

## Batching

The default number of hosts in a batch is five (5).

This can be controlled in a number of ways, from the command line and
from attributes in the code.

### Serial

Similar to forks, a play can specify how many hosts are in the batch.  The
entire play would complete before moving to the next batch.

    - name: Rolling update
      hosts: webservers
      serial: 50%

The `serial` attribute can take a number, a percentage or a list of either.

    - name: Creeping rollout
      hosts: webservers
      serial:
        - 1
        - 33%
        - 100%


### Throttling

A single tasks can also throttle the execution even further.

    - name:
      command: some-cpu-intensive-command
      throttle: 2

### Forks

Forks limits the number of workers a task performs.  Tasks in a play
are performed in sequence normally.

There are 10 servers in this lesson.  Run the command below and notice
the number of servers that return together.

    ansible limits -a 'sleep 3'

Now change the number of hosts in the batch using `--fork`.

    ansible limits -f 3 'sleep 3'


### Run once

Lastly, there may be situations where only one host should perform
an operation, for example, initializing a database.  The `run_once`
attribute will perform the tasks once per batch.


## Rolling releases

The idea that hosts can be run in batches lends itself well to how
the `serial` and `run_once` attributes work.

Assume there are 10 servers that need Ansible and nginx updated.  Additionally
assume that the hosts to be updated need to be removed from the load balancer during
the upgrade.  Only on call needs to be made for each batch.

    ansible-playbook 75-limits/rolling.yml


