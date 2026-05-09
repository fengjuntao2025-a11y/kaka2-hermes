---
name: c4-architecture-docs
description: Generate a complete set of C4 model architecture documentation as standalone HTML files
---

# C4 Architecture Documentation Generator

Generate a professional multi-view architecture documentation set using C4 model + UML conventions.

## When to Use
When the user needs architecture documentation for a system — especially enterprise/technical platforms.

## Output Structure (Categorized, 15 Views)

User preference: **categorized directories with bilingual names** (English + Chinese), sub-views numbered locally within each category. Do NOT use flat v01-v10 numbering.

```
project-arch/
├── README.md
├── 01-structure-结构视图/               # 📐 C4 Structure
│   ├── 01-system-context-系统上下文/     # C4 Level 1
│   ├── 02-container-容器架构/           # C4 Level 2
│   ├── 03-component-组件架构/           # C4 Level 3
│   └── 04-layered-经典分层/            # Classic layered view
├── 02-behavior-行为视图/               # 🔄 UML Behavior
│   ├── 01-use-case-用例图/             # Role × function matrix
│   ├── 02-sequence-交互序列/           # Sequence diagram
│   ├── 03-activity-活动图/             # Activity/workflow diagram
│   └── 04-state-machine-状态机/         # State lifecycle
├── 03-data-数据视图/                   # 💾 Data
│   ├── 01-domain-model-领域模型/        # ER/class diagram
│   └── 02-data-flow-数据流/            # Pipeline + lineage
├── 04-ops-运维视图/                    # 🚀 Operations
│   ├── 01-deployment-部署架构/          # UML deployment
│   ├── 02-tech-stack-技术栈/           # Technology choices
│   ├── 03-security-安全架构/           # 4-layer defense
│   └── 04-observability-可观测性/       # Monitoring + logging + tracing
└── 05-meta-元视图/                    # 📋 Meta
    └── 01-overview-架构总览/            # Index + ADR + metrics
```

Each sub-directory contains `index.html` (self-contained SVG diagram).

## Implementation Approach: Python SVG Generator

For 15+ views, hand-writing HTML is inefficient. Use a **shared Python helper module** + per-category generation scripts.

### Step 1: Create shared helper (`/tmp/arch_helpers.py`)

```python
"""Shared SVG/HTML generation utilities"""
import os
BASE = os.path.expanduser("~/文档/架构/PROJECT_NAME")

COLORS = {
    "L5": "#22d3ee", "L4": "#34d399", "L3": "#a78bfa",
    "L2": "#3b82f6", "L1": "#fbbf24",
    "role": "#f472b6", "ext": "#94a3b8", "danger": "#ef4444",
    "bg": "#0f172a", "card": "#1e293b",
    "text": "#f1f5f9", "gray": "#94a3b8", "dim": "#64748b",
}

def arrow(x1,y1,x2,y2,color=None,dashed=False,width=1.5): ...
def rect(x,y,w,h,color,opacity=0.08,stroke=1.2,rx=8): ...
def text(x,y,content,color=None,size=9,weight="400",anchor="start"): ...
def html_page(title, subtitle, svg_content, legend_items=None): ...
def save(path, content): ...
```

### Step 2: Generate per category

```python
# gen_01_structure.py — generates 01-structure-结构视图/*/index.html
# gen_02_behavior.py — generates 02-behavior-行为视图/*/index.html
# gen_03_rest.py     — generates data + ops + meta views
```

Run: `python3 gen_01_structure.py && python3 gen_02_behavior.py && python3 gen_03_rest.py`

### Why Python over hand-written SVG

- Consistent color palette, arrow styles, font sizes across all views
- Reusable primitives (rect, text, arrow, html_page)
- Easy to regenerate all views when design changes
- Parallel generation (each script independent)

## Implementation Rules

### HTML Format
- Each file is self-contained (no external dependencies except system fonts)
- Inline CSS + SVG diagrams
- Dark theme: background `#0f172a`, cards `#1e293b`
- Color-coded layers with consistent palette (see COLORS above)
- Each SVG has: layer boundaries, module boxes, connection lines with arrows, protocol labels, legend panel

### SVG Diagram Principles
- Use `<svg viewBox>` for responsive scaling
- Use `<defs>` with `<marker>` for arrowheads
- Use `<line>` with `marker-end="url(#a)"` for arrows
- Dashed lines: `stroke-dasharray="5,3"` for async/optional flows
- Group background fills with `rx` rounded rects for layer boundaries
- Include port numbers on deployment diagrams
- Label every connection with protocol + data content
- Add a text-based legend at the bottom
- Minimum font size: 7px for labels, 8px for descriptions

### Content Requirements per View
- System Context: 5 user roles + 5+ external systems + interaction descriptions + protocol labels
- Container: All services with tech stack, databases with port numbers, data flow legend
- Component: 10+ internal components with data flow arrows + flow description panel
- Use Case: Role × function matrix grouped by layer, with detailed descriptions
- Sequence: 10+ steps with participant headers, lifelines, timing annotations
- Activity: Decision diamonds, parallel branches (RAG/SQL/Tool paths), loops
- State Machine: 5+ states, sub-states, retry logic, terminal states
- Domain Model: 10+ entities with PK/FK, storage location (MySQL vs NebulaGraph)
- Data Flow: 5 stages + data lineage + performance baselines
- Deployment: K8s nodes → pods with port numbers, resource limits, HPA config
- Tech Stack: Per-layer technology cards with versions
- Security: 4 layers (Network → Gateway → Application → Data) × 6 controls each
- Observability: 3 pillars (Metrics/Logging/Tracing) + AI-specific monitoring
- Overview: Mini thumbnail + 15-view index + core metrics + ADR table

## Common Pitfalls
- Don't use D3.js force simulation — it conflicts with position control. Use pure SVG + CSS transitions.
- Don't make too-small text — minimum 7px for labels
- Don't forget arrow markers on connection lines
- Don't cluster all modules in one area — spread them with clear spacing
- Always include port numbers in deployment diagrams
- Directory names must include BOTH English AND Chinese: `01-system-context-系统上下文/`
- Sub-view numbering is LOCAL to each category, not global
