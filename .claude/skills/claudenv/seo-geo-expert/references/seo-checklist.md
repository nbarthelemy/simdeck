# SEO Technical Checklist

> Priority-based checklist for comprehensive SEO audits. Work top-down.

## P0: Critical (Fix Immediately)

### Title Tag
- **Check**: Every page has a unique `<title>`
- **Pattern**: `Primary Keyword - Secondary | Brand` (50-60 chars)
- **Mistake**: Missing title, duplicate titles, too long (truncated in SERP)
- **Validate**: `document.title.length` should be 30-60 chars

### Meta Description
- **Check**: Every page has a unique `<meta name="description">`
- **Pattern**: Compelling summary with primary keyword (150-160 chars)
- **Mistake**: Missing, duplicated across pages, over 160 chars
- **Validate**: Check for presence and length

### Canonical URL
- **Check**: Every page has `<link rel="canonical">`
- **Pattern**: Self-referencing canonical pointing to the preferred URL
- **Mistake**: Missing canonical (duplicate content risk), pointing to wrong page
- **Validate**: Canonical URL matches the page URL (or intended canonical)

### Viewport Meta
- **Check**: `<meta name="viewport" content="width=device-width, initial-scale=1.0">`
- **Pattern**: Present on every page, no `maximum-scale=1` (accessibility issue)
- **Mistake**: Missing entirely (mobile indexing failure)
- **Validate**: Present in `<head>`

### Single H1
- **Check**: Exactly one `<h1>` per page
- **Pattern**: Contains primary keyword, describes page content
- **Mistake**: Zero H1s, multiple H1s, H1 used for logo/branding only
- **Validate**: `document.querySelectorAll('h1').length === 1`

### Image Alt Text
- **Check**: Every content image has descriptive `alt` attribute
- **Pattern**: Describe the image content and purpose (5-15 words)
- **Mistake**: Empty alt on content images, "image1.jpg" as alt, keyword-stuffed alt
- **Validate**: `document.querySelectorAll('img:not([alt])').length === 0`

### sitemap.xml
- **Check**: Valid sitemap exists and is accessible
- **Pattern**: Lists all indexable pages with accurate `<lastmod>` dates
- **Mistake**: Missing sitemap, includes noindex pages, stale dates
- **Validate**: Fetch `/sitemap.xml`, check HTTP 200, valid XML

### robots.txt
- **Check**: Valid robots.txt exists at domain root
- **Pattern**: Allows important content, blocks admin/private, references sitemap
- **Mistake**: Blocking CSS/JS files, blocking entire site, missing Sitemap directive
- **Validate**: Fetch `/robots.txt`, check HTTP 200

## P1: Important (Fix Soon)

### Open Graph Tags
- **Check**: `og:title`, `og:description`, `og:image`, `og:url`, `og:type`
- **Pattern**: Compelling content optimized for social sharing
- **Mistake**: Missing og:image (poor social previews), image wrong dimensions
- **Validate**: All 5 properties present; og:image is 1200x630px

### Twitter Card Tags
- **Check**: `twitter:card`, `twitter:title`, `twitter:description`, `twitter:image`
- **Pattern**: `summary_large_image` card type for articles/pages
- **Mistake**: Missing entirely, using `summary` when `summary_large_image` is better
- **Validate**: All 4 properties present

### Structured Data (JSON-LD)
- **Check**: Appropriate Schema.org types for page content
- **Pattern**: JSON-LD in `<script type="application/ld+json">`
- **Mistake**: Wrong type for content, missing required fields, data doesn't match page
- **Validate**: Google Rich Results Test passes, no errors

### Heading Hierarchy
- **Check**: Headings follow sequential order (H1 > H2 > H3)
- **Pattern**: No skipped levels, headings describe content structure
- **Mistake**: H1 > H3 (skipped H2), headings used for styling
- **Validate**: Check sequential nesting with DOM traversal

### Internal Linking
- **Check**: Important pages linked from other pages with descriptive anchor text
- **Pattern**: Contextual links with keyword-rich anchor text
- **Mistake**: "Click here" links, orphan pages, broken internal links
- **Validate**: Check for orphan pages (pages with no incoming links)

### HTTPS
- **Check**: Site served over HTTPS, HTTP redirects to HTTPS
- **Pattern**: All resources (images, scripts, styles) loaded over HTTPS
- **Mistake**: Mixed content warnings, HTTP links to own pages
- **Validate**: No mixed content warnings in browser console

### Mobile Responsiveness
- **Check**: Content renders correctly on mobile devices
- **Pattern**: Touch targets 48px+, readable text without zoom, no horizontal scroll
- **Mistake**: Fixed-width layouts, tiny text, overlapping elements
- **Validate**: Chrome DevTools mobile emulation

## P2: Optimization (Improve When Possible)

### hreflang Tags
- **Check**: Multi-language sites have correct hreflang annotations
- **Pattern**: Reciprocal hreflang tags with x-default fallback
- **Mistake**: Non-reciprocal links, wrong language codes, missing x-default
- **Validate**: Each hreflang target page links back

### Resource Hints
- **Check**: Critical resources preloaded/preconnected
- **Pattern**:
  ```html
  <link rel="preload" as="image" href="/hero.webp">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="dns-prefetch" href="https://cdn.example.com">
  ```
- **Mistake**: Preloading non-critical resources, missing crossorigin on fonts
- **Validate**: Check Network waterfall in DevTools

### Font Optimization
- **Check**: Web fonts loaded efficiently
- **Pattern**: `font-display: swap`, subset fonts, preload critical fonts
- **Mistake**: FOIT (Flash of Invisible Text), loading entire font families
- **Validate**: No layout shift from font loading

### Image Formats
- **Check**: Using modern image formats (WebP, AVIF) with fallbacks
- **Pattern**:
  ```html
  <picture>
    <source srcset="image.avif" type="image/avif">
    <source srcset="image.webp" type="image/webp">
    <img src="image.jpg" alt="Description" width="800" height="600">
  </picture>
  ```
- **Mistake**: Serving only JPEG/PNG, no width/height (CLS), oversized images
- **Validate**: Check image sizes and formats in Network tab

### Lazy Loading
- **Check**: Below-fold images and iframes use lazy loading
- **Pattern**: `loading="lazy"` on images/iframes below the fold
- **Mistake**: Lazy loading above-fold content (delays LCP), lazy loading all images
- **Validate**: First image (LCP candidate) NOT lazy loaded

### URL Structure
- **Check**: Clean, descriptive, keyword-containing URLs
- **Pattern**: `/category/descriptive-slug` (lowercase, hyphens, no params)
- **Mistake**: `/page?id=123`, `/p/abc123`, unnecessary depth
- **Validate**: URLs are human-readable and contain relevant keywords

## P3: Advanced (Edge Cases)

### Pagination
- **Check**: Paginated content uses proper `rel="next"` / `rel="prev"` (deprecated but still used) OR single canonical to view-all page
- **Pattern**: Each page self-canonicalizes, content accessible to crawlers
- **Mistake**: Noindexing paginated pages, canonicalizing all to page 1
- **Validate**: Each paginated page is indexable

### Breadcrumb Schema
- **Check**: Breadcrumb navigation has BreadcrumbList structured data
- **Pattern**:
  ```json
  {
    "@type": "BreadcrumbList",
    "itemListElement": [
      { "@type": "ListItem", "position": 1, "name": "Home", "item": "https://example.com/" },
      { "@type": "ListItem", "position": 2, "name": "Category", "item": "https://example.com/category" }
    ]
  }
  ```
- **Mistake**: Missing position numbers, inconsistent with visible breadcrumbs
- **Validate**: Rich Results Test shows breadcrumb trail

### Video Schema
- **Check**: Pages with video content have VideoObject structured data
- **Pattern**: Include name, description, thumbnailUrl, uploadDate, duration, contentUrl
- **Mistake**: Missing thumbnailUrl (no video rich result), wrong duration format
- **Validate**: Rich Results Test shows video result

### Event Schema
- **Check**: Event pages have Event structured data
- **Pattern**: Include name, startDate, location (Place or VirtualLocation), offers
- **Mistake**: Past events still indexed, missing location type
- **Validate**: Rich Results Test shows event result

### Core Web Vitals
- **Check**: LCP < 2.5s, INP < 200ms, CLS < 0.1
- **Pattern**: Preload LCP element, minimize JS, set dimensions on media
- **Mistake**: Large unoptimized hero images, layout shifts from dynamic content
- **Validate**: PageSpeed Insights, Chrome UX Report, Web Vitals extension

### Crawl Budget
- **Check**: Important pages are crawled efficiently
- **Pattern**: Flat architecture, internal links to important pages, no infinite crawl traps
- **Mistake**: Deep page hierarchies, faceted navigation creating infinite URLs
- **Validate**: Check crawl stats in Google Search Console
