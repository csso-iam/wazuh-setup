The agents installation is automated using ansible.

1- Requirements

For linux based machines:

- SSH access configured using a single sudoer usename:
username: ansible
password: no ui password, access only allow via ssh using a ssh key

OR in sample term, we need to have a single user with configured public key for each linux based machine.
If not using the temporary ssh user/password, we will then configure the and deploy a single public ssh key on all the linux based agents

For windows machines:
Preferably enable Open SSH on the managed machines,
then access is also possible via ssh, if not
enable WinRM on the windows machine,
then create the ansible user with a password

To simplify the scripts,
create a variable to put the target agent ip
# === Configuration ===
$ export TARGET_AGENT=192.168.1.117
$ export TARGET_USER=ansible
# =====================

2- Generate the ssh public key for the ansible user and deployed that
to all the all the linux machines, windows as well if open ssh is enabled on windows (required at least windows 10+)

$ ssh-keygen -t ed25519 -C "ansible"

by default the generated keys will be stored as follows:

- private key: /home/<username>/.ssh/id_ed25519
- public key: /home/<username>/.ssh/id_ed25519.pub

3a. Distribute Public Key via Existing SSH Access (Password-based)
If the managed host allows password-based SSH, you can use ssh-copy-id or a manual ssh command to install the public key.

$ cat ~/.ssh/id_ed25519.pub
This outputs something like:

 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM... ansible

Option A1: Use ssh-copy-id (easiest), if already accessing the system as the ansible user, using password for instance

$ ssh-copy-id -i ~/.ssh/id_ed25519.pub ansible@remote_host

It will prompt for the password and append the key to ~ansible/.ssh/authorized_keys on the remote host.

Example:

$ ssh-copy-id -i ~/.ssh/id_ed25519.pub ansible@192.168.1.101

Step-by-Step Using scp and ssh (if the main user is not ansible)
📥 Step 1: Copy the public key file to the remote machine (as existinguser)

$ scp ~/.ssh/id_ed25519.pub existinguser@remote_host:/tmp/ansible.pub

eg. $ scp ~/.ssh/id_ed25519.pub root@agent.rehl9.5:/tmp/ansible.pub


Step 2: SSH into the remote host and move the key to the ansible user

$ ssh existinguser@remote_host

Then run:

$sudo mkdir -p ~ansible/.ssh
$sudo cp /tmp/ansible.pub ~ansible/.ssh/authorized_keys
$sudo chown -R ansible:ansible ~ansible/.ssh
$sudo chmod 700 ~ansible/.ssh
$sudo chmod 600 ~ansible/.ssh/authorized_keys
$sudo rm /tmp/ansible.pub

Final Check (from the control node)

Try:

ssh ansible@$TARGET_AGENT

If everything worked, you'll connect without a password




4- Now install and configure ansible in the control node
native ansible installation


Step 1: Install Ansible (Native Method)

Step 1A: Install Python 3 and pip
🔹 For Ubuntu / Debian

sudo apt update
sudo apt install -y python3 python3-pip

    You can verify the versions:

python3 --version
pip3 --version


🔹Installing Ansible

Use pip in your selected Python environment to install the full Ansible package for the current user:

python3 -m pip install --user ansible


Check the installed ansible version
ansible --version

Step2: create the ansible user or ensure it is present on the agent node With No Password Login

sudo adduser --disabled-password --gecos "" ansible

Give the User sudo Access (Passwordless Optional)

sudo usermod -aG sudo ansible

If you want ansible to use sudo without being prompted for a password (needed for many Ansible tasks):

echo 'ansible ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/ansible   #debian or yum , ok

Set Up SSH Access From the Control Node
 => referers to the previous section

Step-by-Step Ansible Configuration

 1. Set Up the Inventory File
create a yaml file:

inventory.yml

with the following content:

linux:
  hosts:
    192.168.1.117:
    192.168.1.69:
windows:
  hosts:
    192.168.1.78:

2. Create ansible.cfg in Your Project Folder
[defaults]
inventory = inventory.yml
remote_user = ansible
host_key_checking = False
retry_files_enabled = False

3- Create the playbook file:
playbook.yml file

---
- name: Install Wazuh agent using script with system hostname
  hosts: all
  become: yes
  gather_facts: true  # Required for ansible_hostname

  vars:
    script_local_path: "./agent_install.sh"
    script_remote_path: "/tmp/agent_install.sh"
    manager_ip: "192.168.1.132"  # Replace with your Wazuh manager IP

  tasks:
    - name: Set agent name from system hostname
      set_fact:
        agent_name: "{{ ansible_hostname }}"

    - name: Copy installation script to remote host
      copy:
        src: "{{ script_local_path }}"
        dest: "{{ script_remote_path }}"
        mode: '0755'

    - name: Run the installation script with manager IP and agent name
      shell: "{{ script_remote_path }} {{ manager_ip }} {{ agent_name }}"
      args:
        executable: /bin/bash


3.Run the Playbook
-- cd playbooks folder 
ansible-playbook -i inventory.yml agent_playbook.yml








SPECIAL CASE FOR windows machines using WinRM


On ansible control node:

1- Using pip install winrm
pip3 install "pywinrm>=0.4.0"  # for winrm


2- WinRM Setup

While this guide covers more details on how to enumerate, add, and remove listeners, you can run the following PowerShell snippet to setup the HTTP listener with the defaults:

# Enables the WinRM service and sets up the HTTP listener
Enable-PSRemoting -Force

# Opens port 5985 for all profiles
$firewallParams = @{
    Action      = 'Allow'
    Description = 'Inbound rule for Windows Remote Management via WS-Management. [TCP 5985]'
    Direction   = 'Inbound'
    DisplayName = 'Windows Remote Management (HTTP-In)'
    LocalPort   = 5985
    Profile     = 'Any'
    Protocol    = 'TCP'
}
New-NetFirewallRule @firewallParams

# Allows local user accounts to be used with WinRM
# This can be ignored if using domain accounts
$tokenFilterParams = @{
    Path         = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
    Name         = 'LocalAccountTokenFilterPolicy'
    Value        = 1
    PropertyType = 'DWORD'
    Force        = $true
}
New-ItemProperty @tokenFilterParams


Enumarate listeners

winrm enumerate winrm/config/Listener

3- Test it (from Ansible control machine)
From your Ansible machine (Linux), you can test WinRM using this:

ansible -i inventory.ini windows -m win_ping

4- Run the playbook

ansible-playbook -i inventory.yml agent_playbook_win.yml





