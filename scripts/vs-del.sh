#!/bin/bash

if [[ $# < 1 ]]; then
    echo "input interface"
    exit -1
fi

ETH=$1
mac=`ip link show $ETH | grep link/ether | awk '{print $2}'`
port_name=`cat /sys/class/net/${ETH}/phys_port_name 2>/dev/null`
port=${port_name##*f}
pf=${port_name#*f}
pf=${pf%%v*}

if [[ -z "$port" ]];then
    echo "input port is not a rep port"
    exit -1
fi

if [[ $port == p* ]];then
    echo "input port is a pf"
    exit -1
fi

id=0
found=0

for pci in `lspci | grep -i Eth | grep -i Virtual | awk '{print $1}'`; do
    if [[ $id -eq $port ]];then
        found=1
        break
    fi
    id=$(($id+1))
done

if [ $found -eq 0 ];then
    echo "pci not found"
    exit -1
fi
pci="0000:"$pci

echo "pci=$pci, port=$port, pf=$pf, mac=$mac, ETH=${ETH}"

ovs-vsctl del-port br-int $ETH
echo $pci > /sys/bus/pci/drivers/mlx5_core/unbind

ip netns del $ETH

