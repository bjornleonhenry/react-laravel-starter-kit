#!/usr/bin/env bash
set -euo pipefail  # Exit on any error
# Repair script for React-Laravel Starter Kit
# Usage: ./repair.sh [--yes] [--force] [--backend] [--frontend] [--composer]
# Default: repairs all components interactively
# --yes: skip confirmations
# --force: skip confirmations and do aggressive cleaning
# --backend: only repair backend
# --frontend: only repair frontend
# --composer: only repair composer dependencies

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

prompt() {
    echo -e "${CYAN}$1${NC}"
}fortunes

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

# Function to confirm destructive operations
confirm_action() {
    local message="$1"
    local default_yes="$2"

    if [ "$SKIP_CONFIRMATIONS" = true ]; then
        return 0
    fi

    if [ "$default_yes" = true ]; then
        read -p "$(prompt "$message (Y/n): ")" -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Nn]$ ]]
    else
        read -p "$(prompt "$message (y/N): ")" -n 1 -r
        echo
        [[ $REPLY =~ ^[Yy]$ ]]
    fi
}

# Function to safely remove directory
safe_remove() {
    local path="$1"
    local description="$2"

    if [ -e "$path" ]; then
        info "Removing $description..."
        rm -rf "$path"
        success "$description removed"
    else
        info "$description not found, skipping"
    fi
}

# Function to clean backend
clean_backend() {
    info "Cleaning backend..."
    cd backend

    # Remove vendor directory
    safe_remove "vendor" "vendor directory"

    # Remove composer lock file
    safe_remove "composer.lock" "composer.lock file"

    # Remove node_modules
    safe_remove "node_modules" "node_modules directory"

    # Remove lockfiles
    safe_remove "package-lock.json" "package-lock.json"
    safe_remove "yarn.lock" "yarn.lock"
    safe_remove "pnpm-lock.yaml" "pnpm-lock.yaml"

    # Clear Laravel caches
    info "Clearing Laravel caches..."
    if [ -f "artisan" ]; then
        php artisan config:clear 2>/dev/null || true
        php artisan route:clear 2>/dev/null || true
        php artisan view:clear 2>/dev/null || true
        php artisan cache:clear 2>/dev/null || true
        success "Laravel caches cleared"
    fi

    # Aggressive cleaning in force mode
    if [ "$FORCE_MODE" = true ]; then
        warning "Force mode: Performing aggressive cleaning..."

        # Remove additional cache directories
        safe_remove "storage/framework/cache" "framework cache directory"
        safe_remove "storage/framework/sessions" "session cache directory"
        safe_remove "storage/framework/views" "compiled views cache"
        safe_remove "storage/logs" "log files"
        safe_remove "bootstrap/cache" "bootstrap cache directory"

        # Remove additional files that might cause issues
        safe_remove ".env.backup" ".env backup file"
        safe_remove "storage/app/.gitkeep" ".gitkeep files in storage"

        # Clear additional caches
        if [ -f "artisan" ]; then
            php artisan optimize:clear 2>/dev/null || true
            success "All Laravel caches cleared aggressively"
        fi
    fi

    cd ..
    success "Backend cleaned!"
    echo ""
}

# Function to clean frontend
clean_frontend() {
    info "Cleaning frontend..."
    cd frontend

    # Remove node_modules
    safe_remove "node_modules" "node_modules directory"

    # Remove lockfiles
    safe_remove "package-lock.json" "package-lock.json"
    safe_remove "yarn.lock" "yarn.lock"
    safe_remove "pnpm-lock.yaml" "pnpm-lock.yaml"

    cd ..
    success "Frontend cleaned!"
    echo ""
}

# Function to reinstall backend
reinstall_backend() {
    info "Reinstalling backend dependencies..."
    cd backend

    # Install Composer dependencies
    info "Installing Composer dependencies..."
    composer install --no-interaction

    # Determine package manager
    local package_manager=""
    if command -v pnpm &> /dev/null; then
        package_manager="pnpm"
    elif command -v yarn &> /dev/null; then
        package_manager="yarn"
    elif command -v npm &> /dev/null; then
        package_manager="npm"
    fi

    if [ -n "$package_manager" ]; then
        info "Installing Node.js dependencies with $package_manager..."
        if [ "$package_manager" = "pnpm" ]; then
            pnpm install
            # Auto-approve build scripts for common packages
            (echo "y"; echo "y") | pnpm approve-builds >/dev/null 2>&1 || true
        elif [ "$package_manager" = "yarn" ]; then
            yarn install
        else
            npm install
        fi
        success "Node.js dependencies installed"
    fi

    # Generate application key if .env exists
    if [ -f ".env" ]; then
        info "Generating application key..."
        php artisan key:generate --force
        success "Application key generated"
    fi

    cd ..
    success "Backend dependencies reinstalled!"
    echo ""
}

# Function to reinstall frontend
reinstall_frontend() {
    info "Reinstalling frontend dependencies..."
    cd frontend

    # Determine package manager
    local package_manager=""
    if command -v pnpm &> /dev/null; then
        package_manager="pnpm"
    elif command -v yarn &> /dev/null; then
        package_manager="yarn"
    elif command -v npm &> /dev/null; then
        package_manager="npm"
    fi

    if [ -n "$package_manager" ]; then
        info "Installing dependencies with $package_manager..."
        if [ "$package_manager" = "pnpm" ]; then
            pnpm install
            # Auto-approve build scripts for common packages
            (echo "y"; echo "y") | pnpm approve-builds >/dev/null 2>&1 || true
        elif [ "$package_manager" = "yarn" ]; then
            yarn install
        else
            npm install
        fi
        success "Dependencies installed"
    fi

    cd ..
    success "Frontend dependencies reinstalled!"
    echo ""
}

# Parse command line arguments
REPAIR_COMPOSER=true
REPAIR_BACKEND=true
REPAIR_FRONTEND=true
SKIP_CONFIRMATIONS=false
FORCE_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --yes)
            SKIP_CONFIRMATIONS=true
            shift
            ;;
        --force)
            SKIP_CONFIRMATIONS=true
            FORCE_MODE=true
            shift
            ;;
        --composer)
            REPAIR_COMPOSER=true
            REPAIR_BACKEND=false
            REPAIR_FRONTEND=false
            shift
            ;;
        --backend)
            REPAIR_COMPOSER=false
            REPAIR_BACKEND=true
            REPAIR_FRONTEND=false
            shift
            ;;
        --frontend)
            REPAIR_COMPOSER=false
            REPAIR_BACKEND=false
            REPAIR_FRONTEND=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--yes] [--force] [--composer] [--backend] [--frontend]"
            echo ""
            echo "Options:"
            echo "  --yes       Skip all confirmations"
            echo "  --force     Skip confirmations and do aggressive cleaning"
            echo "  --composer  Only repair Composer dependencies"
            echo "  --backend   Only repair backend Node.js dependencies"
            echo "  --frontend  Only repair frontend Node.js dependencies"
            echo ""
            echo "Default: Repairs all components interactively"
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo "React-Laravel Starter Kit Repair Tool"
echo ""

# Check if we're in the right directory
if [ ! -d "backend" ] || [ ! -d "frontend" ]; then
    error "Please run this script from the root directory containing 'backend' and 'frontend' folders."
    exit 1
fi

# Check system requirements
check_requirements

# Show repair plan
echo "Repair Plan:"
if [ "$FORCE_MODE" = true ]; then
    warning "FORCE MODE: Aggressive cleaning enabled!"
fi
if [ "$REPAIR_COMPOSER" = true ]; then
    echo "  Clean and reinstall Composer dependencies (backend)"
fi
if [ "$REPAIR_BACKEND" = true ]; then
    echo "  Clean and reinstall Node.js dependencies (backend)"
fi
if [ "$REPAIR_FRONTEND" = true ]; then
    echo "  Clean and reinstall Node.js dependencies (frontend)"
fi
echo ""

# Confirm repair operation
confirmation_message="This will delete node_modules, lockfiles, and reinstall dependencies."
if [ "$FORCE_MODE" = true ]; then
    confirmation_message="$confirmation_message This will also perform aggressive cleaning of caches and logs."
fi
confirmation_message="$confirmation_message Continue?"

if ! confirm_action "$confirmation_message" false; then
    info "Repair cancelled."
    exit 0
fi

# Start repair process
warning "Starting repair process... This may take several minutes."

# Clean operations
if [ "$REPAIR_COMPOSER" = true ] || [ "$REPAIR_BACKEND" = true ]; then
    clean_backend
fi

if [ "$REPAIR_FRONTEND" = true ]; then
    clean_frontend
fi

# Reinstall operations
if [ "$REPAIR_COMPOSER" = true ]; then
    reinstall_backend
fi

if [ "$REPAIR_BACKEND" = true ]; then
    reinstall_backend
fi

if [ "$REPAIR_FRONTEND" = true ]; then
    reinstall_frontend
fi

# Final verification
info "Running final verification..."

# Check if key files exist
verification_passed=true

if [ "$REPAIR_COMPOSER" = true ]; then
    if [ ! -d "backend/vendor" ]; then
        error "Composer dependencies not properly installed"
        verification_passed=false
    fi
fi

if [ "$REPAIR_BACKEND" = true ]; then
    if [ ! -d "backend/node_modules" ]; then
        error "Backend Node.js dependencies not properly installed"
        verification_passed=false
    fi
fi

if [ "$REPAIR_FRONTEND" = true ]; then
    if [ ! -d "frontend/node_modules" ]; then
        error "Frontend Node.js dependencies not properly installed"
        verification_passed=false
    fi
fi

if [ "$verification_passed" = true ]; then
    success "Repair completed successfully!"
    echo ""
    echo "Next steps:"
    echo "  - Test your application: cd backend && php artisan serve"
    echo "  - Start frontend: cd frontend && npm run dev (or pnpm dev)"
    echo "  -极 Run database migrations if needed: cd backend && php artisan migrate"
    echo ""
    echo "If you still have issues, check the error messages above or try:"
    echo "  - ./setup.sh (complete fresh setup)"
    echo "  - ./update.sh (update existing dependencies)"
else
    error "Repair completed with issues. Please check the error messages above."
    echo ""
    echo "Troubleshooting suggestions:"
    echo "  - Check your internet connection"
    echo "  - Verify system requirements with './check.sh'"
    echo "  - Try running the script again"
    echo "  - Check logs for more detailed error information"
    exit 1
fi
