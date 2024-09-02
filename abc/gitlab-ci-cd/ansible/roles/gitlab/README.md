Gitlab
======

This role installs and configures GitLab CE. 

Requirements
------------

The only requirement is an Ubuntu 18.x host to run this role against. The host needs to have access to the internet.

Role Variables
--------------

This role has no local variables, but pulls in some variables from ansible/group_vars/gitlab

Dependencies
------------

This role depends on Debian's `apt` and expects an Ubuntu 18.x host with Internet access.

Example Playbook
----------------

This role is extremely simple to use. The easiest way to include this role in your playbook would be:

    - hosts: servers
      roles:
         - gitlab

Limitations
-----------

This role is intended to be run **once** against a clean Ubuntu 18.x host. I have tried to make this role idempotent but I'm new to Ansible and the script is not guaranteed to work when run a second time against the same host. 

License
-------

MIT

Author Information
------------------

Author: Jeremy Pedersen
Personal Site: https://www.jeremypedersen.com
