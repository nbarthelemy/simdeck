#!/bin/bash
# Tech Stack Detection Script
# Outputs JSON with detected technologies

set -e

echo "{"
echo '  "detection": {'

# Package Manager Detection
echo -n '    "packageManager": '
if [ -f "pnpm-lock.yaml" ]; then
    echo '"pnpm",'
elif [ -f "yarn.lock" ]; then
    echo '"yarn",'
elif [ -f "package-lock.json" ]; then
    echo '"npm",'
elif [ -f "bun.lockb" ]; then
    echo '"bun",'
elif [ -f "Cargo.lock" ]; then
    echo '"cargo",'
elif [ -f "go.sum" ]; then
    echo '"go",'
elif [ -f "Gemfile.lock" ]; then
    echo '"bundler",'
elif [ -f "poetry.lock" ]; then
    echo '"poetry",'
elif [ -f "requirements.txt" ]; then
    echo '"pip",'
elif [ -f "composer.lock" ]; then
    echo '"composer",'
else
    echo 'null,'
fi

# Language Detection
echo -n '    "languages": ['
LANGS=""
[ -f "package.json" ] && LANGS="${LANGS}\"javascript\","
[ -f "tsconfig.json" ] && LANGS="${LANGS}\"typescript\","
[ -f "requirements.txt" ] || [ -f "pyproject.toml" ] && LANGS="${LANGS}\"python\","
[ -f "Gemfile" ] && LANGS="${LANGS}\"ruby\","
[ -f "go.mod" ] && LANGS="${LANGS}\"go\","
[ -f "Cargo.toml" ] && LANGS="${LANGS}\"rust\","
[ -f "composer.json" ] && LANGS="${LANGS}\"php\","
find . -maxdepth 3 -name "*.java" -type f 2>/dev/null | head -1 | grep -q . && LANGS="${LANGS}\"java\","
find . -maxdepth 3 -name "*.cs" -type f 2>/dev/null | head -1 | grep -q . && LANGS="${LANGS}\"csharp\","
find . -maxdepth 3 -name "*.swift" -type f 2>/dev/null | head -1 | grep -q . && LANGS="${LANGS}\"swift\","
find . -maxdepth 3 -name "*.kt" -type f 2>/dev/null | head -1 | grep -q . && LANGS="${LANGS}\"kotlin\","
# Remove trailing comma
LANGS=$(echo "$LANGS" | sed 's/,$//')
echo "${LANGS}],"

# Framework Detection (JavaScript/TypeScript)
echo -n '    "frameworks": ['
FRAMEWORKS=""
if [ -f "package.json" ]; then
    grep -qE '"next"' package.json 2>/dev/null && FRAMEWORKS="${FRAMEWORKS}\"nextjs\","
    grep -qE '"nuxt"' package.json 2>/dev/null && FRAMEWORKS="${FRAMEWORKS}\"nuxt\","
    grep -qE '"react"' package.json 2>/dev/null && FRAMEWORKS="${FRAMEWORKS}\"react\","
    grep -qE '"vue"' package.json 2>/dev/null && FRAMEWORKS="${FRAMEWORKS}\"vue\","
    grep -qE '"@angular/core"' package.json 2>/dev/null && FRAMEWORKS="${FRAMEWORKS}\"angular\","
    grep -qE '"svelte"' package.json 2>/dev/null && FRAMEWORKS="${FRAMEWORKS}\"svelte\","
    grep -qE '"astro"' package.json 2>/dev/null && FRAMEWORKS="${FRAMEWORKS}\"astro\","
    grep -qE '"remix"' package.json 2>/dev/null && FRAMEWORKS="${FRAMEWORKS}\"remix\","
    grep -qE '"gatsby"' package.json 2>/dev/null && FRAMEWORKS="${FRAMEWORKS}\"gatsby\","
    grep -qE '"express"' package.json 2>/dev/null && FRAMEWORKS="${FRAMEWORKS}\"express\","
    grep -qE '"fastify"' package.json 2>/dev/null && FRAMEWORKS="${FRAMEWORKS}\"fastify\","
    grep -qE '"@nestjs/core"' package.json 2>/dev/null && FRAMEWORKS="${FRAMEWORKS}\"nestjs\","
    grep -qE '"hono"' package.json 2>/dev/null && FRAMEWORKS="${FRAMEWORKS}\"hono\","
fi
# Python frameworks
if [ -f "requirements.txt" ]; then
    grep -qiE "django" requirements.txt 2>/dev/null && FRAMEWORKS="${FRAMEWORKS}\"django\","
    grep -qiE "flask" requirements.txt 2>/dev/null && FRAMEWORKS="${FRAMEWORKS}\"flask\","
    grep -qiE "fastapi" requirements.txt 2>/dev/null && FRAMEWORKS="${FRAMEWORKS}\"fastapi\","
fi
if [ -f "pyproject.toml" ]; then
    grep -qiE "django" pyproject.toml 2>/dev/null && FRAMEWORKS="${FRAMEWORKS}\"django\","
    grep -qiE "flask" pyproject.toml 2>/dev/null && FRAMEWORKS="${FRAMEWORKS}\"flask\","
    grep -qiE "fastapi" pyproject.toml 2>/dev/null && FRAMEWORKS="${FRAMEWORKS}\"fastapi\","
fi
# Ruby frameworks
if [ -f "Gemfile" ]; then
    grep -qE "rails" Gemfile 2>/dev/null && FRAMEWORKS="${FRAMEWORKS}\"rails\","
    grep -qE "sinatra" Gemfile 2>/dev/null && FRAMEWORKS="${FRAMEWORKS}\"sinatra\","
fi
FRAMEWORKS=$(echo "$FRAMEWORKS" | sed 's/,$//')
echo "${FRAMEWORKS}],"

# Test Runner Detection
echo -n '    "testRunner": '
if [ -f "jest.config.js" ] || [ -f "jest.config.ts" ] || [ -f "jest.config.mjs" ]; then
    echo '"jest",'
elif [ -f "vitest.config.js" ] || [ -f "vitest.config.ts" ]; then
    echo '"vitest",'
elif [ -f "playwright.config.ts" ] || [ -f "playwright.config.js" ]; then
    echo '"playwright",'
elif [ -f "cypress.config.ts" ] || [ -f "cypress.config.js" ]; then
    echo '"cypress",'
elif [ -f "pytest.ini" ] || ([ -f "pyproject.toml" ] && grep -q "pytest" pyproject.toml 2>/dev/null); then
    echo '"pytest",'
elif [ -f "phpunit.xml" ]; then
    echo '"phpunit",'
elif [ -f ".rspec" ]; then
    echo '"rspec",'
else
    echo 'null,'
fi

# Database/ORM Detection
echo -n '    "database": '
if [ -d "prisma" ] || [ -f "prisma/schema.prisma" ]; then
    echo '"prisma",'
elif [ -f "drizzle.config.ts" ]; then
    echo '"drizzle",'
elif [ -f "package.json" ] && grep -qE '"sequelize"' package.json 2>/dev/null; then
    echo '"sequelize",'
elif [ -f "package.json" ] && grep -qE '"typeorm"' package.json 2>/dev/null; then
    echo '"typeorm",'
elif [ -f "package.json" ] && grep -qE '"mongoose"' package.json 2>/dev/null; then
    echo '"mongoose",'
else
    echo 'null,'
fi

# Monorepo Detection
echo -n '    "isMonorepo": '
if [ -f "pnpm-workspace.yaml" ] || [ -f "lerna.json" ] || [ -f "nx.json" ] || [ -f "turbo.json" ] || [ -d "packages" ]; then
    echo 'true,'
else
    echo 'false,'
fi

# CI/CD Detection
echo -n '    "hasCICD": '
if [ -d ".github/workflows" ] || [ -f ".gitlab-ci.yml" ] || [ -f "Jenkinsfile" ] || [ -d ".circleci" ] || [ -f "azure-pipelines.yml" ] || [ -f "bitbucket-pipelines.yml" ]; then
    echo 'true,'
    echo -n '    "cicdPlatform": '
    if [ -d ".github/workflows" ]; then
        echo '"github-actions",'
    elif [ -f ".gitlab-ci.yml" ]; then
        echo '"gitlab-ci",'
    elif [ -f "Jenkinsfile" ]; then
        echo '"jenkins",'
    elif [ -d ".circleci" ]; then
        echo '"circleci",'
    elif [ -f "azure-pipelines.yml" ]; then
        echo '"azure-devops",'
    elif [ -f "bitbucket-pipelines.yml" ]; then
        echo '"bitbucket",'
    else
        echo 'null,'
    fi
else
    echo 'false,'
    echo '    "cicdPlatform": null,'
fi

# Container Detection
echo -n '    "isContainerized": '
if [ -f "Dockerfile" ] || [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ] || [ -f "compose.yml" ] || [ -f ".dockerignore" ]; then
    echo 'true,'
else
    echo 'false,'
fi

# Serverless Detection
echo -n '    "isServerless": '
if [ -f "serverless.yml" ] || [ -f "netlify.toml" ] || [ -f "vercel.json" ] || [ -f "fly.toml" ] || [ -f "railway.json" ]; then
    echo 'true,'
    echo -n '    "serverlessPlatform": '
    if [ -f "vercel.json" ]; then
        echo '"vercel",'
    elif [ -f "netlify.toml" ]; then
        echo '"netlify",'
    elif [ -f "fly.toml" ]; then
        echo '"fly",'
    elif [ -f "serverless.yml" ]; then
        echo '"serverless-framework",'
    elif [ -f "railway.json" ]; then
        echo '"railway",'
    else
        echo 'null,'
    fi
else
    echo 'false,'
    echo '    "serverlessPlatform": null,'
fi

# Cloud Platform Detection
echo -n '    "cloudPlatforms": ['
CLOUDS=""

# AWS Detection
if [ -f "samconfig.toml" ] || [ -f "template.yaml" ] || [ -f "cdk.json" ] || [ -f "amplify.yml" ] || [ -f "aws-exports.js" ] || [ -d ".aws" ] || [ -f "buildspec.yml" ]; then
    CLOUDS="${CLOUDS}\"aws\","
fi

# Heroku Detection
if [ -f "Procfile" ] || [ -f "app.json" ] || [ -f "heroku.yml" ]; then
    CLOUDS="${CLOUDS}\"heroku\","
fi

# Google Cloud Detection
if [ -f "app.yaml" ] || [ -f "cloudbuild.yaml" ] || [ -f ".gcloudignore" ] || [ -d ".gcloud" ]; then
    CLOUDS="${CLOUDS}\"gcp\","
fi

# Azure Detection
if [ -f "azure-pipelines.yml" ] || [ -d ".azure" ] || [ -f "azuredeploy.json" ]; then
    CLOUDS="${CLOUDS}\"azure\","
fi

# DigitalOcean Detection
if [ -f ".do/app.yaml" ] || [ -f "do.yaml" ]; then
    CLOUDS="${CLOUDS}\"digitalocean\","
fi

# Cloudflare Detection
if [ -f "wrangler.toml" ] || [ -f "wrangler.json" ]; then
    CLOUDS="${CLOUDS}\"cloudflare\","
fi

# Supabase Detection
if [ -d "supabase" ] || [ -f "supabase/config.toml" ]; then
    CLOUDS="${CLOUDS}\"supabase\","
fi

# Firebase Detection
if [ -f "firebase.json" ] || [ -f ".firebaserc" ]; then
    CLOUDS="${CLOUDS}\"firebase\","
fi

CLOUDS=$(echo "$CLOUDS" | sed 's/,$//')
echo "${CLOUDS}],"

# Confidence Calculation
echo -n '    "confidence": '
CONFIDENCE="low"
# Count detected items
COUNT=0
[ -f "package.json" ] || [ -f "requirements.txt" ] || [ -f "Gemfile" ] || [ -f "go.mod" ] || [ -f "Cargo.toml" ] && COUNT=$((COUNT + 1))
[ -n "$FRAMEWORKS" ] && COUNT=$((COUNT + 1))
[ -f "jest.config.js" ] || [ -f "vitest.config.ts" ] || [ -f "pytest.ini" ] && COUNT=$((COUNT + 1))
[ -d "src" ] || [ -d "lib" ] || [ -d "app" ] && COUNT=$((COUNT + 1))

if [ $COUNT -ge 3 ]; then
    echo '"high"'
elif [ $COUNT -ge 2 ]; then
    echo '"medium"'
else
    echo '"low"'
fi

echo '  }'
echo "}"
