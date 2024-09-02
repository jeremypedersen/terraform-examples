Common
=========

This role runs `apt-get update` and `apt-upgrade` to bring an Ubuntu host up to date. It also configures unattended upgrades to automatically install security updates.

Requirements
------------

The only requirement is an Ubuntu 18.x host to run this role against.

Role Variables
--------------

This role has no variables.

Dependencies
------------

This role depends on Debian's `apt`.

Example Playbook
----------------

This role is extremely simple to use. The easiest way to include this role in your playbook would be:

    - hosts: servers
      roles:
         - common

License
-------

MIT

Author Information
------------------

Author: Jeremy Pedersen
Personal Site: https://www.jeremypedersen.com
