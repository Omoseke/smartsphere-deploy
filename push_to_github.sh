#!/bin/bash

# Script to help push the SmartSphere repository to GitHub,
# including large files with Git LFS

# Check if Git and Git LFS are installed
if ! command -v git &> /dev/null; then
    echo "Git is not installed. Please install Git first."
    exit 1
fi

if ! command -v git-lfs &> /dev/null; then
    echo "Git LFS is not installed. Please install Git LFS first."
    echo "Visit https://git-lfs.github.com/ for installation instructions."
    exit 1
fi

# Set up repository
REPO_URL="https://github.com/biwunor/SmartSphere.git"
LOCAL_DIR="SmartSphere_local"

echo "Setting up local repository for SmartSphere..."
mkdir -p $LOCAL_DIR
cd $LOCAL_DIR

# Initialize Git repository
git init
git remote add origin $REPO_URL

# Set up Git LFS
git lfs install

# Configure Git LFS tracking
cat > .gitattributes << 'EOL'
*.tar.gz filter=lfs diff=lfs merge=lfs -text
*.zip filter=lfs diff=lfs merge=lfs -text
*.png filter=lfs diff=lfs merge=lfs -text
package-lock.json filter=lfs diff=lfs merge=lfs -text
EOL

git add .gitattributes
git commit -m "Configure Git LFS tracking"

echo "Git LFS has been configured. Now you need to:"
echo "1. Copy all project files into the '$LOCAL_DIR' directory"
echo "2. Run the following commands:"
echo ""
echo "   cd $LOCAL_DIR"
echo "   git add ."
echo "   git commit -m \"Add complete SmartSphere project with Git LFS tracking\""
echo "   git push -u origin main"
echo ""
echo "Note: You will need to authenticate with GitHub during the push."
echo "If you're pushing a large amount of data, this may take some time."
echo ""
echo "For further instructions, refer to the GIT_LFS_INSTRUCTIONS.md file."