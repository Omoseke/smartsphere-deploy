# SmartSphere - Large File Management

This document outlines the various approaches available for handling large files in the SmartSphere repository.

## Overview of Approaches

We've implemented several approaches to handle the large files (totaling ~1.7GB) in this repository:

### 1. GitHub Actions Workflow (Recommended)

The easiest approach is to use the GitHub Actions workflow we've set up:

1. Upload your large files to a temporary file hosting service to get public URLs
2. Use the "LFS File Upload" GitHub Actions workflow to automatically download and commit the files using Git LFS
3. The workflow handles all Git LFS setup and configuration

**Pros:**
- No need to install Git LFS locally
- Automated process through GitHub's infrastructure
- Works from any device with a web browser

**Setup Instructions:**
- [UPLOAD_LARGE_FILES.md](UPLOAD_LARGE_FILES.md) - How to use the GitHub Actions workflow
- [GITHUB_SECRETS_SETUP.md](GITHUB_SECRETS_SETUP.md) - Setting up the required GitHub Secret

### 2. Manual Git LFS Setup

If you prefer a more hands-on approach:

1. Install Git LFS on your local machine
2. Clone the repository
3. Configure Git LFS tracking
4. Add and push large files directly

**Pros:**
- More control over the process
- Good for pushing many files at once
- No need for temporary file hosting

**Setup Instructions:**
- [GIT_LFS_INSTRUCTIONS.md](GIT_LFS_INSTRUCTIONS.md) - Detailed Git LFS usage guide
- [push_to_github.sh](push_to_github.sh) - Helper script for the setup process

### 3. File Chunking

For cases where Git LFS isn't an option:

1. Split large files into smaller chunks
2. Upload each chunk separately
3. Create a manifest for reassembly

**Pros:**
- Works with GitHub's standard file size limits
- Doesn't require Git LFS quota
- Can work via GitHub's web interface

**Setup Instructions:**
- [split_and_upload.sh](split_and_upload.sh) - Script for splitting and uploading files

## Git LFS Demonstration

To understand how Git LFS works:

- Check out the [lfs_demo](lfs_demo) directory
- It contains examples of both regular Git files and LFS-tracked files
- Demonstrates the pointer file mechanism that Git LFS uses

## Required Large Files

The following large files need to be added to the repository:

1. `SmartSphere.tar.gz` - Complete application package including all dependencies
2. `terraform.zip` - Terraform configuration and modules for infrastructure deployment
3. Various large image files used in the application

## GitHub LFS Quota Considerations

GitHub has storage and bandwidth quotas for Git LFS:
- Free accounts: 1GB free LFS storage and 1GB/month bandwidth
- Pro accounts: 2GB free LFS storage and 2GB/month bandwidth

Since this repository requires approximately 1.7GB of LFS storage, you may need a Pro account or data packs to push all the files.
