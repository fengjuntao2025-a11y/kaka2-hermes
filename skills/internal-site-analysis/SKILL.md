---
name: internal-site-analysis
category: devops
description: Analyze internal web applications when browser proxy blocks direct access
---

# Analyzing Internal Web Applications

When browser tools fail due to proxy configuration, use curl with noproxy option to fetch and analyze the site.

## Approach

1. **Fetch main HTML page** to identify JS bundle paths

2. **Analyze app structure** via manifest files (app-manifest.json often exists for micro-frontends)

3. **Extract navigation/routes** from layout components (BasicLayout, Sidebar, Menu)

4. **Check API endpoints** in main bundle by searching for /api/ patterns

5. **Verify other routes** work with HEAD requests

## Common Findings for React SPAs

- app-manifest.json reveals micro-frontend modules
- BasicLayout/Sidebar components contain menu structure
- Route definitions show available pages
- Look for auth guards, error boundaries, loading states

## Proxy Environment Variables

Check with: env | grep -i proxy

Common blocking variables:
- ALL_PROXY
- http_proxy / https_proxy
- HTTP_PROXY / HTTPS_PROXY

Browser tools inherit proxy from shell environment. Use noproxy flag with curl to bypass.
