# Docker Compose Setup

This project includes Docker Compose configurations for both development and production environments.

## Quick Start

### Development Environment

1. **Start the full stack (Frontend + Backend):**
   ```bash
   docker-compose up --build
   ```

2. **Start only the frontend:**
   ```bash
   cd frontend
   docker-compose up --build
   ```

3. **Start only the backend:**
   ```bash
   docker-compose up backend db --build
   ```

### Production Environment

1. **Start production stack:**
   ```bash
   docker-compose --profile production up --build
   ```

## Services

### Frontend (React Router)
- **Development:** `http://localhost:3000`
- **Production:** `http://localhost:3001`
- **Hot reload:** Enabled in development mode
- **Volume mounted:** Source code for live development

### Backend (Laravel)
- **URL:** `http://localhost:8000`
- **Database:** SQLite (persistent volume)
- **Auto-setup:** Migrations run on startup
- **Assets:** Built automatically

### Database
- **Type:** SQLite
- **Location:** `./backend/database/database.sqlite`
- **Persistence:** Volume mounted for data retention

## Environment Variables

### Frontend
- `NODE_ENV`: development/production
- `VITE_API_URL`: Backend API URL

### Backend
- `APP_ENV`: Application environment
- `APP_KEY`: Laravel application key
- `DB_CONNECTION`: Database connection (sqlite)
- `DB_DATABASE`: Database file path

## Useful Commands

### Development
```bash
# View logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f frontend

# Execute commands in containers
docker-compose exec frontend npm run build
docker-compose exec backend php artisan migrate

# Stop all services
docker-compose down

# Stop and remove volumes
docker-compose down -v
```

### Database Operations
```bash
# Access backend container
docker-compose exec backend bash

# Run migrations
docker-compose exec backend php artisan migrate

# Create backup
docker-compose exec backend php artisan db:dump

# Seed database
docker-compose exec backend php artisan db:seed
```

### Frontend Operations
```bash
# Access frontend container
docker-compose exec frontend sh

# Install new dependencies
docker-compose exec frontend npm install <package>

# Run type checking
docker-compose exec frontend npm run typecheck
```

## File Structure

```
docker/
├── docker-compose.yml          # Full stack configuration
├── README.md                   # Docker documentation
├── .env.example               # Environment variables
frontend/
│   ├── docker-compose.yml      # Frontend-only configuration
│   ├── Dockerfile             # Frontend Docker image
│   └── .dockerignore          # Frontend build exclusions
backend/
    ├── Dockerfile             # Backend Docker image
    └── .dockerignore          # Backend build exclusions
```

## Troubleshooting

### Common Issues

1. **Port conflicts:**
   - Change ports in docker-compose.yml if 3000/8000 are in use

2. **Permission issues:**
   - Ensure proper file permissions on host directories

3. **Database issues:**
   - Check SQLite file permissions
   - Run migrations manually if needed

4. **Build failures:**
   - Clear Docker cache: `docker system prune -a`
   - Rebuild: `docker-compose build --no-cache`

### Logs and Debugging

```bash
# View all logs
docker-compose logs

# View logs with timestamps
docker-compose logs -t

# Follow logs in real-time
docker-compose logs -f

# View specific service logs
docker-compose logs backend
```

## Production Deployment

For production deployment, use the `--profile production` flag:

```bash
docker-compose --profile production up -d
```

This starts the production-optimized frontend container instead of the development version.