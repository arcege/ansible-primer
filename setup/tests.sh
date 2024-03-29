#/bin/bash

build_images () {
    echo "== Building test images =="
    output=$(ansible-playbook operator.yml --tags images 2>&1)
    if [ $? -ne 0 ]; then
        echo "ERROR: building test images" >&2
        echo "$output" >&2
        exit 1
    fi
    echo ""
}

set_lesson () {
    echo "== $1 =="
    echo
    output=$(ansible-playbook operator.yml -e lesson=$1 2>&1)
    if [ $? -ne 0 ]; then
        echo "ERROR: starting environment for $1" >&2
        echo "$output" >&2
        exit 1
    fi
    echo ""
}

finish_lesson () {
    echo ""
    output=$(ansible-playbook operator.yml -e operation=finish 2>&1)
    if [ $? -ne 0 ]; then
        echo "ERROR: finishing lessons" >&2
        echo "$output" >&2
        exit 1
    fi
    echo "== finished =="
}

call_adhoc () {
    echo "-- adhoc $* --"
    ansible "$@"
    if [ $? -ne 0 ]; then
        echo "ERROR: adhoc $*" >&2
        exit 1
    fi
    echo ""
}

fail_adhoc () {
    echo "-- adhoc $* --"
    ansible "$@"
    if [ $? -eq 0 ]; then
        echo "ERROR: adhoc $*" >&2
        exit 1
    fi
    echo ""
}

call_playbook () {
    echo "-- playbook $* --"
    ansible-playbook ${1:+"$@"}
    if [ $? -ne 0 ]; then
        echo "ERROR: playbook ${1}" >&2
        exit 1
    fi
    echo ""
}

fail_playbook () {
    echo "-- playbook $* --"
    ansible-playbook ${1:+"$@"}
    if [ $? -eq 0 ]; then
        echo "ERROR: expected eorr: ${1}" >&2
        exit 1
    fi
    echo ""
}

call_molecule () {
    echo "-- molecule $* --"
    (
        cd $1; shift
        molecule "$@"
    )
    if [ $? -ne 0 ]; then
        echo "$ERROR: molecule: ($1) $*" >&2
        exit 1
    fi
    echo ""
}

fail_molecule () {
    echo "-- molecule $* --"
    (
        cd $!; shift
        molecule "$@"
    )
    if [ $? -eq 0 ]; then
        echo "$ERROR: expected error: ($1) $*" >&2
        exit 1
    fi
    echo ""
}

call_lesson_playbooks () {
    set_lesson 10-playbooks

    call_playbook 10-playbooks/plays.yml

    call_playbook 10-playbooks/flow.yml

    call_playbook 10-playbooks/task-status.yml
}

call_lesson_variables () {
    set_lesson 20-variables

    call_playbook 20-variables/variables.yml

    call_playbook 20-variables/facts.yml -e gather=false
    call_playbook 20-variables/facts.yml -e gather=true

    call_playbook 20-variables/filters.yml

    fail_playbook 20-variables/overwrite-hostname.yml

    call_playbook 20-variables/register.yml

    call_playbook 20-variables/set-fact.yml
}

call_lesson_adhoc () {
    set_lesson 30-adhoc

    call_adhoc adhoc -m ansible.builtin.ping

    call_adhoc adhoc -m ansible.builtin.setup

    call_adhoc adhoc -m ansible.builtin.setup -a filter=ansible_os_family

    call_adhoc adhoc -a id

    call_adhoc adhoc -m ansible.builtin.shell -a 'ls -d /proc/[0-9]*/'

    fail_adhoc adhoc -m package -a name=redis
    call_adhoc adhoc -b -m package -a name=redis

    fail_adhoc adhoc -b -m service -a 'enabled=true name=redis'
    fail_adhoc adhoc -b -m service -a 'enabled=true name=redis-server'
}

call_lesson_roles () {
    set_lesson 40-roles

    call_playbook 40-roles/playbook.yml

    call_playbook 40-roles/task-order.yml
}

call_lesson_inventory () {
    set_lesson 50-inventory

    call_adhoc -i 50-inventory/script.py app,group_dns -m debug -a var=inventory_hostname

    call_adhoc -i 50-inventory/script.py app,group_dns -m debug -a var=ansible_host

    call_adhoc -i 50-inventory/static.yml app,group_dns --list-hosts
    call_adhoc -i 50-inventory/static.ini app,group_dns --list-hosts
    call_adhoc -i 50-inventory/docker.yml app,group_dns --list-hosts
    call_adhoc -i 50-inventory/script.py app,group_dns --list-hosts
    call_adhoc -i 50-inventory/localhost app,group_dns --list-hosts
    call_adhoc -i 50-inventory/docker.yml group_webapp:dns01 --list-hosts
    call_adhoc -i 50-inventory/static.yml 'all:!group_database' --list-hosts

    call_adhoc -i 50-inventory/static.yml group_webapp -m debug -a var=install_dir

    fail_adhoc -i 50-inventory/script.py app,group_dns -a id
    call_adhoc -i 50-inventory/docker.yml app,group_dns -b -m service -a 'name=sshd state=started'
    call_adhoc -i 50-inventory/script.py app,group_dns -a id
}

call_lesson_testing () {
    set_lesson 84-testing
    call_molecule 84-testing/roles/minimal test

    call_molecule 84-testing/roles/nginx test -s verify-ansible
    call_molecule 84-testing/roles/nginx test -s verify-testinfra
}

call_lesson_debugging () {
    rm -f inventory/host_vars/s-debugging-svr4.yml
    set_lesson 80-debugging

    fail_adhoc group_ssh_svrs --one-line -m ping
    docker exec debugging-svr5 sudo systemctl start sshd
    call_adhoc s-debugging-svr5 -m ping

    echo ansible_ssh_user: ansible > inventory/host_vars/s-debugging-svr4.yml
    call_adhoc s-debugging-svr4 -m ping

    call_adhoc s-debugging-svr3 -m raw -a 'sudo apt-get install -y python3-minimal'
    call_adhoc s-debugging-svr3 -m ping

    rm -f inventory/host_vars/s-debugging-svr4.yml
}

PRIMER_PROG=init.sh . init.sh

build_images
call_lesson_playbooks
call_lesson_variables
call_lesson_adhoc
call_lesson_roles
call_lesson_inventory
call_lesson_debugging
call_lesson_testing

finish_lesson
