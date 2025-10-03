#!/usr/bin/env bash
set -euo pipefail  # Exit on any error
# Main runner script for React-Laravel Starter Kit
# Usage: ./run.sh [script] [options] [--banner|-b]
# Default: Display interactive menu with banner
# Scripts: setup, update, build, repair, optimize, migrate, check
# Options: --banner, -b (display fancy banner)

set -e  # Exit on any error

# Default values
SHOW_BANNER=false
SCRIPT_ARGS=()

# Parse command line arguments for banner flag and collect script arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -b|--banner)
            SHOW_BANNER=true
            shift
            ;;
        *)
            SCRIPT_ARGS+=("$1")
            shift
            ;;
    esac
done

# Restore positional parameters
set -- "${SCRIPT_ARGS[@]}"

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

# Function to check and install banner dependencies
check_banner_dependencies() {
    local needs_install=false

    if ! command -v lolcat &> /dev/null; then
        warning "lolcat not found"
        needs_install=true
    fi

    if ! command -v figlet &> /dev/null; then
        warning "figlet not found"
        needs_install=true
    fi

    if ! command -v cowsay &> /dev/null; then
        warning "cowsay not found"
        needs_install=true
    fi

    if [ "$needs_install" = true ]; then
        info "installing (lolcat, figlet, cowsay)..."
        if command -v apt &> /dev/null; then
            sudo apt update && sudo apt install -y lolcat figlet cowsay
            success "Banner dependencies installed successfully!"
        else
            error "apt package manager not found install lolcat, figlet, and cowsay manually."
            exit 1
        fi
    else
        success ""
    fi
}

# Function to display the banner
display_banner() {
    echo "✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✧✦✧✦✧"
    echo "✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✧✦✧✦✧" | lolcat 
    echo "✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✧✦✧✦✧"
    figlet "react & laravel" | lolcat
    echo "✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✧✦✧✦✧"
    echo "✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✧✦✧✦✧" | lolcat 
    echo "✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✧✦✧✦✧"
    cowsay -f eyes -e "--" "REACT LARAVEL FULL STACK STARTER KIT" | lolcat
    echo ""
    echo "✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✧✦✧✦✧"
    echo "✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✧✦✧✦✧" | lolcat 
    echo "✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✧✦✧✦✧"
    figlet "* stack./run.sh " | lolcat
    echo "✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✧✦✧✦✧"
    echo "✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✧✦✧✦✧" | lolcat 
    echo "✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✧✦✧✦✧"
    echo ""
}

# Function to execute script with arguments
run_script() {
    local script="$1"
    shift  # Remove script name from arguments

    case "$script" in
        setup)
            info "Running setup script..."
            ./scripts/setup.sh "$@"
            ;;
        update)
            info "Running update script..."
            ./scripts/update.sh "$@"
            ;;
        build)
            info "Running build script..."
            ./scripts/build.sh "$@"
            ;;
        repair)
            info "Running repair script..."
            ./scripts/repair.sh "$@"
            ;;
        optimize)
            info "Running optimize script..."
            ./scripts/optimize.sh "$@"
            ;;
        migrate)
            info "Running migrate script..."
            ./scripts/migrate.sh "$@"
            ;;
        check)
            info "Running system check..."
            ./scripts/check.sh "$@"
            ;;
        menu)
            info "Running menu..."
            ./scripts/menu.sh "$@"
            ;;
        *)
            error "Unknown script: $script"
            echo ""
            echo "Available scripts:"
            echo "  setup    - Initial project setup"
            echo "  update   - Update dependencies"
            echo "  build    - Build for production"
            echo "  repair   - Repair broken installations"
            echo "  optimize - Optimize for production"
            echo "  migrate  - Database migrations"
            echo "  check    - Check system requirements"
            echo "  menu     - Interactive menu"
            echo ""
            echo "Options:"
            echo "  -b, --banner    Display fancy banner (requires lolcat, figlet, cowsay)"
            echo ""
            echo "Usage: ./run.sh [script] [options]"
            echo "Default: Display interactive menu with banner"
            exit 1
            ;;
    esac
}

# Main logic
if [ "$SHOW_BANNER" = true ] || [ $# -eq 0 ]; then
    check_banner_dependencies
    display_banner
fi

if [ $# -eq 0 ]; then
    # Default to interactive menu
    info "Running menu..."
    ./scripts/menu.sh
else
    # Run specific script with arguments
    run_script "$@"
fi