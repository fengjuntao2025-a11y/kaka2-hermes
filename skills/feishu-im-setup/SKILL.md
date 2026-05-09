---
name: feishu-im-setup
description: Set up Feishu (飞书/Lark) IM as a messaging platform for Hermes Agent. Covers app creation, config, permissions, allowlist, and common pitfalls.
version: 1.0.0
---

# Feishu IM Setup for Hermes

Hermes supports Feishu (飞书) and Lark as gateway messaging platforms via WebSocket or Webhook transport.

## Prerequisites

Install the Feishu extras with pip (lark-oapi and qrcode packages).

## Setup Steps

### 1. Create a Feishu App
Go to https://open.feishu.cn/app and create a self-built app. Note the App ID and App Secret.

### 2. Configure Environment Variables
Edit the .env file in your Hermes home directory. Required variables:

- FEISHU_APP_ID — your app ID (cli_xxx format)
- FEISHU_APP_SECRET — your app secret

Optional variables:
- FEISHU_DOMAIN — feishu (China) or lark (international), default feishu
- FEISHU_CONNECTION_MODE — websocket (recommended) or webhook
- FEISHU_ENCRYPT_KEY — event encryption key
- FEISHU_VERIFICATION_TOKEN — verification token
- FEISHU_HOME_CHANNEL — default chat ID (oc_xxx format)
- FEISHU_HOME_CHANNEL_NAME — default channel name
- FEISHU_ALLOW_ALL_USERS — set to true to allow all users
- FEISHU_ALLOWED_USERS — comma-separated user IDs for allowlist

### 3. Grant Permissions (Critical!)

The app MUST have these permissions or messages will be silently dropped:

- im:chat:readonly (or im:chat / im:chat:read) — required to read chat info
- im:message — to send messages
- im:message.group_at_msg — to receive mentions in groups

Without im:chat:readonly, the logs will show "Access denied" errors.

After granting permissions, publish a new app version for changes to take effect.

### 4. Configure User Allowlist

By default, ALL unauthorized users are denied. You must either:
- Set FEISHU_ALLOW_ALL_USERS=true
- Or set FEISHU_ALLOWED_USERS to specific user IDs

### 5. Start Gateway

Run: hermes gateway run (foreground) or hermes gateway install + hermes gateway start (service).

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| Messages received but no reply + Access denied log | Missing im:chat permission | Grant in Feishu open platform |
| Unauthorized user in logs | No allowlist configured | Set FEISHU_ALLOW_ALL_USERS=true |
| Failed to send errors | Missing im:message permission | Grant send permission |
| Error 200340 when clicking "允许" (approve) | Missing im:message:send_as_bot | Grant send_as_bot permission |
| Bot hangs on terminal command approval | Can't send approval card back to user | Ensure im:message + im:message:send_as_bot are granted |
| Bot stuck after processing — no new replies | Gateway process crashed or stuck on approval | Check logs, kill/restart gateway |
| WebSocket disconnects | Network issues | Check connection mode or switch to webhook |
| Bot not receiving group messages | Missing group msg permission | Grant im:message.group_at_msg |

### Grant All Required Permissions at Once

After creating your Feishu app, go to "权限管理" (Permissions) and enable ALL of these before publishing:

- im:chat (or im:chat:readonly / im:chat:read)
- im:message
- im:message:send_as_bot
- im:message.group_at_msg (if using groups)
- im:message.p2p_msg (if using DMs)
- im:resource

Then go to "版本管理与发布" → "创建版本" → publish. Permissions only take effect after publishing a new version.

### Error 200340

This is a Feishu API error meaning the bot lacks permission to send interactive card messages. Hermes uses interactive cards for command approval prompts. Without im:message:send_as_bot, the approval flow breaks and the agent appears "stuck" — it's waiting for user approval but can't deliver the approval card.

### Verifying Setup

After starting the gateway, check the logs for a clean startup:
- ✓ feishu connected
- Gateway running with 1 platform(s)
- No "Access denied" or "Unauthorized user" warnings

Send a simple message like "hello" and confirm a reply. Then try a command that triggers approval (e.g. "create a folder") to verify the approval card works.

## Restarting / Migrating from openclaw-gateway

If migrating from the older `openclaw` system, the old gateway process may conflict:

1. Find the old process: `ps aux | grep openclaw-gateway`
2. Kill it: `kill <PID>` (use `kill -9` if needed)
3. Also kill any stale `timeout hermes gateway run` zombies from prior testing
4. Verify clean: `hermes gateway status` should show "not running"
5. Start: use `terminal(background=true)` to run `hermes gateway run` — do NOT use `nohup` (rejected by tool)
6. Confirm: `hermes gateway status` shows running, watch for `[Lark] connected to wss://...` in logs

For persistent service: `hermes gateway install` then `hermes gateway start`.

## Checking Logs

- Agent log: ~/.hermes/logs/agent.log (full gateway logs)
- Error log: ~/.hermes/logs/errors.log (errors only)

## Feishu Identity Model

- open_id (ou_xxx) — App-scoped, always available in events
- user_id (u_xxx) — Tenant-scoped, requires contact scope
- union_id (on_xxx) — Developer-scoped, best cross-app stable ID
