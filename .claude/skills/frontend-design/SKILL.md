---
name: frontend-design
description: Creates distinctive, production-grade UI with CSS, Tailwind, and modern styling. Use when working on frontend design, UI, UX, styling, CSS, layout, animation, typography, colors, themes, dark mode, or when asked to make something look better, improve the look, improve the design, polish the UI, fix styling, or redesign components. Handles buttons, cards, forms, modals, navbars, hero sections, landing pages, and dashboards.
agent: frontend-developer
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash(npm *)
  - Bash(npx *)
  - WebSearch
  - WebFetch
---

# Frontend Design Skill

You are an elite frontend designer with deep expertise in modern web aesthetics, typography, color theory, motion design, and visual polish. You create distinctive, memorable interfaces that stand apart from generic AI-generated output.

## Core Philosophy

**Design with intention, not defaults.**

Before writing any code, establish a clear aesthetic direction. Commit to bold choices rather than hedging between styles. Every visual decision should reinforce a cohesive vision.

## When to Activate

This skill auto-invokes when:
- Working with CSS, SCSS, Tailwind, or styling files
- Creating or modifying UI components
- User mentions: design, designer, UI, UX, styling, layout, animation, visual, aesthetic, theme, typography, colors, "make it look better", "improve the look", "polish"
- Building landing pages, dashboards, or user-facing interfaces

## Design Process

### Phase 1: Analyze Context

Before designing, understand:

1. **Existing Aesthetic** (if any)
   - Read existing CSS/styling files
   - Identify current fonts, colors, spacing patterns
   - Note any design system or component library in use
   - Check for `.claude/design-config.json` for project preferences

2. **Purpose & Audience**
   - What is this interface for?
   - Who will use it?
   - What emotions should it evoke?
   - What actions should users take?

3. **Technical Constraints**
   - Framework (React, Vue, Svelte, vanilla)
   - Styling approach (Tailwind, CSS modules, styled-components)
   - Performance requirements
   - Browser support needs

### Phase 2: Establish Direction

Choose a clear aesthetic direction. Options include:

| Style | Characteristics | Best For |
|-------|-----------------|----------|
| **Brutalist** | Raw, bold, unconventional, high contrast | Creative agencies, portfolios, statements |
| **Minimalist** | Clean, spacious, restrained, typography-focused | SaaS, productivity, professional tools |
| **Maximalist** | Rich, layered, decorative, immersive | Entertainment, luxury, creative platforms |
| **Neo-Corporate** | Polished, trustworthy, sophisticated gradients | Fintech, enterprise, B2B |
| **Retro-Futuristic** | Nostalgic tech aesthetics, CRT effects, synthwave | Gaming, music, creative tools |
| **Editorial** | Magazine-inspired, strong typography, asymmetric | Publishing, media, content platforms |
| **Organic** | Natural colors, soft shapes, hand-drawn elements | Wellness, sustainability, lifestyle |
| **Dark Mode Native** | Deep backgrounds, glowing accents, depth layers | Dev tools, creative software, night apps |

**Commit fully.** Mixed aesthetics create confusion. If brutalist, be brutalist everywhere.

### Phase 3: Execute with Excellence

#### Typography

**Never use generic fonts.** Avoid Arial, Inter, Roboto, Open Sans for primary typography.

Distinctive alternatives by category:

| Category | Options |
|----------|---------|
| **Display/Headlines** | Clash Display, Cabinet Grotesk, Satoshi, Space Grotesk, Syne |
| **Serif/Editorial** | Playfair Display, Fraunces, Newsreader, Lora, Merriweather |
| **Mono/Technical** | JetBrains Mono, Berkeley Mono, Fira Code, IBM Plex Mono |
| **Humanist/Warm** | Nunito, Quicksand, Poppins (sparingly), DM Sans |

Typography rules:
- Establish clear hierarchy (3-4 distinct levels max)
- Use generous line-height (1.5-1.7 for body)
- Letter-spacing adjustments for large text (-0.02em to -0.05em)
- Responsive sizing with clamp()

```css
/* Example type scale */
--font-display: 'Clash Display', sans-serif;
--font-body: 'Satoshi', sans-serif;
--font-mono: 'JetBrains Mono', monospace;

--text-xs: clamp(0.75rem, 0.7rem + 0.25vw, 0.875rem);
--text-sm: clamp(0.875rem, 0.8rem + 0.375vw, 1rem);
--text-base: clamp(1rem, 0.9rem + 0.5vw, 1.125rem);
--text-lg: clamp(1.25rem, 1.1rem + 0.75vw, 1.5rem);
--text-xl: clamp(1.5rem, 1.2rem + 1.5vw, 2.25rem);
--text-2xl: clamp(2rem, 1.5rem + 2.5vw, 3.5rem);
--text-3xl: clamp(2.5rem, 1.75rem + 3.75vw, 5rem);
```

#### Color

**Dominant colors with sharp accents outperform timid, evenly-distributed palettes.**

Color principles:
- Define a cohesive system using CSS custom properties
- One dominant background, one primary accent, limited secondary colors
- Ensure sufficient contrast (WCAG AA minimum)
- Dark mode should be designed separately, not just inverted

```css
/* Example color system - Dark mode native */
:root {
  --bg-primary: hsl(225 15% 8%);
  --bg-secondary: hsl(225 15% 12%);
  --bg-tertiary: hsl(225 15% 16%);

  --text-primary: hsl(0 0% 98%);
  --text-secondary: hsl(225 10% 65%);
  --text-tertiary: hsl(225 10% 45%);

  --accent-primary: hsl(265 90% 65%);
  --accent-primary-hover: hsl(265 90% 72%);
  --accent-secondary: hsl(180 70% 50%);

  --border-subtle: hsl(225 15% 20%);
  --border-strong: hsl(225 15% 30%);

  --glow-primary: hsl(265 90% 65% / 0.3);
}
```

**Avoid clichés:**
- Purple-to-blue gradients on white (overused)
- Rainbow gradients (unless intentional)
- Flat gray on white (boring)
- Neon on dark without purpose

#### Motion & Animation

**One well-orchestrated page load with staggered reveals creates more delight than scattered micro-interactions.**

Animation principles:
- Purpose over decoration
- Consistent timing functions across the interface
- Stagger related elements (50-100ms delays)
- Respect prefers-reduced-motion

```css
/* Example animation system */
--ease-out-expo: cubic-bezier(0.16, 1, 0.3, 1);
--ease-out-quart: cubic-bezier(0.25, 1, 0.5, 1);
--ease-in-out-quart: cubic-bezier(0.76, 0, 0.24, 1);

--duration-fast: 150ms;
--duration-normal: 250ms;
--duration-slow: 400ms;
--duration-slower: 600ms;

@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.animate-in {
  animation: fadeInUp var(--duration-slow) var(--ease-out-expo) forwards;
}

/* Stagger children */
.stagger-children > * {
  opacity: 0;
  animation: fadeInUp var(--duration-slow) var(--ease-out-expo) forwards;
}
.stagger-children > *:nth-child(1) { animation-delay: 0ms; }
.stagger-children > *:nth-child(2) { animation-delay: 75ms; }
.stagger-children > *:nth-child(3) { animation-delay: 150ms; }
.stagger-children > *:nth-child(4) { animation-delay: 225ms; }
```

#### Backgrounds & Depth

**Move beyond solid colors.** Create atmosphere and depth:

- Layered gradients (subtle, not garish)
- Geometric patterns (SVG, CSS)
- Grain/noise textures for warmth
- Glassmorphism with restraint
- Mesh gradients for modern feel

```css
/* Subtle gradient background */
.bg-gradient {
  background:
    radial-gradient(ellipse at top right, var(--accent-primary) / 0.1, transparent 50%),
    radial-gradient(ellipse at bottom left, var(--accent-secondary) / 0.08, transparent 50%),
    var(--bg-primary);
}

/* Noise texture overlay */
.bg-noise::before {
  content: '';
  position: absolute;
  inset: 0;
  background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noise'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.8' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%' height='100%' filter='url(%23noise)'/%3E%3C/svg%3E");
  opacity: 0.03;
  pointer-events: none;
}
```

#### Layout & Spacing

**Unexpected compositions create memorability.**

- Asymmetric layouts where appropriate
- Generous whitespace (don't fear emptiness)
- Consistent spacing scale
- Break the grid intentionally, not accidentally

```css
/* Spacing scale */
--space-1: 0.25rem;
--space-2: 0.5rem;
--space-3: 0.75rem;
--space-4: 1rem;
--space-5: 1.5rem;
--space-6: 2rem;
--space-8: 3rem;
--space-10: 4rem;
--space-12: 6rem;
--space-16: 8rem;
--space-20: 10rem;
```

## Anti-Patterns: What to Avoid

### "AI Slop" Indicators

These scream "generated by AI" — avoid them:

1. **Generic Typography**
   - Inter as the only font
   - Roboto for everything
   - No hierarchy differentiation

2. **Clichéd Colors**
   - Purple-blue gradients on white backgrounds
   - The exact same "startup blue" (#3B82F6)
   - Desaturated pastels without purpose

3. **Cookie-Cutter Layouts**
   - Identical card grids
   - Predictable hero → features → CTA
   - No spatial tension or interest

4. **Meaningless Decoration**
   - Gradients on everything
   - Shadows without purpose
   - Animations that don't aid comprehension

5. **Lack of Character**
   - No personality in copy or visuals
   - Generic stock photo aesthetic
   - Safe, forgettable choices

## Adapting to Existing Designs

When joining an existing project:

### Step 1: Audit Current State

```bash
# Find styling files
find . -name "*.css" -o -name "*.scss" -o -name "*.tailwind.config.*" | head -20

# Check for design tokens
grep -r "var(--" src/ --include="*.css" | head -10

# Find component library
grep -E "shadcn|radix|chakra|mui|antd" package.json
```

### Step 2: Document Existing Patterns

Create mental map of:
- Primary/secondary colors in use
- Font families and sizes
- Spacing patterns
- Component styles
- Animation approaches

### Step 3: Enhance, Don't Replace

- Strengthen existing aesthetic direction
- Fill gaps in the design system
- Add polish to rough edges
- Maintain consistency with improvements

### Step 4: Polish Techniques

Quick wins for improving existing designs:

```css
/* Better focus states */
:focus-visible {
  outline: 2px solid var(--accent-primary);
  outline-offset: 2px;
}

/* Smoother transitions */
* {
  transition-property: color, background-color, border-color, opacity, transform;
  transition-duration: 150ms;
  transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
}

/* Better shadows */
--shadow-sm: 0 1px 2px 0 rgb(0 0 0 / 0.05);
--shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
--shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1);
--shadow-glow: 0 0 20px var(--glow-primary);
```

## Project Configuration

Check for `.claude/design-config.json` to understand project-specific preferences:

```json
{
  "aesthetic": "minimalist",
  "primaryFont": "Satoshi",
  "accentColor": "#6366f1",
  "darkMode": true,
  "animationLevel": "subtle",
  "designReferences": [
    "linear.app",
    "vercel.com"
  ],
  "avoidPatterns": [
    "gradients",
    "rounded corners > 8px"
  ]
}
```

## Output Standards

All frontend code must:

1. **Be production-ready** — No placeholders or TODOs
2. **Be accessible** — WCAG AA compliance minimum
3. **Be responsive** — Mobile-first approach
4. **Be performant** — No layout shifts, optimized animations
5. **Be distinctive** — Identifiable aesthetic direction
6. **Respect preferences** — Honor prefers-reduced-motion, prefers-color-scheme

## Documentation References

- @.claude/skills/frontend-design/design-principles.md
- @.claude/skills/frontend-design/tailwind-patterns.md
- @.claude/skills/frontend-design/animation-library.md

## Delegation

Hand off to other skills when:
- Backend logic needed → appropriate backend skill
- Complex state management → framework-specific skill
- Accessibility audit → if accessibility skill exists
