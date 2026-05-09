---
name: d3-force-layout-switching
description: Fix D3.js force-directed graph layout switching where animation and force simulation fight for node positions
triggers:
  - D3 force simulation
  - layout switch buttons
  - force-directed graph animation
  - nodes not moving on button click
---

When creating interactive D3.js force-directed graphs with layout switching buttons (grid, radial, grouped, spread), the force simulation and JS animations will fight for control of node positions — causing buttons to appear broken.

## Root Cause
`d3.forceSimulation` runs on a timer and overwrites `node.x / node.y` every tick (~60fps). If you try to animate node positions (e.g., with `requestAnimationFrame`) while the simulation is running, the force overwrites your animation values instantly.

## Correct Pattern

```js
function animateTo(targets, duration, onDone) {
  sim.stop();                    // ← 1. STOP simulation first
  nodes.forEach(n => {
    n.fx = n.x;                  // ← 2. Lock ALL nodes
    n.fy = n.y;
  });

  const t0 = performance.now();
  const origins = targets.map(t => ({ ox: t.node.x, oy: t.node.y }));

  (function frame() {
    const p = Math.min(1, (performance.now() - t0) / duration);
    const ease = p < 0.5 ? 2*p*p : 1 - Math.pow(-2*p+2, 2) / 2;
    targets.forEach((t, i) => {
      t.node.x = origins[i].ox + (t.tx - origins[i].ox) * ease;
      t.node.y = origins[i].oy + (t.ty - origins[i].oy) * ease;
      t.node.fx = t.node.x;      // ← Keep locked during animation
      t.node.fy = t.node.y;
    });
    render();
    if (p < 1) requestAnimationFrame(frame);
    else {
      nodes.forEach(n => { n.fx = null; n.fy = null; }); // ← 3. Unlock
      if (onDone) onDone();       // ← 4. Restart sim in callback
    }
  })();
}

// Usage
animateTo(gridTargets(), 700, () => {
  sim.force('charge', d3.forceManyBody().strength(-2000))
    .alpha(0.6).restart();
});
```

## Key Rules
1. **Always `sim.stop()` before animating**
2. **Lock ALL nodes** with `fx/fy` during animation, not just moved ones
3. **Unlock ALL nodes** (`fx=null, fy=null`) after animation completes
4. **Restart sim only in the animation callback**
5. **Drag handler**: `sim.stop()` on dragstart, `sim.alpha(0.15).restart()` on dragend

## Common Mistakes
- ❌ Calling `sim.restart()` right after `animateTo()` — animation hasn't finished
- ❌ Only locking target nodes — other nodes still get pushed by force
- ❌ Using `d3.transition()` on node positions while sim is running
- ❌ Forgetting to call `render()` manually inside animation loop

## Force Params for Good Spread
- Charge: `-2000` to `-3000` for wide spread
- `distanceMax: 900` limits repulsion range
- Collision: `radius + 40px`, strength `0.9`
- `velocityDecay: 0.6` for stable settling
- `alphaDecay: 0.01` for slow cooling
