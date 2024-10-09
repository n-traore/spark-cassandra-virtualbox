Set up a Spark + Cassandra cluster on your local machine using terraform and Virtualbox.
PS : This example uses a VM with Spark and Cassandra already installed

## Setup

### 1. Clone the repo
```bash
git clone https://github.com/n-traore/spark-cassandra-virtualbox.git && \
cd spark-cassandra-virtualbox
```

### 2. Retrieve your machine interface that virtualbox will use to build your cluster
```bash
chmod +x ./get_machine_interface.sh
./get_machine_interface.sh
```

### 3. Run terraform commands to create the cluster
The terraform version used is 1.4. You might need to make some changes to the cluster definitions if using the latest terraform version as the API has evolved.
```bash
terraform init

# to check the resources that will be created
terraform plan

# create
terraform apply --auto-approve
```
&nbsp;

![tf-apply-cluster(2)](https://github.com/user-attachments/assets/b70abcca-2955-44ea-87b5-345684f7e0af)


### 4. Clean-up
Delete the cluster by running the following command:
```bash
terraform destroy --auto-approve
```
