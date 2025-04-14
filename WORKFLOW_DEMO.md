# GitHub Actions Workflow Demonstration

This file demonstrates how to use the GitHub Actions workflow to upload large files with Git LFS.

## Example: Uploading SmartSphere.tar.gz

Here's a step-by-step walkthrough with screenshots of the process:

### Step 1: Upload the file to a temporary hosting service

Upload your large file to a service like WeTransfer, Dropbox, or any other file hosting service that provides a direct download link.

For example:
- Upload `SmartSphere.tar.gz` to WeTransfer
- Get a link like `https://wetransfer.com/downloads/XXXXXXXXXXXX/YYYYYYYYYY/ZZZZ`

### Step 2: Go to GitHub Actions

1. Navigate to your repository: https://github.com/biwunor/SmartSphere
2. Click on the "Actions" tab

![GitHub Actions Tab](https://docs.github.com/assets/cb-49628/mw-1440/images/help/repository/actions-tab.webp)

### Step 3: Select the LFS File Upload workflow

1. In the left sidebar, click on "LFS File Upload"
2. Click the "Run workflow" button

![Run Workflow Button](https://docs.github.com/assets/cb-79331/mw-1440/images/help/actions/workflow-dispatch.webp)

### Step 4: Fill in the form

1. **File Path**: Enter the URL where your file can be downloaded
   - Example: `https://wetransfer.com/downloads/XXXXXXXXXXXX/YYYYYYYYYY/ZZZZ`
   
2. **Branch**: Enter `main` (or your target branch)

3. Click "Run workflow"

### Step 5: Monitor the workflow

1. The workflow will start running
2. You can click on it to see the progress:
   - Downloading the file from the provided URL
   - Setting up Git LFS tracking if needed
   - Committing and pushing the file to the repository

### Step 6: Verify the upload

1. After the workflow completes successfully, go to the repository files
2. You should see your file listed with a "Stored with Git LFS" badge
3. The file is now properly stored in Git LFS and tracked in your repository

### Step 7: Repeat for other large files

Repeat the process for each large file:
- terraform.zip
- Any other large files

## Notes

- Ensure you've set up the GH_PAT secret as described in GITHUB_SECRETS_SETUP.md
- The file URL must be publicly accessible for the workflow to download it
- The workflow will take longer for larger files
- If you encounter any issues, check the workflow logs for detailed error messages
