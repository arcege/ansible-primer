# Idempotence

The execution philosophy of Ansible is to try to get to a desired state.  As such, code executed for a state,
not an action.  It is very common for tasks to not perform changes when the state is current.  For example,
for a service that is supposed to be in a started state, the task may do nothing if the service is already
running.

Idempotence is an important goal of Ansible to achieve this.  While nothing is required to be, it is valuable to ensure that
a change is not going to creep into the infrastructure because of the code.  The overall condition for Ansible's view
of idempotence is that a running a playbook or a component will produce no changes on subsequence runs.


## Straight forward

It's common to start out converting a script's flow directly into Ansible, take the case of provisioning a Hashicorp Vault
service.  The procedural steps are:

1. Create a 'bin' directory
1. Create an 'etc' directory
1. Download the 'vault.zip' file
1. Extract the binary into the 'bin' directory
1. Copy a base configuration file
1. Clean up the downloaded file

The above steps, when run again would need error handling, for example, creating an existing directory results in an error.
Other steps could require unnecessary, expensive operations, like downloading the zip file when the binary already exists.

The `straight-forward.yml` playbook follows the steps above.  Some of the error handling is taken care of implicitly.
As modules try to be idempotent themselves, creating a directory would pass without changes if the directory exists.

    ansible-playbook 60-idempotence/straight-forward.yml  # first run: 7 of 8 changes
    ansible-playbook 60-idempotence/straight-forward.yml  # second run: 3 of 7 changes

The vault.zip file is still downloaded, even tho extracting the binary is skipped.


## Adapted idempotence

The `idempotent-remote.yml` is more of a variation on `straight-forward.yml`.  It checks to see if the binary exists before attempting to download the zip file.  Some minor improvements are made, like a loop to create the directories instead of separate tasks.

The basic structure of the playbook follows the original procedural steps and it is idempotent.

    ansible-playbook 60-idempotence/idempotent-remote.yml  # first run: 6 of 8 changes
    ansible-playbook 60-idempotence/idempotent-remote.yml  # second run: 0 of 4 changes

## Starting with idempotence

The above are just adaptions of the same procedural steps.  If instead we think about the desired state, then we get a much more simplified playbook.  The goals of provisioning the Vault server are:

* Create directories needed: bin and etc
* Install the 'vault' binary from the zip file
* Create a configuration file

The procedural steps follow these goals, but if we make one small philosophical change, we can get a simplified, idempotent playbook.  That change is to realize that there is no practical difference between downloading the zipfile and storing the zipfile locally.  Similar with storing the configuration template as a local file or an inline string.  With that one change, `idempotent-local.yml` changes to three simple tasks.

    ansible-playbook 60-idempotence/idempotent-local.yml  # first run: 3 of 4 changes
    ansible-playbook 60-idempotence/idempotent-local.yml  # second run: 0 of 3 changes

Notice that the `unarchive` tasks includes a `creates` clause.  That value is used to check if the task should be skipped.
