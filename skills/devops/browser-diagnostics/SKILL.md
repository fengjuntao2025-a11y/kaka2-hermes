---
name: browser-diagnostics
description: Run comprehensive browser diagnostics to check WebRTC support, API connectivity, storage capabilities, media devices, and permissions. Useful for debugging real-time communication apps, authentication flows, and PWA requirements.
version: 1.0.0
dependencies: [browser_console]
---

# Browser Diagnostics Skill

Run diagnostic tests in a browser environment to check capabilities and connectivity.

## When to Use

- Debugging "Invalid API Key" or auth flow failures
- Checking if a browser supports WebRTC for VoIP/video
- Verifying API endpoint reachability from the browser
- Checking media device availability
- Diagnosing permission states

## Quick Diagnostic Script

Use `browser_console` to run this JavaScript on any page:

```javascript
(async () => {
  const r = {};

  // 1. Browser capabilities
  r.browser = {
    webrtc: !!window.RTCPeerConnection,
    websocket: !!window.WebSocket,
    secureContext: window.isSecureContext,
    protocol: window.location.protocol,
    getUserMedia: !!(navigator.mediaDevices?.getUserMedia)
  };

  // 2. API endpoint checks (replace with your endpoints)
  r.api = {};
  for (const url of ['https://api.example.com/health', 'https://auth.example.com/']) {
    try {
      const res = await fetch(url, { signal: AbortSignal.timeout(5000) });
      r.api[url] = { ok: res.ok, status: res.status };
    } catch(e) {
      r.api[url] = { error: e.message };
    }
  }

  // 3. Storage
  r.storage = {
    localStorage: !!window.localStorage,
    indexedDB: !!window.indexedDB,
    cookies: navigator.cookieEnabled
  };

  // 4. Media devices
  try {
    const devs = await navigator.mediaDevices?.enumerateDevices?.();
    r.media = {
      audioIn: devs?.filter(d => d.kind === 'audioinput').length || 0,
      videoIn: devs?.filter(d => d.kind === 'videoinput').length || 0
    };
  } catch(e) { r.media = { error: e.message }; }

  // 5. Permissions
  r.permissions = {};
  for (const p of ['microphone', 'camera', 'notifications']) {
    try {
      r.permissions[p] = (await navigator.permissions.query({name: p})).state;
    } catch(e) { r.permissions[p] = 'query-failed'; }
  }

  return JSON.stringify(r, null, 2);
})()
```

## Server-Side Connectivity Check

When browser tests show API unreachable, verify from server:

```bash
# DNS resolution
dig +short api.example.com

# HTTP connectivity with timeout
curl -sS -o /dev/null -w '%{http_code} %{time_total}s' --connect-timeout 5 --max-time 10 https://api.example.com/health

# Check if proxy is interfering
curl -s --noproxy '*' http://internal-ip/
```

## Common Findings & Fixes

| Finding | Likely Cause | Fix |
|---------|-------------|-----|
| API timeout from browser | CORS, firewall, or server down | Check server-side with curl |
| API timeout from server | DNS or CDN issue | Verify DNS, check CDN status |
| No DNS record | Domain not configured | Set up DNS records |
| getUserMedia fails | HTTPS required or permission denied | Ensure secure context |
| No media devices | Headless environment or no hardware | Expected in server env |

## Interpreting Results

- `signal timed out` = Server unreachable (network/firewall/CDN issue)
- `Failed to fetch` = CORS or DNS resolution failure
- `query-failed` for permissions = API not available in this context
- `prompt` state = Permission not yet requested (normal)
