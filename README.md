# Kubernetes Cluster on AWS with Terraform and Auto Scaling

This project sets up a self-managed Kubernetes cluster on AWS using Terraform. The cluster includes multiple nodes, an ingress controller, and an auto-scaling group. The setup is automated with bash scripts, ensuring that nodes are automatically assigned and registered into the cluster upon creation.

## Features

- **Self-Managed Kubernetes Cluster**: Deploy and manage your own Kubernetes cluster on AWS.
- **Ingress Controller**: Set up an ingress controller to manage external access to services within the cluster.
- **Multiple Nodes**: The cluster includes multiple worker nodes for running your applications.
- **Auto Scaling Group**: Automatically scale the number of worker nodes based on demand.
- **Automated Setup**: Use bash scripts to automate the setup and configuration of the cluster and nodes.
- **Node Auto-Registration**: New nodes are automatically assigned and registered into the cluster upon creation.


## Requirements

- **Terraform**: v0.12 or later
- **AWS CLI**: v2 or later 

## Directory Structure

- **/scripts**: Contains bash scripts for setting up and configuring the cluster and nodes.
- **/k8s-manifests**: Contains Kubernetes manifests for deploying resources within the cluster.
- **data.tf**: Terraform data fetches and output
- **main.tf**: Terraform configuration file for setting up AWS resources.
- **terraform.tfvars/variables.tf**: Terraform variable assignment and declaration
- **README.md**: Project documentation.

## Before you begin

Make sure you create a or import a keypair in AWS. The name should match the one in the `terraform.tfvars` file.

## Getting Started

1. **Clone the Repository**:
   ```sh
   git clone https://github.com/konnikamii/k8s-tf-aws-asg.git
   cd k8s-tf-aws-asg
   ```

2. **Configure AWS Credentials**:  
Ensure your AWS credentials are configured. You can use the AWS CLI to configure your credentials:

   ```sh
   aws configure
   ```

3. **Initialize Terraform**:  
Initialize the Terraform configuration:

   ```sh
   terraform init
   ```

4. **Apply Terraform Configuration**:  
Apply the Terraform configuration to set up the infrastructure:

   ```sh
   terraform apply
   ```

5. **Verify the Cluster**:  
Once the setup is complete, verify that the Kubernetes cluster is running and nodes are registered:

   ```sh
   ssh <user>@<master-node-public-ip>                         # the output prints the command
   kubectl get nodes
   ```

   

 