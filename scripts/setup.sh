#!/usr/bin/env bash
set -euo pipefail  # Exit on any error
# Initial setup script for React-Laravel Starter Kit
# Usage: ./setup.sh [--force-pm-select]


# Source common functions and variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Parse command line arguments
FORCE_PM_SELECT=false
CHANGE_PM=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --force-pm-select)
            FORCE_PM_SELECT=true
            shift
            ;;
        --change-pm)
            CHANGE_PM=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--force-pm-select] [--change-pm]"
            echo ""
            echo "Options:"
            echo "  --force-pm-select    Force interactive package manager selection"
            echo "  --change-pm          Change existing package manager preference"
            echo "  -h, --help           Show this help message"
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            echo "Use --help for usage information."
            exit 1
            ;;
    esac
done

# Function to prompt for .env file copying
prompt_env_copy() {
    local env_type="$1"
    local env_dir="$2"

    if [ -f "$env_dir/.env" ]; then
        info "$env_type .env file already exists, skipping..."
        return 0
    fi

    if [ ! -f "$env_dir/.env.example" ]; then
        warning "$env_type .env.example file not found, skipping..."
        return 0
    fi

    echo ""
    read -p "$(prompt "Copy $env_type .env.example to .env? (Y/n): ")" -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        cp "$env_dir/.env.example" "$env_dir/.env"
        success "$env_type .env file created from .env.example"
        if [ "$env_type" = "Backend" ]; then
            warning "Remember to edit backend/.env with your database credentials!"
        fi
    else
        info "Skipped copying $env_type .env file"
    fi
}

# Check if we're in the right directory
if [ ! -d "backend" ] || [ ! -d "frontend" ]; then
    error "Please run this script from the root directory containing 'backend' and 'frontend' folders."
    exit 1
fi

# Determine package manager to use
# Force interactive selection if --force-pm-select or --change-pm is specified
force_select="$FORCE_PM_SELECT"
if [ "$CHANGE_PM" = true ]; then
    force_select=true
fi

chosen_manager=$(get_package_manager "$force_select")
if [ $? -ne 0 ] || [ -z "$chosen_manager" ]; then
    exit 1
fi

info "Using $chosen_manager for all Node.js operations..."
echo

# Backend setup
info "Setting up backend (Laravel)..."
cd backend

# Prompt to copy environment file
prompt_env_copy "Backend" "."

# Install PHP dependencies
echo "Installing Composer dependencies..."
composer install --no-interaction

# Install Node.js dependencies for Laravel assets
info "Installing Node.js dependencies..."
run_package_install "$chosen_manager" "."

# Generate application key
echo "Generating application key..."
php artisan key:generate

# Ask about database setup
read -p "$(prompt "Do you want to run database migrations? (y/n): ")" run_migrations
if [ "$run_migrations" = "y" ] || [ "$run_migrations" = "Y" ]; then
    echo "Running migrations..."
    php artisan migrate
    success "Migrations completed."

    # Ask about creating an admin user
    read -p "$(prompt "Do you want to create an admin user? (y/n): ")" create_user
    if [ "$create_user" = "y" ] || [ "$create_user" = "Y" ]; then
        # Validate email
        while true; do
            read -p "$(prompt "Enter email for admin user: ")" admin_email
            if echo "$admin_email" | grep -E "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$" > /dev/null; then
                break
            else
                error "Invalid email format. Please try again."
            fi
        done

        # Validate password
        while true; do
            read -s -p "$(prompt "Enter password for admin user (min 8 characters): ")" admin_password
            echo ""
            if [ ${#admin_password} -ge 8 ]; then
                read -s -p "$(prompt "Confirm password: ")" admin_password_confirm
                echo ""
                if [ "$admin_password" = "$admin_password_confirm" ]; then
                    break
                else
                    error "Passwords do not match. Please try again."
                fi
            else
                error "Password must be at least 8 characters. Please try again."
            fi
        done

        read -p "$(prompt "Enter name for admin user: ")" admin_name

        echo "Creating admin user..."
        # Create a temporary PHP script to avoid bash variable expansion issues
        temp_php_script=$(mktemp)
        cat > "$temp_php_script" << 'EOF'
<?php
require_once 'vendor/autoload.php';

$app = require_once 'bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

try {
    $user = new App\Models\User;
    $user->name = getenv('ADMIN_NAME');
    $user->email = getenv('ADMIN_EMAIL');
    $user->password = Hash::make(getenv('ADMIN_PASSWORD'));
    $user->email_verified_at = now();
    $user->save();
    echo "Admin user created successfully with email: " . getenv('ADMIN_EMAIL') . "\n";
} catch (Exception $e) {
    echo "Error creating admin user: " . $e->getMessage() . "\n";
    exit(1);
}
EOF

        # Set environment variables and run the script
        if ADMIN_NAME="$admin_name" ADMIN_EMAIL="$admin_email" ADMIN_PASSWORD="$admin_password" php "$temp_php_script"; then
            success "Admin user created successfully!"
        else
            error "Failed to create admin user. You can create one manually later with 'php artisan tinker'."
        fi

        # Clean up temporary file
        rm -f "$temp_php_script"
    fi
else
    warning "Skipping migrations. You can run 'php artisan migrate' later from the backend directory."
fi

cd ..
success "Backend setup complete!"
echo ""

# Frontend setup
info "Setting up frontend (React)..."
cd frontend

# Prompt to copy environment file
prompt_env_copy "Frontend" "."

# Install dependencies with the chosen package manager
info "Installing dependencies with $chosen_manager..."
run_package_install "$chosen_manager" "."

# Check and prompt for ShadCN CLI
echo "Checking ShadCN CLI..."
if command -v npx &> /dev/null && npx shadcn@latest --help &> /dev/null; then
    success "ShadCN CLI is available."
else
    warning "ShadCN CLI not found or not accessible."
    read -p "$(prompt "Do you want to install ShadCN CLI globally? (y/n): ")" install_shadcn
    if [ "$install_shadcn" = "y" ] || [ "$install_shadcn" = "Y" ]; then
        if command -v npm &> /dev/null; then
            echo "Installing ShadCN CLI..."
            npm install -g shadcn-ui
            success "ShadCN CLI installed. You can now add components with 'npx shadcn@latest add <component>'"
        else
            error "npm not found. Please install Node.js first."
        fi
    else
        warning "Skipping ShadCN CLI installation. You can install it later with 'npm install -g shadcn-ui'"
    fi
fi

cd ..
success "Frontend setup complete!"
echo ""

# Final instructions
success "Setup complete!"
