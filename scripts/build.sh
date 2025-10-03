#!/usr/bin/env bash
set -euo pipefail  # Exit on any errorset -euo pipefail  # Exit on any error
# Build script for React-Laravel Starter Kit
# Usage: ./build.sh [--laravel] [--react]
# Default: builds both backend and frontend

# Source common functions and variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Parse command line arguments
BUILD_BACKEND=true
BUILD_FRONTEND=true

while [[ $# -gt 0 ]]; do
    case $1 in
        --laravel)
            BUILD_FRONTEND=false
            shift
            ;;
        --react)
            BUILD_BACKEND=false
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--laravel] [--react]"
            echo ""
            echo "Options:"
            echo "  --laravel    Build only the Laravel backend"
            echo "  --react      Build only the React frontend"
            echo "  -h, --help   Show this help message"
            echo ""
            echo "By default, builds both backend and frontend."
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            echo "Use --help for usage information."
            exit 1
            ;;
    esac
done

echo "Building React-Laravel Starter Kit..."
echo ""

# Function to check system requirements
check_requirements() {
    echo "Checking system requirements..."
    local requirements_met=true

    # Check PHP
    if command -v php &> /dev/null; then
        php_version=$(php -r "echo PHP_VERSION;")
        php_major=$(php -r "echo PHP_MAJOR_VERSION;")
        php_minor=$(php -r "echo PHP_MINOR_VERSION;")

        if [ "$php_major" -gt 8 ] || ([ "$php_major" -eq 8 ] && [ "$php_minor" -ge 2 ]); then
            success "PHP $php_version - OK"
        else
            error "PHP $php_version - Laravel 12 requires PHP 8.2 or higher"
            requirements_met=false
        fi
    else
        error "PHP not found - Please install PHP 8.2 or higher"
        requirements_met=false
    fi

    # Check Composer
    if command -v composer &> /dev/null; then
        composer_version=$(composer --version | grep -oP "version \K[^\s]+")
        success "Composer $composer_version - OK"
    else
        error "Composer not found - Please install Composer"
        requirements_met=false
    fi

    # Check Node.js
    if command -v node &> /dev/null; then
        node_version=$(node -v | sed 's/v//')
        node_major=$(node -v | sed 's/v//' | cut -d. -f1)

        if [ "$node_major" -ge 18 ]; then
            success "Node.js $node_version - OK"
        elif [ "$node_major" -ge 16 ]; then
            warning "Node.js $node_version - OK (but 18+ recommended)"
        else
            error "Node.js $node_version - Requires Node.js 16 or higher"
            requirements_met=false
        fi
    else
        error "Node.js not found - Please install Node.js 16 or higher"
        requirements_met=false
    fi

    if [ "$requirements_met" = false ]; then
        error "System requirements not met. Please install missing dependencies and try again."
        exit 1
    fi

    success "All system requirements met!"
    echo ""
}

# Check if we're in the right directory
if [ ! -d "backend" ] || [ ! -d "frontend" ]; then
    error "Please run this script from the root directory containing 'backend' and 'frontend' folders."
    exit 1
fi

# Check system requirements first
check_requirements

# Determine package manager to use
PACKAGE_MANAGER=$(get_package_manager)
if [ $? -ne 0 ] || [ -z "$PACKAGE_MANAGER" ]; then
    exit 1
fi

info "Using $PACKAGE_MANAGER for all Node.js operations..."
echo

# Backend build
if [ "$BUILD_BACKEND" = true ]; then
    info "Building backend (Laravel)..."
    cd backend

    # Install/update Composer dependencies
    echo "Installing Composer dependencies..."
    composer install --no-interaction --optimize-autoloader

    # Generate optimized autoload files
    echo "Optimizing autoloader..."
    composer dump-autoload --optimize

    # Clear and cache config
    echo "Caching configuration..."
    php artisan config:cache
    php artisan route:cache
    php artisan view:cache

    # Install Node.js dependencies and build assets
    info "Installing Node.js dependencies..."
    run_package_install "$PACKAGE_MANAGER" "." true
    info "Building Laravel assets..."
    run_package_build "$PACKAGE_MANAGER" "."

    cd ..
    success "Backend build complete!"
    echo ""
fi

# Frontend build
if [ "$BUILD_FRONTEND" = true ]; then
    info "Building frontend (React)..."
    cd frontend

    info "Using $PACKAGE_MANAGER for frontend build..."

    # Install dependencies
    info "Installing dependencies..."
    run_package_install "$PACKAGE_MANAGER" "." true

    # Build the frontend
    info "Building frontend..."
    run_package_build "$PACKAGE_MANAGER" "."

    cd ..
    success "Frontend build complete!"
    echo ""
fi

success "Build completed successfully!"

if [ "$BUILD_BACKEND" = true ] && [ "$BUILD_FRONTEND" = true ]; then
    echo ""
    info "Both backend and frontend have been built."
    echo "You can now deploy the application or run it in production."
elif [ "$BUILD_BACKEND" = true ]; then
    echo ""
    info "Backend build complete. Run './build.sh --react' to build the frontend."
elif [ "$BUILD_FRONTEND" = true ]; then
    echo ""
    info "Frontend build complete. Run './build.sh --laravel' to build the backend."
fi
