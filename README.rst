========================================
Ansible Execution Environment Hardening
========================================


********************
Project Description
********************

This is a demo of how Ansible Execution Environment can harden playbooks execution

*************
Use Case
*************


As AAP administrator, you may want to forbid certain Windows authorisation methods. For example, only forbid `ansible_winrm_scheme=http` or enforce `ansible_winrm_transport=ntlm`.
There is no standard method in Ansible Automation Platform UI to do that, but it's possible via hardening the Execution Environment.


*************
EE Anatomy
*************


Ansible Automation Platform uses Execution Environments on Execution nodes. The Execution Environment is a container image that requires python modules, collections and modules to run playbooks.
Every time AAP executes tasks, Ansible Controller copies the automation playbook, runs a podman container with mounted `/project` with playbook. Therefore, to harden the EE, most obviously do it in the image.


Ansible has well `documented <https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_variables.html#understanding-variable-precedence>`_ scope of variables. As you may see from the doco, cli argument `-e` always wins! So, therefore to override any customer variable, we need to add `-e` to whatever user runs.


*************
The Solution
*************


Winrm module uses predefined `variables <https://docs.ansible.com/ansible/latest/os_guide/windows_winrm.html>`_ to establish connection with remote host. For example basic auth:


.. code-block:: yaml


   ansible_user: LocalUsername
   ansible_password: Password
   ansible_connection: winrm
   ansible_winrm_transport: basic
   ansible_winrm_scheme: http




In the example above ansible uses basic auth over HTTP connection. In case we want to harden execution and allow only HTTPS transport, the playbook must be launched with `-e ansible_winrm_scheme=https`.


The good news, that we can use `ansible-builder` to customize Execution Environment, and `V3 Manifest <https://ansible.readthedocs.io/projects/builder/en/latest/definition/#version-3-sample-file>`_ file is very customizable. And to add desired flag we need to do 2 things:


* Create a custom bash script to override default `entrypoint` to append desired `-e` extra variables


.. code-block:: bash


   #!/usr/bin/env bash


   echo "Enforcing script arguments: $@"
   # Enforce NTML transport
   set -- "$@" "-e ansible_winrm_transport=ntlm"
   # Enforce SSL mode
   set -- "$@" "-e ansible_winrm_scheme=http"
   # Print enforced values
   echo "WARNING -> Enforced arguments: ${@}"
   # Run default entrypoint with extra params
   exec /opt/builder/bin/entrypoint $@


`/opt/builder/bin/entrypoint` is default entrypoint of EE, therefore script above just builds extra variables and calls the original script


* Build EE and use it for all AAP Windows projects




*************
Building
*************


Build EE


.. code-block:: bash
  
   make build REGISTRY=<REGISTRY/username> IMAGE=<image> TAG=<image tag>


Push EE


.. code-block:: bash
  
   make push REGISTRY=<REGISTRY/username> IMAGE=<image> TAG=<image tag>




Test EE


.. code-block:: bash
  
   make run_test REGISTRY=<REGISTRY/username> IMAGE=<image> TAG=<image tag>









