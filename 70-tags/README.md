# Tags

Tags are associated with plays, blocks or tasks.

In an automated world, tags are not always useful.  But if a large set of tasks are in a playbook (including in roles), then it could take time when you know that changes are unnecessary.

For example, a network with 30 nginx servers already provisioned need to have a critical config changes.  There is no need to run through all the tasks that normally are performed without changes.  Instead, only the segments of the code dealing with pushing those changes and restarting the server processes need to be performed.  If tags are associated with tags judiciously, then selecting, say, a 'config' tag would ensure that only the tasks and handlers dealing with the configuration files would be run.

There are some predefined tags.  The first three are used when selecting
tags and are not expected to be used in plays, blocks or tasks.


* `all` - all the tasks that are not marked 'never'; this is the default
* `tagged` - tasks marked with any tag
* `untagged` - tasks marked without a tag
* `always` - always call
* `never` - do not call by default


Ansible uses a `tags` attribute to mark plays, blocks or tasks with tags.

  - name: Install nginx
    package:
      name: nginx
    tags:
      - install
      - nginx

This shows two tags associated with the "Install nginx" task.  If either
tag is specified, then the task is run.

The `tags` attribute could be a lists, as bove, or a single tag. All the tags in the list do not need to be specified.

## Show tags

The `ansible-playbook` command has three options to help with using tags.

    ansible-playbook 70-tags/simple.yml --list-tags
    ansible-playbook 70-tags/simple.yml --list-tasks
    ansible-playbook 70-tags/simple.yml --list-tasks --tags A --skip-tags D

## Tag selection

When Ansible loads the playbooks, tasks files and roles, the list of tags in each is accumulated.  From the command-line, the set of tags can
be specified to limit the set of tasks that are run.

* `--tags` - the set of tags to include
* `--skip-tags` - the set of tags ot exclude

The tasks with the modified list of tags are then executed.

As tags ultimately are associated with tags, tagging higher-level constructs
applies for all the tasks inside.

    ansible-playbook 70-tags/simple.py --tags sphere
    ansible-playbook 70-tags/simple.py --skip-tags cube

### Untagged and tagged

    ansible-playbook 70-tags/simple.py --list-tags --tags tagged
    ansible-playbook 70-tags/simple.py --list-tags --tags untagged

## Without tags on the command-line

    ansible-playbook 70-tags/simple.yml

This is the same as using `--tags all`.

The task with the 'never' tag will not be run by default.

## Combining tags

Especially if multiple tags are attached to the object, then skipping
and including tags can help tailor the flow more appropriately.

    ansible-playbook 70-tags/simple.yml --tags A --skip-tags D

Now imagine software for a LAMP service needs to be the http server updated, but not the config files.

    ansible-playbook 70-tags/lamp.yml --tags apache --skip-tags config,system

## Importing vs Including

Ansible has two constructs that have been used throughout these lessons,
the `import_*` and `include_*` classes of modules.

At the surface, the two do the same thing: access the contents of
other files as code.

The difference between the two is _when_ the processing of the file occurs.  Importing a file occurs when it encounters the file.  Importing is at the time Ansible loads the playbook, roles, tasks and starts to process inventory, tags, etc.

As mentioned earlier, the set of tags are determined when Ansible first starts, before executing any tasks.  As imported files are loaded at that time, the tags inside the imported file are available.  Included files are loaded in the middle of execution, long after the list of tags is built.

This means that tags inside `import_*` modules are honored, whereas the tags on tasks inside `include_*` modules are not.

However, tags on the actual `include_*` tasks are in the calling file, and would be honored.

    ansible-playbook 70-tags/lamp.yml --list-tasks

The difference between the sets of tasks shown for the nginx-server and the mongodb roles is clear.  Importing will enumerate the tasks, while importing will obscure them.
