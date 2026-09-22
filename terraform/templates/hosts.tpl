[load_balance]
%{ for ip in super_nodes ~}
${ ip } ansible_user=traipoap
%{ endfor ~}

[k3s_masters]
%{ for ip in master_nodes ~}
${ ip } ansible_user=traipoap
%{ endfor ~}

[k3s_workers]
%{ for ip in worker_nodes ~}
${ ip } ansible_user=traipoap
%{ endfor ~}

[k3s_cluster:children]
k3s_masters
k3s_workers
