#!/usr/bin/env bash
set -euo pipefail  # Exit on any error
# Docker Compose Helper Script for React-Laravel Starter Kit
# Usage: ./scripts/docker.sh [command] [options]

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helper functions
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

# Check if docker and docker-compose are available
check_requirements() {
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed. Please install Docker first."
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi

    success "Docker and Docker Compose are available"
}

# Use docker compose (new syntax) if available, otherwise docker-compose (old syntax)
docker_compose_cmd() {
    if docker compose version &> /dev/null; then
        echo "docker compose"
    else
        echo "docker-compose"
    fi
}

# Main functions
start_dev() {
    info "Starting development environment..."
    cd docker
    $(docker_compose_cmd) up --build
}

start_prod() {
    info "Starting production environment..."
    cd docker
    $(docker_compose_cmd) --profile production up --build -d
}

start_frontend_only() {
    info "Starting frontend only..."
    cd frontend
    $(docker_compose_cmd) up --build
}

stop_all() {
    info "Stopping all services..."
    cd docker
    $(docker_compose_cmd) down
}

stop_all_with_volumes() {
    warning "This will remove all volumes and data!"
    read -p "$(prompt "Are you sure? (y/N): ")" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        info "Stopping all services and removing volumes..."
        cd docker
        $(docker_compose_cmd) down -v
    fi
}

show_logs() {
    service="${1:-}"
    if [ -n "$service" ]; then
        info "Showing logs for $service..."
        cd docker
        $(docker_compose_cmd) logs -f "$service"
    else
        info "Showing all logs..."
        cd docker
        $(docker_compose_cmd) logs -f
    fi
}

exec_command() {
    service="$1"
    shift
    if [ -z "$service" ]; then
        error "Please specify a service name"
        echo "Available services: frontend, backend, db"
        exit 1
    fi
    info "Executing command in $service container..."
    cd docker
    $(docker_compose_cmd) exec "$service" "$@"
}

build_images() {
    info "Building Docker images..."
    cd docker
    $(docker_compose_cmd) build --no-cache
}

clean_up() {
    warning "This will remove all unused Docker resources!"
    read -p "$(prompt "Are you sure? (y/N): ")" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        info "Cleaning up Docker resources..."
        docker system prune -a --volumes -f
    fi
}

show_status() {
    info "Docker containers status:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

show_help() {
    echo "Docker Compose Helper Script for React-Laravel Starter Kit"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  dev          Start development environment (frontend + backend)"
    echo "  prod         Start production environment"
    echo "  frontend     Start frontend only"
    echo "  stop         Stop all services"
    echo "  stop-all     Stop all services and remove volumes"
    echo "  logs         Show all logs"
    echo "  logs <svc>   Show logs for specific service"
    echo "  exec <svc>   Execute command in service container"
    echo "  build        Rebuild all images"
    echo "  clean        Remove unused Docker resources"
    echo "  status       Show container status"
    echo "  help         Show this help message"
    echo ""
    echo "Services: frontend, backend, db"
    echo ""
    echo "Examples:"
    echo "  $0 dev                    # Start development stack"
    echo "  $0 logs frontend          # Show frontend logs"
    echo "  $0 exec backend bash      # Open shell in backend container"
    echo "  $0 exec backend php artisan migrate  # Run migrations"
}

# Main script logic
check_requirements

case "${1:-help}" in
    dev)
        start_dev
        ;;
    prod)
        start_prod
        ;;
    frontend)
        start_frontend_only
        ;;
    stop)
        stop_all
        ;;
    stop-all)
        stop_all_with_volumes
        ;;
    logs)
        show_logs "$2"
        ;;
    exec)
        shift
        exec_command "$@"
        ;;
    build)
        build_images
        ;;
    clean)
        clean_up
        ;;
    status)
        show_status
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
