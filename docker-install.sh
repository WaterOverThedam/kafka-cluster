#/bin/bash

[ ! -f "$1" ] && {
  echo "no parameter for host file"
  exit 1
}

declare -A hosts=()
while read host;do 
 host=$(echo $host|cut -d ' ' -f 1)  
hosts[#${host[*]}]=$host
done <cfg/cluster_hosts_ha

for host in ${hosts[*]};do
 echo "$host ..."
 scp -r docker-rpm  $host:~/
 ssh $host  "systemctl status docker.service &>/dev/null || { 
            cd /root/docker-rpm && yum localinstall *.rpm -y 
   }" 
 ssh $host "systemctl enable docker.service && systemctl start docker.service"
done
