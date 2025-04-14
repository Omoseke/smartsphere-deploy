# Using Git LFS to Upload Large Files

This document explains how to use Git Large File Storage (LFS) to push large files (like your 2GB files) to the GitHub repository.

## What is Git LFS?

Git LFS is an extension to Git that replaces large files with text pointers inside Git, while storing the file contents on a remote server like GitHub's LFS storage service.

## Installation

1. Download and install Git LFS from [git-lfs.github.com](https://git-lfs.github.com/)
2. Set up Git LFS for your user account:
   ```
   git lfs install
   ```

## Upload Large Files to GitHub

### Option 1: Command Line

1. Clone the repository locally:
   ```
   git clone https://github.com/biwunor/s-s.git
   cd s-s
   ```

2. Configure Git LFS tracking for large file types:
   ```
   git lfs track "*.tar.gz"
   git lfs track "*.zip"
   git lfs track "*.png"
   git lfs track "package-lock.json"
   ```

3. Add the .gitattributes file to Git:
   ```
   git add .gitattributes
   git commit -m "Configure Git LFS tracking"
   ```

4. Add your large files:
   ```
   git add SmartSphere.tar.gz terraform.zip generated-icon.png package-lock.json
   git commit -m "Add large files via Git LFS"
   ```

5. Push to GitHub:
   ```
   git push origin main
   ```

### Option 2: GitHub Actions Workflow

I've created a GitHub Actions workflow that can automatically handle Git LFS uploads. To use it:

1. Go to your GitHub repository
2. Navigate to the "Actions" tab
3. Select the "Upload Large Files with Git LFS" workflow
4. Click "Run workflow"
5. Enter the branch name (usually "main") and click "Run workflow"

## Troubleshooting

- **File size errors**: If you get errors about file sizes when pushing directly, make sure you've correctly set up Git LFS tracking before adding the files.
- **Authentication issues**: Ensure you have the necessary permissions to push to the repository.
- **LFS bandwidth limits**: GitHub has LFS bandwidth limits for free accounts. For very large files, you might need to consider a paid GitHub plan.

## Additional Resources

- [Git LFS Documentation](https://git-lfs.github.com/)
- [GitHub's Git LFS Tutorial](https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-git-large-file-storage)