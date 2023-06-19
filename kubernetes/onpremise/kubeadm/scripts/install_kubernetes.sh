# install Kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(<kubectl.sha256) kubectl" | sha256sum --check
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# install Kubernetes
modprobe br_netfilter
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system

cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
sudo systemctl enable --now kubelet

sudo yum install -y kubelet kubeadm
sudo systemctl enable kubelet && systemctl start kubelet

mkdir -p /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
"exec-opts": ["native.cgroupdriver=systemd"],
"log-driver": "json-file",
"log-opts": {
    "max-size": "100m"
},
"storage-driver": "overlay2"
}
EOF

sudo systemctl enable docker
sudo systemctl daemon-reload
sudo systemctl restart docker

sudo mkdir -p /etc/containerd
sudo touch /etc/containerd/config.toml
sudo chown ${user}:${user} /etc/containerd/config.toml
sudo containerd config default > /etc/containerd/config.toml
sudo sed -i '/sandbox_image/s#registry.k8s.io/pause:3.6#registry.k8s.io/pause:3.9#' /etc/containerd/config.toml
sudo chown root:root /etc/containerd/config.toml
cat /etc/containerd/config.toml | grep -i sandbox_image
sudo systemctl restart containerd


%{ if node == "master" ~}
#sudo kubeadm init --token "${token}" --token-ttl 15m --apiserver-cert-extra-sans="${master_public_ip}" --pod-network-cidr=192.168.0.0/16 

echo "token: ${token}"
echo "master_public_ip: ${master_public_ip}"

sudo kubeadm init \
  --token "${token}" \
  --token-ttl 40320m \
  --apiserver-cert-extra-sans "${master_public_ip}" \
  --pod-network-cidr "${cni_cidr}" \ 
  --node-name ${node_name}

# #Calico
# sudo curl -s https://docs.projectcalico.org/manifests/calico.yaml > calico.yaml
# sudo curl -s https://docs.tigera.io/calico/latest/manifests/calico.yaml > calico.yaml
# sudo sed -i -e 's?# - name: CALICO_IPV4POOL_CIDR?- name: CALICO_IPV4POOL_CIDR?g' calico.yaml
# sudo sed -i -e 's?#   value: "192.168.0.0/16"?  value: "192.168.0.0/16"?g' calico.yaml
# sudo kubectl apply -f calico.yaml

mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Prepare kubeconfig file for downloading
#sudo chmod 660 /etc/kubernetes/admin.conf
sudo cp /etc/kubernetes/admin.conf /tmp/admin.conf
sudo chown ${user}:${user} /tmp/admin.conf
chmod 660 /tmp/admin.conf
kubectl --kubeconfig /tmp/admin.conf config set-cluster kubernetes --server "https://${master_public_ip}:6443"

#------------------------------------------------------------------------------#
# Master: Network Pluggin configuration
#------------------------------------------------------------------------------#
%{~ if cni_pluggin == "calico" ~}
echo "----> config network : CNI pluggin will be Calico !"
sudo curl -s  https://raw.githubusercontent.com/projectcalico/calico/v3.25.1/manifests/tigera-operator.yaml > tigera-operator.yaml
sudo kubectl create -f tigera-operator.yaml
sudo curl -s https://raw.githubusercontent.com/projectcalico/calico/v3.25.1/manifests/custom-resources.yaml > custom-resources.yaml
sudo kubectl create -f custom-resources.yaml
%{~ endif ~}

%{~ if cni_pluggin == "flannel" ~}
echo "----> config network : CNI pluggin will be Flannel !"
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
%{~ endif ~}

#------------------------------------------------------------------------------#
# Master: Install Load Balancer
#------------------------------------------------------------------------------#
%{~ if loadbalancer_plugin == "metalLB" ~}
echo "Step 1 : preparation of metalLB !"
# "metalLB config - Preparation step"
kubectl get configmap kube-proxy -n kube-system -o yaml | \
sed -e "s/strictARP: false/strictARP: true/" | \
kubectl apply -f - -n kube-system
# Step 2 : installation of metalLB :
echo "Step 2 : installation of metalLB"
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.9/config/manifests/metallb-native.yaml
# patch metal LB to be allowed to run on master node
kubectl patch deployment controller -n metallb-system --type='json' -p='[{"op": "add", "path": "/spec/template/spec/tolerations", "value":[{"operator":"Exists","key":"node-role.kubernetes.io/control-plane","effect":"NoSchedule"}]}]'
kubectl rollout restart deployment controller -n metallb-system

#wait for metal lb pod to be ready
while [[ $(kubectl get pods -n metallb-system -l app=metallb,component=controller -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]];
do echo "Waiting for pod : metalLB" && kubectl get pods -A -o wide && sleep 10;
done
kubectl wait --namespace metallb-system --for=condition=ready pod -l app=metallb,component=controller --timeout=180s

while [[ $(kubectl get pods -n metallb-system -l app=metallb,component=speaker -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]];
do echo "Waiting for pod : metalLB speaker" && kubectl get pods -A -o wide && sleep 10;
done
kubectl wait --namespace metallb-system --for=condition=ready pod -l app=metallb,component=speaker --timeout=180s

# Step 3 : config IP of the LB :
echo "Step 3 : config IP of the LB :"

cat <<EOF >>/tmp/metallbipaddressrange.yaml
#set available ip range for the LB
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - 10.0.101.50-10.0.101.60
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example
  namespace: metallb-system
EOF
kubectl replace --force -f /tmp/metallbipaddressrange.yaml

%{~ endif ~} # end of metalLB

%{~ endif ~}

%{~ if node == "worker" ~}
#------------------------------------------------------------------------------#
# Worker: join cluster
#------------------------------------------------------------------------------#
sudo kubeadm join "${master_private_ip}:6443" \
  --token "${token}" \
  --discovery-token-unsafe-skip-ca-verification \
  --node-name ${node_name}
%{~ endif }
