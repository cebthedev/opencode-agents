#!/usr/bin/env python3
"""Add tags to skill SKILL.md files for improved discoverability."""

import os
import yaml
import re
from pathlib import Path

SKILLS_DIR = Path("/Users/chevass/Projects/opencode-agents/lazy-skills")

# Tags mapping for the most important skills
TAGS_MAP = {
    # Research / Arxiv
    "arxiv-database": ["arxiv", "papers", "research", "NLP", "ML", "AI", "literature-review", "preprints"],
    "arxiv-to-md": ["arxiv", "papers", "markdown", "conversion", "research", "reading"],
    "bgpt-paper-search": ["papers", "search", "research", "academic", "google-scholar"],
    "paper-2-web": ["papers", "web", "conversion", "research", "sharing"],
    "perplexity-search": ["search", "web", "research", "AI", "answers"],
    "openalex-database": ["papers", "citations", "research", "academic", "bibliometrics"],
    "literature-review": ["research", "papers", "review", "writing", "academic"],
    "peer-review": ["research", "review", "papers", "feedback", "academic"],
    "research-lookup": ["research", "lookup", "facts", "verification"],
    "research-grants": ["research", "funding", "grants", "academic", "proposal"],
    "scholar-evaluation": ["research", "evaluation", "metrics", "academic"],
    "scientific-writing": ["writing", "research", "papers", "academic", "communication"],
    "scientific-brainstorming": ["ideas", "creativity", "research", "innovation"],
    "scientific-critical-thinking": ["analysis", "critical-thinking", "research", "evaluation"],
    "deep-research": ["research", "deep-dive", "analysis", "comprehensive"],
    "tessl__deep-research": ["research", "deep-dive", "analysis", "comprehensive"],
    "denario": ["research", "multi-agent", "automation", "publication", "workflow"],
    "hypothesis-generation": ["research", "hypothesis", "ideas", "science"],
    "hypogenic": ["research", "hypothesis", "data-analysis", "testing"],
    
    # ML / DL / Foundation Models
    "scikit-learn": ["ML", "machine-learning", "classification", "regression", "clustering", "preprocessing"],
    "pytorch-lightning": ["deep-learning", "PyTorch", "neural-networks", "training", "ML"],
    "transformers": ["HuggingFace", "LLM", "NLP", "BERT", "GPT", "foundation-models", "transformers"],
    "torch-geometric": ["GNN", "graph-neural-networks", "deep-learning", "PyTorch", "graphs"],
    "stable-baselines3": ["RL", "reinforcement-learning", "policy", "agent", "OpenAI-Gym"],
    "shap": ["XAI", "explainability", "interpretability", "model-explanation", "ML"],
    "timesfm-forecasting": ["time-series", "forecasting", "temporal", "Google", "deep-learning"],
    "aeon": ["time-series", "ML", "classification", "forecasting", "clustering"],
    "pymc": ["probabilistic-programming", "Bayesian", "statistics", "inference"],
    "umap-learn": ["dimensionality-reduction", "visualization", "clustering", "ML"],
    "pufferlib": ["RL", "environments", "parallel", "training"],
    "qiskit": ["quantum", "computing", "IBM", "algorithms"],
    
    # Data Engineering
    "dask": ["big-data", "parallel", "distributed", "DataFrame", "scaling"],
    "polars": ["DataFrame", "fast", "Rust", "data-processing", "analytics"],
    "vaex": ["DataFrame", "big-data", "out-of-core", "visualization"],
    "zarr-python": ["arrays", "storage", "compression", "chunked", "N-dimensional"],
    "geopandas": ["GIS", "geospatial", "maps", "spatial-data"],
    "datacommons-client": ["data", "API", "statistics", "Google-Data-Commons"],
    
    # Backend / DevOps
    "modal": ["serverless", "cloud", "compute", "GPU", "deployment", "infrastructure"],
    "networkx": ["graphs", "network-analysis", "algorithms", "data-structures"],
    "sympy": ["symbolic-math", "algebra", "calculus", "mathematics"],
    "simpy": ["simulation", "discrete-event", "modeling", "processes"],
    
    # Visualization
    "matplotlib": ["plotting", "visualization", "charts", "graphs", "Python"],
    "seaborn": ["visualization", "statistics", "plots", "aesthetic", "matplotlib"],
    "plotly": ["interactive", "visualization", "dashboards", "web", "charts"],
    "infographics": ["visualization", "design", "graphics", "communication"],
    "scientific-visualization": ["visualization", "research", "plots", "scientific"],
    "scientific-schematics": ["diagrams", "schematics", "research", "visualization"],
    "scientific-slides": ["presentation", "slides", "research", "communication"],
    
    # Code / Dev
    "codebase-analysis": ["code-review", "architecture", "analysis", "repository"],
    "refactor": ["refactoring", "clean-code", "technical-debt", "improvement"],
    "implement": ["coding", "implementation", "feature", "development"],
    "problem-analysis": ["debugging", "analysis", "problem-solving", "root-cause"],
    "prompt-engineer": ["prompts", "LLM", "optimization", "engineering"],
    "architecture-decision-records": ["ADR", "architecture", "documentation", "decisions"],
    "incoherence": ["validation", "consistency", "specs", "quality"],
    "completeness": ["validation", "traceability", "requirements", "quality"],
    "guidelines": ["standards", "best-practices", "guidelines", "domain-specific"],
    
    # OpenSpec
    "openspec-explore": ["planning", "requirements", "exploration", "workflow"],
    "openspec-new-change": ["planning", "change", "specification", "workflow"],
    "openspec-apply-change": ["implementation", "coding", "workflow", "change"],
    "openspec-verify-change": ["validation", "testing", "workflow", "quality"],
    "openspec-continue-change": ["resume", "workflow", "change", "continuation"],
    "openspec-archive-change": ["archive", "history", "workflow", "change"],
    "openspec-bulk-archive-change": ["archive", "bulk", "workflow", "history"],
    "openspec-ff-change": ["fast-forward", "workflow", "change"],
    "openspec-onboard": ["onboarding", "setup", "workflow", "new-project"],
    "openspec-sync-specs": ["sync", "specifications", "workflow", "consistency"],
    
    # General utilities
    "cc-history": ["history", "Claude-Code", "conversation", "analysis"],
    "doc-sync": ["documentation", "sync", "maintenance"],
    "docx": ["Word", "documents", "generation", "Office"],
    "xlsx": ["Excel", "spreadsheets", "data", "Office"],
    "pptx": ["PowerPoint", "presentation", "slides", "Office"],
    "pdf": ["PDF", "documents", "reading", "extraction"],
    "pdf-to-markdown": ["PDF", "conversion", "markdown", "extraction"],
    "markdown-mermaid-writing": ["markdown", "diagrams", "mermaid", "documentation"],
    "drawio-diagrams-enhanced": ["diagrams", "drawio", "visualization", "architecture"],
    "latex-posters": ["LaTeX", "posters", "academic", "research"],
    "venue-templates": ["templates", "venues", "research", "submissions"],
    "generate-image": ["images", "generation", "AI", "visualization"],
    "humanizer": ["writing", "AI-detection", "natural", "style"],
    "consciousness-council": ["deliberation", "decisions", "perspectives", "council"],
    "constitution": ["principles", "guidelines", "project", "rules"],
    "planner": ["planning", "organization", "tasks"],
    "planning": ["planning", "strategy", "organization"],
    "tasks": ["tasks", "management", "organization"],
    "templates": ["templates", "boilerplate", "starting-point"],
    "specification": ["specs", "requirements", "documentation"],
    "rewrite": ["writing", "editing", "improvement"],
    "what-if-oracle": ["scenarios", "analysis", "forecasting", "what-if"],
    "get-available-resources": ["resources", "tools", "discovery"],
    "parallel-web": ["web", "parallel", "scraping", "requests"],
    "markitdown": ["markdown", "conversion", "documents"],
    "citation-management": ["citations", "references", "bibliography", "research"],
    "exploratory-data-analysis": ["EDA", "data-analysis", "statistics", "visualization"],
    "statistical-analysis": ["statistics", "analysis", "hypothesis-testing", "data"],
    "statsmodels": ["statistics", "regression", "time-series", "econometrics"],
    "alpha-vantage": ["finance", "stocks", "API", "market-data"],
    "hedgefundmonitor": ["finance", "hedge-funds", "monitoring", "data"],
    "fred-economic-data": ["economics", "data", "FRED", "Federal-Reserve"],
    "usfiscaldata": ["fiscal", "government", "data", "economics"],
    "market-research-reports": ["market-research", "reports", "business", "analysis"],
    "open-notebook": ["notebook", "research", "AI", "documents", "privacy"],
    "pyzotero": ["Zotero", "references", "bibliography", "research"],
    
    # Agents sub-skills (lazy-loaded versions that are NOT in global)
    "aidex-skill": ["code-search", "indexing", "repository", "navigation"],
}


def add_tags_to_skill(skill_name: str, tags: list[str]) -> bool:
    """Add tags field to a skill's SKILL.md frontmatter."""
    skill_dir = SKILLS_DIR / skill_name
    if not skill_dir.exists():
        print(f"  SKIP: {skill_name} directory not found")
        return False
    
    skill_md = skill_dir / "SKILL.md"
    if not skill_md.exists():
        print(f"  SKIP: {skill_name}/SKILL.md not found")
        return False
    
    content = skill_md.read_text()
    
    # Check if already has tags
    if "tags:" in content.split("---")[1] if "---" in content else "":
        print(f"  SKIP: {skill_name} already has tags")
        return False
    
    # Find the first --- boundary and add tags after description
    lines = content.split("\n")
    
    # Find frontmatter boundaries
    try:
        first_boundary = lines.index("---")
        second_boundary = lines.index("---", first_boundary + 1)
    except ValueError:
        print(f"  SKIP: {skill_name} has invalid frontmatter")
        return False
    
    # Insert tags before the closing ---
    # Find the best insertion point (after description or license line)
    insert_idx = second_boundary
    for i in range(second_boundary - 1, first_boundary, -1):
        if lines[i].strip() and not lines[i].startswith("#"):
            insert_idx = i + 1
            break
    
    tags_yaml = f"tags: [{', '.join(tags)}]"
    lines.insert(insert_idx, tags_yaml)
    
    skill_md.write_text("\n".join(lines))
    print(f"  OK: {skill_name} -> {tags_yaml}")
    return True


def main():
    print("Adding tags to skills for discoverability...")
    print(f"Skills directory: {SKILLS_DIR}")
    print()
    
    success = 0
    skipped = 0
    
    for skill_name, tags in TAGS_MAP.items():
        result = add_tags_to_skill(skill_name, tags)
        if result:
            success += 1
        else:
            skipped += 1
    
    print()
    print(f"Done: {success} tagged, {skipped} skipped")
    print(f"Total skills processed: {len(TAGS_MAP)}")


if __name__ == "__main__":
    main()
