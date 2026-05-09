---
name: spa-reverse-engineering
description: Reverse-engineer Single Page Application (SPA) frontends by analyzing bundled JS/CSS assets to extract routes, features, and architecture. Useful for documenting internal tools.
category: software-development
confirm: true
---

# SPA Reverse Engineering

Use when the user asks to analyze, reverse-engineer, or document the architecture of a web application — especially internal SPAs where crawling URLs doesn't work.

## Step 1: Fetch the HTML shell

```bash
curl -s http://TARGET_URL/
```

Extract `<script src="...">` and `<link href="...">` asset paths.

**If you get 502 or connection errors:** check for proxy interference:
```bash
curl -sv http://TARGET_URL/ 2>&1 | head -15
# If it shows "Uses proxy env variable http_proxy" routing through localhost, bypass it:
curl -s --noproxy '*' http://TARGET_URL/
```

## Step 2: Analyze JS bundles

SPA bundles contain string literals that reveal the full feature set:

```bash
# Feature chunk names (reveals module structure)
curl -s ASSET_URL | grep -oP 'assets/[^"]+\.(js|css)' | sort -u

# Route definitions
curl -s ASSET_URL | grep -oE 'path:"[^"]*"' | sort -u

# UI labels and page titles (reveals all features/pages)
curl -s ASSET_URL | grep -oE '(label|title|name):"[^"]*"' | sort -u

# API endpoint patterns
curl -s ASSET_URL | grep -oE '"/api/[^"]*"' | sort -u

# Keyword frequency across feature chunks
curl -s CHUNK_URL | grep -oiE '(keyword1|keyword2|keyword3)' | sort | uniq -c | sort -rn
```

## Step 3: Analyze CSS for design system

```bash
# CSS custom properties (design tokens)
curl -s CSS_URL | grep -oE '\-\-[a-z-]+:[^;]+' | head -30

# UI component patterns from class names
curl -s CSS_URL | grep -oE '\.[a-z]+-[a-z0-9-]+' | sort -u | head -30
```

## Step 4: Fetch each feature chunk

From step 2, you get chunk names like `ModuleName-xxx.js`. Fetch each individually to understand that module's routes, labels, and capabilities.

## Output Template

Generate a Markdown architecture document with:

1. **System overview** — what the app does, its positioning
2. **Tech stack** — framework, UI library, build tool (from bundle format)
3. **Feature module map** — hierarchical view from route + label analysis
4. **Route table** — all discovered paths and their targets
5. **Backend architecture (inferred)** — based on API patterns, clearly label as推测/inferred
6. **Design system** — CSS variables, color scheme, component patterns
7. **Assessment** — strengths, concerns, technical debt signals

## Pitfalls

- **Never present inferred backend info as fact** — always label推测sections clearly.
- **Minified JS = string literals only** — don't try to parse the AST; grep for quoted strings.
- **Lazy-loaded chunks may be missing** from the main bundle — check for preload hints in HTML.
- **WAF/CDN may block curl** — add a User-Agent header or use the browser tool.
- **Proxy environments** — always check `curl -sv` output first if requests fail unexpectedly.
