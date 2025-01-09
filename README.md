# Azure GitHub Runner

This repository contains reusable workflows for creating and managing self-hosted GitHub runners in Azure.

## Workflows

### Create Runner (`create.yml`)
Creates an Azure VM and configures it as a GitHub Actions runner.

### Delete Runner (`delete.yml`)
Cleans up the Azure VM and removes the GitHub Actions runner.

## Usage

In your workflow:

```yaml
jobs:
  start-runner:
    uses: your-org/azure-runner/.github/workflows/create.yml@main
    with:
      VM_SIZE: Standard_B1s
      LOCATION: eastus
      VNET_NAME: your-vnet  # optional
      VNET_RG: your-rg      # optional
      SUBNET_NAME: your-subnet  # optional
    secrets:
      ARM_CLIENT_ID: ${{ secrets.ARM_CLIENT_ID }}
      ARM_CLIENT_SECRET: ${{ secrets.ARM_CLIENT_SECRET }}
      ARM_TENANT_ID: ${{ secrets.ARM_TENANT_ID }}
      ARM_SUBSCRIPTION_ID: ${{ secrets.ARM_SUBSCRIPTION_ID }}
      GH_TOKEN: ${{ secrets.GH_TOKEN }}

  your-job:
    needs: start-runner
    runs-on: ${{ needs.start-runner.outputs.uniq_label }}
    steps:
      - your steps here...

  stop-runner:
    needs: your-job
    uses: your-org/azure-runner/.github/workflows/delete.yml@main
    if: always()
    secrets:
      ARM_CLIENT_ID: ${{ secrets.ARM_CLIENT_ID }}
      ARM_CLIENT_SECRET: ${{ secrets.ARM_CLIENT_SECRET }}
      ARM_TENANT_ID: ${{ secrets.ARM_TENANT_ID }}
      ARM_SUBSCRIPTION_ID: ${{ secrets.ARM_SUBSCRIPTION_ID }}
      GH_TOKEN: ${{ secrets.GH_TOKEN }}
```

## Required Secrets

- `ARM_CLIENT_ID`: Azure Service Principal Client ID
- `ARM_CLIENT_SECRET`: Azure Service Principal Secret
- `ARM_TENANT_ID`: Azure Tenant ID
- `ARM_SUBSCRIPTION_ID`: Azure Subscription ID
- `GH_TOKEN`: GitHub Personal Access Token with repo scope 
