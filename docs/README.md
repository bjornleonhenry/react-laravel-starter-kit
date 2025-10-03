# Laravel React Starter Kit

A modern, decoupled full-stack starter kit featuring Laravel v12+ backend with React frontend, designed for scalable web applications.

## 🚀 Quick Start

```bash
# Clone the repository
git clone <repository-url>
cd laravel-react-starter-kit

# Start the full stack
./run.sh

# Or start individual components
./run.sh backend  # Start only Laravel backend
./run.sh frontend # Start only React frontend
```

## 📁 Project Structure

```
├── backend/          # Laravel v12+ application
│   ├── app/         # Application code
│   ├── database/    # Migrations and seeds
│   ├── resources/   # Views and assets
│   └── routes/      # API routes
├── frontend/         # React + Vite application
│   ├── app/         # React components and routes
│   ├── public/      # Static assets
│   └── src/         # Source code
├── scripts/          # Automation scripts
├── docs/            # Documentation
└── docker-compose.yml # Full stack orchestration
```

## 🛠️ Tech Stack

### Backend
- **Laravel v12+** - PHP framework
- **Laravel Sanctum** - API authentication
- **Laravel Fortify** - Authentication scaffolding
- **Filament v4+** - Admin panel
- **SQLite/PostgreSQL** - Database

### Frontend
- **React** - UI framework
- **React Router** - Client-side routing
- **Vite** - Build tool and dev server
- **ShadCN UI** - Component library
- **Tailwind CSS** - Styling

### DevOps
- **Docker** - Containerization
- **Docker Compose** - Multi-service orchestration
- **Bash scripts** - Automation

## 🔧 Development

### Prerequisites
- Docker & Docker Compose
- Git

### Available Scripts
```bash
./run.sh              # Interactive menu
./run.sh setup        # Initial setup
./run.sh build        # Production build
./run.sh check        # System check
./run.sh optimize     # Performance optimization
```

### Environment Setup
1. Copy environment files:
   ```bash
   cp backend/.env.example backend/.env
   cp frontend/.env.example frontend/.env
   ```

2. Configure your environment variables in the `.env` files

3. Start development environment:
   ```bash
   ./run.sh
   ```

## 📚 Documentation

- [Docker Setup](README-DOCKER.md) - Container configuration and deployment
- [Backend API](backend/README.md) - Laravel application documentation
- [Frontend Guide](frontend/README.md) - React application documentation

## 🤝 Contributing

1. Follow the project constitution in `.specify/memory/constitution.md`
2. Use the provided templates for specifications and planning
3. Ensure all changes follow the established principles
4. Update documentation for any new features

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

Built with modern web development best practices, inspired by the Laravel and React ecosystems.