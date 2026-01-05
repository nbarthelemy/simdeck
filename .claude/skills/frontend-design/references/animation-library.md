# Animation Library

Production-ready animation patterns for modern interfaces.

## Core Principles

1. **Purpose over decoration** — Every animation should aid comprehension or provide feedback
2. **Consistent timing** — Use the same easing and duration patterns throughout
3. **Performance first** — Only animate transform and opacity (GPU accelerated)
4. **Respect preferences** — Honor prefers-reduced-motion

---

## Timing Functions

### Easing Curves

```css
/* Standard curves */
--ease-linear: linear;
--ease-in: cubic-bezier(0.4, 0, 1, 1);
--ease-out: cubic-bezier(0, 0, 0.2, 1);
--ease-in-out: cubic-bezier(0.4, 0, 0.2, 1);

/* Expressive curves */
--ease-out-expo: cubic-bezier(0.16, 1, 0.3, 1);
--ease-out-quart: cubic-bezier(0.25, 1, 0.5, 1);
--ease-out-back: cubic-bezier(0.34, 1.56, 0.64, 1);
--ease-in-out-quart: cubic-bezier(0.76, 0, 0.24, 1);

/* Spring-like */
--ease-spring: cubic-bezier(0.68, -0.55, 0.265, 1.55);
--ease-bounce: cubic-bezier(0.68, -0.6, 0.32, 1.6);
```

### Duration Scale

| Category | Duration | Use Case |
|----------|----------|----------|
| Instant | 0ms | State changes (no animation) |
| Fast | 100-150ms | Micro-interactions, hovers, toggles |
| Normal | 200-300ms | Standard transitions, modals |
| Slow | 400-500ms | Page transitions, emphasis |
| Slower | 600-800ms | Complex sequences, hero animations |

```css
--duration-instant: 0ms;
--duration-fast: 150ms;
--duration-normal: 250ms;
--duration-slow: 400ms;
--duration-slower: 600ms;
```

---

## Entrance Animations

### Fade In

```css
@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

.animate-fade-in {
  animation: fadeIn var(--duration-normal) var(--ease-out) forwards;
}
```

### Fade In Up

```css
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

.animate-fade-in-up {
  animation: fadeInUp var(--duration-slow) var(--ease-out-expo) forwards;
}
```

### Fade In Down

```css
@keyframes fadeInDown {
  from {
    opacity: 0;
    transform: translateY(-20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.animate-fade-in-down {
  animation: fadeInDown var(--duration-slow) var(--ease-out-expo) forwards;
}
```

### Slide In (Directional)

```css
@keyframes slideInLeft {
  from {
    opacity: 0;
    transform: translateX(-30px);
  }
  to {
    opacity: 1;
    transform: translateX(0);
  }
}

@keyframes slideInRight {
  from {
    opacity: 0;
    transform: translateX(30px);
  }
  to {
    opacity: 1;
    transform: translateX(0);
  }
}

.animate-slide-in-left {
  animation: slideInLeft var(--duration-slow) var(--ease-out-expo) forwards;
}

.animate-slide-in-right {
  animation: slideInRight var(--duration-slow) var(--ease-out-expo) forwards;
}
```

### Scale In

```css
@keyframes scaleIn {
  from {
    opacity: 0;
    transform: scale(0.9);
  }
  to {
    opacity: 1;
    transform: scale(1);
  }
}

.animate-scale-in {
  animation: scaleIn var(--duration-normal) var(--ease-out-back) forwards;
}
```

### Bounce In

```css
@keyframes bounceIn {
  0% {
    opacity: 0;
    transform: scale(0.3);
  }
  50% {
    transform: scale(1.05);
  }
  70% {
    transform: scale(0.9);
  }
  100% {
    opacity: 1;
    transform: scale(1);
  }
}

.animate-bounce-in {
  animation: bounceIn var(--duration-slower) var(--ease-spring) forwards;
}
```

---

## Exit Animations

### Fade Out

```css
@keyframes fadeOut {
  from { opacity: 1; }
  to { opacity: 0; }
}

.animate-fade-out {
  animation: fadeOut var(--duration-fast) var(--ease-in) forwards;
}
```

### Fade Out Down

```css
@keyframes fadeOutDown {
  from {
    opacity: 1;
    transform: translateY(0);
  }
  to {
    opacity: 0;
    transform: translateY(20px);
  }
}

.animate-fade-out-down {
  animation: fadeOutDown var(--duration-normal) var(--ease-in) forwards;
}
```

### Scale Out

```css
@keyframes scaleOut {
  from {
    opacity: 1;
    transform: scale(1);
  }
  to {
    opacity: 0;
    transform: scale(0.9);
  }
}

.animate-scale-out {
  animation: scaleOut var(--duration-fast) var(--ease-in) forwards;
}
```

---

## Stagger System

### CSS Stagger Pattern

```css
/* Parent applies stagger to children */
.stagger-children > * {
  opacity: 0;
  animation: fadeInUp var(--duration-slow) var(--ease-out-expo) forwards;
}

.stagger-children > *:nth-child(1) { animation-delay: 0ms; }
.stagger-children > *:nth-child(2) { animation-delay: 75ms; }
.stagger-children > *:nth-child(3) { animation-delay: 150ms; }
.stagger-children > *:nth-child(4) { animation-delay: 225ms; }
.stagger-children > *:nth-child(5) { animation-delay: 300ms; }
.stagger-children > *:nth-child(6) { animation-delay: 375ms; }
.stagger-children > *:nth-child(7) { animation-delay: 450ms; }
.stagger-children > *:nth-child(8) { animation-delay: 525ms; }

/* Utility classes for manual control */
.delay-0 { animation-delay: 0ms; }
.delay-75 { animation-delay: 75ms; }
.delay-150 { animation-delay: 150ms; }
.delay-225 { animation-delay: 225ms; }
.delay-300 { animation-delay: 300ms; }
.delay-400 { animation-delay: 400ms; }
.delay-500 { animation-delay: 500ms; }
```

### Tailwind Stagger

```html
<div class="space-y-4">
  <div class="animate-fade-in-up">Item 1</div>
  <div class="animate-fade-in-up opacity-0 [animation-delay:75ms]">Item 2</div>
  <div class="animate-fade-in-up opacity-0 [animation-delay:150ms]">Item 3</div>
  <div class="animate-fade-in-up opacity-0 [animation-delay:225ms]">Item 4</div>
</div>
```

---

## Continuous Animations

### Pulse

```css
@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.5; }
}

.animate-pulse {
  animation: pulse 2s var(--ease-in-out) infinite;
}
```

### Pulse Glow

```css
@keyframes pulseGlow {
  0%, 100% {
    box-shadow: 0 0 20px var(--glow-primary);
  }
  50% {
    box-shadow: 0 0 40px var(--glow-primary), 0 0 60px var(--glow-primary);
  }
}

.animate-pulse-glow {
  animation: pulseGlow 2s var(--ease-in-out) infinite;
}
```

### Float

```css
@keyframes float {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-10px); }
}

.animate-float {
  animation: float 3s var(--ease-in-out) infinite;
}
```

### Spin

```css
@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}

.animate-spin {
  animation: spin 1s linear infinite;
}

.animate-spin-slow {
  animation: spin 3s linear infinite;
}
```

### Shimmer (Loading)

```css
@keyframes shimmer {
  0% {
    background-position: -200% 0;
  }
  100% {
    background-position: 200% 0;
  }
}

.animate-shimmer {
  background: linear-gradient(
    90deg,
    var(--bg-secondary) 25%,
    var(--bg-tertiary) 50%,
    var(--bg-secondary) 75%
  );
  background-size: 200% 100%;
  animation: shimmer 1.5s infinite;
}
```

---

## Interactive Animations

### Hover Lift

```css
.hover-lift {
  transition: transform var(--duration-fast) var(--ease-out);
}

.hover-lift:hover {
  transform: translateY(-4px);
}
```

### Hover Scale

```css
.hover-scale {
  transition: transform var(--duration-fast) var(--ease-out);
}

.hover-scale:hover {
  transform: scale(1.02);
}
```

### Hover Glow

```css
.hover-glow {
  transition: box-shadow var(--duration-normal) var(--ease-out);
}

.hover-glow:hover {
  box-shadow: 0 0 30px var(--glow-primary);
}
```

### Press Effect

```css
.press-effect {
  transition: transform var(--duration-fast) var(--ease-out);
}

.press-effect:hover {
  transform: translateY(-2px);
}

.press-effect:active {
  transform: translateY(0);
}
```

### Magnetic Hover (Advanced)

```css
/* Requires JavaScript for full effect */
.magnetic {
  transition: transform var(--duration-fast) var(--ease-out);
}

/* JS applies transform based on cursor position */
```

---

## Page Transitions

### Fade Transition

```css
.page-enter {
  opacity: 0;
}

.page-enter-active {
  opacity: 1;
  transition: opacity var(--duration-slow) var(--ease-out);
}

.page-exit {
  opacity: 1;
}

.page-exit-active {
  opacity: 0;
  transition: opacity var(--duration-fast) var(--ease-in);
}
```

### Slide Transition

```css
.page-enter {
  opacity: 0;
  transform: translateX(20px);
}

.page-enter-active {
  opacity: 1;
  transform: translateX(0);
  transition: all var(--duration-slow) var(--ease-out-expo);
}

.page-exit {
  opacity: 1;
  transform: translateX(0);
}

.page-exit-active {
  opacity: 0;
  transform: translateX(-20px);
  transition: all var(--duration-normal) var(--ease-in);
}
```

---

## Scroll Animations

### Reveal on Scroll

```css
.scroll-reveal {
  opacity: 0;
  transform: translateY(40px);
  transition: all var(--duration-slower) var(--ease-out-expo);
}

.scroll-reveal.is-visible {
  opacity: 1;
  transform: translateY(0);
}
```

### Parallax Layer

```css
.parallax-slow {
  transform: translateY(calc(var(--scroll-y) * 0.3));
}

.parallax-medium {
  transform: translateY(calc(var(--scroll-y) * 0.5));
}

.parallax-fast {
  transform: translateY(calc(var(--scroll-y) * 0.7));
}
```

---

## Accessibility

### Reduced Motion

```css
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

### Safe Animations (Alternative)

```css
/* Provide simpler alternatives for reduced motion */
@media (prefers-reduced-motion: reduce) {
  .animate-fade-in-up,
  .animate-slide-in-left,
  .animate-bounce-in {
    animation: fadeIn var(--duration-fast) var(--ease-out) forwards;
  }
}
```

---

## Framework Integration

### Tailwind Config

```js
// tailwind.config.js
module.exports = {
  theme: {
    extend: {
      animation: {
        'fade-in': 'fadeIn 0.5s ease-out forwards',
        'fade-in-up': 'fadeInUp 0.5s ease-out forwards',
        'fade-in-down': 'fadeInDown 0.5s ease-out forwards',
        'slide-in-left': 'slideInLeft 0.4s ease-out forwards',
        'slide-in-right': 'slideInRight 0.4s ease-out forwards',
        'scale-in': 'scaleIn 0.3s ease-out forwards',
        'bounce-in': 'bounceIn 0.6s cubic-bezier(0.68, -0.55, 0.265, 1.55) forwards',
        'pulse-glow': 'pulseGlow 2s ease-in-out infinite',
        'float': 'float 3s ease-in-out infinite',
        'shimmer': 'shimmer 1.5s infinite',
      },
      keyframes: {
        fadeIn: { /* ... */ },
        fadeInUp: { /* ... */ },
        // ... all keyframes
      },
    },
  },
}
```

### React/Framer Motion

```jsx
// Common animation variants
export const fadeInUp = {
  initial: { opacity: 0, y: 20 },
  animate: { opacity: 1, y: 0 },
  exit: { opacity: 0, y: -10 },
  transition: { duration: 0.4, ease: [0.16, 1, 0.3, 1] }
};

export const staggerContainer = {
  animate: {
    transition: {
      staggerChildren: 0.075
    }
  }
};

export const scaleIn = {
  initial: { opacity: 0, scale: 0.9 },
  animate: { opacity: 1, scale: 1 },
  transition: { duration: 0.3, ease: [0.34, 1.56, 0.64, 1] }
};
```

### Vue Transitions

```vue
<template>
  <Transition name="fade-up">
    <div v-if="show">Content</div>
  </Transition>
</template>

<style>
.fade-up-enter-active {
  transition: all 0.4s cubic-bezier(0.16, 1, 0.3, 1);
}
.fade-up-leave-active {
  transition: all 0.2s ease-in;
}
.fade-up-enter-from {
  opacity: 0;
  transform: translateY(20px);
}
.fade-up-leave-to {
  opacity: 0;
  transform: translateY(-10px);
}
</style>
```
