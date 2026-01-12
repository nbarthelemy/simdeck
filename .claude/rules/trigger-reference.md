# Trigger Reference

> Auto-generated from triggers.json - DO NOT EDIT MANUALLY

Use this reference to match user requests to the appropriate skill or agent.

## Skill Triggers

When the user's request contains these keywords or phrases, invoke the corresponding skill.

### frontend-design
**Keywords:** UI, UX, CSS, SCSS, styling, Tailwind, layout, animation, typography, colors, themes, dark mode, light mode, responsive, mobile-first
**Phrases:** "make it look better", "improve the look", "improve the design", "polish the UI", "fix styling", "redesign components", "beautify", "make it pretty", "update the styles", "modernize the UI", "make it responsive", "add dark mode", "needs visual polish", "looks ugly", "looks bad"

### autonomous-loop
**Keywords:** loop, iterate, autonomous, autopilot
**Phrases:** "keep going until done", "work autonomously", "run overnight", "continue until", "don't stop until", "keep iterating", "run in a loop", "iterate until complete", "work until finished", "autonomous mode"

### lsp-setup
**Keywords:** LSP, language server, intellisense, code intelligence
**Phrases:** "go-to-definition", "find references", "hover docs", "code navigation", "jump to definition", "find usages", "symbol search", "setup language server", "install LSP"

### project-interview
**Keywords:** interview, specification, spec, requirements
**Phrases:** "create a spec", "help plan", "define what to build", "starting a new project", "new project setup", "gather requirements", "planning architecture", "making tech decisions", "what should we build", "help me plan this", "project requirements", "write a spec"

### skill-creator
**Keywords:** none
**Phrases:** "create a skill", "creating a skill", "new skill", "scaffold skill", "scaffolding skill", "initialize skill", "build a skill", "make a skill"

### meta-skill
**Keywords:** none
**Phrases:** "unknown framework", "unfamiliar technology", "never used before", "don't know this tech", "extend capabilities", "add support for", "learn about this framework"

### tech-detection
**Keywords:** stack, technologies, frameworks
**Phrases:** "analyze project", "detect stack", "what tech is used", "detecting technologies", "bootstrapping infrastructure", "setting up permissions", "what frameworks", "identify stack"

### pattern-observer
**Keywords:** patterns, learnings, automations
**Phrases:** "review learnings", "analyze patterns", "create automations", "workflow optimization", "pending suggestions", "what did you learn", "what have we learned", "repeated tasks", "automate this pattern"

### orchestrator
**Keywords:** comprehensive, thorough, complete
**Phrases:** "full review", "review everything", "across the codebase", "refactor all", "entire project", "all files", "comprehensive analysis", "parallel execution", "spawn agents", "multi-domain task"

### agent-creator
**Keywords:** none
**Phrases:** "create an agent", "new specialist agent", "specialist for this tech", "need an expert for"

### spec-workflow
**Keywords:** spec, specification, setup, bootstrap
**Phrases:** "set up project", "bootstrap project", "create specification", "project specification", "initialize project", "new project from scratch", "start fresh project", "create project spec"

### autopilot-workflow
**Keywords:** autopilot, autonomous, unattended
**Phrases:** "complete all features", "work through todo", "finish everything", "run autonomously", "hands-off mode", "complete without me", "work overnight", "autonomous completion", "finish the todo list", "process all features"


## Agent Triggers

When the user's request contains these keywords or phrases, consider delegating to the corresponding agent.

### frontend-developer
**Keywords:** UI, component, CSS, SCSS, styling, layout, responsive, animation, frontend, React, Vue, Svelte, Next.js, Tailwind, HTML
**Phrases:** "build the frontend", "create a component", "fix the layout", "make it responsive", "style this page", "update the UI", "frontend implementation", "build this screen"
**File patterns:** *.tsx, *.jsx, *.vue, *.svelte, *.css, *.scss

### backend-architect
**Keywords:** API, database, service, endpoint, server, backend, microservice, REST, GraphQL, middleware
**Phrases:** "build the backend", "create an API", "design the database", "implement the service", "backend architecture", "server-side logic", "data model design"
**File patterns:** *.py, *.go, *.rs, *.java, *.rb, *.ts

### code-reviewer
**Keywords:** review, quality, refactor, patterns, best practices, code smell, clean code, DRY, SOLID
**Phrases:** "review this code", "check for issues", "improve code quality", "refactor this", "code review", "find problems", "any issues here", "is this good code"

### security-auditor
**Keywords:** security, vulnerability, auth, authentication, authorization, encryption, XSS, injection, OWASP, CVE, secrets, credentials
**Phrases:** "security audit", "check for vulnerabilities", "is this secure", "security review", "find security issues", "penetration test", "security scan", "check authentication"

### test-engineer
**Keywords:** test, testing, coverage, TDD, Jest, pytest, Playwright, Cypress, unit test, integration test, e2e, mock, fixture
**Phrases:** "write tests", "add test coverage", "create unit tests", "test this function", "add integration tests", "e2e tests", "testing strategy", "increase coverage"
**File patterns:** *.test.*, *.spec.*, *_test.*, test_*.*

### devops-engineer
**Keywords:** deploy, CI, CD, Docker, Kubernetes, K8s, infrastructure, pipeline, GitHub Actions, Terraform, AWS, GCP, Azure, container
**Phrases:** "set up CI/CD", "deploy this", "create a pipeline", "containerize", "infrastructure setup", "configure deployment", "set up Docker", "create Dockerfile"
**File patterns:** Dockerfile, docker-compose.*, *.yaml, .github/workflows/*

### api-designer
**Keywords:** API, endpoint, schema, OpenAPI, GraphQL, REST, swagger, routes, request, response
**Phrases:** "design the API", "create endpoints", "API schema", "define routes", "REST API design", "GraphQL schema", "API documentation", "endpoint structure"
**File patterns:** *.yaml, *.json, openapi.*, swagger.*, *.graphql

### performance-analyst
**Keywords:** performance, optimize, slow, benchmark, profiling, memory, CPU, latency, throughput, caching, fast
**Phrases:** "optimize performance", "make it faster", "why is it slow", "performance issues", "speed this up", "reduce latency", "improve throughput", "memory leak"

### accessibility-checker
**Keywords:** accessibility, a11y, WCAG, ARIA, screen reader, keyboard navigation, contrast, alt text
**Phrases:** "accessibility audit", "check accessibility", "WCAG compliance", "screen reader support", "keyboard accessible", "add ARIA labels", "accessibility review", "a11y check"
**File patterns:** *.tsx, *.jsx, *.vue, *.html, *.svelte

### documentation-writer
**Keywords:** docs, documentation, README, guide, tutorial, API docs, JSDoc, comments, changelog
**Phrases:** "write documentation", "update the README", "document this", "add comments", "create a guide", "API documentation", "write a tutorial", "generate docs"
**File patterns:** *.md, *.mdx, *.rst, README*, CHANGELOG*

### release-manager
**Keywords:** release, version, changelog, deploy, publish, tag, semver, bump
**Phrases:** "prepare release", "version bump", "update changelog", "create release", "publish package", "tag version", "release notes", "ship it"
**File patterns:** package.json, CHANGELOG*, version.*

### migration-specialist
**Keywords:** migrate, upgrade, refactor, modernize, legacy, transition, deprecate, breaking change
**Phrases:** "migrate to", "upgrade from", "modernize this", "refactor legacy", "handle breaking changes", "version upgrade", "migration plan", "deprecation strategy"


## Matching Rules

1. **Case-insensitive** - match regardless of capitalization
2. **Partial match** - trigger phrase can be part of larger request
3. **Multiple matches** - if multiple skills/agents match, prefer the most specific
4. **Skills vs Agents** - Skills run in main context; Agents run as subagents via Task tool

## Invocation

- **Skills**: Use the `Skill` tool with the skill name
- **Agents**: Use the `Task` tool with `subagent_type` matching the agent name
