#  Testing

There is a lot to be said about testing Ansible code.  Unfortunately, a lot of
it can't be said in a G rated venue.

That's a lie for the most part.  Molecule, while also having a steep learning
curve, is powerful and adaptable to test most any role or playbook.  Ansible
has a testing subsystem itself, `ansible-test`, but that will be left for
the reader to research - it is mostly for testing collections, not roles.

# What is Molecule

Molecole is a system that manages throwaway hosts, running the role or playbook
against those hosts, then verifying the expected/desired state.

In the vein of TDD, the hosts could be started, then molecule can repeatedly
run the role being developed against thost hosts, showing errors before
getting to the verification tests.

## Execution

Molecule has a number of subcommands to control the testing flow.  The most
used would be `test`.

Above all, Molecule expects to be where in the same directory as the
`molecule` subdirectory resides.

    pushd 84-testing/roles/minimal
    molecule test
    popd

Other common commands are `create`, `converge`, `verify`, `destroy`.

## Test hosts

Molecule handles the inventory and the access control to the hosts, such as
SSH keys, AWS security groups, etc.  The configuration takes care of the
orchestration.

The test hosts can be Docker containers, Vagrant VMs, EC2 instances, etc.
There are drivers for many standard virtual host methods.  How and what to use
depends largely on the need and the capabilities of where Molecule will be
running.

The most common is to use Docker containers.  But in general, Ansible will
run against an OS, not a partial system, like many containers.  The image used
need to be closely vetted and may need to be provisioned to get to a state
where the role or playbook expects of it.  Molecule can provision with
custom Dockerfiles and `prepare` phases.

## Scenarios

Molecule breaks down into what it calls scenarios.  For the most part, there
is only the `default` scenario, which covers about 95% of the use cases.

The default scenario is something like:
1. install dependencies
1. start the test hosts
1. get them ready (extra software or roles to run)
1. run the role being developed against the test hosts
1. test idempotence
1. run verification tests
1. stop the test hosts

This covers the wide range of testing that would be needed during and after
development.

However, imagine making a role for installing a software package and the
software has already shown that it does not survive system restarts well.
A separate scenerio could be created that reboots the tests hosts after the
role has been applyed, then the verification tests could check for specific
conditions.  The scenerio would be like:

1. install dependencies
1. start the test hosts, possible VMs instead of docker containers
1. get them ready
1. run the role being developed
1. reboot the test hosts
1. run restart verification tests
1. stop the test hosts

It's a subtle difference, but the 'reboot the test hosts' could be expensive (time wise).
It may not be desirable to perform this scenario often in a CI pipeline.
Keeping separate scenarios allows the testing to be seperated as well.

## The `molecule.yml` file

The configuration for a scenario is in the `{scenario}/molecule.yml` file.
This file should exist for each scenario.  It defines:

* which driver to use for orchestating the test hosts
* metadata for each test host
* what to perform in the scenerio
* how to provision each host
* how to verify each host

See the `84-testing/roles/minimal/molecule/default/molecule.yml` file.

The phases in the scenerio are, generally, controlled by Ansible playbooks.
Often Molecule will use builtins, but custom playbooks can be placed in the
scenario directory for use.

### Dockerfile

For the `docker` driver, a `Dockerfile.j2` template is used to create a
separate image for each test host.  This can be overriden:

1. Use the unaltered base image,
2. Use a `Dockerfile.j2` file in the scenario, for custom docker changes
(for example, systemd support).

## Converge

When the Scenario is created, a `converge.yml` file is created which would
call the role being tested against all test hosts.  The file could be
changed, but generally it is unnecessary for roles.

### Testing playbooks

Changing the `converge.yml` to include the top playbook instead of a role
will allow Molecule to perform functional tests on at whole systems.  The
`converge.yml` file would look something like:

    ---
    - import_playbook: ../../playbook.yml

The `molecule.yml` would need to appropriately recreate any group membership
use as the real inventory is not accessible.


## Verifiers

Was it forgotten after all this: the original purpose for learning Molecule
was for testing and verifying.

The default verification engine is Ansible.  A `verify.yml` playbook is stored
in the scenario directory and is called during the `verify` phase of the
scenario.

---

Authors note: For many things, Ansible is sufficient for verifying the test
hosts; but I find pytest-testinfra to be more intuitive.  By this I mean,
I don't see Ansible as a tesitng tool - too much has been said so far about
getting to a desired state.  It is hard to get out of the mindset of testing
without changing.  I'll explain some of the testing modules and patterns,
but I'll concentrate on Testinfra testing later.

---

## Ansible assertions

Ansible has an `ansible.builtin.assert` module.  This takes Jinja2 expressions
to assert a fact.

    - name: Check sudoers attributes
      ansible.builtin.assert
        that:
          - sudoers.stat.owner == 'root'
          - not sudoers.stat.readable
          - not sudoers.stat.writable
          - not sudoers.stat.executable
        fail_msg: "Accessible /etc/sudoers file"

As the `that` clauses are all Jinja2/Python expressions, there is a good bit
of flexibility when working with registers and facts.

When getting into the areas where the modules would make changes if the desired
state is not correct, the assertions need to check the results.

    # potentially changing the state post-provisioning, which should be a
    # no-no in testing
    - name: Test that nginx is installed
      become: true
      package:
        state: present
        name: nginx
      register: nginx_package

Yes, the state of the host is checked... but should it possibly be
destructive.  This is only a philosophical issue; generally the `verify`
phase is called after the `idempotence` phase is called.  This means
that if the role is not idempotence, the test hosts would not be verified.

The `nginx` role in the lesson has two scenarios.  The Ansible form is:

    molecule test -s verify-ansible

## Testinfra

Testinfra is a Pytest plugin that provides a library of read-only,
system level routines and hooks (fixtures) to run those routines on
the test hosts.  The equivalent of the two tests above might look like:

    def nginx_package(host):
        '''Check the nginx group on webservers'''
        # this does not require sudo
        assert host.package('nginx').is_installed
        assert host.service('nginx').is_enabled
        assert host.service('nginx').is_running

While this isn't Ansible, the tests are clear and non-destructive.

    molecule test -s verify-testinfra

# Development testing, converging

The normal mode for unit and functional testing is to use the `test`
operation.  It is a composite of multiple phases, but will essentially
create the test hosts, apply the role against them, run tests and then
destroys the hosts.  This is well and good for QA and CI/CD systems, but
not for iterative development.

Luckily, Molecule can stand up the test hosts separately, apply the
test playbook as many times as necessary, without tearing down the
test hosts repeatedly.


    molecule converge -s verify-testinfra

The idempotence and verify phases are not performed but can be performed
manually on the same test servers.

    molecule idempotence -s verify-testinfra
    molecule verify -s verify-testinfra

When finished, test the whole thing just to be sure, or simply tear down
the hosts.

    molecule destroy -s verify-testinfra
