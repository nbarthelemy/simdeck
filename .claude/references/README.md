# Reference Documentation

This directory contains curated best practices and reference materials for your project's tech stack. These documents are read by Claude during `/ce:prime` to provide informed, stack-specific guidance.

## Purpose

Reference docs help Claude:
- Understand your project's conventions
- Follow framework-specific best practices
- Avoid common pitfalls
- Use idiomatic patterns

## Suggested Files

Based on your tech stack, consider adding:

### Backend Frameworks
- `fastapi-best-practices.md` - FastAPI patterns, dependency injection, Pydantic usage
- `django-best-practices.md` - Django patterns, ORM usage, middleware
- `express-best-practices.md` - Express.js patterns, middleware, error handling
- `nestjs-best-practices.md` - NestJS modules, decorators, testing

### Frontend Frameworks
- `react-best-practices.md` - React patterns, hooks, state management
- `nextjs-best-practices.md` - Next.js routing, SSR, data fetching
- `vue-best-practices.md` - Vue composition API, Pinia, routing

### Languages
- `typescript-conventions.md` - Type patterns, utility types, strict mode
- `python-conventions.md` - Type hints, async patterns, packaging
- `go-conventions.md` - Error handling, concurrency, project layout

### Infrastructure
- `docker-best-practices.md` - Dockerfile patterns, compose, multi-stage builds
- `kubernetes-best-practices.md` - Resource management, deployments, secrets
- `terraform-best-practices.md` - Module structure, state management

### Testing
- `testing-strategy.md` - Test pyramid, coverage targets, mocking
- `e2e-testing.md` - Playwright/Cypress patterns, page objects

### Database
- `postgresql-best-practices.md` - Indexing, queries, migrations
- `mongodb-best-practices.md` - Schema design, aggregations

## Creating Reference Docs

Each reference doc should include:

1. **Overview** - Brief description of when to use
2. **Key Principles** - Core guidelines to follow
3. **Patterns** - Common patterns with examples
4. **Anti-patterns** - What to avoid
5. **Project-specific** - Any local customizations

### Template

```markdown
# {Technology} Best Practices

> For use with {project description}

## Key Principles

1. {Principle 1}
2. {Principle 2}

## Patterns

### {Pattern Name}

{When to use}

```{language}
// Example code
```

### {Another Pattern}
...

## Anti-Patterns

### {Anti-pattern Name}

{Why it's bad}

```{language}
// Bad example
```

Instead:

```{language}
// Good example
```

## Project-Specific Conventions

- {Convention 1}
- {Convention 2}

## Resources

- [Official Docs](url)
- [Style Guide](url)
```

## Auto-Generation

Run `/ce:prime` to see which reference docs would be helpful for your detected stack. Claude can help generate initial reference docs based on official documentation.
