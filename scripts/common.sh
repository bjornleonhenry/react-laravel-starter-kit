#!/usr/bin/env bash
set -euo pipefail  # Exit on any error
# Common functions and utilities for React-Laravel Starter Kit scripts
# This file should be sourced by other scripts, not executed directly

readonly VERSION="1.0.0"
readonly NODE_PACKET_MANAGER=""

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color


# Helper functions for colored output
error() {
    echo -e "${RED}Error:${NC} $1" >&2
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

warning() {
    echo -e "${YELLOW}Warning:${NC} $1" >&2
}

info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

prompt() {
    echo -e "${CYAN}→${NC} $1"
}

# Function to confirm user actions
confirm_action() {
    local message="$1"
    local default_yes="${2:-false}"

    if [ "$default_yes" = true ]; then
        read -p "$message (Y/n): " -n 1 -r NODE_PACKET_MANAGER
        [[ $REPLY =~ ^[Yy]$ ]]
    fi
}

# Function to validate we're in the correct project directory
validate_project_structure() {
    if [ ! -d "backend" ] || [ ! -d "frontend" ]; then
        error "Please run this script from the root directory containing 'backend' and 'frontend' folders."
        return 1
    fi
    return 0
}

# Function to detect available package managers
detect_package_managers() {
    # Return space-separated list of available managers
    local managers=""

    if command -v npm &> /dev/null; then
        managers="${managers} npm"
    fi
    if command -v yarn &> /dev/null; then
        managers="${managers} yarn"
    fi
    if command -v pnpm &> /dev/null; then
        managers="${managers} pnpm"
    fi

    # Trim leading space
    echo "${managers#"${managers%%[![:space:]]*}"}"
}

# Function to select package manager interactively
select_package_manager() {
    local available_managers=("$@")
    local chosen_manager=""

    if [ ${#available_managers[@]} -eq 0 ]; then
        error "No package managers found. Please install npm, pnpm, or yarn." >&2
        return 1
    fi

    if [ ${#available_managers[@]} -eq 1 ]; then
        chosen_manager="${available_managers[0]}"
        echo "Using ${chosen_manager} (only package manager available)" >&2
    else
        echo "Choose your preferred package manager:" >&2
        echo "Available package managers:" >&2
        for i in "${!available_managers[@]}"; do
            echo "  $((i+1)). ${available_managers[$i]}" >&2
        done

        while true; do
            read -p "Enter your choice (1-${#available_managers[@]}): " choice
            if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#available_managers[@]}" ]; then
                chosen_manager="${available_managers[$((choice-1))]}"
                break
            else
                error "Invalid choice. Please enter a number between 1 and ${#available_managers[@]}." >&2
            fi
        done
    fi

    # Return the chosen manager via stdout
    echo "$chosen_manager"
}

# Function to get package manager persistence file
get_pm_file() {
    echo ".package-manager"
}

# Function to save selected package manager
save_selected_package_manager() {
    local manager="$1"
    local pm_file="$(get_pm_file)"
    echo "$manager" > "$pm_file"
}

# Function to load previously selected package manager
load_selected_package_manager() {
    local pm_file="$(get_pm_file)"
    if [ -f "$pm_file" ]; then
        local saved_pm=$(cat "$pm_file" 2>/dev/null | tr -d '\n\r')
        if [ -n "$saved_pm" ]; then
            # Validate that the saved manager is still available
            local available_managers=$(detect_package_managers)
            if echo "$available_managers" | grep -q "\b$saved_pm\b"; then
                echo "$saved_pm"
                return 0
            fi
        fi
    fi
    echo ""
}

# Function to detect package manager from environment/project
# Priority: Environment variable > Saved preference > Lock files > Available managers
detect_project_package_manager() {
    local available_managers_string=$(detect_package_managers)
    IFS=' ' read -ra available_managers <<< "$available_managers_string"

    # Check for environment variable (highest priority)
    if [ -n "$NODE_PACKET_MANAGER" ]; then
        if echo "$available_managers_string" | grep -q "\b$NODE_PACKET_MANAGER\b"; then
            echo "$NODE_PACKET_MANAGER"
            return 0
        fi
    fi

    # Check for saved preference (second priority)
    local saved_pm=$(load_selected_package_manager)
    if [ -n "$saved_pm" ]; then
        echo "$saved_pm"
        return 0
    fi

    # Auto-detect from lock files (third priority)
    local auto_detected=$(auto_detect_package_manager)
    if [ -n "$auto_detected" ] && echo "$available_managers_string" | grep -q "\b$auto_detected\b"; then
        echo "$auto_detected"
        return 0
    fi

    # Fall back to first available manager (lowest priority)
    if [ ${#available_managers[@]} -gt 0 ]; then
        echo "${available_managers[0]}"
        return 0
    fi

    echo ""
}

# Function to auto-detect package manager from lock files
auto_detect_package_manager() {
    if [ -f "frontend/package-lock.json" ]; then
        echo "npm"
    elif [ -f "frontend/yarn.lock" ]; then
        echo "yarn"
    elif [ -f "frontend/pnpm-lock.yaml" ]; then
        echo "pnpm"
    else
        echo ""
    fi
}

# Function to get package manager with smart detection
get_package_manager() {
    local force_interactive="${1:-false}"
    local available_managers_string=$(detect_package_managers)
    IFS=' ' read -ra available_managers <<< "$available_managers_string"

    if [ ${#available_managers[@]} -eq 0 ]; then
        error "No package managers found. Please install npm, pnpm, or yarn."
        return 1
    fi

    # Try project/environment-based detection first (unless forced interactive)
    local detected_pm=$(detect_project_package_manager)
    if [ -n "$detected_pm" ] && [ "$force_interactive" != true ]; then
        # Output informational message to stderr so it doesn't interfere with return value
        if [ -n "$NODE_PACKET_MANAGER" ]; then
            echo "Using package manager from environment: $detected_pm" >&2
        elif [ -n "$(load_selected_package_manager)" ]; then
            echo "Using saved package manager preference: $detected_pm" >&2
        elif [ -n "$(auto_detect_package_manager)" ]; then
            echo "Auto-detected package manager from lock files: $detected_pm" >&2
        else
            echo "Using available package manager: $detected_pm" >&2
        fi
        echo "$detected_pm"
        return 0
    fi

    # If force_interactive is true OR no saved preference found, go to selection
    local chosen_manager=$(select_package_manager "${available_managers[@]}")
    if [ $? -eq 0 ] && [ -n "$chosen_manager" ]; then
        save_selected_package_manager "$chosen_manager"
        echo "Selected package manager: $chosen_manager" >&2
        echo "$chosen_manager"
        return 0
    fi

    return 1
}

# Function to check PHP requirements
check_php() {
    if command -v php &> /dev/null; then
        local php_version=$(php -r "echo PHP_VERSION;")
        local php_major=$(php -r "echo PHP_MAJOR_VERSION;")
        local php_minor=$(php -r "echo PHP_MINOR_VERSION;")

        if [ "$php_major" -gt 8 ] || ([ "$php_major" -eq 8 ] && [ "$php_minor" -ge 2 ]); then
            success "PHP $php_version - OK"
            return 0
        else
            error "PHP $php_version - Laravel requires PHP 8.2 or higher"
            return 1
        fi
    else
        error "PHP not found - Please install PHP 8.2 or higher"
        return 1
    fi
}

# Function to check Composer
check_composer() {
    if command -v composer &> /dev/null; then
        local composer_version=$(composer --version | grep -oP "version \K[^\s]+")
        success "Composer $composer_version - OK"
        return 0
    else
        error "Composer not found - Please install Composer"
        return 1
    fi
}

# Function to check Node.js
check_nodejs() {
    if command -v node &> /dev/null; then
        local node_version=$(node -v | sed 's/v//')
        local node_major=$(node -v | sed 's/v//' | cut -d. -f1)

        if [ "$node_major" -ge 18 ]; then
            success "Node.js $node_version - OK"
            return 0
        elif [ "$node_major" -ge 16 ]; then
            warning "Node.js $node_version - OK (but 18+ recommended)"
            return 0
        else
            error "Node.js $node_version - Requires Node.js 16 or higher"
            return 1
        fi
    else
        error "Node.js not found - Please install Node.js 16 or higher"
        return 1
    fi
}

# Function to check package managers
check_package_managers() {
    info "Checking package managers..."
    local package_managers_found=false

    if command -v npm &> /dev/null; then
        local npm_version=$(npm --version)
        success "npm $npm_version - OK"
        package_managers_found=true
    fi

    if command -v yarn &> /dev/null; then
        local yarn_version=$(yarn --version)
        success "yarn $yarn_version - OK"
        package_managers_found=true
    fi

    if command -v pnpm &> /dev/null; then
        local pnpm_version=$(pnpm --version)
        success "pnpm $pnpm_version - OK"
        package_managers_found=true
    fi

    if [ "$package_managers_found" = false ]; then
        error "No package managers found - Please install npm, yarn, or pnpm"
        return 1
    fi

    return 0
}

# Function to run package manager install command
run_package_install() {
    local manager="$1"
    local directory="${2:-.}"
    local silent="${3:-false}"

    case "$manager" in
        npm)
            # Check if package-lock.json exists for npm ci, otherwise use npm install
            if [ "$silent" = true ] && [ -f "$directory/package-lock.json" ]; then
                npm ci >/dev/null 2>&1
            else
                if [ "$silent" = true ]; then
                    npm install >/dev/null 2>&1
                else
                    npm install
                fi
            fi
            ;;
        yarn)
            if [ "$silent" = true ]; then
                yarn install --silent >/dev/null 2>&1
            else
                yarn install
            fi
            ;;
        pnpm)
            if [ "$silent" = true ]; then
                pnpm install --frozen-lockfile >/dev/null 2>&1
            else
                pnpm install
            fi
            ;;
        *)
            error "Unknown package manager: $manager"
            return 1
            ;;
    esac
}

# Function to run package manager build command
run_package_build() {
    local manager="$1"
    local directory="${2:-.}"

    case "$manager" in
        npm)
            npm run build
            ;;
        yarn)
            yarn build
            ;;
        pnpm)
            pnpm run build
            ;;
        *)
            error "Unknown package manager: $manager"
            return 1
            ;;
    esac
}

# Function to run package manager update command
run_package_update() {
    local manager="$1"
    local directory="${2:-.}"

    case "$manager" in
        npm)
            npm update
            ;;
        yarn)
            yarn upgrade
            ;;
        pnpm)
            pnpm update
            ;;
        *)
            error "Unknown package manager: $manager"
            return 1
            ;;
    esac
}

# Function to check if directory contains node_modules
check_node_modules() {
    local directory="$1"
    if [ ! -d "$directory/node_modules" ]; then
        return 1
    fi
    return 0
}

# Function to check if backend has vendor directory
check_backend_vendor() {
    if [ ! -d "backend/vendor" ]; then
        return 1
    fi
    return 0
}

# Function to check if backend has node_modules
check_backend_node_modules() {
    if [ ! -d "backend/node_modules" ]; then
        return 1
    fi
    return 0
}

# Function to check if frontend has node_modules
check_frontend_node_modules() {
    if [ ! -d "frontend/node_modules" ]; then
        return 1
    fi
    return 0
}

# Function to clean up console output (remove empty lines and duplicates)
cleanup_output() {
    # This function can be used to clean output if needed
    # For now, it's a placeholder for future enhancements
    true
}
