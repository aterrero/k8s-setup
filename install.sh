#!/bin/sh

#Docker and Kubernetes
python3 setup.py
kubeadm init --ignore-preflight-errors='all' --pod-network-cidr=10.244.0.0/16
kubeadm token create --print-join-command > joincommand.sh
chmod 755 joincommand.sh
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

cat workers | while read line
do
    if [ "$line" = "-" ]; then
        echo "Skip $line"
    else
        scp joincommand.sh root@$line:/root
        scp setup.py root@$line:/root
        scp master root@$line:/root
        scp workernfsconfigurator.py root@$line:/root
        ssh root@$line -n "cd /root && python3 setup.py && ./joincommand.sh"
    fi
done

#Grafana
python3 grafanasetup.py "master"

cat workers | while read line
do
    if [ "$line" = "-" ]; then
        echo "Skip $line"
    else
        scp grafanasetup.py root@$line:/root
        ssh -o StrictHostKeyChecking=no root@$line -n "cd /root && python3 grafanasetup.py worker"
        echo "Finished config node $line"
        echo "########################################################"
    fi
done

#NFS
python3 masternfsconfigurator.py
cat workers | while read line
do
    if [ "$line" = "-" ]; then
        echo "Skip $line"
    else
        ssh root@$line -n "cd /root && python3 workernfsconfigurator.py"
    fi
done


echo "Finished Installation"
