# Tailwind CSS Patterns

Modern, distinctive patterns for Tailwind CSS projects.

## Custom Configuration

### Extend, Don't Override

```js
// tailwind.config.js
module.exports = {
  theme: {
    extend: {
      // Custom fonts
      fontFamily: {
        display: ['Clash Display', 'sans-serif'],
        body: ['Satoshi', 'sans-serif'],
        mono: ['JetBrains Mono', 'monospace'],
      },

      // Custom colors (HSL for flexibility)
      colors: {
        brand: {
          50: 'hsl(265 100% 98%)',
          100: 'hsl(265 95% 94%)',
          200: 'hsl(265 90% 85%)',
          300: 'hsl(265 85% 74%)',
          400: 'hsl(265 80% 64%)',
          500: 'hsl(265 75% 54%)',
          600: 'hsl(265 70% 45%)',
          700: 'hsl(265 65% 36%)',
          800: 'hsl(265 60% 28%)',
          900: 'hsl(265 55% 20%)',
          950: 'hsl(265 50% 12%)',
        },
      },

      // Custom animations
      animation: {
        'fade-in': 'fadeIn 0.5s ease-out forwards',
        'fade-in-up': 'fadeInUp 0.5s ease-out forwards',
        'fade-in-down': 'fadeInDown 0.5s ease-out forwards',
        'scale-in': 'scaleIn 0.3s ease-out forwards',
        'slide-in-right': 'slideInRight 0.4s ease-out forwards',
        'slide-in-left': 'slideInLeft 0.4s ease-out forwards',
        'bounce-in': 'bounceIn 0.6s cubic-bezier(0.68, -0.55, 0.265, 1.55) forwards',
        'spin-slow': 'spin 3s linear infinite',
        'pulse-glow': 'pulseGlow 2s ease-in-out infinite',
      },

      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        fadeInUp: {
          '0%': { opacity: '0', transform: 'translateY(20px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        fadeInDown: {
          '0%': { opacity: '0', transform: 'translateY(-20px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        scaleIn: {
          '0%': { opacity: '0', transform: 'scale(0.9)' },
          '100%': { opacity: '1', transform: 'scale(1)' },
        },
        slideInRight: {
          '0%': { opacity: '0', transform: 'translateX(20px)' },
          '100%': { opacity: '1', transform: 'translateX(0)' },
        },
        slideInLeft: {
          '0%': { opacity: '0', transform: 'translateX(-20px)' },
          '100%': { opacity: '1', transform: 'translateX(0)' },
        },
        bounceIn: {
          '0%': { opacity: '0', transform: 'scale(0.3)' },
          '50%': { transform: 'scale(1.05)' },
          '70%': { transform: 'scale(0.9)' },
          '100%': { opacity: '1', transform: 'scale(1)' },
        },
        pulseGlow: {
          '0%, 100%': { boxShadow: '0 0 20px hsl(265 75% 54% / 0.3)' },
          '50%': { boxShadow: '0 0 40px hsl(265 75% 54% / 0.6)' },
        },
      },

      // Custom spacing
      spacing: {
        '18': '4.5rem',
        '22': '5.5rem',
        '128': '32rem',
        '144': '36rem',
      },

      // Custom backdrop blur
      backdropBlur: {
        xs: '2px',
      },

      // Animation delays
      transitionDelay: {
        '0': '0ms',
        '75': '75ms',
        '100': '100ms',
        '150': '150ms',
        '200': '200ms',
        '300': '300ms',
        '400': '400ms',
        '500': '500ms',
      },
    },
  },
  plugins: [],
}
```

---

## Component Patterns

### Distinctive Buttons

```html
<!-- Primary with glow -->
<button class="
  px-6 py-3
  bg-brand-500 hover:bg-brand-400
  text-white font-medium
  rounded-lg
  shadow-lg shadow-brand-500/25
  hover:shadow-xl hover:shadow-brand-500/30
  transform hover:-translate-y-0.5
  transition-all duration-200
  focus:outline-none focus:ring-2 focus:ring-brand-400 focus:ring-offset-2
">
  Get Started
</button>

<!-- Ghost button -->
<button class="
  px-6 py-3
  bg-transparent
  text-gray-300 hover:text-white
  border border-gray-700 hover:border-gray-500
  rounded-lg
  transition-all duration-200
  focus:outline-none focus:ring-2 focus:ring-gray-500
">
  Learn More
</button>

<!-- Gradient button -->
<button class="
  px-6 py-3
  bg-gradient-to-r from-brand-500 to-purple-500
  hover:from-brand-400 hover:to-purple-400
  text-white font-medium
  rounded-lg
  shadow-lg
  transform hover:scale-[1.02]
  transition-all duration-200
">
  Try Now
</button>
```

### Modern Cards

```html
<!-- Glass card -->
<div class="
  p-6
  bg-white/5 backdrop-blur-xl
  border border-white/10
  rounded-2xl
  hover:bg-white/10 hover:border-white/20
  transition-all duration-300
">
  <h3 class="text-xl font-semibold text-white">Card Title</h3>
  <p class="mt-2 text-gray-400">Card description goes here.</p>
</div>

<!-- Elevated card with hover -->
<div class="
  p-6
  bg-gray-900
  border border-gray-800
  rounded-xl
  shadow-lg
  hover:shadow-2xl hover:shadow-brand-500/10
  hover:border-gray-700
  transform hover:-translate-y-1
  transition-all duration-300
">
  <h3 class="text-xl font-semibold text-white">Card Title</h3>
  <p class="mt-2 text-gray-400">Card description goes here.</p>
</div>

<!-- Bento card -->
<div class="
  relative overflow-hidden
  p-8
  bg-gradient-to-br from-gray-900 to-gray-800
  border border-gray-700
  rounded-3xl
  group
">
  <!-- Gradient orb -->
  <div class="
    absolute -top-24 -right-24
    w-48 h-48
    bg-brand-500/30
    rounded-full
    blur-3xl
    group-hover:bg-brand-500/40
    transition-colors duration-500
  "></div>

  <div class="relative z-10">
    <h3 class="text-2xl font-bold text-white">Feature</h3>
    <p class="mt-4 text-gray-400">Description text.</p>
  </div>
</div>
```

### Inputs & Forms

```html
<!-- Modern input -->
<div class="relative">
  <input
    type="text"
    placeholder="Enter your email"
    class="
      w-full
      px-4 py-3
      bg-gray-900
      border border-gray-700
      rounded-lg
      text-white placeholder:text-gray-500
      focus:outline-none focus:border-brand-500 focus:ring-2 focus:ring-brand-500/20
      transition-all duration-200
    "
  />
</div>

<!-- Floating label input -->
<div class="relative">
  <input
    type="text"
    id="email"
    placeholder=" "
    class="
      peer
      w-full
      px-4 pt-6 pb-2
      bg-gray-900
      border border-gray-700
      rounded-lg
      text-white
      focus:outline-none focus:border-brand-500
      transition-all duration-200
    "
  />
  <label
    for="email"
    class="
      absolute left-4 top-4
      text-gray-500
      transition-all duration-200
      peer-placeholder-shown:top-4 peer-placeholder-shown:text-base
      peer-focus:top-2 peer-focus:text-xs peer-focus:text-brand-400
      peer-[:not(:placeholder-shown)]:top-2 peer-[:not(:placeholder-shown)]:text-xs
    "
  >
    Email address
  </label>
</div>
```

### Navigation

```html
<!-- Glassmorphism navbar -->
<nav class="
  fixed top-0 inset-x-0
  px-6 py-4
  bg-gray-950/80 backdrop-blur-xl
  border-b border-white/5
  z-50
">
  <div class="max-w-7xl mx-auto flex items-center justify-between">
    <a href="/" class="text-xl font-bold text-white">Logo</a>

    <div class="flex items-center gap-8">
      <a href="#" class="text-gray-400 hover:text-white transition-colors">Features</a>
      <a href="#" class="text-gray-400 hover:text-white transition-colors">Pricing</a>
      <a href="#" class="text-gray-400 hover:text-white transition-colors">Docs</a>
    </div>

    <button class="
      px-4 py-2
      bg-brand-500 hover:bg-brand-400
      text-white text-sm font-medium
      rounded-lg
      transition-colors
    ">
      Sign In
    </button>
  </div>
</nav>
```

---

## Layout Patterns

### Hero Section

```html
<section class="relative min-h-screen flex items-center overflow-hidden">
  <!-- Background gradient -->
  <div class="absolute inset-0 bg-gray-950">
    <div class="absolute top-0 left-1/4 w-96 h-96 bg-brand-500/20 rounded-full blur-3xl"></div>
    <div class="absolute bottom-0 right-1/4 w-96 h-96 bg-purple-500/20 rounded-full blur-3xl"></div>
  </div>

  <!-- Grid pattern overlay -->
  <div class="absolute inset-0 bg-[linear-gradient(rgba(255,255,255,0.02)_1px,transparent_1px),linear-gradient(90deg,rgba(255,255,255,0.02)_1px,transparent_1px)] bg-[size:64px_64px]"></div>

  <div class="relative z-10 max-w-7xl mx-auto px-6 py-24 text-center">
    <h1 class="text-5xl md:text-7xl font-bold text-white tracking-tight">
      Build something
      <span class="text-transparent bg-clip-text bg-gradient-to-r from-brand-400 to-purple-400">
        remarkable
      </span>
    </h1>
    <p class="mt-6 text-xl text-gray-400 max-w-2xl mx-auto">
      Description text that explains the value proposition clearly and concisely.
    </p>
    <div class="mt-10 flex flex-col sm:flex-row gap-4 justify-center">
      <button class="px-8 py-4 bg-brand-500 hover:bg-brand-400 text-white font-medium rounded-lg transition-colors">
        Get Started Free
      </button>
      <button class="px-8 py-4 bg-white/5 hover:bg-white/10 text-white font-medium rounded-lg border border-white/10 transition-colors">
        View Demo
      </button>
    </div>
  </div>
</section>
```

### Bento Grid

```html
<div class="grid grid-cols-2 md:grid-cols-4 gap-4 p-4">
  <!-- Large feature -->
  <div class="col-span-2 row-span-2 p-8 bg-gray-900 rounded-3xl border border-gray-800">
    <h3 class="text-2xl font-bold text-white">Main Feature</h3>
  </div>

  <!-- Small cards -->
  <div class="p-6 bg-gray-900 rounded-2xl border border-gray-800">
    <h4 class="font-semibold text-white">Feature 1</h4>
  </div>
  <div class="p-6 bg-gray-900 rounded-2xl border border-gray-800">
    <h4 class="font-semibold text-white">Feature 2</h4>
  </div>

  <!-- Wide card -->
  <div class="col-span-2 p-6 bg-gray-900 rounded-2xl border border-gray-800">
    <h4 class="font-semibold text-white">Wide Feature</h4>
  </div>
</div>
```

---

## Animation Utilities

### Staggered Children

```html
<div class="space-y-4">
  <div class="animate-fade-in-up [animation-delay:0ms]">Item 1</div>
  <div class="animate-fade-in-up [animation-delay:100ms] opacity-0">Item 2</div>
  <div class="animate-fade-in-up [animation-delay:200ms] opacity-0">Item 3</div>
  <div class="animate-fade-in-up [animation-delay:300ms] opacity-0">Item 4</div>
</div>
```

### Hover Reveals

```html
<div class="group relative overflow-hidden rounded-xl">
  <img src="..." class="w-full transition-transform duration-500 group-hover:scale-110" />
  <div class="
    absolute inset-0
    bg-gradient-to-t from-black/80 to-transparent
    opacity-0 group-hover:opacity-100
    transition-opacity duration-300
    flex items-end p-6
  ">
    <h3 class="text-white font-bold translate-y-4 group-hover:translate-y-0 transition-transform duration-300">
      Title
    </h3>
  </div>
</div>
```

---

## Utility Classes to Add

```css
@layer utilities {
  /* Text gradient */
  .text-gradient {
    @apply text-transparent bg-clip-text bg-gradient-to-r from-brand-400 to-purple-400;
  }

  /* Glow effect */
  .glow {
    box-shadow: 0 0 20px theme('colors.brand.500 / 0.3');
  }

  .glow-lg {
    box-shadow: 0 0 40px theme('colors.brand.500 / 0.4');
  }

  /* Hide scrollbar */
  .scrollbar-hide {
    -ms-overflow-style: none;
    scrollbar-width: none;
  }
  .scrollbar-hide::-webkit-scrollbar {
    display: none;
  }

  /* Noise texture */
  .bg-noise {
    background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noise'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.8' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%' height='100%' filter='url(%23noise)'/%3E%3C/svg%3E");
  }
}
```
