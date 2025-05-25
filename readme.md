# 🚀 Wazuh Agent Automated Setup Using Ansible

This guide provides a step-by-step approach to automating the installation of Wazuh agents on Linux and Windows systems using **Ansible**.

---

## 📋 1. Requirements

### 🐧 Linux-Based Agents
- SSH access must be configured using a **single sudo-enabled user**:
  - **Username**: `ansible`
  - **Password**: Not used — access is via **SSH key only**

> If not already configured, deploy a public SSH key to each Linux machine manually or using a temporary user.

### 🪟 Windows-Based Agents
- Preferred: Enable **OpenSSH** (Windows 10+)
- If not available: Enable **WinRM** and create an `ansible` user with a password

---

## 🖥️ 2. Prepare the Ansible Control Node

### Step 1: Install Python and Ansible

For Ubuntu/Debian:

```bash
sudo apt update
sudo apt install -y python3 python3-pip
python3 -m pip install --user ansible
```

Verify installation:

```bash
python3 --version
pip3 --version
ansible --version
```

### Step 2: Generate an SSH Key for the Ansible User

```bash
ssh-keygen -t ed25519 -C "ansible"
```

Generated key paths:
- Private: `~/.ssh/id_ed25519`
- Public: `~/.ssh/id_ed25519.pub`

---

## 🛠️ 3. Prepare the Agent Machines

### 🔑 Linux: Set Up the `ansible` User

On each Linux agent:

```bash
sudo adduser --disabled-password --gecos "" ansible
sudo usermod -aG sudo ansible
echo 'ansible ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/ansible
```

### 🔐 Distribute SSH Public Key

#### Option A: Using `ssh-copy-id` (if password-based SSH is temporarily available)

```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub ansible@192.168.1.101
```

#### Option B: Manual Method (if logging in with another user)

```bash
scp ~/.ssh/id_ed25519.pub root@agent:/tmp/ansible.pub
ssh root@agent
```

Then on the agent:

```bash
sudo mkdir -p ~ansible/.ssh
sudo cp /tmp/ansible.pub ~ansible/.ssh/authorized_keys
sudo chown -R ansible:ansible ~ansible/.ssh
sudo chmod 700 ~ansible/.ssh
sudo chmod 600 ~ansible/.ssh/authorized_keys
sudo rm /tmp/ansible.pub
```

### ✅ Verify SSH Access

From the control node:

```bash
ssh ansible@192.168.1.101
```

---

## 📂 4. Set Up the Ansible Project

### Create an Inventory File

`inventory.yml`:

```yaml
linux:
  hosts:
    192.168.1.117:
    192.168.1.69:

windows:
  hosts:
    192.168.1.78:
```

---

### Create an Ansible Configuration File

`ansible.cfg`:

```ini
[defaults]
inventory = inventory.yml
remote_user = ansible
host_key_checking = False
retry_files_enabled = False
```

---

### Create the Linux Agent Playbook

`agent_playbook.yml`:

```yaml
---
- name: Install Wazuh agent using script with system hostname
  hosts: all
  become: yes
  gather_facts: true

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
```

---

## ▶️ 5. Run the Playbook

From your playbook directory:

```bash
ansible-playbook -i inventory.yml agent_playbook.yml
```

---

## 🪟 6. Windows Agent Setup (Optional - If Using WinRM)

If you cannot use OpenSSH on Windows, configure WinRM as follows.

### Step 1: Install Python WinRM module

```bash
pip3 install "pywinrm>=0.4.0"
```

---

### Step 2: Configure WinRM on the Windows Host (PowerShell)

Run as Administrator:

```powershell
Enable-PSRemoting -Force

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

$tokenFilterParams = @{
    Path         = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
    Name         = 'LocalAccountTokenFilterPolicy'
    Value        = 1
    PropertyType = 'DWORD'
    Force        = $true
}
New-ItemProperty @tokenFilterParams
```

Check listeners:

```powershell
winrm enumerate winrm/config/Listener
```

---

### Step 3: Test WinRM from Control Node

```bash
ansible -i inventory.yml windows -m win_ping
```

---

### Step 4: Run the Windows Playbook

```bash
ansible-playbook -i inventory.yml agent_playbook_win.yml
```

---

## 🧩 7. Troubleshooting Tips

- Make sure firewalls allow SSH (Linux) or port 5985 (WinRM)
- Validate IPs in your inventory
- Ensure correct permissions on `~/.ssh` and `authorized_keys`
- Test basic connectivity: `ping` or `telnet` to the agent's IP
- Use `-vvv` with Ansible commands for verbose output

---

## ✅ Summary

- Control node must have Python and Ansible installed
- Linux agents must have the `ansible` user and public SSH key installed
- Windows agents can be managed via OpenSSH or WinRM
- Inventory and playbooks should be cleanly structured and easy to maintain

> You're ready to automate Wazuh agent deployments like a pro 🚀

