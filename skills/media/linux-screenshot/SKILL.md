---
name: linux-screenshot
description: Take screenshots on Linux (X11) from the terminal. Use when the user asks to capture the screen, take a screenshot, or see the desktop.
---

# Linux Screenshot (X11)

## Quick Capture

```bash
ffmpeg -y -f x11grab -video_size 1920x1080 -i $DISPLAY -frames:v 1 screenshot.png
```

## Key Pitfalls

1. **PIL ImageGrab hangs/timeout on X11** — do not use `from PIL import ImageGrab`.
2. **`xwd -root`** outputs XWD format that PIL cannot read — avoid this path unless you convert with ImageMagick (`convert screen.xwd screen.png`).
3. **DISPLAY variable matters** — always use `$DISPLAY` or detect it:
   ```bash
   echo $DISPLAY  # typically :1 or :0
   ```
   If running from a non-interactive session, grab it from a running process:
   ```bash
   DISPLAY=$(cat /proc/$(pgrep -u $USER gnome-shell | head -1)/environ | tr '\0' '\n' | grep DISPLAY | cut -d= -f2)
   ```
4. **Resolution** — detect screen size with `xdpyinfo | grep dimensions` or hardcode `1920x1080`.

## Analyze After Capture

Use `vision_analyze` tool to describe what's on screen:
```python
vision_analyze(image_url="/path/to/screenshot.png", question="Describe what's on screen")
```

## Send via Messaging

`send_message` supports text but **not image files** on most platforms (Feishu, Telegram, etc.). To send a screenshot:
- Describe it with `vision_analyze` and send the text summary
- Or upload via platform-specific API (not available through generic send_message)
