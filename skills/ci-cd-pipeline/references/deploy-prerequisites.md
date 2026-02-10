# Deploy Platform Prerequisites

Manual setup steps required before CI/CD deploy workflows will function. Complete the relevant section before pushing a workflow that targets that platform.

## Railway

**Setup steps:**

1. Create an account at [railway.app](https://railway.app)
2. Create a new project from the Railway dashboard
3. Optionally link your GitHub repo from the project's Settings > Source panel

**Generate token:**

- Go to your project in the Railway dashboard
- Navigate to Settings > Tokens
- Click "Generate Token" and copy the value

**GitHub Secrets:**

Add the following secret via Repo > Settings > Secrets and variables > Actions > New repository secret:

- `RAILWAY_TOKEN` -- the project token generated above

**Verify:**

```bash
gh secret list  # confirm RAILWAY_TOKEN appears
```

## Fly.io

**Setup steps:**

1. Install the Fly CLI: `brew install flyctl` (macOS) or `curl -L https://fly.io/install.sh | sh`
2. Sign up or log in: `fly auth signup` or `fly auth login`
3. Create your app: `fly apps create <app-name>`
4. Run an initial deploy locally to confirm it works: `fly deploy`

**Generate token:**

- Create a deploy-scoped token: `fly tokens create deploy -a <app-name>`
- Copy the output token value

**GitHub Secrets:**

Add the following secret via Repo > Settings > Secrets and variables > Actions > New repository secret:

- `FLY_API_TOKEN` -- the deploy token generated above

**Verify:**

```bash
gh secret list            # confirm FLY_API_TOKEN appears
fly status -a <app-name>  # confirm the app exists and is reachable
```

## Vercel

**Setup steps:**

1. Create an account at [vercel.com](https://vercel.com)
2. Install the CLI and link your project:
   ```bash
   npm i -g vercel
   vercel link
   ```
3. Note the org and project IDs printed during linking, or read them from `.vercel/project.json`

**Generate token:**

- Go to [vercel.com/account/tokens](https://vercel.com/account/tokens)
- Click "Create Token", give it a descriptive name, and copy the value

**GitHub Secrets:**

Add the following secrets via Repo > Settings > Secrets and variables > Actions > New repository secret:

- `VERCEL_TOKEN` -- the personal access token generated above
- `VERCEL_ORG_ID` -- the `orgId` value from `.vercel/project.json`
- `VERCEL_PROJECT_ID` -- the `projectId` value from `.vercel/project.json`

**Verify:**

```bash
gh secret list  # confirm all three VERCEL_* secrets appear
vercel whoami   # confirm the CLI is authenticated
```

## Terraform

**Setup steps:**

1. Install Terraform: `brew install terraform` or download from [terraform.io](https://www.terraform.io/downloads)
2. Run `terraform init` locally to initialize providers and backend
3. Configure a remote state backend (e.g., S3, GCS, Terraform Cloud) so CI and local runs share state
4. Create a dedicated service account or IAM user for CI with the minimum permissions your plan requires

**Generate token:**

- **AWS:** Create an IAM user in the AWS Console > IAM > Users > Add user > Attach policies > Create access key
- **GCP:** Create a service account in GCP Console > IAM > Service Accounts > Create key (JSON)
- **Terraform Cloud:** Go to User Settings > Tokens > Create an API token

**GitHub Secrets:**

Add the relevant secrets via Repo > Settings > Secrets and variables > Actions > New repository secret:

- AWS provider:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
- GCP provider:
  - `GOOGLE_CREDENTIALS` -- the full JSON key file contents
- Terraform Cloud:
  - `TF_API_TOKEN`

**Verify:**

```bash
gh secret list       # confirm the provider secrets appear
terraform plan       # confirm local plan succeeds with the same credentials
```

## Kubernetes

**Setup steps:**

1. Have a running Kubernetes cluster (EKS, GKE, AKS, or self-managed)
2. Create a CI-specific service account with scoped RBAC:
   ```bash
   kubectl create serviceaccount ci-deploy -n <namespace>
   kubectl create rolebinding ci-deploy-binding \
     --clusterrole=edit \
     --serviceaccount=<namespace>:ci-deploy \
     -n <namespace>
   ```
3. Generate a kubeconfig scoped to that service account

**Generate token:**

- Export and base64-encode the kubeconfig:
  ```bash
  kubectl config view --raw --minify | base64 | tr -d '\n'
  ```
- Copy the full base64 string

**GitHub Secrets:**

Add the following secret via Repo > Settings > Secrets and variables > Actions > New repository secret:

- `KUBECONFIG` -- the base64-encoded kubeconfig from above

**Verify:**

```bash
gh secret list                          # confirm KUBECONFIG appears
echo "$KUBECONFIG" | base64 -d | kubectl --kubeconfig /dev/stdin get nodes  # confirm access locally
```

## AWS CodeDeploy

**Setup steps:**

1. Create a dedicated IAM user for CI in the AWS Console > IAM > Users > Add user
2. Attach the following managed policies (or equivalents):
   - `AWSCodeDeployDeployerAccess`
   - `AmazonS3ReadOnlyAccess` (if deploying from S3 bundles)
3. Create a CodeDeploy application and deployment group in the AWS Console > CodeDeploy
4. Confirm your `appspec.yml` is in the repo root and references valid hooks

**Generate token:**

- Select the IAM user in AWS Console > IAM > Users
- Go to Security credentials > Create access key
- Copy the Access Key ID and Secret Access Key

**GitHub Secrets:**

Add the following secrets via Repo > Settings > Secrets and variables > Actions > New repository secret:

- `AWS_ACCESS_KEY_ID` -- the access key ID from above
- `AWS_SECRET_ACCESS_KEY` -- the secret access key from above
- `AWS_REGION` -- the region your CodeDeploy application lives in (e.g., `us-east-1`)

**Verify:**

```bash
gh secret list  # confirm all three AWS_* secrets appear
aws deploy list-applications --region <your-region>  # confirm access locally
```

## Serverless Framework

**Setup steps:**

1. Install the Serverless CLI: `npm i -g serverless`
2. Configure provider credentials locally (e.g., `aws configure` for AWS)
3. Run an initial deploy to verify everything works:
   ```bash
   serverless deploy --stage dev
   ```
4. Confirm the service is live and the `serverless.yml` references the correct provider, runtime, and functions

**Generate token:**

- Use the same provider credentials as Terraform (see the Terraform section above for AWS/GCP token generation)
- For Serverless Dashboard users: go to [app.serverless.com](https://app.serverless.com) > Org Settings > Access Keys > Create key, and store it as `SERVERLESS_ACCESS_KEY`

**GitHub Secrets:**

Add the relevant secrets via Repo > Settings > Secrets and variables > Actions > New repository secret:

- AWS provider:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
- Serverless Dashboard (optional):
  - `SERVERLESS_ACCESS_KEY`

**Verify:**

```bash
gh secret list       # confirm the provider secrets appear
serverless info      # confirm the service is deployed and accessible
```
