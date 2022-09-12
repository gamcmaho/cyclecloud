# Azure CycleCloud deployment using BICEP

<h3>Please refer to the Azure CycleCloud architecture below.  We will automate the deployment of this solution using BICEP, as a Domain Specific Language (DSL)
<br>
<br>
<br>
<img src="https://github.com/gamcmaho/cyclecloud/blob/main/CycleCloud.jpg">
<br>
<br>
<h3>1. Using the Azure Portal, create a Cloud Shell (or use your existing Cloud Shell)</h3>
Nb. Click the icon to the right of the Search bar (top centre) and provide mandatory input
<br>
<br>
<h3>2. From the Cloud Shell dropdown, select Bash rather than PowerShell</h3>
<br>
<h3>3. Accept the "Marketplace CycleCloud Terms and Conditions" by running:</h3>
az vm image terms accept --urn azurecyclecloud:azure-cyclecloud:cyclecloud8:latest
<br>
<br>
<h3>4. Accept the "Alma Linux Terms and Conditions" by running:</h3>
az vm image terms accept --urn almalinux:almalinux-hpc:8_5-hpc:latest
<br>
<br>
<h3>5. Git Clone this repo to your Cloud Shell and change working directory</h3>
git clone https://github.com/gamcmaho/cyclecloud.git
<br>
cd cyclecloud
<br>
<br>
<h3>6. Deploy the Azure CycleCloud solution using BICEP</h3>
a. Create a new Resource Group in your chosen Azure region
<br>
<br>
e.g. az group create --name rg-hpc --location northeurope
<br>
<br>
b. Customise the parameters.json and ensure your Storage Account Name is globally unique
<br>
c. Perform Resource Group deployment, remembering to replace values X and Y
<br>
<br>
e.g. az deployment group create --name X --resource-group Y --template-file template.bicep --parameters parameters.json
<br>
<br>
d. Enter Admin credentials as secure parameters
<br>
<br>
<h3>7. Assign Contributor role to Managed Identity of CycleCloud VM scoped to Subscription</h3>
<br>
<h3>8. Azure Bastion to CycleCloud VM and generate an SSH Keypair</h3>
a. ssh-keygen -f ~/.ssh/id_rsa -m pem -t rsa -N "" -b 4096
<br>
<br>Nb.  Passphrase not required
<br>
<br>
b. Make note of the Public key that is required later
<br>
<br>
Nb. Ensure any carriage returns are carefully removed and Public key is expressed on a single line
<br>
<br>
<h3>9. Azure Bastion to Windows jumpbox and access CycleCloud Portal over HTTPS</h3>
e.g. https://10.0.4.4  (Using IP of your CycleCloud VM)
<br>
<br>
a. In response to "Your connection isn't private warning", click Advanced
<br>
b. Then click Continue
<br>
<br>
Nb. The warning is in response to the use of a self-signed SSL certificate
<br>
<br>
<h3>10. Complete the Welcome to CycleCloud workflow</h3>
a. Enter Site Name, then next
<br>
b. Accept the Software License Agreement, then next
<br>
c. Enter initial Admin credentials
<br>
d. Enter SSH Public Key from the earlier step
<br>
<br>Nb. Once again, the Public key should have carriage returns removed and expressed on a single line
<br>
<br>
e. Enter Subscription Name
<br>
f. Ensure Managed Identity checkbox is selected, then select Validate Credentials
<br>
<br>Nb. Ensure "Test succeeded" before proceeding
<br>
<br>
g. Enter Default Location, e.g. North Europe
<br>
h. Select your existing Resource Group from the dropdown
<br>
i. Select your existing Storage Account from the dropdown
<br>
j. Leave Storage Container as "cyclecloud"
<br>
k. Click Save, then Back to clusters
<br>
<br>
<h3>Congratulations, you're now in a position to deploy your first Azure HPC Cluster</h3>
