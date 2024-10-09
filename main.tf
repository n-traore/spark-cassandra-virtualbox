locals {
  interface_type = "bridged"
  network_device = "IntelPro1000MTDesktop"
  worker_count   = 2
  ls_workers_ips = join(",", [for i in virtualbox_vm.worker: i.network_adapter.0.ipv4_address])
  ls_workers = [for i in virtualbox_vm.worker: i]
  cassandra_cluster_name = "Cluster TF"
}

resource "virtualbox_vm" "master" {
  name = "master-node"
  image = "https://storage.googleapis.com/ntr-gcs-pu-xd448/spark-vm.tar.gz"
  cpus   = 1
  memory = "512 mib"

  network_adapter {
    device         = local.network_device
    type           = local.interface_type
    host_interface = local.interface_type == "bridged" || local.interface_type == "hostonly" ? trimspace(file("${path.root}/machine_interface.txt")) : ""
  }
}

resource "virtualbox_vm" "worker" {
  count = local.worker_count
  name  = format("worker-node-%02d", count.index + 1)
  image  = "https://storage.googleapis.com/ntr-prj-uasb03-gcs-pu-xa354/spark-vm.tar.gz"
  cpus   = 1
  memory = "1536 mib"

  network_adapter {
    device         = local.network_device
    type           = local.interface_type
    host_interface = local.interface_type == "bridged" || local.interface_type == "hostonly" ? trimspace(file("${path.root}/machine_interface.txt")) : ""
  }
}

resource "null_resource" "master_exec" {
  depends_on = [virtualbox_vm.master]
  connection {
    type     = "ssh"
    host     = virtualbox_vm.master.network_adapter.0.ipv4_address
    user     = var.vm_user
    password = var.vm_pwd
  }

  provisioner "remote-exec" {
    inline = [
      "sed -i 's/^SPARK_LOCAL_IP/#SPARK_LOCAL_IP/' /opt/spark/conf/spark-env.sh",
      "export SPARK_MASTER_HOST_IP=${virtualbox_vm.master.network_adapter.0.ipv4_address}",
      "start-master.sh"
    ]
  }
}

resource "null_resource" "workers_exec" {
  count      = local.worker_count
  depends_on = [virtualbox_vm.master, virtualbox_vm.worker[0], virtualbox_vm.worker[1], null_resource.master_exec]
  connection {
    type     = "ssh"
    host     = virtualbox_vm.worker[count.index].network_adapter.0.ipv4_address
    user     = var.vm_user
    password = var.vm_pwd
  }

  provisioner "remote-exec" {
    inline = [
      "export SPARK_MASTER_HOST_IP=${virtualbox_vm.master.network_adapter.0.ipv4_address} SPARK_WORKER_MACHINE_IP=${virtualbox_vm.worker[count.index].network_adapter.0.ipv4_address}",
      "start-worker.sh spark://$SPARK_MASTER_HOST_IP:7077",
      "echo ${var.vm_pwd} | sudo -S service cassandra stop",
      "echo ${var.vm_pwd} | sudo -S rm -rf /var/lib/cassandra/data/system/*",
      "echo ${var.vm_pwd} | sudo -S sed -i 's/- seeds.*/- seeds: \"${local.ls_workers_ips}\"/' /etc/cassandra/cassandra.yaml",
      "echo ${var.vm_pwd} | sudo -S sed -i \"s/^cluster_name.*/cluster_name: \\\"${local.cassandra_cluster_name}\\\"/\" /etc/cassandra/cassandra.yaml",
      "echo ${var.vm_pwd} | sudo -S sed -i 's/^listen_address.*/listen_address: ${virtualbox_vm.worker[count.index].network_adapter.0.ipv4_address}/' /etc/cassandra/cassandra.yaml",
      "echo ${var.vm_pwd} | sudo -S sed -i 's/^rpc_address.*/rpc_address: ${virtualbox_vm.worker[count.index].network_adapter.0.ipv4_address}/' /etc/cassandra/cassandra.yaml",
      "echo ${var.vm_pwd} | sudo -S service cassandra start"
    ]
  }
}