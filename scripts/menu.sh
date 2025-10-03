#!/usr/bin/env bash
set -euo pipefail  # Exit on any error
# Interactive menu script for React-Laravel Starter Kit
# Usage: ./scripts/menu.sh

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
    echo -e "${GREEN}$1${NC}"
}

prompt() {
    echo -e "${GREEN}$1${NC}"
}

# Function to confirm user actions
confirm_action() {
    local message="$1"
    local default_yes="$2"

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

# Function to check if setup is complete
check_setup() {
    local setup_complete=true

    # Check backend dependencies
    if [ ! -d "backend/vendor" ]; then
        warning "Backend vendor directory not found"
        setup_complete=false
    fi

    if [ ! -d "backend/node_modules" ]; then
        warning "Backend node_modules directory not found"
        setup_complete=false
    fi

    # Check frontend dependencies
    if [ ! -d "frontend/node_modules" ]; then
        warning "Frontend node_modules directory not found"
        setup_complete=false
    fi

    if [ "$setup_complete" = true ]; then
        success "Setup is complete"
        return 0
    else
        warning "Setup is incomplete - running setup script"
        return 1
    fi
}

# Function to run post-setup workflow
run_post_setup_workflow() {
    info "Setup completed successfully!"

    # Prompt for package updates
    if confirm_action "Would you like to update all packages to their latest versions?" true; then
        info "Updating packages..."
        ./scripts/update.sh
        success "Packages updated successfully!"
    fi

    # Run build process
    info "Building application for production..."
    ./scripts/build.sh
    success "Build completed successfully!"

    # Start development servers
    run_dev
}

# Function to run development servers
run_dev() {
    info "Starting development servers..."
    echo "Backend (Laravel) + Frontend (React) will start concurrently"
    echo "Press Ctrl+C to stop all servers"

    cd backend
    composer run dev
}

# Function to display interactive menu
show_menu() {
    echo "REACT LARAVEL  Starter"
    echo ""
    info "Available OPTIONS:"
    echo ""
    echo "  1. install (composer and node dependencies)"
    echo "  2. migrate (database migration and backup)"
    echo "  3. build (run build in backend & frontend)"
    echo "  4. start (cd ./backend && composer run dev)"
    echo "  5. docker (run docker build compose up -d)"
    echo "  6. update (update composer & node packages)"
    echo "  7. optimize (php artisan optimize & clear)"
    echo "  8. deploy (run deploy to vercel server etc)"
    echo "  9. repair (fix composer and node problems)"
    echo "  0. quit (ctrl + q to exit)"
    echo ""
    read -p "$(prompt "select option(0-9): ")" choice
    echo ""

    case $choice in
        1)
            if ./scripts/check.sh; then
                echo ""
                info "Running setup script..."
                # Only force interactive selection if no package manager preference is saved
                if [ -f ".package-manager" ] && [ -n "$(cat .package-manager 2>/dev/null | tr -d '\n\r')" ]; then
                    ./scripts/setup.sh
                else
                    ./scripts/setup.sh --force-pm-select
                fi
                run_post_setup_workflow
            else
                echo ""
                warning "System requirements not met. Setup cancelled."
                show_menu
            fi
            ;;
        2)
            info "Running migrate script..."
            ./scripts/migrate.sh
            echo ""
            show_menu
            ;;
        3)
            info "Running build script..."
            ./scripts/build.sh
            echo ""
            show_menu
            ;;
        4)
            if check_setup; then
                run_dev
            else
                warning "Setup is incomplete. Please run setup first."
                show_menu
            fi
            ;;
        5)
            info "Running Docker operations..."
            ./scripts/docker.sh
            echo ""
            show_menu
            ;;
        6)
            info "Running update script..."
            ./scripts/update.sh
            echo ""
            show_menu
            ;;
        7)
            info "Running optimize script..."
            ./scripts/optimize.sh
            echo ""
            show_menu
            ;;
        8)
            info "Deploy option selected"
            warning "Deploy functionality not yet implemented"
            echo "This would deploy to Vercel or other servers"
            echo ""
            show_menu
            ;;
        9)
            info "Running repair script..."
            ./scripts/repair.sh
            echo ""
            show_menu
            ;;
        0)
            exit 0
            ;;
        *)
            error "Invalid option: $choice"
            echo ""
            show_menu
            ;;
    esac
}

# Main function
main() {
    show_menu
}

# Run main function
main
