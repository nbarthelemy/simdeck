# Schema.org JSON-LD Patterns

> Complete templates for common Schema.org types. Copy and customize.

## Organization

```json
{
  "@context": "https://schema.org",
  "@type": "Organization",
  "@id": "https://example.com/#organization",
  "name": "Company Name",
  "url": "https://example.com",
  "logo": {
    "@type": "ImageObject",
    "url": "https://example.com/logo.png",
    "width": 600,
    "height": 60
  },
  "description": "Brief company description.",
  "foundingDate": "2020-01-01",
  "sameAs": [
    "https://twitter.com/company",
    "https://linkedin.com/company/company",
    "https://github.com/company"
  ],
  "contactPoint": {
    "@type": "ContactPoint",
    "telephone": "+1-555-555-5555",
    "contactType": "customer support",
    "availableLanguage": ["English"]
  }
}
```

**Required**: `name`, `url`
**Recommended**: `logo`, `sameAs`, `description`
**Validation**: Logo should be 112x112px minimum, rectangular preferred

## WebSite

```json
{
  "@context": "https://schema.org",
  "@type": "WebSite",
  "@id": "https://example.com/#website",
  "url": "https://example.com",
  "name": "Site Name",
  "description": "Site description for search engines.",
  "publisher": {
    "@id": "https://example.com/#organization"
  },
  "potentialAction": {
    "@type": "SearchAction",
    "target": {
      "@type": "EntryPoint",
      "urlTemplate": "https://example.com/search?q={search_term_string}"
    },
    "query-input": "required name=search_term_string"
  }
}
```

**Required**: `url`, `name`
**Recommended**: `potentialAction` (enables sitelinks search box)
**Note**: SearchAction only works if your site has internal search

## WebPage

```json
{
  "@context": "https://schema.org",
  "@type": "WebPage",
  "@id": "https://example.com/page#webpage",
  "url": "https://example.com/page",
  "name": "Page Title",
  "description": "Page meta description.",
  "isPartOf": {
    "@id": "https://example.com/#website"
  },
  "datePublished": "2025-01-15",
  "dateModified": "2025-03-20",
  "breadcrumb": {
    "@id": "https://example.com/page#breadcrumb"
  },
  "inLanguage": "en-US"
}
```

**Required**: `url`, `name`
**Recommended**: `datePublished`, `dateModified`, `breadcrumb`

## Article / BlogPosting

```json
{
  "@context": "https://schema.org",
  "@type": "Article",
  "headline": "Article Title (Max 110 Characters Recommended)",
  "description": "Brief article summary for search results.",
  "image": [
    "https://example.com/article-hero-1200x630.jpg",
    "https://example.com/article-hero-4x3.jpg",
    "https://example.com/article-hero-16x9.jpg"
  ],
  "datePublished": "2025-01-15T08:00:00+00:00",
  "dateModified": "2025-03-20T10:30:00+00:00",
  "author": {
    "@type": "Person",
    "name": "Author Name",
    "url": "https://example.com/about/author",
    "jobTitle": "Senior Engineer",
    "sameAs": [
      "https://twitter.com/author",
      "https://linkedin.com/in/author"
    ]
  },
  "publisher": {
    "@id": "https://example.com/#organization"
  },
  "mainEntityOfPage": {
    "@type": "WebPage",
    "@id": "https://example.com/blog/article-slug"
  },
  "wordCount": 2500,
  "articleSection": "Technology",
  "keywords": ["keyword1", "keyword2", "keyword3"]
}
```

**Required**: `headline`, `image`, `datePublished`, `author`
**Recommended**: `dateModified`, `publisher`, `wordCount`
**Note**: Use `BlogPosting` for blog posts, `NewsArticle` for news, `TechArticle` for technical docs
**Tip**: Include multiple image aspect ratios (1:1, 4:3, 16:9) for different SERP placements

## Product

```json
{
  "@context": "https://schema.org",
  "@type": "Product",
  "name": "Product Name",
  "description": "Product description with key features.",
  "image": "https://example.com/product-image.jpg",
  "brand": {
    "@type": "Brand",
    "name": "Brand Name"
  },
  "sku": "SKU12345",
  "gtin13": "1234567890123",
  "offers": {
    "@type": "Offer",
    "url": "https://example.com/product",
    "priceCurrency": "USD",
    "price": "49.99",
    "priceValidUntil": "2025-12-31",
    "availability": "https://schema.org/InStock",
    "seller": {
      "@id": "https://example.com/#organization"
    }
  },
  "aggregateRating": {
    "@type": "AggregateRating",
    "ratingValue": "4.5",
    "reviewCount": "127",
    "bestRating": "5",
    "worstRating": "1"
  },
  "review": [
    {
      "@type": "Review",
      "author": {
        "@type": "Person",
        "name": "Reviewer Name"
      },
      "datePublished": "2025-01-10",
      "reviewRating": {
        "@type": "Rating",
        "ratingValue": "5",
        "bestRating": "5"
      },
      "reviewBody": "Review text content."
    }
  ]
}
```

**Required**: `name`, `offers` (with price, currency, availability)
**Recommended**: `aggregateRating`, `review`, `brand`, `image`, `sku`
**Note**: `availability` must use Schema.org enumeration URLs

## FAQPage

```json
{
  "@context": "https://schema.org",
  "@type": "FAQPage",
  "mainEntity": [
    {
      "@type": "Question",
      "name": "What is the return policy?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "You can return any item within 30 days of purchase for a full refund. Items must be in original condition with tags attached."
      }
    },
    {
      "@type": "Question",
      "name": "How long does shipping take?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Standard shipping takes 5-7 business days. Express shipping (2-3 days) is available for an additional fee."
      }
    },
    {
      "@type": "Question",
      "name": "Do you offer international shipping?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Yes, we ship to over 50 countries. International shipping typically takes 10-15 business days."
      }
    }
  ]
}
```

**Required**: `mainEntity` with at least one Question/Answer pair
**Note**: Questions must match visible FAQ content on the page
**GEO Tip**: FAQ schema is heavily cited by AI answer engines - invest in comprehensive Q&A

## HowTo

```json
{
  "@context": "https://schema.org",
  "@type": "HowTo",
  "name": "How to Set Up a Development Environment",
  "description": "Step-by-step guide to setting up a local development environment for this project.",
  "totalTime": "PT30M",
  "estimatedCost": {
    "@type": "MonetaryAmount",
    "currency": "USD",
    "value": "0"
  },
  "tool": [
    {
      "@type": "HowToTool",
      "name": "Node.js 18+"
    },
    {
      "@type": "HowToTool",
      "name": "Git"
    }
  ],
  "supply": [
    {
      "@type": "HowToSupply",
      "name": "GitHub account"
    }
  ],
  "step": [
    {
      "@type": "HowToStep",
      "name": "Clone the repository",
      "text": "Run git clone https://github.com/org/repo.git to clone the repository to your local machine.",
      "url": "https://example.com/docs/setup#clone",
      "image": "https://example.com/docs/step1.png"
    },
    {
      "@type": "HowToStep",
      "name": "Install dependencies",
      "text": "Navigate to the project directory and run npm install to install all required dependencies.",
      "url": "https://example.com/docs/setup#install"
    },
    {
      "@type": "HowToStep",
      "name": "Start the development server",
      "text": "Run npm run dev to start the local development server on port 3000.",
      "url": "https://example.com/docs/setup#start"
    }
  ]
}
```

**Required**: `name`, `step` (with `text` for each step)
**Recommended**: `totalTime`, `tool`, `image` per step
**Note**: `totalTime` uses ISO 8601 duration format (PT30M = 30 minutes)

## BreadcrumbList

```json
{
  "@context": "https://schema.org",
  "@type": "BreadcrumbList",
  "@id": "https://example.com/category/item#breadcrumb",
  "itemListElement": [
    {
      "@type": "ListItem",
      "position": 1,
      "name": "Home",
      "item": "https://example.com/"
    },
    {
      "@type": "ListItem",
      "position": 2,
      "name": "Category",
      "item": "https://example.com/category"
    },
    {
      "@type": "ListItem",
      "position": 3,
      "name": "Item Name"
    }
  ]
}
```

**Required**: `itemListElement` with `position` and `name`
**Note**: Last item should NOT have `item` (it's the current page)
**Validation**: Position numbers must be sequential starting from 1

## LocalBusiness

```json
{
  "@context": "https://schema.org",
  "@type": "LocalBusiness",
  "name": "Business Name",
  "description": "Business description.",
  "image": "https://example.com/storefront.jpg",
  "url": "https://example.com",
  "telephone": "+1-555-555-5555",
  "email": "contact@example.com",
  "address": {
    "@type": "PostalAddress",
    "streetAddress": "123 Main Street",
    "addressLocality": "City",
    "addressRegion": "CA",
    "postalCode": "90001",
    "addressCountry": "US"
  },
  "geo": {
    "@type": "GeoCoordinates",
    "latitude": "34.0522",
    "longitude": "-118.2437"
  },
  "openingHoursSpecification": [
    {
      "@type": "OpeningHoursSpecification",
      "dayOfWeek": ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"],
      "opens": "09:00",
      "closes": "17:00"
    },
    {
      "@type": "OpeningHoursSpecification",
      "dayOfWeek": ["Saturday"],
      "opens": "10:00",
      "closes": "14:00"
    }
  ],
  "priceRange": "$$",
  "sameAs": [
    "https://www.facebook.com/business",
    "https://www.yelp.com/biz/business"
  ]
}
```

**Required**: `name`, `address`
**Recommended**: `geo`, `openingHoursSpecification`, `telephone`, `image`
**Note**: Use specific subtypes when possible (Restaurant, Dentist, etc.)

## Person

```json
{
  "@context": "https://schema.org",
  "@type": "Person",
  "name": "Person Name",
  "url": "https://example.com/about",
  "image": "https://example.com/headshot.jpg",
  "jobTitle": "Software Engineer",
  "worksFor": {
    "@type": "Organization",
    "name": "Company Name",
    "url": "https://company.com"
  },
  "alumniOf": {
    "@type": "CollegeOrUniversity",
    "name": "University Name"
  },
  "knowsAbout": ["JavaScript", "System Design", "Cloud Architecture"],
  "sameAs": [
    "https://twitter.com/person",
    "https://linkedin.com/in/person",
    "https://github.com/person"
  ]
}
```

**Required**: `name`
**Recommended**: `jobTitle`, `sameAs`, `image`
**GEO Tip**: `sameAs` links help AI engines disambiguate people

## Event

```json
{
  "@context": "https://schema.org",
  "@type": "Event",
  "name": "Event Name",
  "description": "Event description.",
  "startDate": "2025-06-15T09:00:00-07:00",
  "endDate": "2025-06-15T17:00:00-07:00",
  "eventStatus": "https://schema.org/EventScheduled",
  "eventAttendanceMode": "https://schema.org/OfflineEventAttendanceMode",
  "location": {
    "@type": "Place",
    "name": "Venue Name",
    "address": {
      "@type": "PostalAddress",
      "streetAddress": "123 Event Blvd",
      "addressLocality": "City",
      "addressRegion": "CA",
      "postalCode": "90001",
      "addressCountry": "US"
    }
  },
  "image": "https://example.com/event-banner.jpg",
  "performer": {
    "@type": "Person",
    "name": "Speaker Name"
  },
  "organizer": {
    "@id": "https://example.com/#organization"
  },
  "offers": {
    "@type": "Offer",
    "url": "https://example.com/event/tickets",
    "price": "50.00",
    "priceCurrency": "USD",
    "availability": "https://schema.org/InStock",
    "validFrom": "2025-01-01T00:00:00-07:00"
  }
}
```

**Required**: `name`, `startDate`, `location` (or `VirtualLocation` for online)
**Recommended**: `offers`, `performer`, `image`, `eventStatus`
**Note**: For virtual events, use `eventAttendanceMode: OnlineEventAttendanceMode` and `VirtualLocation`

## VideoObject

```json
{
  "@context": "https://schema.org",
  "@type": "VideoObject",
  "name": "Video Title",
  "description": "Video description.",
  "thumbnailUrl": "https://example.com/video-thumbnail.jpg",
  "uploadDate": "2025-01-15T08:00:00+00:00",
  "duration": "PT5M30S",
  "contentUrl": "https://example.com/video.mp4",
  "embedUrl": "https://www.youtube.com/embed/VIDEO_ID",
  "interactionStatistic": {
    "@type": "InteractionCounter",
    "interactionType": "https://schema.org/WatchAction",
    "userInteractionCount": "15000"
  },
  "publisher": {
    "@id": "https://example.com/#organization"
  }
}
```

**Required**: `name`, `thumbnailUrl`, `uploadDate`
**Recommended**: `contentUrl` or `embedUrl`, `duration`, `description`
**Note**: `duration` uses ISO 8601 format (PT5M30S = 5 minutes, 30 seconds)

## Combined Graph Pattern

For pages with multiple schema types, use `@graph`:

```json
{
  "@context": "https://schema.org",
  "@graph": [
    {
      "@type": "Organization",
      "@id": "https://example.com/#organization",
      "name": "Company Name",
      "url": "https://example.com",
      "logo": "https://example.com/logo.png"
    },
    {
      "@type": "WebSite",
      "@id": "https://example.com/#website",
      "url": "https://example.com",
      "name": "Site Name",
      "publisher": { "@id": "https://example.com/#organization" }
    },
    {
      "@type": "WebPage",
      "@id": "https://example.com/page#webpage",
      "url": "https://example.com/page",
      "name": "Page Title",
      "isPartOf": { "@id": "https://example.com/#website" },
      "breadcrumb": { "@id": "https://example.com/page#breadcrumb" }
    },
    {
      "@type": "BreadcrumbList",
      "@id": "https://example.com/page#breadcrumb",
      "itemListElement": [
        { "@type": "ListItem", "position": 1, "name": "Home", "item": "https://example.com/" },
        { "@type": "ListItem", "position": 2, "name": "Page Title" }
      ]
    }
  ]
}
```

**Benefits**: Establishes entity relationships, reduces duplication, builds knowledge graph
**Rule**: Use `@id` references to connect entities instead of nesting
