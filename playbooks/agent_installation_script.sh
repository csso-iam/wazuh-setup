#!/bin/bash
###  WAZUH AGENT INSTALLATION SCRIPT

echo "Welcome to Wazuh agent installation..."

echo "Enter your manager's IP address: "
read MANAGER_IP

echo "enter your agent's registration name"
read NAME

echo "Getting system architecture"
if [ -n "$(command -v yum)" ]; then
    sys_type="yum"
    sep="-"
elif [ -n "$(command -v zypper)" ]; then
    sys_type="zypper"
    sep="-"
elif [ -n "$(command -v apt-get)" ]; then
    sys_type="apt-get"
    sep="="
fi

echo "Importing GPG key"
	if [ "${sys_type}" == "yum" ]; then
            rpm --import https://packages.wazuh.com/key/GPG-KEY-WAZUH
	    echo "Adding the repository"
    	    cat > /etc/yum.repos.d/wazuh.repo << EOF
[wazuh]
gpgcheck=1
gpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH
enabled=1
name=EL-\$releasever - Wazuh
baseurl=https://packages.wazuh.com/4.x/yum/
protect=1
EOF
        elif [ "${sys_type}" == "zypper" ]; then
            rpm --import https://packages.wazuh.com/key/GPG-KEY-WAZUH
	    echo "Adding the repository"
    	    cat > /etc/zypp/repos.d/wazuh.repo << EOF
[wazuh]
gpgcheck=1
gpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH
enabled=1
name=EL-\$releasever - Wazuh
baseurl=https://packages.wazuh.com/4.x/yum/
protect=1
EOF
		zypper refresh
        elif [ "${sys_type}" == "apt-get" ]; then
            curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && chmod 644 /usr/share/keyrings/wazuh.gpg
	    echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee -a /etc/apt/sources.list.d/wazuh.list
	    apt-get update
        fi


echo "Deploying wazuh agent"
if [ "${sys_type}" == "yum" ]; then
	WAZUH_MANAGER="$MANAGER_IP" yum -y install wazuh-agent
elif [ "${sys_type}" == "zypper" ]; then
	WAZUH_MANAGER="$MANAGER_IP" zipper -y install wazuh-agent
elif [ "${sys_type}" == "apt-get" ]; then
	WAZUH_MANAGER="$MANAGER_IP" apt-get -y install wazuh-agent
fi

echo "wazuh-agent installed successfully"

echo "Requesting a key from the manager"
/var/ossec/bin/agent-auth -m $MANAGER_IP -A $NAME

echo "Starting the wazuh-agent service"
systemctl daemon-reload
systemctl enable wazuh-agent
systemctl start wazuh-agent

echo "Disabling automatic updates"
if [ "${sys_type}" == "yum" ]; then
	sed -i "s/^enabled=1/enabled=0/" /etc/yum.repos.d/wazuh.repo
elif [ "${sys_type}" == "zypper" ]; then
	sed -i "s/^enabled=1/enabled=0/" /etc/zypp/repos.d/wazuh.repo
elif [ "${sys_type}" == "apt-get" ]; then
	sed -i "s/^deb/#deb/" /etc/apt/sources.list.d/wazuh.list
	apt-get update
	echo "wazuh-agent hold" | dpkg --set-selections
fi
