# 🚀 Wazuh Agent Automated Deployment with Ansible

This repository accompanies my Medium article: [Automating Wazuh Agent Installation on Linux and Windows with Ansible](https://medium.com/@tsognong-fidele/automating-wazuh-agent-installation-on-linux-and-windows-with-ansible-92dbf433acab).

It demonstrates a **step-by-step automated deployment** of **Wazuh agents** on Linux and Windows systems using **Ansible**, simplifying setup and management while ensuring clarity and reproducibility.

---

## 📋 1. Requirements

### Linux Agents
- SSH access configured with a **sudo-enabled user** (`ansible` recommended)
- Authentication via **SSH key only** (no password)
- If not yet configured, deploy the public SSH key to each Linux machine manually or using a temporary account

### Windows Agents
- Preferred: OpenSSH enabled (Windows 10+)
- Alternative: WinRM enabled with an `ansible` user and password

> Ensure that the control node can communicate with all agent machines over SSH (Linux) or WinRM (Windows).

---

## 🖥️ 2. Prepare the Ansible Control Node

- Install **Python** and **Ansible** on your control machine
- Generate an SSH key for the `ansible` user
- Verify that Ansible is correctly installed and can connect to target hosts

> The control node acts as the central point for managing agents and running playbooks.

---

## 🛠️ 3. Prepare Agent Machines

### Linux Agents
- Create a dedicated `ansible` user with sudo privileges  
- Deploy the SSH public key to enable key-based authentication  
- Verify connectivity from the control node

### Windows Agents
- Use OpenSSH if available, otherwise configure WinRM  
- Ensure the correct firewall rules and remote access policies are applied  
- Test connectivity from the control node before deployment

> Proper user setup and connectivity are essential for successful automation.

---

## 📂 4. Ansible Project Structure

The repository is organized for clarity and maintainability:

- **Inventory file:** defines all Linux and Windows hosts
- **Configuration file (`ansible.cfg`):** sets default parameters and paths
- **Playbooks:** separate playbooks for Linux and Windows agent installation
- **Scripts:** installation scripts stored in the repository and executed by the playbooks

> This structure ensures modularity and easy updates for large environments.

---

## ▶️ 5. Deployment Workflow

1. Configure inventory and Ansible settings
2. Prepare agent machines (users, keys, connectivity)
3. Run the Linux playbook for all Linux agents
4. Run the Windows playbook if using WinRM
5. Verify that all agents are connected to the Wazuh manager

> Following this workflow guarantees a smooth, automated deployment across multiple systems.

---

## 🧩 6. Troubleshooting Guidelines

- Confirm firewall rules allow SSH (Linux) or WinRM (Windows)
- Validate IP addresses and hostnames in the inventory
- Ensure correct permissions on SSH keys
- Test connectivity with `ping` or network checks
- Use verbose mode in Ansible for detailed debugging

> Proactive testing before full deployment reduces errors and downtime.

---

## ✅ Summary

- **Control node:** Python and Ansible installed, SSH key generated  
- **Linux agents:** `ansible` user with SSH key, sudo privileges  
- **Windows agents:** managed via OpenSSH or WinRM  
- **Project structure:** clean, modular, and maintainable for both small and large-scale deployments  

> This repository showcases an **automated, reproducible, and professional setup** for Wazuh agents using Ansible.
