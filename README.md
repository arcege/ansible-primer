# Ansible Primer
## Michael P. Reilly (arcege@gmail.com/mreilly@ptc.com)

This is meant to be an excelerated lesson for learning Ansible.

## Quick-start

    source init.sh
    ansible-playbook operator.yml -e lesson=10-playbooks
    ansible-playbook 10-playbooks/book1.yml
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

## Environment

The primer uses Docker to create containers used during each lesson.  In each lesson,
containers are started and then destroyed when moving to the next lesson.

There is an Ansible playbook at the top level called `operator.yml`.  The `lesson`
variable needs to be given on the command line with the lesson to be provisioned.

    $ ansible-playbook operator.yml -e lesson=10-playbooks

If the lesson is not being changed, then the variable does not need to
be specified on the command-line.


# Lessons

Each lesson will have a `README.md` file that walks the user through the steps.
Some steps will be manual to who the difficulty, but most will be running Ansible
commands.

## Failures

There will be some lessons that have explicit, deliberate failures.  Those will be
shown in the lesson documents.  Others may occur for other reasons; for those, my
apologies.
