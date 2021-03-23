# **Azure Private Link DNS MicroHack**

# Contents

[MicroHack introduction and context](#Scenario)

[Challenge 1 : Connect to Azure SQL](#challenge-1--connect-to-azure-sql)

[Challenge 2 : Route internet traffic through Azure Firewall]
(# Challenge 2: Route internet traffic through Azure Firewall)

[Challenge 3 : Deploy a Private Endpoint to utilise Azure Private Link for access to Azure SQL](#challenge-3--deploy-a-private-endpoint-to-utilise-azure-private-link-for-access-to-azure-sql)

[Challenge 4 : Deny public access to Azure SQL Server](#challenge-4--deny-public-access-to-azure-sql-server)

[Challenge 5 : Work with a custom DNS server inside of Azure](#challenge-5--work-with-a-custom-dns-server-inside-of-azure)

[Challenge 6 : Use Private Link to access an Azure SQL database over a Private Hybrid Connection](#challenge-6--use-private-link-to-access-an-azure-sql-database-over-a-private-hybrid-connection)

[Challenge 7 : (Warning! Stretch Goal / Advanced) Use Private Link from On-Premises without a pre-existing DNS Server in Azure](#challenge-7--warning-stretch-goal--advanced-use-private-link-from-on-premises-without-a-pre-existing-dns-server-in-azure)

# Scenario

TBD

## Context

TBD

# Pre-requisites

## Overview

In order to use the MicroHack time most effectively, the following tasks should be completed prior to starting the session.

With these pre-requisites in place, we can focus on building the differentiated knowledge in Azure Networking that is required when working with the product, rather than spending hours repeating relatively simple tasks such as setting up Virtual Networks and Virtual Machines. 

At the end of this section your base lab build looks as follows:

![image](images/base.PNG)

In summary:

- "On-Premises" environment simulated by Azure Virtual Network
- On-Premises contains a management VM (*onprem-mgmt-vm*) and a dns server VM (*onprem-dns-vm*)
- On-Premises is connected to Azure via a Site-to-Site VPN
- Azure contains a simple Hub and Spoke topology, containing a management VM in the spoke (*az-mgmt-vm*) and a dns server VM in the hub (*az-dns-vm*)
- Azure Bastion is deployed in all VNets to enable easy remote desktop access to the Windows VMs
- All of the above is deployed within a single resource group called *privatelink-dns-microhack-rg*

## Task 1 : Deploy Template

We are going to use a predefined Terraform template to deploy the base environment. It will be deployed in to *your* Azure subscription, with resources running in the your specified Azure region.

To start the terraform deployment, follow the steps listed below:

- Login to Azure cloud shell [https://shell.azure.com/](https://shell.azure.com/)
- Ensure that you are operating within the correct subscription via:

`az account show`

- Clone the following GitHub repository 

`git clone https://github.com/latj/hub-spoke-microhack`

- Go to the new folder hub-spoke-microhack and initialize the terraform modules and download the azurerm resource provider

`terraform init`

- Now run apply to start the deployment (When prompted, confirm with a **yes** to start the deployment)

`terraform apply`

- Choose you region for deployment (location). E.g. eastus, westeurope, etc

- Choose a suitable password to be used for your Virtual Machines administrator account (username: AzureAdmin)

- Wait for the deployment to complete. This will take around 30 minutes (the VPN gateways take a while).

## Task 2 : Explore and verify the deployed resources

- Verify you can access all four Virtual Machine via Azure Bastion

Username: AzureAdmin

Password: {as per above step}

- Verify that your VNet Peering and Site-to-site VPN are funcitoning as expected. The easiest way to do this is as follows; Once you have Azure Bastion access to the desktop of *az-mgmt-vm*, launch remote desktop (mstsc), and attempt a connection to *onprem-mgmt-vm* (IP address 192.168.0.5). You should recieve the login prompt.



# Challenge 1: Working with user defiend route UDR and Network Security Group NSG 
# Challenge 2: Route internet traffic through Azure Firewall

In this challenge you will explore how Contoso can address the performance problem reported by WVD users. You will build a secure edge in Azure, thus removing the need to route all internet-bound connections to Contoso's on-prem datacenter (red line). Routing WVD traffic directly to the internet via Azure Firewall reduces latency and improves user experience (green line).

![image](images/forced-vs-direct.png)

## Task 1: Deploy Azure Firewall

In the Azure Portal, deploy a new Azure Firewall instance in the hub-vnet. A subnet named "AzureFirewallSubnet" has been already created for you. 

![image](images/firewall.png)

> Please note that the "Forced tunneling" switch must be disabled. The switch allows forwarding internet traffic to custom next hops (including gateways connected to remote networks) after it has been inspected by Azure Firewall. In this scenario, you are using Azure Firewall as your secure internet edge and want your internet traffic to egress to the internet directly, after being inspected by Azure Firewall.

Your Azure Firewall instance will take about 10 minutes to deploy. When the deployment completes, go to the new firewall's overview tile a take note of its *private* IP address. This IP address will become the default gateway for Contoso's Azure VNets. 

## Task 2: Configure a default route via azure Firewall

In the Azure portal, go to your Azure Firewall instance's "Overview" and take note of its private IP address:

![image](images/firewall-overview.png)

Go to the Route Table "spoke-vnet-rt" and modify the next hop of the default route that you defined in the previous challenge. To do so, click on “Routes” on the menu on the left, find the custom default route that you defined in the previous challenge and click on it. Replace the next hop "Virtual Network Gateway" with the private IP of your Azure firewall instance. 

![image](images/default-via-azfw.png)

Remove the default route configuration from the VPN gateway (configured in Challenge 1):

Verify that you no longer have connectivity to the internet from the az-mgmt-vm. Connections are now being routed to Azure Firewall, which is running with the default "deny all" policy.

## Task 3: Implement Contoso's security policy with Azure Firewall rules

Configure Azure Firewall to implement the same internet access policy as Contoso's on-premises proxy:

- Access to "docs.microsoft.com" is allowed
- Access to "ipinfo.io" is allowed
- Access to any other sites is denied

In the Azure Portal, create a new application rule collection for Azure Firewall as shown in the screenshot below.

![image](images/manual-azfw-policy.png)

Confirm that you can now access https://ipinfo.io and https://docs.microsoft.com. Verify that your public IP address is now the public IP address of your Azure Firewall.

![image](images/azfw-public-ip.png)

## Task 4: Enable access to WVD endpoints via Azure Firewall

In this task you will address the performance issues reported by Contoso's WVD users, by allowing direct access to WVD endpoints via Azure Firewall. 

WVD session hosts connect to a list of well-known endpoints, documented [here](https://docs.microsoft.com/en-us/azure/virtual-desktop/safe-url-list#virtual-machines). Each WVD endpoint has an associated Azure Service Tag. 

![image](images/wvd-endpoints.png)

Azure Firewall supports service tags, which would make it easy to configure rules to allow access to WVD required URLs.  However, Azure Firewall rules allowing connections to "Azure Cloud" and "Internet" are too permissive and not compatible with Contoso's security requirements.

You have negotiated with the security team a solution that strikes an acceptable trade-off between security and WVD performance:

- Only the "Windows Virtual Desktop" service tag, which corresponds to a small set of Microsoft-controlled endpoints, will be used in the firewall configuration
- For the other required URLs, application rules matching only the specific URLs will be used.

To implement this policy, go to the "scripts/" directory and execute the wvd-firewall-rules.ps1 script. 

  `cd internet-outbound/scripts`

  `./wvd-firewall-rules.ps1 -AzFwName <your Azure Firewall name>`

When done, go to your Azure Firewall configuration in the portal and verify that you have two rule collections (one network rule collection, one application rule collection) that allow access to the endpoints listed in the previous figure.

## :checkered_flag: Results

You have implemented a secure internet edge based on Azure Firewall, which allows Contoso to control internet access for the wvd-workstation without routing traffic to the on-prem proxy. This approach reduces latency for connections between the wvd-workstation and the WVD control plane endpoints and helps improve the WVD user experience. It also allows Contoso to provide WVD users with access to external, trusted web sites directly from Azure.



# Finished? Delete your lab

- Delete the resource group privatelink-dns-microhack-rg

Thank you for participating in this MicroHack!



