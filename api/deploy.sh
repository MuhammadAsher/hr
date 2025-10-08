#!/bin/bash

# HR Management SaaS Platform - API Documentation Deployment Script
# This script helps you deploy your API documentation to various platforms

echo "🚀 HR Management SaaS Platform - API Documentation Deployment"
echo "=============================================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to display menu
show_menu() {
    echo "Choose deployment option:"
    echo ""
    echo "1) 🌐 GitHub Pages (FREE - Recommended)"
    echo "2) 🚀 Netlify (FREE)"
    echo "3) ⚡ Vercel (FREE)"
    echo "4) 🖥️  Local Server (Testing)"
    echo "5) 📋 View deployment instructions"
    echo "6) ❌ Exit"
    echo ""
}

# Function to deploy to GitHub Pages
deploy_github_pages() {
    echo -e "${BLUE}Deploying to GitHub Pages...${NC}"
    echo ""
    
    # Check if git is initialized
    if [ ! -d .git ]; then
        echo -e "${YELLOW}Git repository not initialized. Initializing...${NC}"
        git init
    fi
    
    # Add and commit files
    git add api/
    git commit -m "Add API documentation"
    
    # Push to GitHub
    echo ""
    echo -e "${YELLOW}Please push to GitHub and enable GitHub Pages:${NC}"
    echo "1. Push: git push origin main"
    echo "2. Go to repository Settings → Pages"
    echo "3. Source: Deploy from branch 'main' → '/api' folder"
    echo "4. Click Save"
    echo ""
    echo -e "${GREEN}Your docs will be at: https://YOUR_USERNAME.github.io/YOUR_REPO_NAME/${NC}"
}

# Function to deploy to Netlify
deploy_netlify() {
    echo -e "${BLUE}Deploying to Netlify...${NC}"
    echo ""
    
    # Check if netlify-cli is installed
    if ! command -v netlify &> /dev/null; then
        echo -e "${YELLOW}Netlify CLI not found. Installing...${NC}"
        npm install -g netlify-cli
    fi
    
    # Create netlify.toml if it doesn't exist
    if [ ! -f api/netlify.toml ]; then
        cat > api/netlify.toml << EOF
[build]
  publish = "."

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
EOF
        echo -e "${GREEN}Created netlify.toml${NC}"
    fi
    
    # Deploy
    cd api
    netlify deploy --prod
    cd ..
    
    echo ""
    echo -e "${GREEN}✅ Deployed to Netlify!${NC}"
}

# Function to deploy to Vercel
deploy_vercel() {
    echo -e "${BLUE}Deploying to Vercel...${NC}"
    echo ""
    
    # Check if vercel-cli is installed
    if ! command -v vercel &> /dev/null; then
        echo -e "${YELLOW}Vercel CLI not found. Installing...${NC}"
        npm install -g vercel
    fi
    
    # Deploy
    cd api
    vercel --prod
    cd ..
    
    echo ""
    echo -e "${GREEN}✅ Deployed to Vercel!${NC}"
}

# Function to start local server
start_local_server() {
    echo -e "${BLUE}Starting local server...${NC}"
    echo ""
    
    # Check if Python is available
    if command -v python3 &> /dev/null; then
        echo -e "${GREEN}Starting Python HTTP server...${NC}"
        echo -e "${YELLOW}Open: http://localhost:8000${NC}"
        cd api
        python3 -m http.server 8000
        cd ..
    elif command -v python &> /dev/null; then
        echo -e "${GREEN}Starting Python HTTP server...${NC}"
        echo -e "${YELLOW}Open: http://localhost:8000${NC}"
        cd api
        python -m SimpleHTTPServer 8000
        cd ..
    elif command -v npx &> /dev/null; then
        echo -e "${GREEN}Starting Node.js HTTP server...${NC}"
        echo -e "${YELLOW}Open: http://localhost:8000${NC}"
        npx http-server api -p 8000
    else
        echo -e "${YELLOW}No suitable HTTP server found.${NC}"
        echo "Please install Python or Node.js to run a local server."
    fi
}

# Function to show deployment instructions
show_instructions() {
    echo -e "${BLUE}📋 Deployment Instructions${NC}"
    echo ""
    echo "=== GitHub Pages (FREE) ==="
    echo "1. Push code to GitHub"
    echo "2. Go to Settings → Pages"
    echo "3. Select branch 'main' and '/api' folder"
    echo "4. Your docs: https://USERNAME.github.io/REPO/"
    echo ""
    echo "=== Netlify (FREE) ==="
    echo "1. Go to https://netlify.com"
    echo "2. Drag and drop the 'api' folder"
    echo "3. Your docs: https://YOUR_SITE.netlify.app"
    echo ""
    echo "=== Vercel (FREE) ==="
    echo "1. Install: npm install -g vercel"
    echo "2. Run: cd api && vercel"
    echo "3. Your docs: https://YOUR_PROJECT.vercel.app"
    echo ""
    echo "=== Swagger Hub (FREE for public APIs) ==="
    echo "1. Go to https://app.swaggerhub.com/"
    echo "2. Create account"
    echo "3. Import api/openapi.yaml"
    echo "4. Your docs: https://app.swaggerhub.com/apis/USERNAME/hr-platform/1.0.0"
    echo ""
}

# Main script
while true; do
    show_menu
    read -p "Enter your choice [1-6]: " choice
    echo ""
    
    case $choice in
        1)
            deploy_github_pages
            ;;
        2)
            deploy_netlify
            ;;
        3)
            deploy_vercel
            ;;
        4)
            start_local_server
            ;;
        5)
            show_instructions
            ;;
        6)
            echo -e "${GREEN}Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${YELLOW}Invalid option. Please try again.${NC}"
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
    clear
done

