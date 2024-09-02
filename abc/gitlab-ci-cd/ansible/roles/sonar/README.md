Common
=========

This role installs and configures SonarQube on an Ubuntu 18.x host.

Requirements
------------

A clean Ubuntu 18.x host with Internet access.

Role Variables
--------------

This role pulls in some variable information from ansible/group_vars/sonar

Dependencies
------------

This role depends on Debian's `apt`, and expects to have Internet access.

Example Playbook
----------------

This role is extremely simple to use. The easiest way to include this role in your playbook would be:

    - hosts: servers
      roles:
         - sonar

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
