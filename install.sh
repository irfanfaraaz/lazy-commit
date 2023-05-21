#!/bin/bash

# lazy-commit plugin installer
# Installs the lazy-commit plugin to ~/.claude/plugins/

set -e

REPO_URL="https://github.com/irfanfaraaz/lazy-commit.git"
INSTALL_DIR="${HOME}/.claude/plugins/lazy-commit"

echo "Installing lazy-commit plugin..."
echo "Repository: $REPO_URL"
echo "Install path: $INSTALL_DIR"
echo ""

# Create plugins directory if it doesn't exist
mkdir -p "${HOME}/.claude/plugins"

# Clone or update the repository
if [ -d "$INSTALL_DIR" ]; then
    echo "Directory exists. Updating..."
    cd "$INSTALL_DIR"
    git pull origin main
else
    echo "Cloning repository..."
    git clone "$REPO_URL" "$INSTALL_DIR"
fi

echo ""
echo "✅ Installation complete!"
echo ""
echo "Next steps:"
echo "1. Verify git-filter-repo is installed:"
echo "   brew install git-filter-repo     # macOS"
echo "   pip install git-filter-repo      # Linux/Windows"
echo ""
echo "2. Test the plugin by running:"
echo "   /lazy-commit spread my commits from [start-date] to [end-date]"
echo ""
echo "For more information, see: $INSTALL_DIR/README.md"
