#!/usr/bin/env bash
set -euo pipefail  # Exit on any error
# Optimize script for React-Laravel Starter Kit
# Usage: ./optimize.sh [--clear] [--laravel] [--composer] [--backend] [--frontend]
# Default: optimizes all components
# --clear: clear caches before optimizing
# --laravel: only optimize Laravel (artisan commands)
# --composer: only optimize Composer
# --backend: only optimize backend Node.js
# --frontend: only optimize frontend Node.js

set -e  # Exit on any error

# Source common functions and variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Function to check system requirements
check_requirements() {
    info "Checking system requirements..."
    local requirements_met=true

    # Check PHP
    check_php || requirements_met=false

    # Check Composer
    check_composer || requirements_met=false

    # Check Node.js
    check_nodejs || requirements_met=false

    # Check package managers
    check_package_managers || requirements_met=false

    if [ "$requirements_met" = false ]; then
        error "System requirements not met. Please install missing dependencies and try again."
        exit 1
    fi

    success "All system requirements met!"
    echo
}

# Function to optimize Laravel
optimize_laravel() {
    info "Optimizing Laravel application..."
    cd backend

    if [ "$CLEAR_CACHES" = true ]; then
        info "Clearing existing caches..."
        php artisan optimize:clear 2>/dev/null || warning "Some caches could not be cleared (this is normal)"
        success "Caches cleared"
    fi

    info "Running Laravel optimizations..."

    # Configuration caching
    info "Caching configuration..."
    php artisan config:cache
    success "Configuration cached"

    # Route caching
    info "Caching routes..."
    php artisan route:cache
    success "Routes cached"

    # View caching (optional, skip if not configured)
    info "Caching views..."
    if php artisan view:cache 2>/dev/null; then
        success "Views cached"
    else
        warning "View caching skipped (view.compiled path not configured)"
    fi

    # General optimization
    info "Running general optimizations..."
    if php artisan optimize 2>/dev/null; then
        success "General optimizations completed"
    else
        warning "General optimizations partially completed (view caching skipped)"
    fi

    # Event caching (if using events)
    if php artisan event:list &> /dev/null; then
        info "Caching events..."
        php artisan event:cache
        success "Events cached"
    fi

    cd ..
    success "Laravel optimization complete!"
    echo ""
}

# Function to optimize Composer
optimize_composer() {
    info "Optimizing Composer dependencies..."
    cd backend

    # Dump autoload with optimization
    info "Optimizing autoloader..."
    composer dump-autoload --optimize
    success "Autoloader optimized"

    # Install with optimized autoloader (if composer.lock exists)
    if [ -f "composer.lock" ]; then
        info "Installing with optimized autoloader..."
        composer install --optimize-autoloader --no-dev --no-interaction
        success "Dependencies installed with optimized autoloader"
    fi

    cd ..
    success "Composer optimization complete!"
    echo ""
}

# Function to optimize backend Node.js
optimize_backend_nodejs() {
    info "Optimizing backend Node.js dependencies..."
    cd backend

    # Determine package manager
    local package_manager=""
    if [ -f "pnpm-lock.yaml" ] && command -v pnpm &> /dev/null; then
        package_manager="pnpm"
    elif [ -f "yarn.lock" ] && command -v yarn &> /dev/null; then
        package_manager="yarn"
    elif [ -f "package-lock.json" ] && command -v npm &> /dev/null; then
        package_manager="npm"
    elif command -v pnpm &> /dev/null; then
        package_manager="pnpm"
    elif command -v yarn &> /dev/null; then
        package_manager="yarn"
    elif command -v npm &> /dev/null; then
        package_manager="npm"
    fi

    if [ -n "$package_manager" ]; then
        info "Running $package_manager optimizations..."

        case $package_manager in
            "pnpm")
                # pnpm specific optimizations
                pnpm install --frozen-lockfile
                ;;
            "yarn")
                # yarn specific optimizations
                yarn install --frozen-lockfile
                ;;
            "npm")
                # npm specific optimizations
                npm ci
                ;;
        esac

        success "Node.js dependencies optimized with $package_manager"
    else
        warning "No suitable package manager found for backend optimization"
    fi

    cd ..
    success "Backend Node.js optimization complete!"
    echo ""
}

# Function to optimize frontend Node.js
optimize_frontend_nodejs() {
    info "Optimizing frontend Node.js dependencies and building for production..."
    cd frontend

    # Determine package manager
    local package_manager=""
    if [ -f "pnpm-lock.yaml" ] && command -v pnpm &> /dev/null; then
        package_manager="pnpm"
    elif [ -f "yarn.lock" ] && command -v yarn &> /dev/null; then
        package_manager="yarn"
    elif [ -f "package-lock.json" ] && command -v npm &> /dev/null; then
        package_manager="npm"
    elif command -v pnpm &> /dev/null; then
        package_manager="pnpm"
    elif command -v yarn &> /dev/null; then
        package_manager="yarn"
    elif command -v npm &> /dev/null; then
        package_manager="npm"
    fi

    if [ -n "$package_manager" ]; then
        info "Running $package_manager optimizations..."

        case $package_manager in
            "pnpm")
                # pnpm specific optimizations
                pnpm install --frozen-lockfile
                # Auto-approve build scripts
                (echo "y"; echo "y") | pnpm approve-builds >/dev/null 2>&1 || true
                ;;
            "yarn")
                # yarn specific optimizations
                yarn install --frozen-lockfile
                ;;
            "npm")
                # npm specific optimizations
                npm ci
                ;;
        esac

        success "Dependencies optimized with $package_manager"

        # Build for production
        info "Building frontend for production..."
        case $package_manager in
            "pnpm")
                pnpm run build
                ;;
            "yarn")
                yarn build
                ;;
            "npm")
                npm run build
                ;;
        esac

        success "Frontend built for production"
    else
        warning "No suitable package manager found for frontend optimization"
    fi

    cd ..
    success "Frontend Node.js optimization complete!"
    echo ""
}

# Parse command line arguments
OPTIMIZE_LARAVEL=true
OPTIMIZE_COMPOSER=true
OPTIMIZE_BACKEND=true
OPTIMIZE_FRONTEND=true
CLEAR_CACHES=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --clear)
            CLEAR_CACHES=true
            shift
            ;;
        --laravel)
            OPTIMIZE_LARAVEL=true
            OPTIMIZE_COMPOSER=false
            OPTIMIZE_BACKEND=false
            OPTIMIZE_FRONTEND=false
            shift
            ;;
        --composer)
            OPTIMIZE_LARAVEL=false
            OPTIMIZE_COMPOSER=true
            OPTIMIZE_BACKEND=false
            OPTIMIZE_FRONTEND=false
            shift
            ;;
        --backend)
            OPTIMIZE_LARAVEL=false
            OPTIMIZE_COMPOSER=false
            OPTIMIZE_BACKEND=true
            OPTIMIZE_FRONTEND=false
            shift
            ;;
        --frontend)
            OPTIMIZE_LARAVEL=false
            OPTIMIZE_COMPOSER=false
            OPTIMIZE_BACKEND=false
            OPTIMIZE_FRONTEND=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--clear] [--laravel] [--composer] [--backend] [--frontend]"
            echo ""
            echo "Options:"
            echo "  --clear     Clear caches before optimizing"
            echo "  --laravel   Only optimize Laravel (artisan commands)"
            echo "  --composer  Only optimize Composer dependencies"
            echo "  --backend   Only optimize backend Node.js"
            echo "  --frontend  Only optimize frontend Node.js"
            echo ""
            echo "Default: Optimizes all components"
            echo ""
            echo "Examples:"
            echo "  $0                    # Optimize everything"
            echo "  $0 --clear            # Clear caches first, then optimize"
            echo "  $0 --laravel          # Only Laravel optimizations"
            echo "  $0 --frontend         # Only frontend production build"
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo "React-Laravel Starter Kit Optimizer"
echo ""

# Check if we're in the right directory
if [ ! -d "backend" ] || [ ! -d "frontend" ]; then
    error "Please run this script from the root directory containing 'backend' and 'frontend' folders."
    exit 1
fi

# Check system requirements
check_requirements

# Show optimization plan
echo "Optimization Plan:"
if [ "$CLEAR_CACHES" = true ]; then
    warning "Cache clearing enabled"
fi
if [ "$OPTIMIZE_LARAVEL" = true ]; then
    echo "  Laravel optimizations (config, routes, views caching)"
fi
if [ "$OPTIMIZE_COMPOSER" = true ]; then
    echo "  Composer optimizations (autoloader, dependencies)"
fi
if [ "$OPTIMIZE_BACKEND" = true ]; then
    echo "  Backend Node.js optimizations"
fi
if [ "$OPTIMIZE_FRONTEND" = true ]; then
    echo "  Frontend Node.js optimizations + production build"
fi
echo ""

# Start optimization process
info "Starting optimization process..."

# Run optimizations
if [ "$OPTIMIZE_LARAVEL" = true ]; then
    optimize_laravel
fi

if [ "$OPTIMIZE_COMPOSER" = true ]; then
    optimize_composer
fi

if [ "$OPTIMIZE_BACKEND" = true ]; then
    optimize_backend_nodejs
fi

if [ "$OPTIMIZE_FRONTEND" = true ]; then
    optimize_frontend_nodejs
fi

# Final summary
success "Optimization complete!"

if [ "$OPTIMIZE_LARAVEL" = true ] && [ "$OPTIMIZE_COMPOSER" = true ] && [ "$OPTIMIZE_BACKEND" = true ] && [ "$OPTIMIZE_FRONTEND" = true ]; then
    echo ""
    echo "All optimizations completed:"
    echo "  Laravel configuration, routes, and views cached"
    echo "  Composer autoloader optimized"
    echo "  Backend dependencies optimized"
    echo "  Frontend built for production"
    echo ""
    echo "Your application is now optimized for production performance!"
elif [ "$OPTIMIZE_LARAVEL" = true ]; then
    echo ""
    echo "Laravel optimizations completed:"
    echo "  Configuration cached"
    echo "  Routes cached"
    echo "  Views cached"
    echo "  General optimizations applied"
elif [ "$OPTIMIZE_COMPOSER" = true ]; then
    echo ""
    echo "Composer optimizations completed:"
    echo "  Autoloader optimized"
    echo "  Dependencies installed with optimized autoloader"
elif [ "$OPTIMIZE_BACKEND" = true ]; then
    echo ""
    echo "Backend Node.js optimizations completed:"
    echo "  Dependencies optimized"
elif [ "$OPTIMIZE_FRONTEND" = true ]; then
    echo ""
    echo "Frontend Node.js optimizations completed:"
    echo "  Dependencies optimized"
    echo "  Production build completed"
fi
