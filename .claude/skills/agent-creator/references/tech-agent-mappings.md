# Tech to Agent Mappings

This file maps detected technologies to the specialist agents that should be created.

## Mapping Rules

1. **Generic agents cover most cases** - Only create specialized agents when deep expertise is needed
2. **Create on detection** - If tech is detected, create the agent immediately
3. **One agent per major technology** - Don't create multiple overlapping agents

## Frontend Technologies

| Technology | Create Agent | Rationale |
|------------|--------------|-----------|
| React | `react-specialist` | Hooks, JSX patterns, ecosystem |
| Vue | `vue-specialist` | Composition API, Vue-specific patterns |
| Angular | `angular-specialist` | Decorators, RxJS, module system |
| Svelte | `svelte-specialist` | Unique reactivity model |
| SvelteKit | `sveltekit-specialist` | SSR, load functions, adapters |
| Next.js | `nextjs-specialist` | SSR, routing, API routes specific |
| Nuxt | `nuxt-specialist` | SSR, composables, module system |
| Remix | `remix-specialist` | Loader/action patterns |
| Astro | `astro-specialist` | Island architecture |
| Solid.js | `solidjs-specialist` | Fine-grained reactivity, signals |
| Qwik | `qwik-specialist` | Resumability, lazy loading |
| Preact | `preact-specialist` | Lightweight React alternative |
| Lit | `lit-specialist` | Web components, decorators |
| Ember | `ember-specialist` | Convention-driven, Octane patterns |
| Alpine.js | `alpine-specialist` | Lightweight interactivity |
| HTMX | `htmx-specialist` | Hypermedia, server-driven |
| Tailwind CSS | `tailwind-specialist` | Utility-first CSS, config |

## Backend Technologies

| Technology | Create Agent | Rationale |
|------------|--------------|-----------|
| Django | `django-specialist` | ORM, class-based views, Django patterns |
| FastAPI | `fastapi-specialist` | Async patterns, Pydantic |
| Express | `express-specialist` | Middleware patterns |
| NestJS | `nestjs-specialist` | Decorators, DI, modules |
| Rails | `rails-specialist` | Convention over configuration, ActiveRecord |
| Flask | `flask-specialist` | Lightweight patterns, Blueprints |
| Spring | `spring-specialist` | Bean management, annotations |
| Spring Boot | `springboot-specialist` | Auto-configuration, starters |
| Laravel | `laravel-specialist` | Eloquent, Blade, artisan |
| Symfony | `symfony-specialist` | Bundles, Doctrine, Twig |
| Phoenix | `phoenix-specialist` | LiveView, Ecto, channels |
| Koa | `koa-specialist` | Async middleware, context |
| Hono | `hono-specialist` | Edge-first, Web Standards |
| Fastify | `fastify-specialist` | Schema validation, plugins |
| Gin | `gin-specialist` | Go web framework, middleware |
| Echo | `echo-specialist` | Go, high-performance routing |
| Fiber | `fiber-specialist` | Go, Express-inspired |
| Actix | `actix-specialist` | Rust async web framework |
| Axum | `axum-specialist` | Rust, Tower integration |
| ASP.NET | `aspnet-specialist` | .NET, MVC, Razor, Blazor |
| Adonis | `adonis-specialist` | Node.js, Laravel-inspired |
| Strapi | `strapi-specialist` | Headless CMS, content types |

## Cloud Platforms

| Technology | Create Agent | Rationale |
|------------|--------------|-----------|
| AWS | `aws-architect` | Service selection, IAM, Lambda, architecture |
| AWS Lambda | `lambda-specialist` | Serverless functions, layers, cold starts |
| AWS CDK | `cdk-specialist` | Infrastructure as code, constructs |
| AWS SAM | `sam-specialist` | Serverless Application Model |
| AWS Amplify | `amplify-specialist` | Full-stack apps, hosting, auth |
| GCP | `gcp-architect` | Service selection, IAM, Cloud Functions |
| GCP Cloud Run | `cloudrun-specialist` | Container deployment, scaling |
| Azure | `azure-architect` | Service selection, RBAC, Functions |
| Azure Functions | `azure-functions-specialist` | Serverless, bindings, triggers |
| Vercel | `vercel-specialist` | Edge functions, deployment, ISR |
| Cloudflare | `cloudflare-specialist` | Workers, D1, R2, Pages, KV |
| Cloudflare Workers | `workers-specialist` | Edge compute, Durable Objects |
| Netlify | `netlify-specialist` | Functions, Edge, Forms |
| Fly.io | `flyio-specialist` | Machines, Postgres, global deployment |
| Railway | `railway-specialist` | Deployment, databases, environments |
| Render | `render-specialist` | Web services, background workers |
| Heroku | `heroku-specialist` | Dynos, add-ons, pipelines |
| DigitalOcean | `digitalocean-specialist` | Droplets, App Platform, spaces |
| Linode | `linode-specialist` | Linodes, LKE, object storage |
| Deno Deploy | `deno-deploy-specialist` | Edge runtime, KV |
| Supabase | `supabase-specialist` | Postgres, Auth, Edge Functions, Realtime |
| Firebase | `firebase-specialist` | Firestore, Auth, Cloud Functions |
| PlanetScale | `planetscale-specialist` | Serverless MySQL, branching |
| Neon | `neon-specialist` | Serverless Postgres, branching |
| Upstash | `upstash-specialist` | Redis, Kafka, serverless |

## Databases

| Technology | Create Agent | Rationale |
|------------|--------------|-----------|
| PostgreSQL | `postgresql-specialist` | Advanced queries, indexing |
| MySQL | `mysql-specialist` | Optimization, replication |
| MongoDB | `mongodb-specialist` | Aggregations, schema design |
| Redis | `redis-specialist` | Caching patterns, data structures |
| SQLite | Skip | Simple enough for generic agents |

## ORMs

| Technology | Create Agent | Rationale |
|------------|--------------|-----------|
| Prisma | `prisma-specialist` | Schema design, migrations |
| Drizzle | `drizzle-specialist` | Type-safe patterns |
| TypeORM | `typeorm-specialist` | Decorators, relations |
| Sequelize | `sequelize-specialist` | Models, associations |
| SQLAlchemy | `sqlalchemy-specialist` | ORM vs Core, sessions |

## Third-Party Services

| Technology | Create Agent | Rationale |
|------------|--------------|-----------|
| Stripe | `stripe-specialist` | Payments, subscriptions, webhooks |
| Auth0 | `auth0-specialist` | Auth flows, rules, actions |
| Clerk | `clerk-specialist` | Components, middleware |
| Firebase | `firebase-specialist` | Realtime, auth, functions |
| Supabase | `supabase-specialist` | Postgres, realtime, auth |
| Twilio | `twilio-specialist` | SMS, voice, verify |
| SendGrid | `sendgrid-specialist` | Email templates, deliverability |
| Algolia | `algolia-specialist` | Search, indexing, faceting |
| Contentful | `contentful-specialist` | CMS, content types, localization |
| Sanity | `sanity-specialist` | CMS, GROQ queries, schemas |

## E-Commerce Platforms

| Technology | Create Agent | Rationale |
|------------|--------------|-----------|
| Shopify | `shopify-specialist` | Liquid, themes, apps, Storefront API |
| Shopify Hydrogen | `hydrogen-specialist` | React, Remix, Storefront API |
| Shopify Theme | `shopify-theme-specialist` | Liquid templating, Dawn theme, sections |
| Shopify App | `shopify-app-specialist` | App Bridge, Admin API, webhooks |
| Shopify Plus | `shopify-plus-specialist` | Scripts, Flow, checkout customization |
| WooCommerce | `woocommerce-specialist` | WordPress, PHP, hooks |
| BigCommerce | `bigcommerce-specialist` | Stencil, APIs |
| Medusa | `medusa-specialist` | Headless commerce, plugins |
| Saleor | `saleor-specialist` | GraphQL, Python, plugins |

## Languages (Usually Covered by Generic Agents)

| Technology | Create Agent | Rationale |
|------------|--------------|-----------|
| TypeScript | Skip | Covered by `frontend-developer`, `backend-architect` |
| Python | Skip | Covered by `backend-architect` |
| Go | Skip | Covered by `backend-architect` |
| Rust | `rust-specialist` | Ownership model, lifetimes unique enough |
| Java | Skip | Covered by `backend-architect` |
| Ruby | Skip | Covered by `backend-architect` |

## Testing Frameworks (Usually Covered by test-engineer)

| Technology | Create Agent | Rationale |
|------------|--------------|-----------|
| Jest | Skip | Covered by `test-engineer` |
| Vitest | Skip | Covered by `test-engineer` |
| Playwright | Skip | Covered by `test-engineer` |
| Cypress | Skip | Covered by `test-engineer` |
| pytest | Skip | Covered by `test-engineer` |

## Build Tools (Usually Covered by devops-engineer)

| Technology | Create Agent | Rationale |
|------------|--------------|-----------|
| Vite | Skip | Covered by generic agents |
| Webpack | Skip | Covered by generic agents |
| Turbopack | Skip | Covered by generic agents |
| esbuild | Skip | Covered by generic agents |
