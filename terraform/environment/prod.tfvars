---
# .github/workflows/deploy.yaml
name: Terraform - validation
run-name: '[${{ github.event_name }} - ${{ github.ref_name }}] Terraform executed by @${{ github.actor }}'

on:
  push:
    branches:
      - dev
      - main

  pull_request:
    branches:
      - main
      - dev

permissions:
  id-token: write
  contents: read
  pull-requests: write

env:
  terraformVersion: 1.5.0
  terraformWorkDir: ./
  awsAccountNumber : ${{ secrets.AWS_ACCOUNT_ID }}
  terraformS3Key: ${{ secrets.AWS_ACCOUNT_ID }}/terraform-registry.tfstate
  backendTerraformBucket: terraform-module-state-files
  backendTerraformDynamo: terraform-module-state-files

  awsIamRoleSessionDuration: 3600
  awsRegion: ${{ secrets.AWS_REGION }}


jobs:
  lint:
    name: Lint
    runs-on: ubuntu-20.04

    steps:
      - name: Check out code
        uses: actions/checkout@v3

      - name: Sets env vars for Dev
        run: |
          echo "awsIamRole=arn:aws:iam::${{ env.awsAccountNumber }}:role/Github-OIDC-role" >> $GITHUB_ENV
          echo "terraformBucket=${{ env.backendTerraformBucket }}" >> $GITHUB_ENV
          echo "terraformDynamo=${{ env.backendTerraformDynamo }}" >> $GITHUB_ENV

        if: ${{ (github.ref_name == 'dev') || ( github.base_ref == 'dev') }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: ${{ env.terraformVersion }}
          terraform_wrapper: false

      - name: Terraform Format
        run: terraform fmt --check

      - name: Terraform Initialize
        id: init
        run: |
          cd ${{ env.terraformWorkDir }}
          terraform init -upgrade -backend=false

      - name: Terraform Validate
        id: validate
        run: |
          cd ${{ env.terraformWorkDir }}
          terraform validate

  plan_apply:
    name: Terraform Plan & apply
    needs: lint
    runs-on: ubuntu-20.04

    steps:
      - name: Check out code
        uses: actions/checkout@v3

      - name: configure aws credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: arn:aws:iam::${{ secrets.ADEX_POC }}:role/Github-OIDC-role
          role-session-name: OIDCSession
          aws-region: ${{ env.awsRegion }}
          role-duration-seconds: ${{ env.awsIamRoleSessionDuration }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: ${{ env.terraformVersion }}

      - name: Setup Python
        uses: actions/setup-python@v2
        with:
          python-version: '3.9'

      - name: Check Python3 Path
        run: |
          python3_path=$(which python3)
          echo "Python3 is installed at: $python3_path"

      - name: Terraform Initialize
        id: init
        run: |
          cd ${{ env.terraformWorkDir }}
          terraform init -backend-config="bucket=${{ env.backendTerraformBucket }}" -backend-config="dynamodb_table=${{ env.backendTerraformDynamo }}" -backend-config="key=${{ env.terraformS3Key}}" -backend-config="region=${{ env.awsRegion }}"

      - name: Terraform Plans
        id: plan
        if: github.event_name == 'pull_request'
        continue-on-error: true
        run: |
          cd ${{ env.terraformWorkDir }}
          terraform plan -var-file=environment/dev.tfvars -no-color -out tfplan

      - name: Upload Terraform Plan File
        if: steps.plan.outcome == 'success' && github.event_name == 'pull_request'
        uses: actions/upload-artifact@v3
        with:
          name: tfplan
          path: ${{ env.terraformWorkDir }}/tfplan
          retention-days: 3

      - name: Terraform Show
        if: steps.plan.outcome == 'success' && github.event_name == 'pull_request'
        id: show
        run: |-
            echo '${{ steps.plan.outputs.stdout || steps.plan.outputs.stderr }}' | tail -c 35000 \
            | sed -E 's/^([[:space:]]+)([-+])/\2\1/g' > /tmp/plan.txt
            PLAN=$(cat /tmp/plan.txt)

      - name: Post Plan to GitHub PR
        if: steps.plan.outcome == 'success' && github.event_name == 'pull_request'
        uses: mshick/add-pr-comment@v2
        with:
          allow-repeats: true
          repo-token: ${{ secrets.GITHUB_TOKEN }}
          message: |
            ## Terraform Plan
            ### Environment: ${{ github.base_ref }}
            ### Region: us-east-1
            ***Author***: `${{ github.actor }}` ***Action***: `${{ github.event_name }}`
            ***Working Directory***: `${{ env.terraformWorkDir }}`
            ***Workflow***: `${{ github.workflow }}`
            this is test
            Please review below Terraform plan before accepting merge request:
            ```diff
            ${{ steps.plan.outputs.stdout }}
            ```

      - name: Post Plan Failure
        if: steps.plan.outcome == 'failure'
        uses: mshick/add-pr-comment@v1
        with:
          repo-token: ${{ secrets.GITHUB_TOKEN }}
          message: |
            ## Terraform Plan
            ### Environment: ${{ github.base_ref }}
            ### Region: us-east-1
            ***Author***: `${{ github.actor }}` ***Action***: `${{ github.event_name }}`
            ***Working Directory***: `${{ env.terraformWorkDir }}`
            ***Workflow***: `${{ github.workflow }}`
            ```
            ${{ steps.plan.outputs.stderr }}
            ```

      - name: Stop pipeline if failed
        if: steps.plan.outcome == 'failure'
        run: exit 1

      - name: Terraform Apply
        if: github.event_name == 'push'
        id: apply
        run: |
          cd ${{ env.terraformWorkDir }}
          terraform apply -auto-approve  -var-file=environment/dev.tfvars -no-color
