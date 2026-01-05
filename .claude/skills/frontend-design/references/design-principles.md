# Design Principles Reference

Deep knowledge base for the frontend-design skill.

## The Hierarchy of Design Decisions

### 1. Concept (Most Important)
What story is this interface telling? What emotion should users feel?

### 2. Layout
How is space organized? Where does the eye travel?

### 3. Typography
How does text communicate hierarchy and personality?

### 4. Color
How do colors reinforce the concept and guide attention?

### 5. Details (Least Important, But Memorable)
Shadows, borders, animations, micro-interactions

**Work top-down.** A beautiful button cannot save a confused layout.

---

## Typography Deep Dive

### Font Pairing Strategies

**Contrast Pairing** (Most common, safest)
- Serif headlines + Sans body
- Display font + Neutral body
- Example: Playfair Display + Source Sans Pro

**Superfamily Pairing**
- Same family, different weights/styles
- Example: Inter Display + Inter
- Guarantees harmony

**Mood Pairing**
- Match emotional register
- Both fonts feel technical, or both feel warm
- Example: Space Grotesk + JetBrains Mono (technical)

### Typography Scale Systems

**Modular Scale** (1.25 ratio)
```
12px → 15px → 19px → 24px → 30px → 37px → 47px → 59px
```

**Fluid Typography**
```css
/* Base: 16px at 320px, 20px at 1200px */
font-size: clamp(1rem, 0.9rem + 0.5vw, 1.25rem);
```

### Line Height Guide

| Text Size | Line Height |
|-----------|-------------|
| < 16px | 1.6 - 1.7 |
| 16-20px | 1.5 - 1.6 |
| 20-32px | 1.3 - 1.5 |
| 32-48px | 1.2 - 1.3 |
| > 48px | 1.0 - 1.2 |

---

## Color Theory in Practice

### Building a Palette

**60-30-10 Rule**
- 60% Dominant (backgrounds, large areas)
- 30% Secondary (cards, sections)
- 10% Accent (CTAs, highlights)

**Semantic Colors**
```css
/* Success/Error/Warning/Info */
--success: hsl(142 70% 45%);
--error: hsl(0 84% 60%);
--warning: hsl(38 92% 50%);
--info: hsl(200 98% 48%);
```

### Dark Mode Principles

1. **Don't invert** — Design fresh for dark
2. **Reduce contrast** — Pure white (#fff) on pure black (#000) strains eyes
3. **Desaturate slightly** — Bright colors feel harsh on dark
4. **Add depth with subtle gradients** — Prevents flat feeling
5. **Glow effects work** — Neon/glow is appropriate in dark mode

```css
/* Dark mode color adjustments */
.dark {
  --text-primary: hsl(0 0% 93%); /* Not pure white */
  --bg-primary: hsl(225 20% 8%); /* Not pure black */
  --accent-primary: hsl(265 80% 68%); /* Slightly desaturated */
}
```

### Color Accessibility

| Contrast Ratio | Use Case |
|---------------|----------|
| 4.5:1 | Normal text (WCAG AA) |
| 3:1 | Large text, UI components |
| 7:1 | Normal text (WCAG AAA) |

---

## Layout Patterns

### The Bento Grid
Asymmetric grid with varied cell sizes. Modern, interesting.
```css
.bento {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  grid-template-rows: repeat(3, 200px);
  gap: 1rem;
}
.bento-large { grid-column: span 2; grid-row: span 2; }
.bento-wide { grid-column: span 2; }
.bento-tall { grid-row: span 2; }
```

### Broken Grid
Elements that break the grid create visual tension.
```css
.break-grid {
  margin-left: -2rem;
  width: calc(100% + 4rem);
}
```

### Overlap Compositions
Layered elements create depth.
```css
.overlap-container {
  display: grid;
  grid-template-columns: 1fr;
}
.overlap-container > * {
  grid-column: 1;
  grid-row: 1;
}
```

---

## Animation Principles

### The 12 Principles (Adapted for UI)

1. **Timing** — Fast for UI (150-300ms), slower for emphasis
2. **Easing** — Never linear; ease-out for entrances, ease-in for exits
3. **Anticipation** — Slight pull-back before forward motion
4. **Staging** — Guide the eye to what matters
5. **Follow-through** — Elements settle, don't just stop

### Animation Categories

**Micro-interactions** (100-200ms)
- Button hover states
- Toggle switches
- Icon morphs

**Transitions** (200-400ms)
- Page transitions
- Modal open/close
- Drawer slides

**Emphasis** (400-800ms)
- Hero animations
- Success celebrations
- Onboarding sequences

### Performance Rules

1. **Only animate transform and opacity** — GPU accelerated
2. **Use will-change sparingly** — Only on elements about to animate
3. **Respect prefers-reduced-motion**
   ```css
   @media (prefers-reduced-motion: reduce) {
     *, *::before, *::after {
       animation-duration: 0.01ms !important;
       transition-duration: 0.01ms !important;
     }
   }
   ```

---

## Component Design Patterns

### Cards

**The Perfect Card:**
```css
.card {
  background: var(--bg-secondary);
  border: 1px solid var(--border-subtle);
  border-radius: 12px;
  padding: 1.5rem;
  transition: all 200ms ease;
}

.card:hover {
  border-color: var(--border-strong);
  transform: translateY(-2px);
  box-shadow: var(--shadow-lg);
}
```

### Buttons

**Button Hierarchy:**
1. **Primary** — Main action, filled
2. **Secondary** — Alternative action, outlined
3. **Ghost** — Tertiary, minimal styling
4. **Destructive** — Dangerous actions, red

```css
.btn-primary {
  background: var(--accent-primary);
  color: white;
  padding: 0.75rem 1.5rem;
  border-radius: 8px;
  font-weight: 500;
  transition: all 150ms ease;
}

.btn-primary:hover {
  background: var(--accent-primary-hover);
  transform: translateY(-1px);
}

.btn-primary:active {
  transform: translateY(0);
}
```

### Forms

**Input Excellence:**
```css
.input {
  width: 100%;
  padding: 0.75rem 1rem;
  background: var(--bg-tertiary);
  border: 1px solid var(--border-subtle);
  border-radius: 8px;
  color: var(--text-primary);
  transition: all 150ms ease;
}

.input:hover {
  border-color: var(--border-strong);
}

.input:focus {
  outline: none;
  border-color: var(--accent-primary);
  box-shadow: 0 0 0 3px var(--glow-primary);
}

.input::placeholder {
  color: var(--text-tertiary);
}
```

---

## Responsive Design

### Breakpoint Strategy

```css
/* Mobile-first breakpoints */
--bp-sm: 640px;   /* Large phones */
--bp-md: 768px;   /* Tablets */
--bp-lg: 1024px;  /* Laptops */
--bp-xl: 1280px;  /* Desktops */
--bp-2xl: 1536px; /* Large monitors */
```

### Container Queries (Modern)

```css
.card-container {
  container-type: inline-size;
}

@container (min-width: 400px) {
  .card {
    flex-direction: row;
  }
}
```

---

## Design System Tokens

### Complete Token Set

```css
:root {
  /* Colors */
  --color-gray-50: hsl(220 20% 98%);
  --color-gray-100: hsl(220 17% 93%);
  --color-gray-200: hsl(220 15% 85%);
  --color-gray-300: hsl(220 13% 70%);
  --color-gray-400: hsl(220 11% 55%);
  --color-gray-500: hsl(220 9% 45%);
  --color-gray-600: hsl(220 11% 35%);
  --color-gray-700: hsl(220 13% 25%);
  --color-gray-800: hsl(220 15% 16%);
  --color-gray-900: hsl(220 17% 10%);
  --color-gray-950: hsl(220 20% 6%);

  /* Spacing */
  --space-px: 1px;
  --space-0: 0;
  --space-1: 0.25rem;
  --space-2: 0.5rem;
  --space-3: 0.75rem;
  --space-4: 1rem;
  --space-5: 1.25rem;
  --space-6: 1.5rem;
  --space-8: 2rem;
  --space-10: 2.5rem;
  --space-12: 3rem;
  --space-16: 4rem;
  --space-20: 5rem;
  --space-24: 6rem;

  /* Border Radius */
  --radius-sm: 4px;
  --radius-md: 8px;
  --radius-lg: 12px;
  --radius-xl: 16px;
  --radius-2xl: 24px;
  --radius-full: 9999px;

  /* Shadows */
  --shadow-xs: 0 1px 2px 0 rgb(0 0 0 / 0.05);
  --shadow-sm: 0 1px 3px 0 rgb(0 0 0 / 0.1);
  --shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.1);
  --shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.1);
  --shadow-xl: 0 20px 25px -5px rgb(0 0 0 / 0.1);
  --shadow-2xl: 0 25px 50px -12px rgb(0 0 0 / 0.25);

  /* Transitions */
  --transition-fast: 150ms ease;
  --transition-normal: 250ms ease;
  --transition-slow: 400ms ease;

  /* Z-index */
  --z-dropdown: 100;
  --z-sticky: 200;
  --z-modal: 300;
  --z-popover: 400;
  --z-toast: 500;
}
```
