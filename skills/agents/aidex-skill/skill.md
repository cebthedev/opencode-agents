---
name: aidex-guide
description: Force AI to use AiDex MCP instead of grep/glob for code search
triggers:
  - search code
  - find definition
  - where is
  - what changed
---

## AiDex - Persistent Code Index (MCP Server)

AiDex provides fast, precise code search through a pre-built index.
**Always prefer AiDex over Grep/Glob for code searches.**

### REQUIRED: Before using Grep/Glob/Read for code searches
Do I want to search code?
├── .aidex/ exists → STOP! Use AiDex instead
├── .aidex/ missing → run aidex_init (don't ask), THEN use AiDex
└── Config/Logs/Text → Grep/Read is fine

Add to your AI's instructions (e.g., ~/.claude/CLAUDE.md for Claude Code, or the equivalent for your AI client). This tells the AI when and how to use AiDex instead of grepping:

## AiDex - Persistent Code Index (MCP Server)

AiDex provides fast, precise code search through a pre-built index.
**Always prefer AiDex over Grep/Glob for code searches.**

### REQUIRED: Before using Grep/Glob/Read for code searches
Do I want to search code? ├── .aidex/ exists → STOP! Use AiDex instead ├── .aidex/ missing → run aidex_init (don't ask), THEN use AiDex └── Config/Logs/Text → Grep/Read is fine


**NEVER do this when .aidex/ exists:**
- ❌ `Grep pattern="functionName"` → ✅ `aidex_query term="functionName"`
- ❌ `Grep pattern="class.*Name"` → ✅ `aidex_query term="Name" mode="contains"`
- ❌ `Read file.cs` to see methods → ✅ `aidex_signature file="file.cs"`
- ❌ `Glob pattern="**/*.cs"` + Read → ✅ `aidex_signatures pattern="**/*.cs"`

### Session-Start Rule (REQUIRED — every session, no exceptions)

1. Call `aidex_session({ path: "<project>" })` — detects external changes, auto-reindexes
2. If `.aidex/` does NOT exist → run `aidex_init` automatically (don't ask)
3. If a session note exists → **show it to the user** before continuing
4. **Before ending a session:** always leave a note about what to do next

### Question → Right Tool

| Question | Tool |
|----------|------|
| "Where is X defined?" | `aidex_query term="X"` |
| "Find anything containing X" | `aidex_query term="X" mode="contains"` |
| "All functions starting with X" | `aidex_query term="X" mode="starts_with"` |
| "What methods does file Y have?" | `aidex_signature file="Y"` |
| "Explore all files in src/" | `aidex_signatures pattern="src/**"` |
| "Project overview" | `aidex_summary` + `aidex_tree` |
| "What changed recently?" | `aidex_query term="X" modified_since="2h"` |
| "What files changed today?" | `aidex_files path="." modified_since="8h"` |
| "Have I ever written X?" | `aidex_global_query term="X" mode="contains"` |
| "Which project has class Y?" | `aidex_global_signatures term="Y" kind="class"` |
| "All indexed projects?" | `aidex_global_status` |

### Search Modes

- **`exact`** (default): Finds only the exact identifier — `log` won't match `catalog`
- **`contains`**: Finds identifiers containing the term — `render` matches `preRenderSetup`
- **`starts_with`**: Finds identifiers starting with the term — `Update` matches `UpdatePlayer`, `UpdateUI`

### All Tools (30)

| Category | Tools | Purpose |
|----------|-------|---------|
| Search & Index | `aidex_init`, `aidex_query`, `aidex_update`, `aidex_remove`, `aidex_status` | Index project, search identifiers (exact/contains/starts_with), time filter |
| Signatures | `aidex_signature`, `aidex_signatures` | Get classes + methods without reading files |
| Overview | `aidex_summary`, `aidex_tree`, `aidex_describe`, `aidex_files` | Entry points, file tree, file listing by type |
| Cross-Project | `aidex_link`, `aidex_unlink`, `aidex_links`, `aidex_scan` | Link dependencies, discover projects |
| Global Search | `aidex_global_init`, `aidex_global_query`, `aidex_global_signatures`, `aidex_global_status`, `aidex_global_refresh` | Search across ALL projects |
| Guidelines | `aidex_global_guideline` | Persistent AI instructions & conventions (key-value, global) |
| Sessions | `aidex_session`, `aidex_note` | Track sessions, leave notes (with searchable history) |
| Tasks | `aidex_task`, `aidex_tasks` | Built-in backlog with priorities, tags, summaries, auto-logged history, scheduled/recurring tasks |
| Log Hub | `aidex_log` | Universal log receiver — any program sends logs via HTTP, AI queries them, live in Viewer |
| Screenshots | `aidex_screenshot`, `aidex_windows` | Screen capture with LLM optimization (scale + color reduction, no index needed) |
| Viewer | `aidex_viewer` | Interactive browser UI with file tree, signatures, tasks, and live logs |

**11 languages:** C#, TypeScript, JavaScript, Rust, Python, C, C++, Java, Go, PHP, Ruby

### Session Notes

Leave notes for the next session — they persist in the database:
aidex_note({ path: ".", note: "Test the fix after restart" }) # Write aidex_note({ path: ".", note: "Also check edge cases", append: true }) # Append aidex_note({ path: "." }) # Read aidex_note({ path: ".", search: "parser" }) # Search history aidex_note({ path: ".", clear: true }) # Clear

- **Before ending a session:** automatically leave a note about next steps
- **User says "remember for next session: ..."** → write it immediately

### Task Backlog

Track TODOs, bugs, and features right next to your code index:
aidex_task({ path: ".", action: "create", title: "Fix bug", priority: 1, tags: "bug" }) aidex_task({ path: ".", action: "update", id: 1, status: "done" }) aidex_task({ path: ".", action: "log", id: 1, note: "Root cause found" }) aidex_tasks({ path: ".", status: "active" })

Scheduled & recurring tasks
aidex_task({ path: ".", action: "create", title: "Check PR status", due: "3d", interval: "3d", task_action: "gh pr list" })

Priority: 1=high, 2=medium, 3=low | Status: `backlog → active → done | cancelled`

### Global Search (across all projects)

aidex_global_init({ path: "/path/to/all/repos" }) # Scan & register aidex_global_init({ path: "...", index_unindexed: true }) # + auto-index small projects aidex_global_query({ term: "TransparentWindow", mode: "contains" }) # Search everywhere aidex_global_signatures({ term: "Render", kind: "method" }) # Find methods everywhere aidex_global_status({ sort: "recent" }) # List all projects


### Screenshots

aidex_screenshot() # Full screen aidex_screenshot({ mode: "active_window" }) # Active window aidex_screenshot({ mode: "window", window_title: "VS Code" }) # Specific window aidex_screenshot({ scale: 0.5, colors: 2 }) # B&W, half size (ideal for LLM) aidex_screenshot({ colors: 16 }) # 16 colors (UI readable) aidex_windows({ filter: "chrome" }) # Find window titles

No index needed. Returns file path → use `Read` to view immediately.

**LLM optimization strategy:** Always start with aggressive settings, then retry if unreadable:
1. First try: `scale: 0.5, colors: 2` (B&W, half size — smallest possible)
2. If unreadable: retry with `colors: 16` (adds shading for UI elements)
3. If still unclear: `scale: 0.75` or omit `colors` for full quality
4. **Remember** what works for each window/app during the session — don't retry every time.
4. Index your project
Ask your AI: "Index this project with AiDex"

Or manually in the AI chat:

aidex_init({ path: "/path/to/your/project" })
Available Tools
Tool	Description
aidex_init	Index a project (creates .aidex/)
aidex_query	Search by term (exact/contains/starts_with)
aidex_signature	Get one file's classes + methods
aidex_signatures	Get signatures for multiple files (glob)
aidex_update	Re-index a single changed file
aidex_remove	Remove a deleted file from index
aidex_summary	Project overview
aidex_tree	File tree with statistics
aidex_describe	Add documentation to summary
aidex_link	Link another indexed project
aidex_unlink	Remove linked project
aidex_links	List linked projects
aidex_status	Index statistics
aidex_scan	Find indexed projects in directory tree
aidex_files	List project files by type (code/config/doc/asset)
aidex_note	Read/write session notes (persists between sessions)
aidex_session	Start session, detect external changes, auto-reindex
aidex_viewer	Open interactive project tree in browser
aidex_task	Create, read, update, delete tasks with priority and tags
aidex_tasks	List and filter tasks by status, priority, or tag
aidex_screenshot	Take a screenshot (fullscreen, window, region) with optional scale + color reduction
aidex_windows	List open windows for screenshot targeting
aidex_global_init	Scan directory tree, register all indexed projects in global DB
aidex_global_status	List all registered projects with stats
aidex_global_query	Search terms across ALL registered projects
aidex_global_signatures	Search methods/types by name across all projects
aidex_global_refresh	Update stats and remove stale projects from global DB
aidex_global_guideline	Store/retrieve AI guidelines and coding conventions (key-value, global)
aidex_log	Universal log receiver — start HTTP server, query logs, live stream in Viewer
Time-based Filtering
Track what changed recently with modified_since and modified_before:

aidex_query({ term: "render", modified_since: "2h" })   # Last 2 hours
aidex_query({ term: "User", modified_since: "1d" })     # Last day
aidex_query({ term: "API", modified_since: "1w" })      # Last week
Supported formats:

Relative: 30m (minutes), 2h (hours), 1d (days), 1w (weeks)
ISO date: 2026-01-27 or 2026-01-27T14:30:00
Perfect for questions like "What did I change in the last hour?"

Project Structure
AiDex indexes ALL files in your project (not just code), letting you query the structure:

aidex_files({ path: ".", type: "config" })  # All config files
aidex_files({ path: ".", type: "test" })    # All test files
aidex_files({ path: ".", pattern: "**/*.md" })  # All markdown files
aidex_files({ path: ".", modified_since: "30m" })  # Changed this session
File types: code, config, doc, asset, test, other, dir

Use modified_since to find files changed in this session - perfect for "What did I edit?"

Session Notes
Leave reminders for the next session - no more losing context between chats:

aidex_note({ path: ".", note: "Test the glob fix after restart" })  # Write
aidex_note({ path: ".", note: "Also check edge cases", append: true })  # Append
aidex_note({ path: "." })                                              # Read
aidex_note({ path: ".", clear: true })                                 # Clear
Note History (v1.10): Old notes are automatically archived when overwritten or cleared. Browse and search past notes:

aidex_note({ path: ".", history: true })                    # Browse archived notes (shows summaries)
aidex_note({ path: ".", search: "parser" })                 # Search note history (searches summaries too)
aidex_note({ path: ".", history: true, limit: 5 })          # Last 5 archived notes
Note Summaries (v1.15): Provide a summary when writing/clearing a note — the archived note gets this one-sentence description. History then shows summaries instead of truncated text:

aidex_note({ path: ".", note: "New focus", summary: "Previous session: finished parser refactoring" })
Use cases:

Before ending a session: "Remember to test X next time"
AI auto-reminder: Save what to verify after a restart
Handover notes: Context for the next session without editing config files
Search past sessions: "What did we do about the parser?"
Notes are stored in the SQLite database (.aidex/index.db) and persist indefinitely.

Task Backlog
Keep your project tasks right next to your code index - no Jira, no Trello, no context switching:

aidex_task({ path: ".", action: "create", title: "Fix parser bug", priority: 1, tags: "bug", summary: "Parser crashes on nested generics in C#" })
aidex_task({ path: ".", action: "update", id: 1, status: "done" })
aidex_task({ path: ".", action: "log", id: 1, note: "Root cause: unbounded buffer" })
aidex_tasks({ path: ".", status: "active" })
Scheduled & Recurring Tasks
Tasks can have due dates and repeat intervals. Overdue tasks are reported at every session start across ALL projects:

# One-shot: remind in 3 days
aidex_task({ path: ".", action: "create", title: "Review PR", due: "3d", task_action: "Check if PR was submitted" })

# Recurring: check every week
aidex_task({ path: ".", action: "create", title: "Check dependencies", due: "1w", interval: "1w", task_action: "npm outdated" })

# Auto-execute: runs the action automatically when due
aidex_task({ path: ".", action: "create", title: "Refresh stats", due: "1d", interval: "1d", auto_go: true })
Due formats: Relative ("30m", "2h", "3d", "1w") or ISO date ("2026-04-10")

At every aidex_session call, the Task Scheduler checks ~/.aidex/global.db for due tasks across all projects — even if you're working on a different project. Recurring tasks automatically advance their due date after each trigger.

Features:

Summaries: One-sentence table-of-contents per task — scan the backlog without reading full details
Priorities: 🔴 high, 🟡 medium, ⚪ low
Statuses: backlog → active → done | cancelled
Tags: Categorize tasks (bug, feature, docs, etc.)
History log: Every status change is auto-logged, plus manual notes
Scheduling: Due dates, recurring intervals, actions, auto-execute across all projects
Viewer integration: Tasks tab in the browser viewer with live updates
Persistent: Tasks survive between sessions, stored in .aidex/index.db
Your AI assistant can create tasks while working ("found a bug in the parser, add it to the backlog"), track progress, and pick up where you left off next session.

Global Search
Search across ALL your indexed projects at once. Perfect for "Have I ever written a transparent window?" or "Where did I use that algorithm?"

Setup
aidex_global_init({ path: "Q:/develop" })                              # Scan & register
aidex_global_init({ path: "Q:/develop", exclude: ["llama.cpp"] })      # Skip external repos
aidex_global_init({ path: "Q:/develop", index_unindexed: true })       # Auto-index all found projects
aidex_global_init({ path: "Q:/develop", index_unindexed: true, show_progress: true })  # With browser progress UI
This scans your project directory, registers all AiDex-indexed projects in a global database (~/.aidex/global.db), and reports any unindexed projects it finds by detecting project markers (.csproj, package.json, Cargo.toml, etc.).

With index_unindexed: true, it also auto-indexes all discovered projects with ≤500 code files. Larger projects are listed separately for user decision. Add show_progress: true to open a live progress UI in your browser (http://localhost:3334).

Search
aidex_global_query({ term: "TransparentWindow" })                      # Exact match
aidex_global_query({ term: "transparent", mode: "contains" })          # Fuzzy search
aidex_global_signatures({ term: "Render", kind: "method" })            # Find methods
aidex_global_signatures({ term: "Player", kind: "class" })             # Find classes
How it works
Uses SQLite ATTACH DATABASE to query project databases directly — no data copying
Results are cached in memory (5-minute TTL) for fast repeated queries
Projects are batched (8 at a time) to respect SQLite's attachment limit
Each project keeps its own .aidex/index.db as the single source of truth
Auto-deduplication: Parent projects that contain sub-projects are automatically skipped (e.g., MyApp/ is removed when MyApp/Frontend/ and MyApp/Backend/ exist as separate indexed projects)
Management
aidex_global_status()                                                  # List all projects
aidex_global_status({ sort: "recent" })                                # Most recently indexed first
aidex_global_refresh()                                                 # Update stats, remove stale
AI Guidelines
Store persistent coding conventions, review checklists, and AI instructions in a single place — shared across all projects.

aidex_global_guideline({ action: "set", key: "review", value: "Always check: error handling, null safety, no hardcoded strings" })
aidex_global_guideline({ action: "set", key: "style", value: "Use PascalCase for classes, camelCase for methods, 4-space indent" })
aidex_global_guideline({ action: "get", key: "review" })               # Retrieve a guideline
aidex_global_guideline({ action: "list" })                             # Show all guidelines
aidex_global_guideline({ action: "list", filter: "code" })             # Filter by name
aidex_global_guideline({ action: "delete", key: "old-rule" })          # Remove a guideline
Use cases:

Code review checklist: Tell your AI exactly what to look for every time
Coding conventions: Store team style rules once, reference them in any project
Release checklist: Step-by-step process for shipping
Project-agnostic instructions: No more pasting the same context into every session
Guidelines are stored in ~/.aidex/global.db — available across all your projects without aidex_init. Ask your AI: "Load the review guideline and apply it to this file."


