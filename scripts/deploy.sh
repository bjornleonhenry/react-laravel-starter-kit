#!/usr/bin/env bash
set -euo pipefail  # Exit on any error
# Deploy script for React-Laravel Starter Kit
# Usage: ./deploy.sh [platform] [options]
# Platforms: vercel, netlify, heroku, railway, digitalocean, aws
# Options: --frontend, --backend, --full (default: --full)

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helper functions for colored output
error() {
    echo -e "${RED}Error:${NC} $1"
}

success() {
    echo -e "${GREEN}$1${NC}"
}

warning() {
    echo -e "${YELLOW}Warning:${NC} $1"
}

info() {
    echo -e "${BLUE}$1${NC}"
}

# Function to check if Vercel CLI is installed
check_vercel_cli() {
    if ! command -v vercel &> /dev/null; then
        error "Vercel CLI not found. Please install it with: npm install -g vercel"
        exit 1
    fi
    success "Vercel CLI is available"
}

# Function to deploy to Vercel
deploy_vercel() {
    local deploy_type="$1"
    
    check_vercel_cli
    
    case "$deploy_type" in
        frontend)
            info "Deploying frontend to Vercel..."
            cd frontend
            vercel --prod
            cd ..
            ;;
        backend)
            info "Deploying backend to Vercel..."
            warning "Note: Vercel is primarily for frontend. Backend may require different platform."
            cd backend
            vercel --prod
            cd ..
            ;;
        full)
            info "Deploying full stack to Vercel..."
            warning "Full stack deployment may require separate frontend/backend projects"
            # Build frontend first
            cd frontend
            npm run build
            vercel --prod
            cd ..
            ;;
    esac
}

# Function to deploy to Netlify
deploy_netlify() {
    local deploy_type="$1"
    
    if ! command -v netlify &> /dev/null; then
        error "Netlify CLI not found. Please install it with: npm install -g netlify-cli"
        exit 1
    fi
    
    info "Deploying to Netlify..."
    
    if [ "$deploy_type" = "frontend" ] || [ "$deploy_type" = "full" ]; then
        cd frontend
        npm run build
        netlify deploy --prod --dir=dist
        cd ..
    fi
}

# Function to deploy to Heroku
deploy_heroku() {
    local deploy_type="$1"
    
    if ! command -v heroku &> /dev/null; then
        error "Heroku CLI not found. Please install it from https://devcenter.heroku.com/articles/heroku-cli"
        exit 1
    fi
    
    info "Deploying to Heroku..."
    
    if [ "$deploy_type" = "backend" ] || [ "$deploy_type" = "full" ]; then
        cd backend
        # Heroku typically uses git push for deployment
        git add .
        git commit -m "Deploy to Heroku" || true
        git push heroku main
        cd ..
    fi
}

# Function to show deployment help
show_help() {
    echo "Deploy Script for React-Laravel Starter Kit"
    echo ""
    echo "Usage: $0 [platform] [options]"
    echo ""
    echo "Platforms:"
    echo "  vercel        Deploy to Vercel (frontend focused)"
    echo "  netlify       Deploy to Netlify"
    echo "  heroku        Deploy to Heroku (backend focused)"
    echo "  railway       Deploy to Railway"
    echo "  digitalocean  Deploy to DigitalOcean App Platform"
    echo "  aws           Deploy to AWS"
    echo ""
    echo "Options:"
    echo "  --frontend    Deploy only frontend"
    echo "  --backend     Deploy only backend"
    echo "  --full        Deploy full stack (default)"
    echo "  --help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 vercel --frontend    # Deploy frontend to Vercel"
    echo "  $0 heroku --backend     # Deploy backend to Heroku"
    echo "  $0 netlify --full       # Deploy full stack to Netlify"
}

# Parse command line arguments
PLATFORM=""
DEPLOY_TYPE="full"

while [[ $# -gt 0 ]]; do
    case $1 in
        vercel|netlify|heroku|railway|digitalocean|aws)
            PLATFORM="$1"
            shift
            ;;
        --frontend)
            DEPLOY_TYPE="frontend"
            shift
            ;;
        --backend)
            DEPLOY_TYPE="backend"
            shift
            ;;
        --full)
            DEPLOY_TYPE="full"
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Main deployment logic
if [ -z "$PLATFORM" ]; then
    error "Please specify a deployment platform"
    show_help
    exit 1
fi

echo "Deploying React-Laravel Starter Kit"
echo "Platform: $PLATFORM"
echo "Type: $DEPLOY_TYPE"
echo ""

case "$PLATFORM" in
    vercel)
        deploy_vercel "$DEPLOY_TYPE"
        ;;
    netlify)
        deploy_netlify "$DEPLOY_TYPE"
        ;;
    heroku)
        deploy_heroku "$DEPLOY_TYPE"
        ;;
    railway)
        info "Railway deployment would be implemented here"
        warning "Railway deployment not yet implemented"
        ;;
    digitalocean)
        info "DigitalOcean App Platform deployment would be implemented here"
        warning "DigitalOcean deployment not yet implemented"
        ;;
    aws)
        info "AWS deployment would be implemented here"
        warning "AWS deployment not yet implemented"
        ;;
    *)
        error "Unsupported platform: $PLATFORM"
        show_help
        exit 1
        ;;
esac

success "Deployment process completed!"
info "Check your deployment platform dashboard for status updates"
