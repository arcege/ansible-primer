# Ansible Primer
## Michael P. Reilly (arcege@gmail.com/mreilly@ptc.com)

This is meant to be an accelerated lesson for learning Ansible.

The lessons are written to be interactive and self-paced; to read through the
playbooks, roles and related files as hte lesson progresses.

# Lessons

Each lesson will have a `README.md` file that walks the user through the steps.
Some steps may be manual to show the difficulty, but most will be running Ansible
commands.

* `10-playbooks` - learn the basic structure and flow of playbooks, plays and tasks
* `20-variables` - learn about variables, facts and registers
* `30-adhoc` - use ad-hoc commands to execute on a range of hosts
* `40-roles` - modularized execution
* `50-inventory` - hosts, groups and related variables
* `60-idempotence` - desired state as opposed to functional ends
* `70-tags` - limit tasks to be executed
* `75-limits` - limit hosts to be executed against
* `80-debugging` - how to handle issues

Each lesson has its own environment, see `Environment` below, to orchestrate and
provision hosts for that lesson to perform against.

## Quick-start

    source init.sh
    ansible-playbook operator.yml -e lesson=10-playbooks
    ansible-playbook 10-playbooks/plays.yml
    ansible-playbook 10-playbooks/flow.yml
    ansible-playbook 10-playbooks/task-status.yml
    ansible-playbook operator.yml -e lesson=20-variables
    ...

## Assumptions

To make learning this easier, I've made some assumptions:

* Know a little about YAML and its format
* Know a little about Jinja2 templating
* Have Python 3 installed
* Have docker installed and running - special privileges are not required
* Have a Bourne-like shell running on a Linux-like system
    * Bash and Zsh are supported
    * CentOS, Ubuntu and Darwin (macos) are supported

# Setup

## Initialization

In the top level of the directory, load the init.sh script.

    $ source init.sh

This will create and activate a Python Virtualenv and populate it with the tools needed.
If called from within a virtualenv, it will be used instead of creating a new one.

### Completion

When finished with the lessons, you can tear down the environment using:

    $ ansible-playbook operator.yml -e operation=finish

## Environment

The primer uses Docker to create containers used during each lesson.  In each lesson,
containers are started and then destroyed when moving to the next lesson.

There is an Ansible playbook at the top level called `operator.yml`.  The `lesson`
variable needs to be given on the command line with the lesson to be provisioned.

    $ ansible-playbook operator.yml -e lesson=10-playbooks

If the lesson is not being changed, then the variable does not need to
be specified on the command-line.

## Documentation

The overall documentation is the README files, but the `setup/mkdocs.sh` program
will convert them to HTML in the `docs` directory.

## Failures

There will be some lessons that have explicit, deliberate failures.  Those will be
shown in the lesson documents.  Others may occur for other reasons; for those, my
apologies.

## Supporting files

The following files can be ignored for the lessons, they are for the environment to
use.

* `setup/`
* `LICENSE`
