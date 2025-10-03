# Contributing to React Laravel Starter Kit

Thank you for your interest in contributing to the React Laravel Starter Kit! We welcome contributions from the community.

## Code of Conduct

This project follows a code of conduct to ensure a welcoming environment for all contributors. Please read and follow our [Code of Conduct](CODE_OF_CONDUCT.md).

## How to Contribute

### Reporting Issues

- Check if the issue has already been reported in [GitHub Issues](https://github.com/bjornleonhenry/react-laravel-starter-kit/issues)
- Use a clear, descriptive title
- Provide detailed steps to reproduce the issue
- Include relevant information about your environment (OS, PHP version, Node version, etc.)
- Add screenshots or code examples if applicable

### Feature Requests

- Check if the feature has already been requested
- Clearly describe the proposed feature and its benefits
- Explain how it fits with the project's goals and architecture
- Consider providing mockups or examples if applicable

### Pull Requests

1. **Fork the repository** and create your branch from `main`
2. **Follow coding standards**:
   - Use consistent code formatting
   - Write clear, descriptive commit messages
   - Add comments for complex logic
   - Follow PSR standards for PHP code
   - Follow TypeScript/JavaScript best practices for frontend code

3. **Test your changes**:
   - Run the test suite: `./run.sh check`
   - Test both frontend and backend functionality
   - Ensure Docker setup works correctly

4. **Update documentation**:
   - Update README.md if needed
   - Add comments to new code
   - Update API documentation for backend changes

5. **Submit the pull request**:
   - Use a clear, descriptive title
   - Provide a detailed description of the changes
   - Reference any related issues
   - Ensure CI checks pass

## Development Setup

```bash
# Clone your fork
git clone https://github.com/your-username/react-laravel-starter-kit.git
cd react-laravel-starter-kit

# Install dependencies
./run.sh setup

# Start development environment
./run.sh

# Run tests
./run.sh check
```

## Project Structure

```
├── backend/          # Laravel application
├── frontend/         # React application
├── docker/          # Docker configuration
├── scripts/         # Automation scripts
├── docs/            # Documentation
└── run.sh           # Main runner script
```

## Coding Standards

### PHP (Backend)
- Follow PSR-12 coding standards
- Use meaningful variable and method names
- Add PHPDoc comments for classes and methods
- Keep methods focused on single responsibilities

### TypeScript/JavaScript (Frontend)
- Use TypeScript for type safety
- Follow consistent naming conventions
- Use meaningful component and function names
- Keep components small and focused

### Git Commits
- Use clear, descriptive commit messages
- Start with a verb (Add, Fix, Update, Remove, etc.)
- Keep commits focused on single changes
- Reference issue numbers when applicable

## Testing

- Write tests for new features
- Ensure existing tests pass
- Test both happy path and error scenarios
- Include integration tests for API endpoints

## Documentation

- Update README.md for significant changes
- Add code comments for complex logic
- Update API documentation in README.md
- Keep documentation current with code changes

## Questions?

If you have questions about contributing, please:
- Check existing documentation
- Search existing issues and discussions
- Contact the maintainers at bjornleonhenry.com

We appreciate your contributions to making this project better!
