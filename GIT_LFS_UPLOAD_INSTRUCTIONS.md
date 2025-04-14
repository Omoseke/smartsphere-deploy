# How to Push Large Files (1.7GB) to GitHub with Git LFS

To properly push all your large files including SmartSphere.tar.gz, terraform.zip, and large images to GitHub, you'll need to follow these steps on your local machine (not in Replit).

## Prerequisites

1. [Git](https://git-scm.com/downloads) installed on your local machine
2. [Git LFS](https://git-lfs.github.com/) installed on your local machine
3. GitHub account with access to the repository

## Step-by-Step Instructions

### 1. Download the project from Replit

First, download the entire project from Replit to your local machine. You can do this using the Replit interface by clicking the three dots menu (...) in the file browser and selecting "Download as zip".

### 2. Initialize a local Git repository

```bash
# Create a directory for your project
mkdir smartsphere
cd smartsphere

# Extract the zip file you downloaded from Replit
# (This might be a different command depending on how you extract it)
unzip /path/to/downloaded/replit-project.zip -d .

# Initialize a new Git repository
git init

# Set up your remote (replace with your repository URL)
git remote add origin https://github.com/biwunor/SmartSphere.git
```

### 3. Set up Git LFS

```bash
# Install Git LFS (if you haven't already)
# macOS (with Homebrew): brew install git-lfs
# Windows (with Chocolatey): choco install git-lfs
# Linux (Ubuntu/Debian): apt-get install git-lfs

# Initialize Git LFS
git lfs install

# Track large file types
git lfs track "*.tar.gz"
git lfs track "*.zip"
git lfs track "*.png"
git lfs track "package-lock.json"

# Add the .gitattributes file to Git
git add .gitattributes
git commit -m "Configure Git LFS tracking"
```

### 4. Add and commit all files

```bash
# Add all files to the repository
git add .

# Commit all files
git commit -m "Add complete SmartSphere application including large files"
```

### 5. Push to GitHub

```bash
# Push to GitHub (you'll need to authenticate)
git push -u origin main
```

During the push process, Git LFS will automatically handle the large files, uploading them through the LFS system.

## Verifying the Upload

After pushing, you can verify that your files were properly uploaded:

1. Visit your GitHub repository in a web browser
2. Check that large files show a "Stored with Git LFS" badge
3. Click on these files to see the LFS details

## Troubleshooting

### File size limits

GitHub has storage and bandwidth limits for Git LFS:
- Free accounts: 1GB free LFS storage and 1GB/month bandwidth
- Pro accounts: 2GB free LFS storage and 2GB/month bandwidth

For your 1.7GB upload, you might need a Pro account or data packs.

### Push errors

If you encounter errors during push:
- Make sure Git LFS is properly installed and initialized
- Check that your .gitattributes file is correctly set up
- Ensure you have sufficient Git LFS storage quota
- Try pushing smaller batches of files if needed

### Authentication issues

If you have authentication problems:
- Use a personal access token instead of password authentication
- Ensure your token has the necessary permissions for the repository

## Alternative Approach: GitHub Actions

If you're still having trouble with the direct approach, I've set up a GitHub Actions workflow in your repository that can help automate the Git LFS process. See `.github/workflows/lfs-upload.yml` for details.