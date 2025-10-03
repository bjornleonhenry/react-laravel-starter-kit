#!/usr/bin/env bash
set -euo pipefail  # Exit on any error
# System requirements checker for React-Laravel Starter Kit
# Usage: ./check.sh

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

    echo

    if [ "$requirements_met" = true ]; then
        success "All system requirements met!"
        return 0
    else
        error "System requirements not met. Please install missing dependencies."
        return 1
    fi
}

# Run the check
check_requirements