#!/bin/bash

set -e

BRANCH_NAME="$1"
COMMIT_MESSAGE="$2"

if [ -z "$BRANCH_NAME" ] || [ -z "$COMMIT_MESSAGE" ]; then
    echo "Usage: $0 <branch-name> \"<commit-message>\""
    exit 1
fi

echo "Switching to main..."
git checkout main

echo "Pulling latest changes..."
git pull origin main

echo "Creating branch: $BRANCH_NAME"
git checkout -b "$BRANCH_NAME"

echo "Adding files..."
git add .

echo "Committing changes..."
git commit -m "$COMMIT_MESSAGE"

echo "Pushing branch..."
git push -u origin "$BRANCH_NAME"

echo "Switching back to main..."
git checkout main

echo "Deleting local branch..."
git branch -D "$BRANCH_NAME"

echo ""
echo "✅ Done!"
echo "Branch '$BRANCH_NAME' has been pushed to origin."
echo "Create a PR when ready."  