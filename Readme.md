# Conrad Connect Challenge

## Introduction

Thank you for the opportunity

This repository creates a GCP instances with an External IP and installs Nginx & Jenkins. The directory structure is structures as follow

```
prod.ini                  # inventory file for production stage
dev.ini                   # inventory file for development stage
.vpass                    # ansible-vault password file ( not used in this repo)
                          # This file should not be committed into the repository
                          # therefore file is in ignored by git
group_vars/
    all/                  # variables under this directory belongs all the groups
        gcp.yml           # gcp_compute role variable file for all groups
        python.yml        # python  interpreter for all groups
    jenkins/              # here we assign variables to jenkins group
        apt.yml           # apt role config for jenkins group
        java.yml          # java role confg for jenkins group
        nginx.yml         # nginx role config for jenkins group
    concourse/            # here we assign variables to concourse group
plays/
    ansible.cfg           # Ansible.cfg file that holds all ansible config ( you should run plays from here)
    jenkins.yml           # playbook for jenkins instance
roles/
    roles_requirements.yml# All the information about the roles
    external/             # All the roles that are in git or ansible galaxy
                          # Roles that are in roles_requirements.yml file will be downloaded into this directory
                          # This directory is git ignored
    internal/             # All the roles that are not public
service_account.json      # GCP service account (git ignored)
.vpass                    # ansible-vault password file
                          # This file should not be committed into the repository
                          # therefore file is in ignored by git
```

## Requirements

You will need to have the following installed

- Python3 (python2 might work, but not tested)
- Ansible >= 2.7.0
- Python modules (google-auth, requests) Setup Ansible control

## Setup Ansible control

You need to setup the Ansible control machine before running the play

1. head to the terminal and run

```bash
# Fetch external roles dependency. To maintain integrity external roles are git ignored
# requirements.yml have pinned version of roles
./roles/roles_update.sh

# required python modules (change to pip if your using pip)
pip3 install -r requirements.txt
# this is the vault password "Typically i don't commit the passwords in the ReadME :) "
echo pass1 > .vpass
```

2. Fill in the GCP variables located `group_vars/all/gcp.yml` 
3. Create a file in the root project `service_account.json` with your service account
4. By default Ansible will try to use the control machine username `$USER` if your username differs to GCP you can override with `ànsible_user`
5. By default Ansible will try to use the private ssh key located `~/.ssh/id_rsa` you must take care of key management in GCP and on the control machine.

## Running the play

After setup you can run the `jenkins.yml`

```bash
cd plays
ansible-playbook -i ../prod.ini jenkins.yml
```

## Expected outcome

- A GCP instance will be created on the default network with port 22,80,443 exposed on an external IP.
- Ansible will wait for ssh port to be accessible before continuing execution
- apt role will run, it will update the apt-cache and install any security reboot. If the instance requires reboot for security updates to take effect the role will do that. This will only happen the first time. due to guard file
- Jenkins role will install Jenkins no further setup is done on Jenkins.
- Nginx role creates a self signed TLS cert and install nginx. Nginx is configured to redirect port 80 to 433
- Jenkins web interface is accessible by https://XXX.XXX.XXX.XXX (ip will be displayed part of the ansible run)
- Jenkins User is located in group_vars/jenkins/jenkins.yml and Password is encrypted and located in group_vars/jenkins/jenkins_enc.yml (admin/admin) very secure :)

## In a real production environment

- I would highly advice against publishing Jenkins directly on Internet. I would recommend a VPN or jumpbox 
- I would also recommend using terraform to manage the networks and the infrastructure instead of ansible
- I would use ansible vault to keep secrets
- I would use FQDN for hosts and register the host after instance creation or use dynamic inventory.
- Some tasks can be fired in Async mode that will decrease run duration.
- The nginx role is not idempotent, in a real production environment I would use only idempotent tasks/roles 
- I would use develop tests for each groups

## Concourse-CI

Optionally I added [https://concourse-ci.org/](concourse CI) play and role. An alternative to jenkins.

to install head to your terminal and run 

```bash
cd plays
ansible-playbook -i ../prod.ini concourse-web.yml
```
- All credentials/secrets required by concourse are stored in vault with postfix ``*_enc.yml`
- Jenkins User is located in group_vars/concourse-web/concourse.yml and Password is encrypted and located in group_vars/concourse-web/concourse_enc.yml (emad/pass1) very secure :)


Concourse is easy to automate and all pipelines are described as code. Each task runs in a separate container. On the long run it makes maintenance much easier.
