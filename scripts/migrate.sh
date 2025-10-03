#!/usr/bin/env bash
set -euo pipefail  # Exit on any error
# Migration script for React-Laravel Starter Kit
# Usage: ./migrate.sh [command] [--seed] [--class=SeederClass] [--force] [--output=file]
# Commands: status, migrate, rollback, reset, refresh, fresh, seed, backup, dump
# Default: migrate (run migrations)
# --seed: run seeders after migration
# --class: specify seeder class (default: DatabaseSeeder)
# --force: skip confirmations for destructive operations
# --output: specify output file for backup/dump operations

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
}

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

    # Check if we're in the backend directory or can find artisan
    if [ ! -f "artisan" ]; then
        error "Artisan file not found. Please run this script from the backend directory or ensure Laravel is properly set up."
        requirements_met=false
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

    if [ "$FORCE_MODE" = true ]; then
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

# Function to run migrations
run_migrate() {
    info "Running migrations..."
    php artisan migrate --force
    success "Migrations completed successfully"
}

# Function to show migration status
show_status() {
    info "Checking migration status..."
    php artisan migrate:status
}

# Function to rollback migrations
run_rollback() {
    local steps="${1:-1}"
    info "Rolling back $steps migration(s)..."
    php artisan migrate:rollback --step=$steps --force
    success "Rolled back $steps migration(s)"
}

# Function to reset migrations
run_reset() {
    warning "This will reset ALL migrations (drop all tables)!"
    if confirm_action "Are you sure you want to reset all migrations?" false; then
        info "Resetting all migrations..."
        php artisan migrate:reset --force
        success "All migrations have been reset"
    else
        info "Migration reset cancelled"
        exit 0
    fi
}

# Function to refresh migrations
run_refresh() {
    warning "This will rollback and re-run all migrations!"
    if confirm_action "Are you sure you want to refresh all migrations?" false; then
        info "Refreshing all migrations..."
        php artisan migrate:refresh --force
        success "All migrations have been refreshed"
    else
        info "Migration refresh cancelled"
        exit 0
    fi
}

# Function to run fresh migrations
run_fresh() {
    warning "This will drop all tables and re-run all migrations from scratch!"
    if confirm_action "Are you sure you want to run fresh migrations?" false; then
        info "Running fresh migrations..."
        php artisan migrate:fresh --force
        success "Fresh migrations completed"
    else
        info "Fresh migration cancelled"
        exit 0
    fi
}

# Function to run seeders
run_seed() {
    local seeder_class="$1"

    if [ -n "$seeder_class" ]; then
        info "Running seeder: $seeder_class..."
        php artisan db:seed --class="$seeder_class" --force
        success "Seeder $seeder_class completed"
    else
        info "Running database seeders..."
        php artisan db:seed --force
        success "Database seeding completed"
    fi
}

# Function to create database backup/dump
run_backup() {
    local output_file="$1"

    # Get database configuration from Laravel
    local db_connection=$(php artisan tinker --execute="echo config('database.default');" | tr -d '\n')
    local db_name=""
    local db_type=""

    case $db_connection in
        sqlite)
            db_type="sqlite"
            db_name=$(php artisan tinker --execute="echo config('database.connections.sqlite.database');" | tr -d '\n')
            ;;
        mysql)
            db_type="mysql"
            db_name=$(php artisan tinker --execute="echo config('database.connections.mysql.database');" | tr -d '\n')
            ;;
        pgsql)
            db_type="pgsql"
            db_name=$(php artisan tinker --execute="echo config('database.connections.pgsql.database');" | tr -d '\n')
            ;;
        *)
            error "Unsupported database type: $db_connection"
            error "Currently supported: SQLite, MySQL, PostgreSQL"
            exit 1
            ;;
    esac

    # Generate output filename if not provided
    if [ -z "$output_file" ]; then
        local timestamp=$(date +"%Y%m%d_%H%M%S")
        case $db_type in
            sqlite)
                output_file="backup_${timestamp}.sql"
                ;;
            mysql)
                output_file="backup_${db_name}_${timestamp}.sql"
                ;;
            pgsql)
                output_file="backup_${db_name}_${timestamp}.sql"
                ;;
        esac
    fi

    info "Creating database backup..."
    info "Database type: $db_type"
    info "Output file: $output_file"

    case $db_type in
        sqlite)
            if [ ! -f "$db_name" ]; then
                error "SQLite database file not found: $db_name"
                exit 1
            fi
            sqlite3 "$db_name" ".dump" > "$output_file"
            ;;
        mysql)
            local db_host=$(php artisan tinker --execute="echo config('database.connections.mysql.host');" | tr -d '\n')
            local db_username=$(php artisan tinker --execute="echo config('database.connections.mysql.username');" | tr -d '\n')
            local db_password=$(php artisan tinker --execute="echo config('database.connections.mysql.password');" | tr -d '\n')

            if ! command -v mysqldump &> /dev/null; then
                error "mysqldump command not found. Please install MySQL client tools."
                exit 1
            fi

            mysqldump -h"$db_host" -u"$db_username" -p"$db_password" "$db_name" > "$output_file"
            ;;
        pgsql)
            local db_host=$(php artisan tinker --execute="echo config('database.connections.pgsql.host');" | tr -d '\n')
            local db_username=$(php artisan tinker --execute="echo config('database.connections.pgsql.username');" | tr -d '\n')
            local db_password=$(php artisan tinker --execute="echo config('database.connections.pgsql.password');" | tr -d '\n')

            if ! command -v pg_dump &> /dev/null; then
                error "pg_dump command not found. Please install PostgreSQL client tools."
                exit 1
            fi

            PGPASSWORD="$db_password" pg_dump -h "$db_host" -U "$db_username" "$db_name" > "$output_file"
            ;;
    esac

    if [ $? -eq 0 ]; then
        local file_size=$(du -h "$output_file" | cut -f1)
        success "Database backup created successfully: $output_file ($file_size)"
    else
        error "Failed to create database backup"
        exit 1
    fi
}

# Parse command line arguments
COMMAND="migrate"
SEED=false
SEEDER_CLASS=""
FORCE_MODE=false
ROLLBACK_STEPS=1
BACKUP_OUTPUT=""

while [[ $# -gt 0 ]]; do
    case $1 in
        status)
            COMMAND="status"
            shift
            ;;
        migrate)
            COMMAND="migrate"
            shift
            ;;
        rollback)
            COMMAND="rollback"
            shift
            ;;
        reset)
            COMMAND="reset"
            shift
            ;;
        refresh)
            COMMAND="refresh"
            shift
            ;;
        fresh)
            COMMAND="fresh"
            shift
            ;;
        seed)
            COMMAND="seed"
            shift
            ;;
        backup)
            COMMAND="backup"
            shift
            ;;
        dump)
            COMMAND="dump"
            shift
            ;;
        --seed)
            SEED=true
            shift
            ;;
        --class=*)
            SEEDER_CLASS="${1#*=}"
            shift
            ;;
        --force)
            FORCE_MODE=true
            shift
            ;;
        --step=*)
            ROLLBACK_STEPS="${1#*=}"
            shift
            ;;
        --output=*)
            BACKUP_OUTPUT="${1#*=}"
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [command] [options]"
            echo ""
            echo "Commands:"
            echo "  status     Show migration status"
            echo "  migrate    Run pending migrations (default)"
            echo "  rollback   Rollback last migration(s)"
            echo "  reset      Reset all migrations"
            echo "  refresh    Reset and re-run all migrations"
            echo "  fresh      Drop all tables and re-run all migrations"
            echo "  seed       Run database seeders"
            echo "  backup     Create database backup"
            echo "  dump       Create database dump (alias for backup)"
            echo ""
            echo "Options:"
            echo "  --seed           Run seeders after migration"
            echo "  --class=Class    Specify seeder class (default: DatabaseSeeder)"
            echo "  --force          Skip confirmations for destructive operations"
            echo "  --step=N         Number of migrations to rollback (default: 1)"
            echo "  --output=FILE    Output file for backup/dump (default: auto-generated)"
            echo ""
            echo "Examples:"
            echo "  $0                    # Run pending migrations"
            echo "  $0 status             # Show migration status"
            echo "  $0 fresh --seed       # Fresh migrate and seed"
            echo "  $0 rollback --step=2  # Rollback 2 migrations"
            echo "  $0 seed --class=UsersTableSeeder  # Run specific seeder"
            echo "  $0 backup             # Create database backup"
            echo "  $0 dump --output=my-backup.sql  # Create dump with custom filename"
            ;;
        *)
            error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo "React-Laravel Migration Manager"
echo ""

# Check if we're in the backend directory
if [ ! -f "artisan" ]; then
    # Try to find backend directory
    if [ -d "backend" ] && [ -f "backend/artisan" ]; then
        info "Switching to backend directory..."
        cd backend
    else
        error "Could not find Laravel artisan file. Please run this script from the backend directory."
        exit 1
    fi
fi

# Check system requirements
check_requirements

# Show operation plan
echo "Migration Plan:"
case $COMMAND in
    status)
        echo "  Show migration status"
        ;;
    migrate)
        echo "  Run pending migrations"
        ;;
    rollback)
        echo "  Rollback $ROLLBACK_STEPS migration(s)"
        ;;
    reset)
        echo "  Reset all migrations"
        ;;
    refresh)
        echo "  Refresh all migrations (reset + migrate)"
        ;;
    fresh)
        echo "  Fresh migrations (drop all + migrate)"
        ;;
    seed)
        if [ -n "$SEEDER_CLASS" ]; then
            echo "  Run seeder: $SEEDER_CLASS"
        else
            echo "  Run database seeders"
        fi
        ;;
    backup|dump)
        if [ -n "$BACKUP_OUTPUT" ]; then
            echo "  Create database backup: $BACKUP_OUTPUT"
        else
            echo "  Create database backup (auto-generated filename)"
        fi
        ;;
esac

if [ "$SEED" = true ] && [ "$COMMAND" != "seed" ]; then
    if [ -n "$SEEDER_CLASS" ]; then
        echo "  Then run seeder: $SEEDER_CLASS"
    else
        echo "  Then run database seeders"
    fi
fi

if [ "$FORCE_MODE" = true ]; then
    warning "⚠️  Force mode enabled - skipping confirmations"
fi
echo ""

# Execute the command
case $COMMAND in
    status)
        show_status
        ;;
    migrate)
        run_migrate
        ;;
    rollback)
        run_rollback "$ROLLBACK_STEPS"
        ;;
    reset)
        run_reset
        ;;
    refresh)
        run_refresh
        ;;
    fresh)
        run_fresh
        ;;
    seed)
        run_seed "$SEEDER_CLASS"
        ;;
    backup|dump)
        run_backup "$BACKUP_OUTPUT"
        ;;
esac

# Run seeders if requested
if [ "$SEED" = true ] && [ "$COMMAND" != "seed" ]; then
    echo ""
    run_seed "$SEEDER_CLASS"
fi

# Final success message
echo ""
success "Database operation completed successfully!"

# Show next steps
echo ""
echo "Useful commands:"
echo "  - Check status: $0 status"
echo "  - Run migrations: $0 migrate"
echo "  - Seed data: $0 seed"
echo "  - Create backup: $0 backup"
echo "  - Fresh start: $0 fresh --seed"
echo ""
echo "For more options, run: $0 --help"
