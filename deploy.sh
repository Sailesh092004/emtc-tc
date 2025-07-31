#!/bin/bash

# eMTC Backend Deployment Script
# This script helps automate the deployment process to Render

echo "🚀 eMTC Backend Deployment Script"
echo "======================================"

# Check if git is initialized
if [ ! -d ".git" ]; then
    echo "📁 Initializing git repository..."
    git init
fi

# Add all files
echo "📦 Adding files to git..."
git add .

# Check if there are changes to commit
if git diff --cached --quiet; then
    echo "✅ No changes to commit"
else
    echo "💾 Committing changes..."
    git commit -m "Update eMTC backend - $(date)"
fi

# Check if remote is set
if ! git remote get-url origin > /dev/null 2>&1; then
    echo "⚠️  No remote repository set."
    echo "Please add your GitHub repository:"
    echo "git remote add origin https://github.com/your-username/emtc"
    echo ""
    echo "Then run this script again."
    exit 1
fi

# Push to GitHub
echo "🚀 Pushing to GitHub..."
if git push origin main; then
    echo "✅ Successfully pushed to GitHub!"
    echo ""
    echo "🎯 Next Steps:"
    echo "1. Go to https://dashboard.render.com/"
    echo "2. Click 'New +' → 'Web Service'"
    echo "3. Connect your GitHub repository"
    echo "4. Configure the service:"
    echo "   - Name: emtc-backend"
    echo "   - Environment: Docker"
    echo "   - Dockerfile Path: backend/Dockerfile"
    echo "5. Click 'Create Web Service'"
    echo ""
    echo "📱 After deployment, update your mobile app:"
    echo "   Update _baseUrl in lib/services/api_service.dart"
    echo "   to your Render URL"
else
    echo "❌ Failed to push to GitHub"
    echo "Please check your git configuration and try again."
    exit 1
fi

echo ""
echo "🎉 Deployment script completed!" 