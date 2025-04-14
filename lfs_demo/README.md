# Git LFS Demonstration

This directory demonstrates how Git LFS works with a small example:

## Files in this directory:
- `.gitattributes` - Configures which files should be tracked by Git LFS
- `normal_file.txt` - A regular text file tracked by normal Git
- `sample_large_file.tar.gz` - A sample large file tracked by Git LFS

## Understanding the difference

When you look at `normal_file.txt` in GitHub's interface, you'll see the actual file content.

When you look at `sample_large_file.tar.gz`, you'll see a message indicating it's stored with Git LFS, and GitHub will show a download button instead of displaying the content directly.

## How Git LFS works behind the scenes

1. When you add a file that matches a pattern in `.gitattributes`, Git LFS replaces it with a small pointer file in the repository
2. The pointer contains a reference to the actual file content, which is stored separately
3. When you clone the repository, Git LFS automatically downloads the actual content

## Pointer file format

The pointer file that Git stores in the repository for LFS-tracked files looks like this:

```
version https://git-lfs.github.com/spec/v1
oid sha256:2fe6a6d6726c484785146dd26784055f74be380dd90539c978c7cd63cfccece9
size 5242880
```

This contains:
- The LFS version specification
- The SHA-256 hash of the file (object ID)
- The size of the file in bytes

Git LFS uses this information to download the actual file content when needed.
