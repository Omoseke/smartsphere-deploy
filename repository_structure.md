# SmartSphere Repository Structure

This document provides a comprehensive overview of the SmartSphere application's repository structure.

## Core Application Files

- **server.js**: Main Express.js server that serves the application
- **index.html**: Primary landing page 
- **script.js**: Main client-side JavaScript for the application
- **styles.css**: CSS styling for the application
- **package.json**: NPM package dependencies and scripts

## Directory Structure

### `/src` - React Application

Contains the React frontend application:

- `/src/src/App.js`: Main React component
- `/src/src/index.js`: React entry point
- `/src/src/components/`: React UI components
  - `DashboardWidget.js`: Configurable dashboard widget
  - `EmojiReaction.js`: Interactive emoji feedback component
  - `Layout.js`: Application layout and structure
  - `OnboardingTour.js`: User onboarding flow
- `/src/src/components/charts/`: Data visualization
  - Various chart types (Bar, Line, Pie, etc.)
- `/src/src/pages/`: Application pages
  - `Dashboard.js`: Main dashboard
  - `Deployments.js`: Deployment management
  - `Infrastructure.js`: Infrastructure view
  - `Monitoring.js`: System monitoring
  - `Security.js`: Security management
  - `Settings.js`: Application settings

### `/server` - Backend Services

- `/server/db.ts`: Database connection and configuration

### `/routes` - API Routes

- `/routes/api.js`: REST API routes and handlers

### `/models` - Database Models

- `/models/index.js`: Sequelize model definitions

### `/public` & `/assets` - Static Assets

- Various icons, images, and static resources

### `/terraform` - Infrastructure as Code

- Various `.tf` files defining AWS infrastructure
- `/terraform/lambda/`: AWS Lambda function implementations
- `/terraform/canary/`: Canary deployment configurations

### `/docs` - Documentation

- Architecture, deployment, security documentation

### `/scripts` - Automation Scripts

- Various shell scripts for deployment, monitoring, etc.

### `/nginx` - Web Server Configuration

- NGINX configuration for production deployments

## Large Files

The following large files are tracked with Git LFS:
- `SmartSphere.tar.gz`
- `terraform.zip`
- Large image assets in `/Assests/`

For instructions on working with these large files, see [GIT_LFS_INSTRUCTIONS.md](./GIT_LFS_INSTRUCTIONS.md).

## GitHub Workflows

- `.github/workflows/lfs-upload.yml`: Workflow to handle Git LFS uploads
- `.github/workflows/ci.yml`: Continuous Integration workflow
- `.github/workflows/cd.yml`: Continuous Deployment workflow
