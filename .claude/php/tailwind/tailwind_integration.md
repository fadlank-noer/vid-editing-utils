# Tailwind CSS v4 — Integration with FlightPHP + Latte + Bazel Docker

## Overview

Guide for integrating Tailwind CSS v4 into a FlightPHP + Latte project built with Bazel and deployed via Docker. This setup uses a multi-stage Docker build to compile CSS without adding Node.js to the final image.

## Architecture

```
client/
├── package.json              # Tailwind v4 + @tailwindcss/cli
├── src/
│   ├── assets/css/
│   │   ├── input.css         # Tailwind source (@import "tailwindcss", @theme, @source)
│   │   └── style.css         # Generated output (served by PHP)
│   └── index.php             # Must handle static file passthrough
```

## Key Setup Steps

### 1. package.json

```json
{
  "private": true,
  "scripts": {
    "dev": "npx @tailwindcss/cli -i src/assets/css/input.css -o src/assets/css/style.css --watch",
    "build": "npx @tailwindcss/cli -i src/assets/css/input.css -o src/assets/css/style.css"
  },
  "devDependencies": {
    "@tailwindcss/cli": "^4",
    "tailwindcss": "^4"
  }
}
```

No `tailwind.config.js` needed — Tailwind v4 uses CSS-first configuration.

### 2. input.css (Tailwind Source)

```css
@import "tailwindcss";

@source "../../app/views/**/*.latte";

@theme {
  --color-primary: #3b82f6;
  --color-primary-dark: #2563eb;
}
```

- `@source` tells Tailwind where to scan for utility class usage (`.latte` files)
- `@theme` defines custom design tokens (generates `bg-primary`, `text-primary`, etc.)

### 3. Dockerfile (Multi-Stage Build)

```dockerfile
# Stage 1: Build CSS with Node.js
FROM node:22-alpine AS css-builder
WORKDIR /build
COPY package.json package-lock.json ./
RUN npm ci
COPY src/assets/css/input.css src/assets/css/input.css
COPY src/app/views/ src/app/views/
RUN npx @tailwindcss/cli -i src/assets/css/input.css -o src/assets/css/style.css

# Stage 2: PHP application
FROM php:8.5.6-zts-alpine3.22
WORKDIR /app
# ... composer install ...
COPY src/ src/
COPY --from=css-builder /build/src/assets/css/style.css src/assets/css/style.css
CMD ["php", "-S", "0.0.0.0:8080", "-t", "src", "src/index.php"]
```

The `css-builder` stage copies the views so Tailwind can scan `.latte` files for class usage during build.

### 4. Static File Serving (Critical)

PHP built-in server with a router script intercepts ALL requests, including static files. Without handling this, CSS files return `200 text/html` instead of `text/css`.

**Fix in `index.php`:**

```php
<?php
if (php_sapi_name() === 'cli-server') {
    $path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
    $file = __DIR__ . $path;
    if (is_file($file)) {
        return false; // Let PHP serve the static file directly
    }
}
// ... rest of FlightPHP bootstrap
```

- `return false` tells PHP's built-in server to serve the file as-is
- Must be at the top of the router script, before any framework bootstrapping

### 5. `-t src` Flag (Document Root)

```
CMD ["php", "-S", "0.0.0.0:8080", "-t", "src", "src/index.php"]
```

Without `-t src`, the document root is `/app/`. A request for `/assets/css/style.css` looks for `/app/assets/css/style.css` (wrong path — file is at `/app/src/assets/css/style.css`). Adding `-t src` sets document root to `/app/src/`.

### 6. .gitignore

```
/node_modules/
/vendor/
```

`node_modules` is gitignored. The built `style.css` is NOT committed — it's generated inside the Docker build.

## Dev Workflow

1. `npm run dev` — watches `.latte` files and `input.css`, rebuilds `style.css` on change
2. `bazel run //client:reload` — rebuilds Docker image (runs Tailwind build inside)
3. CSS-only changes don't need container restart (PHP reads from disk), but the CSS must be built inside the container via the Dockerfile

## Common Pitfalls

| Problem | Cause | Fix |
|---|---|---|
| CSS returns `text/html` | Router script intercepts static files | Add `return false` check in index.php |
| CSS 404 from browser | Document root mismatch | Add `-t src` to PHP server CMD |
| Custom colors not generating | Missing `@theme` block in input.css | Add `--color-*` vars in `@theme` |
| Classes missing from output | Tailwind not scanning `.latte` files | Add `@source "../../app/views/**/*.latte"` |
| CSS not updating after template change | Docker cache | Rebuild container (`bazel run //client:reload`) |

## Tailwind v4 vs v3 Differences

- No `tailwind.config.js` — config is CSS-first via `@theme` and `@source` in CSS
- Source file uses `@import "tailwindcss"` instead of `@tailwind` directives
- Custom colors: `@theme { --color-primary: #3b82f6; }` generates `bg-primary`, `text-primary`, etc.
- CLI package is `@tailwindcss/cli` (separate from `tailwindcss`)
