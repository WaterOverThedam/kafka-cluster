#/bin/bash

declare -A hosts=()
while read host;do 
 host=$(echo $host|cut -d ' ' -f 1)  
 hosts[#${host[*]}]=$host
done <cfg/cluster_hosts_ha

[ -d ~/.ssh ] || ssh-keygen -t rsa -P ''
for host in ${hosts[*]};do
    ssh-copy-id $host
done
