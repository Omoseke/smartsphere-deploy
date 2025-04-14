# Setting Up GitHub Secrets for the LFS File Upload Workflow

For the GitHub Actions workflow to function properly and upload large files to your repository, you need to set up a Personal Access Token as a repository secret.

## Step 1: Create a Personal Access Token (PAT)

1. Go to your GitHub account settings
   - Click on your profile picture in the top right
   - Select "Settings"
   
2. Navigate to Developer Settings
   - Scroll down to the bottom of the sidebar
   - Click on "Developer settings"
   
3. Generate a Personal Access Token
   - Click on "Personal access tokens" → "Tokens (classic)"
   - Click "Generate new token" → "Generate new token (classic)"
   - Give your token a descriptive name (e.g., "SmartSphere LFS Upload")
   - Set an expiration date (recommend at least 30 days)
   
4. Select the Required Scopes
   - Check the box for "repo" (Full control of private repositories)
   - This gives the token permission to push to your repository
   
5. Generate the Token
   - Scroll to the bottom and click "Generate token"
   - **IMPORTANT**: Copy the generated token immediately - you will not be able to see it again!

## Step 2: Add the Token as a Repository Secret

1. Go to your repository
   - Navigate to https://github.com/biwunor/SmartSphere
   
2. Access Repository Settings
   - Click on "Settings" (tab at the top of your repository)
   
3. Navigate to Secrets
   - In the left sidebar, click on "Secrets and variables" → "Actions"
   
4. Add a New Secret
   - Click "New repository secret"
   - Name: `GH_PAT`
   - Value: [Paste your personal access token]
   - Click "Add secret"

## Step 3: Verify the Secret

1. The secret should now appear in your list of repository secrets
2. The actual value will be hidden for security

## Important Notes

- Keep your personal access token secure - it provides access to your GitHub account
- If you believe your token has been compromised, revoke it immediately in GitHub Settings
- The GitHub Actions workflow is configured to look specifically for a secret named `GH_PAT`
- If the token expires, you'll need to generate a new one and update the repository secret

After completing these steps, the GitHub Actions workflow will be able to authenticate and push large files to your repository using Git LFS.