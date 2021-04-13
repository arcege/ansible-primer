"""Role testing files using testinfra."""

import stat, pytest

UNDESIRED = stat.S_IXUSR | stat.S_IWGRP | stat.S_IXGRP | \
                    stat.S_IROTH | stat.S_IWOTH | stat.S_IXOTH


def test_sudoers_file(host):
    '''Test against the sudoers file'''
    fstat = host.file('/etc/sudoers')
    assert fstat.user == 'root'
    assert fstat.group == 'root' or fstat.mode & stat.S_IRGRP == 0
    assert fstat.mode & UNDESIRED == 0

def test_nginx_package(host):
    '''Check the nginx group on webservers'''
    # this does not require sudo
    assert host.package('nginx').is_installed
    assert host.service('nginx').is_enabled
    assert host.service('nginx').is_running
