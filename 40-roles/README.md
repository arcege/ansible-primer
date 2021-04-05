# Roles

Like recipes are to Chef, roles are integral to complex provisioning.  Ask with tasks,
roles operate per host.

## Encapsulated provisioning

Roles allow changes to be made as a unit, with variables passed to allow
for changes.

## Variables

The scope and extend of variables inside the role are only for the duration of the role.
Passing values out of a role is through facts.


## Structure

By default, Ansible will attempt to find a `main.yml` file in the sub-directores
(with some exceptoins).

* `defaults/main.yml` - variables that are expecting to be overriden by the caller
* `files/` - files are raw data, accessible to many modules without pathnames
* `handlers/main.yml` - registered handlers 
* `meta/main.yml` - metadata required for Ansible Galaxy
* `tasks/main.yml` - tasks to be performed
* `templates/` - Jinja2 templates, with the `template` module
* `vars/` - vars files, usually loaded explicitly with `include_vars` without
  pathnames

### Tasks

Like in a play, the tasks are sequentially executed for each host.  Like in a play,
hosts that fail halt execution for that host (handlers are still executed at the end
of the play).

Often, the `include_tasks` or `import_tasks` modules are used to load tasks from other
files in the `tasks/` dircetory.  Variables can be used to determine which file to
load.

    - name: Load OS specific tasks
      include_tasks: "{{ ansible_os_family }}.yml"

On RedHat systems, this would attempt to load and execute the tasks in
`tasks/RedHat.yml`.  On Ubuntu, `tasks/Ubuntu.yml` would be loaded
and executed.

### Defaults

Default values are very important as the role should not require all the values be
specified by the caller.  These values have the lowest precedence, but can be very
useful when used in conjuntion with other variables and using _filters_ to narrow
the desired value.

    software_url: https://raw.githubusercontent.com/Org/Project/releases/{{ version }}/project_{{ ansible_machine }}.zip

This uses the `version` variable, coming from the caller, and `ansible_machine` is a
gathered fact from the host.  In the role tasks, only `software_url` needs to be used.
While it won't likely be overridden by the caller, it is possible.

### Vars

The difference between vars and defaults is nuanced.  Most defaults could be vars without
affecting the precendence rules.

The `include_vars` module will look for files only in `vars/`.  There could be multiple
files in the directory that are accessible.

For defaults, the only file processed is `defaults/main.yml`.

### Handlers

Tasks notify handlers defined in `handlers/main.yml`.  Handlers are run at the end of the
calling play, not at the end of the role.  If roles are being called multiple times,
then special handling needs to be made, as only one registered by name.  This means that
some cleanup may not occur.

### Templates

Ansible uses Jinja2 through-out, but there is a `template` module which takes a file
from the `templates/` directory and uploads it to the host(s) with interpolation.

### Files

Similar to the `template` module, the `copy` module uses files in the `files/` directory, copying them to the host.  Data is not interpolated.

Other modules will use files here as well, such as `unarchive` and `patch`.

## Roles vs tasks

The example playbook, `playbook.yml` shows two plays, one using a role under `roles`, and another with an `import_role` task.  Both call the role in the same way and if the play is simple, then either is
fine.

Except mixing `roles` and `tasks` must be managed more carefully.  Tasks under `tasks` are always run after all the roles in `roles`.  As the next example illustrates:

    ansible-playbook 40-roles/task-order.yml

While `tasks` is before `roles` in the first play, the tasks are executed after.  The second play allows for a proper mix of task and role execution by only using `tasks` with `import_role`.
