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
sudo snap install -y jq
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
sudo apt install -y docker-ce
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add
curl -s -L https://nvidia.github.io/nvidia-docker/ubuntu18.04/nvidia-docker.list -o nvidia-docker.list
sudo cp nvidia-docker.list /etc/apt/sources.list.d/nvidia-docker.list
sudo apt update
sudo apt install -y nvidia-docker2
sudo pkill -SIGHUP dockerd
wget http://developer.download.nvidia.com/compute/cuda/10.2/Prod/local_installers/cuda_10.2.89_440.33.01_linux.run
sudo sh cuda_10.2.89_440.33.01_linux.run --silent --driver --toolkit --samples
token=$(curl 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://vault.azure.net' -H metadata:true |jq --raw-output '.access_token')
echo $token
dcs=$(curl 'https://$KEYVAULTNAME.vault.azure.net/secrets/deviceConnectionString?api-version=2016-10-01' -H "Authorization: Bearer $token")
echo "here" $dcs
sudo apt install iotedge -y
echo "installing  IoT Edge"
sudo sed -i "s#\(device_connection_string: \).*#\1\"$dcs\"#g" /etc/iotedge/config.yaml
sudo systemctl restart iotedge
echo "restarting IoT Edge"
