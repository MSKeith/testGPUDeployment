#! /bin/bash
curl https://packages.microsoft.com/config/ubuntu/18.04/multiarch/prod.list > ./microsoft-prod.list
sudo cp ./microsoft-prod.list /etc/apt/sources.list.d/
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo cp ./microsoft.gpg /etc/apt/trusted.gpg.d/
sudo apt install -q -y apt-transport-https 
sudo apt install -q -y ca-certificates
sudo apt install -q -y curl
sudo apt install -q -y software-properties-common
sudo apt install -q -y build-essential
sudo apt install -q -y jq
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
sudo apt install -y docker-ce
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add
curl -s -L https://nvidia.github.io/nvidia-docker/ubuntu18.04/nvidia-docker.list -o nvidia-docker.list
cp nvidia-docker.list /etc/apt/sources.list.d/nvidia-docker.list
apt update
apt install -y nvidia-docker2
pkill -SIGHUP dockerd
wget http://developer.download.nvidia.com/compute/cuda/10.2/Prod/local_installers/cuda_10.2.89_440.33.01_linux.run
sh cuda_10.2.89_440.33.01_linux.run --silent --driver --toolkit --samples
token=$(curl 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://vault.azure.net' -H metadata:true |jq --raw-output '.access_token')
echo $token
dcs=$(curl 'https://$KEYVAULTNAME.vault.azure.net/secrets/deviceConnectionString?api-version=2016-10-01' -H "Authorization: Bearer $token")
echo "here" $dcs
|
    set -x
    (
      # Wait for docker daemon to start
      while [ $(ps -ef | grep -v grep | grep docker | wc -l) -le 0 ]; do 
        sleep 3
      done

      # Prevent iotedge from starting before the device connection string is set in config.yaml
      sudo ln -s /dev/null /etc/systemd/system/iotedge.service
      apt install iotedge -y
      sed -i "s#\(device_connection_string: \).*#\1\"', $dcs, '\"#g" /etc/iotedge/config.yaml 
      systemctl unmask iotedge
      systemctl start iotedge
    ) &
