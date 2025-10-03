#!/usr/bin/env bash
set -euo pipefail  # Exit on any error
# Update script for React-Laravel Starter Kit
# Usage: ./update.sh [--composer] [--backend] [--frontend]
# Default: updates all (composer in backend, node in frontend and backend)


# Source common functions and variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

info "Updating React-Laravel Starter Kit..."
echo

# Function to check system requirements
check_requirements() {
    echo "Checking system requirements..."
    local requirements_met=true

    # Check PHP
    check_php || requirements_met=false

    # Check Composer
    check_composer || requirements_met=false

    # Check Node.js
    check_nodejs || requirements_met=false

    # Check package managers
    available_managers=()
    if command -v pnpm &> /dev/null; then
        available_managers+=("pnpm")
    fi
    if command -v yarn &> /dev/null; then
        available_managers+=("yarn")
    fi
    if command -v npm &> /dev/null; then
        available_managers+=("npm")
    fi

    if [ ${#available_managers[@]} -eq 0 ]; then
        error "No package managers found - Please install npm, pnpm, or yarn"
        requirements_met=false
    else
        echo "Available package managers: ${available_managers[*]}"
    fi

    if [ "$requirements_met" = false ]; then
        error "System requirements not met. Please install missing dependencies and try again."
        exit 1
    fi

    success "All system requirements met!"
    echo ""
}

# Parse command line arguments
UPDATE_COMPOSER=true
UPDATE_BACKEND=true
UPDATE_FRONTEND=true

while [[ $# -gt 0 ]]; do
    case $1 in
        --composer)
            UPDATE_COMPOSER=true
            UPDATE_BACKEND=false
            UPDATE_FRONTEND=false
            shift
            ;;
        --backend)
            UPDATE_COMPOSER=false
            UPDATE_BACKEND=true
            UPDATE_FRONTEND=false
            shift
            ;;
        --frontend)
            UPDATE_COMPOSER=false
            UPDATE_BACKEND=false
            UPDATE_FRONTEND=true
            shift
            ;;
        *)
            error "Unknown option: $1"
            echo "Usage: $0 [--composer] [--backend] [--frontend]"
            echo "Default: updates all (composer in backend, node in frontend and backend)"
            exit 1l
            ;;
    esac
done

# Check if we're in the right directory
if [ ! -d "backend" ] || [ ! -d "frontend" ]; then
    error "Please run this script from the root directory containing 'backend' and 'frontend' folders."
    exit 1
fi

# Check system requirements
check_requirements

# Determine package manager to use
PACKAGE_MANAGER=$(get_package_manager)
if [ $? -ne 0 ] || [ -z "$PACKAGE_MANAGER" ]; then
    exit 1
fi

info "Using $PACKAGE_MANAGER for all Node.js operations..."
echo

# Update Composer dependencies in backend
if [ "$UPDATE_COMPOSER" = true ]; then
    info "Updating Composer dependencies in backend..."
    cd backend

    echo "Updating Composer dependencies..."
    composer update --no-interaction

    cd ..
    success "Composer dependencies updated!"
    echo ""
fi

# Update Node.js dependencies in backend
if [ "$UPDATE_BACKEND" = true ]; then
    info "Updating Node.js dependencies in backend..."
    cd backend

    info "Updating Node.js dependencies..."
    run_package_update "$PACKAGE_MANAGER" "."
    # Special handling for pnpm approve-builds
    if [ "$PACKAGE_MANAGER" = "pnpm" ]; then
        (echo "y"; echo "y") | pnpm approve-builds >/dev/null 2>&1 || true
    fi

    cd ..
    success "Backend Node.js dependencies updated!"
    echo
fi

# Update Node.js dependencies in frontend
if [ "$UPDATE_FRONTEND" = true ]; then
    info "Updating Node.js dependencies in frontend..."
    cd frontend

    info "Updating Node.js dependencies..."
    run_package_update "$PACKAGE_MANAGER" "."
    # Special handling for pnpm approve-builds
    if [ "$PACKAGE_MANAGER" = "pnpm" ]; then
        (echo "y"; echo "y") | pnpm approve-builds >/dev/null 2>&1 || true
    fi

    cd ..
    success "Frontend Node.js dependencies updated!"
    echo
fi

# Clear caches if backend was updated
if [ "$UPDATE_COMPOSER" = true ] || [ "$UPDATE_BACKEND" = true ]; then
    info "Clearing Laravel caches..."
    cd backend

    echo "Clearing configuration cache..."
    php artisan config:clear

    echo "Clearing route cache..."
    php artisan route:clear

    echo "Clearing view cache..."
    php artisan view:clear

    echo "Optimizing application..."
    php artisan optimize

    cd ..
    success "Laravel caches cleared and application optimized!"
    echo ""
fi

# Final summary
success "Update complete!"

if [ "$UPDATE_COMPOSER" = true ] && [ "$UPDATE_BACKEND" = true ] && [ "$UPDATE_FRONTEND" = true ]; then
    echo ""
    echo "All dependencies have been updated:"
    echo "  ✅ Composer dependencies in backend"
    echo "  ✅ Node.js dependencies in backend"
    echo "  ✅ Node.js dependencies in frontend"
    echo "  ✅ Laravel caches cleared and optimized"
elif [ "$UPDATE_COMPOSER" = true ]; then
    echo ""
    echo "Updated:"
    echo "  ✅ Composer dependencies in backend"
    echo "  ✅ Laravel caches cleared and optimized"
elif [ "$UPDATE_BACKEND" = true ]; then
    echo ""
    echo "Updated:"
    echo "  ✅ Node.js dependencies in backend"
    echo "  ✅ Laravel caches cleared and optimized"
elif [ "$UPDATE_FRONTEND" = true ]; then
    echo ""
    echo "Updated:"
    echo "  ✅ Node.js dependencies in frontend"
fi

success "Setup complete!"