# How to Upload Large Files Using the GitHub Actions Workflow

I've set up a GitHub Actions workflow that makes it easy to upload large files to the repository. Here's how to use it:

## Step 1: Create Publicly Accessible URLs for Your Large Files

Before using the workflow, you need to have your large files accessible via public URLs. Here are some options:

1. **Temporary File Hosting Services**:
   - [WeTransfer](https://wetransfer.com/) 
   - [MediaFire](https://www.mediafire.com/)
   - [Jumpshare](https://jumpshare.com/)
   - [Temporary Cloud Storage Shares (Dropbox, Google Drive, OneDrive, etc.)]

2. **Your Own Web Server**:
   - If you have access to a web server, you can host the files there temporarily

## Step 2: Launch the GitHub Actions Workflow

1. Go to your GitHub repository: [biwunor/SmartSphere](https://github.com/biwunor/SmartSphere)
2. Click on the "Actions" tab
3. In the left sidebar, click on "LFS File Upload"
4. Click the "Run workflow" button
5. Fill in the form:
   - **File Path**: Enter the public URL where your file can be downloaded
   - **Branch**: Enter "main" (or your target branch)
6. Click "Run workflow"

## Step 3: Monitor the Workflow

1. The workflow will automatically download the file from the URL
2. It will configure Git LFS tracking for that file type if needed
3. It will commit and push the file to the repository using Git LFS
4. You can monitor the progress in the Actions tab

## Step 4: Repeat for Each Large File

Repeat the process for each large file. Here are the large files that need to be uploaded:

1. `SmartSphere.tar.gz` - Complete application package
2. `terraform.zip` - Terraform configuration and modules
3. Any other large image or binary files

## Notes

- Ensure that each URL is publicly accessible (no authentication required)
- The workflow will handle all the Git LFS setup automatically
- If the file is very large, the workflow might take some time to complete
- GitHub has storage limits for LFS files (1GB for free accounts, 2GB for Pro accounts)
