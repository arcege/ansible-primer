# Variables

## Namespaces

While they aren't called namespaces, Ansible has an integral namespace: the
host.  All variables are loaded into the hosts' variables by a (rather large)
set of precedence (read more in the Ansible docs).  Variables can hold strings,
numbers, dicts, lists and `null` or be undefined.

While there is only namespace, there are different kinds of variables.

* facts
* task vars (arguments)
* host/group vars
* play/rule vars
* command-line vars and files

## Setting variables

When Ansible starts, variables are loaded from the inventory, host and group
vars, external variables, etc.  These are loaded into the host namespace.
Thereafter, they are not normally updated.

The first playbook shows different methods of setting a variable.

    ansible-playbook 20-variables/variables.yml

The first play, Play variables, shows a play variable, `app`.
The second play, Play varsfile, loads the `app` variable from a file before
the play starts.
The third play, Play include\_vars, loads the variable from a file, but as
a task.

The First come play looks at multiple files; the first one found is loaded.
With the `include_vars` task, there are three different files to search file,
The search is based on host facts.

The last two pull variables from the inventory's host and group vars files,
`inventory/host_vars/` and `inventory/group_vars`.  These are loaded
automatically when Ansible is first started.

Once Ansible has started, there are generally only two means of the code to
set a variable, not including scoped extents:

## Registers

Registers capture the tasks metadata and results of the tasks.  Each task has
its own metadata to include, but there are standard values.

* `changed` (bool) - did the task make a change to yield the expected state
* `failed` (bool) - did the task fail
* `skipped` (bool, optional) - was the task skipped

Setting registers is through the task attribute `register`.

    ansible-playbook 20-variables/register.yml

For spawning modules like `command`, there are `stdout` and `stderr`, with
accompanying `*_lines` values and a `rc` value.

The result of the `stat` module includes a dict with the `stat(1)` results,
including `exists`.

When performing loops on a task, the `results` is a list of the result of each
task in the loop.  This results list can then be passed as a `loop` variable.


## Facts

Facts are loaded by the `setup` module, which is executed by default on
plays, unless the play has `gather_facts: false`.  The `facts.yml` playbook
shows two runs both with and without facts being gathered.  Without, the
standard facts are all undefined; with, they are defined.

    ansible-playbook 20-variables/facts.yml -e gather=false
    ansible-playbook 20-variables/facts.yml -e gather=true


## Changing variables

The `set_fact` module will change a variable/fact on a host.  This is not
used often, but is useful when data needs to be transformed.

It is also useful for accumulating values into a single variable, such as in
a loop.

    ansible-playbook 20-variables/set-fact.yml

Any variable can be changed, including the predefined variables that Ansible
uses internally.  For example, changing `ansible_host` can lead to undesirable
results.

    ansible-playbook 20-variables/overwrite-hostname.yml

## Filters

Filters are Jinja2 routines that transform data being passed through the
string interpolation.  These are a simple as string manipulation to as complex
as transforming data structures.

A simple form is `{{ value | filer }}`.  These can be chained together.

    ansible-playbook 20-variables/filters.yml

Sometimes it becomes necessary for filters to be used.  In the last two
examples in the `filters.yml` playbook,  a bash shell `ls` command on a string
that contains spaces.

Without quoting, the shell splits the string on the
whitespace.  To prevent that, the string needs to be quoted.

The first,
unquoted task will return three entries: file, with, spaces.

The second,
quoted task will return one entry: "file with spaces".

Using the filter allows
the quoting delimiter to be applied independent of the command.  Notice the
`cmd` and `stdout_lines` results.
