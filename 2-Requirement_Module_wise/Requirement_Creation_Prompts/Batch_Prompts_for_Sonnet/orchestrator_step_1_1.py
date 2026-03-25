#!/usr/bin/env python3
"""
orchestrator_step_1_1.py
========================
Prime-AI Pipeline — Batched SRS Generator (Step 1.1)

Runs the SRS generation prompt once per batch using claude-sonnet-4-6,
then merges all batch outputs into a single srs.md.

Usage:
    python orchestrator_step_1_1.py                     # Run all batches
    python orchestrator_step_1_1.py --batch 3           # Run only batch 3
    python orchestrator_step_1_1.py --merge-only        # Skip generation, just merge
    python orchestrator_step_1_1.py --validate-only     # Validate existing outputs
    python orchestrator_step_1_1.py --status            # Show completion status

Requirements:
    pip install anthropic pyyaml rich
"""

import argparse
import json
import os
import re
import sys
import time
from datetime import datetime
from pathlib import Path

import anthropic
import yaml

try:
    from rich.console import Console
    from rich.panel import Panel
    from rich.progress import Progress, SpinnerColumn, TextColumn, TimeElapsedColumn
    from rich.table import Table
    RICH_AVAILABLE = True
except ImportError:
    RICH_AVAILABLE = False

# ─────────────────────────────────────────────
# CONFIGURATION
# ─────────────────────────────────────────────

PIPELINE_ROOT   = Path(__file__).parent
CONFIG_FILE     = PIPELINE_ROOT / "config" / "pipeline.config.yaml"
BATCH_CONFIG    = PIPELINE_ROOT / "config" / "step-1.1-batch-config.yaml"
PROMPT_TEMPLATE = PIPELINE_ROOT / "phases" / "phase-1_requirements-architecture" / "step-1.1_srs" / "prompt.md"
OUTPUT_DIR      = PIPELINE_ROOT / "phases" / "phase-1_requirements-architecture" / "step-1.1_srs" / "output"
STATE_FILE      = OUTPUT_DIR / ".batch-state.json"

MODEL           = "claude-sonnet-4-6"
MAX_TOKENS      = 16000   # Sonnet comfortably produces 10k–14k tokens per batch; 16k gives headroom
RETRY_LIMIT     = 2
RETRY_DELAY_SEC = 10

console = Console() if RICH_AVAILABLE else None

def log(msg, style=""):
    if RICH_AVAILABLE:
        console.print(msg, style=style)
    else:
        print(msg)


# ─────────────────────────────────────────────
# LOAD CONFIG
# ─────────────────────────────────────────────

def load_config():
    with open(CONFIG_FILE) as f:
        base = yaml.safe_load(f)
    with open(BATCH_CONFIG) as f:
        batch = yaml.safe_load(f)
    return base, batch["steps"]["1.1"]


def load_rbs(config: dict, step_cfg: dict) -> str:
    """Load the full RBS file. Returns raw text."""
    rbs_path_template = step_cfg["inputs"]["rbs_file"]
    inputs_dir = config["paths"]["inputs_dir"]
    rbs_path = Path(rbs_path_template.replace("{{config.paths.inputs_dir}}", inputs_dir))

    if not rbs_path.exists():
        log(f"[red]ERROR: RBS file not found at {rbs_path}[/red]")
        log(f"[yellow]Please place your RBS file at: {rbs_path}[/yellow]")
        sys.exit(1)

    return rbs_path.read_text(encoding="utf-8")


# ─────────────────────────────────────────────
# RBS EXTRACTION PER BATCH
# ─────────────────────────────────────────────

def extract_rbs_for_batch(full_rbs: str, batch_cfg: dict) -> str:
    """
    Extract the RBS sections relevant to this batch's modules.

    Strategy: search for each module name/code in the RBS and extract
    surrounding context. Falls back to returning the full RBS with a
    filter instruction if sections can't be isolated.
    """
    module_codes = [m["code"] for m in batch_cfg["modules"]]
    module_names = [m["name"] for m in batch_cfg["modules"]]

    extracted_sections = []

    lines = full_rbs.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i]
        # Check if this line is a heading that matches any module in this batch
        is_match = any(
            (code in line or name in line)
            for code, name in zip(module_codes, module_names)
        )
        if is_match:
            # Capture from this heading until the next top-level heading
            section_lines = [line]
            j = i + 1
            while j < len(lines):
                next_line = lines[j]
                # Stop at next top-level heading (same or higher level)
                if next_line.startswith("# ") and not next_line.startswith("## "):
                    break
                section_lines.append(next_line)
                j += 1
            extracted_sections.append("\n".join(section_lines))
            i = j
        else:
            i += 1

    if extracted_sections:
        return "\n\n---\n\n".join(extracted_sections)

    # Fallback: return full RBS with instruction to filter
    module_list = ", ".join(module_names)
    return (
        f"<!-- FILTER INSTRUCTION: Process ONLY these modules from the RBS below: {module_list} -->\n\n"
        + full_rbs
    )


# ─────────────────────────────────────────────
# PROMPT RESOLUTION
# ─────────────────────────────────────────────

def resolve_prompt(template: str, config: dict, step_cfg: dict, batch_cfg: dict, rbs_extract: str) -> str:
    """Replace all {{placeholders}} in the prompt template."""

    module_names_str = ", ".join(m["name"] for m in batch_cfg["modules"])

    # Determine next batch description
    all_batches = step_cfg["batches"]
    batch_keys  = list(all_batches.keys())
    current_key = f"batch-{batch_cfg['number']}"
    current_idx = batch_keys.index(current_key)
    if current_idx + 1 < len(batch_keys):
        next_batch  = all_batches[batch_keys[current_idx + 1]]
        next_desc   = f"Batch {next_batch['number']} — {next_batch['label']}"
    else:
        next_desc = "All batches complete — run merge step"

    roles_str = ", ".join(config.get("roles", []))
    volumes   = step_cfg.get("volumes", {})

    replacements = {
        # Batch metadata
        "{{batch.number}}":           str(batch_cfg["number"]),
        "{{batch.total}}":            str(len(all_batches)),
        "{{batch.module_names}}":     module_names_str,
        "{{batch.next_description}}": next_desc,
        "{{input:batch:rbs_extract}}": rbs_extract,

        # Project / config
        "{{config.project.name}}":        config.get("project", {}).get("name", "Prime-AI"),
        "{{config.project.description}}": config.get("project", {}).get("description", ""),
        "{{config.roles}}":               roles_str,
        "{{config.database.tenant_id_column}}": config.get("database", {}).get("tenant_id_column", "tenant_id"),
        "{{config.conventions.api_prefix}}":    config.get("conventions", {}).get("api_prefix", "api/v1"),

        # Volume assumptions
        "{{config.volumes.tenants_launch}}":        str(volumes.get("tenants_launch", 50)),
        "{{config.volumes.tenants_scale}}":         str(volumes.get("tenants_scale", 2000)),
        "{{config.volumes.students_per_tenant}}":   str(volumes.get("students_per_tenant", "500–5000")),
        "{{config.volumes.staff_per_tenant}}":      str(volumes.get("staff_per_tenant", "50–500")),
        "{{config.volumes.concurrent_users_peak}}": str(volumes.get("concurrent_users_peak", 200)),
    }

    # Replace module-level placeholders (uses first module as context for template header)
    first_module = batch_cfg["modules"][0]
    replacements.update({
        "{{module.name}}":        first_module["name"],
        "{{module.code}}":        first_module["code"],
        "{{module.slug}}":        first_module["slug"],
        "{{module.table_prefix}}": first_module["table_prefix"],
        "{{module.description}}": first_module["description"],
        "{{module.depends_on}}":  first_module["depends_on"],
    })

    # Apply prompt-header.md if referenced
    header_path = PIPELINE_ROOT / "templates" / "prompt-header.md"
    if header_path.exists():
        replacements["{{> templates/prompt-header.md}}"] = header_path.read_text(encoding="utf-8")

    resolved = template
    for placeholder, value in replacements.items():
        resolved = resolved.replace(placeholder, value)

    return resolved


# ─────────────────────────────────────────────
# CLAUDE API CALL
# ─────────────────────────────────────────────

def call_claude(prompt: str, batch_number: int) -> str:
    """
    Send the resolved prompt to claude-sonnet-4-6 and return the text response.
    Retries up to RETRY_LIMIT times on API errors.
    """
    client = anthropic.Anthropic()   # Reads ANTHROPIC_API_KEY from environment

    system_prompt = (
        "You are a senior software architect and business analyst specialising in "
        "multi-tenant SaaS platforms for Indian K-12 education. "
        "You produce exhaustive, structured technical documentation. "
        "Never abbreviate, truncate, or use placeholder text like '[continue...]'. "
        "Complete every section fully before finishing your response. "
        "Output only the Markdown document — no preamble, no commentary."
    )

    for attempt in range(1, RETRY_LIMIT + 2):
        try:
            log(f"  [cyan]Calling {MODEL} — batch {batch_number} (attempt {attempt})...[/cyan]")
            message = client.messages.create(
                model=MODEL,
                max_tokens=MAX_TOKENS,
                system=system_prompt,
                messages=[{"role": "user", "content": prompt}],
            )
            return message.content[0].text

        except anthropic.RateLimitError:
            if attempt <= RETRY_LIMIT:
                wait = RETRY_DELAY_SEC * attempt
                log(f"  [yellow]Rate limited. Waiting {wait}s before retry...[/yellow]")
                time.sleep(wait)
            else:
                log("[red]Rate limit exceeded after retries. Exiting.[/red]")
                raise

        except anthropic.APIError as e:
            if attempt <= RETRY_LIMIT:
                log(f"  [yellow]API error: {e}. Retrying in {RETRY_DELAY_SEC}s...[/yellow]")
                time.sleep(RETRY_DELAY_SEC)
            else:
                raise


# ─────────────────────────────────────────────
# VALIDATION
# ─────────────────────────────────────────────

def validate_batch_output(content: str, batch_cfg: dict, step_cfg: dict) -> list[str]:
    """Returns list of validation error strings. Empty list = passed."""
    errors = []
    validations = step_cfg.get("validation", {}).get("per_batch", [])

    for rule in validations:
        check = rule["check"]
        if check == "contains_pattern":
            pattern = rule["pattern"].replace("{n}", str(batch_cfg["number"]))
            if pattern not in content:
                errors.append(f"Missing pattern: '{pattern}' — {rule.get('description', '')}")
        elif check == "min_length":
            if len(content) < rule["chars"]:
                errors.append(
                    f"Output too short: {len(content)} chars < {rule['chars']} minimum. "
                    f"Likely truncated. {rule.get('description', '')}"
                )

    # Always check that every module in the batch has at least one FR
    for module in batch_cfg["modules"]:
        fr_pattern = f"FR-{module['code']}-"
        if fr_pattern not in content:
            errors.append(f"No functional requirements found for module {module['code']} (expected '{fr_pattern}...')")

    return errors


# ─────────────────────────────────────────────
# STATE MANAGEMENT
# ─────────────────────────────────────────────

def load_state() -> dict:
    if STATE_FILE.exists():
        with open(STATE_FILE) as f:
            return json.load(f)
    return {"completed_batches": [], "failed_batches": [], "started_at": None}


def save_state(state: dict):
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    with open(STATE_FILE, "w") as f:
        json.dump(state, f, indent=2)


# ─────────────────────────────────────────────
# MERGE
# ─────────────────────────────────────────────

def merge_batches(step_cfg: dict) -> Path:
    """Merge all srs-batch-N.md files into srs.md with a unified ToC."""
    output_dir = OUTPUT_DIR
    all_batches = step_cfg["batches"]

    merged_sections = []
    all_module_names = []

    for batch_key, batch_cfg in all_batches.items():
        batch_file = output_dir / f"srs-batch-{batch_cfg['number']}.md"
        if not batch_file.exists():
            log(f"[red]Cannot merge: {batch_file} not found. Run all batches first.[/red]")
            sys.exit(1)

        content = batch_file.read_text(encoding="utf-8")

        # Strip the individual batch ToC and Batch Summary — we'll rebuild them
        content = re.sub(r"^## Table of Contents.*?(?=^#\s)", "", content, flags=re.DOTALL | re.MULTILINE)
        content = re.sub(r"^## Batch Summary.*$", "", content, flags=re.DOTALL | re.MULTILINE)
        content = content.strip()

        merged_sections.append(f"<!-- ═══ BATCH {batch_cfg['number']}: {batch_cfg['label'].upper()} ═══ -->\n\n{content}")
        all_module_names.extend(m["name"] for m in batch_cfg["modules"])

    # Build unified ToC
    toc_lines = [
        "# Prime-AI Software Requirements Specification",
        "",
        f"> **Generated:** {datetime.now().strftime('%Y-%m-%d %H:%M')}  ",
        f"> **Platform:** {step_cfg.get('volumes', {}).get('tenants_scale', 2000)} tenant scale  ",
        f"> **Total Modules:** {len(all_module_names)}",
        "",
        "## Table of Contents",
        "",
    ]
    for i, (batch_key, batch_cfg) in enumerate(all_batches.items(), 1):
        toc_lines.append(f"### Batch {i}: {batch_cfg['label']}")
        for module in batch_cfg["modules"]:
            slug = module["name"].lower().replace(" ", "-").replace("&", "and")
            toc_lines.append(f"- [{module['name']}](#{slug})")
        toc_lines.append("")

    toc = "\n".join(toc_lines)

    final_content = toc + "\n\n---\n\n" + "\n\n---\n\n".join(merged_sections)

    # Post-merge validation
    validations = step_cfg.get("validation", {}).get("post_merge", [])
    merge_errors = []
    for rule in validations:
        if rule["check"] == "contains_all_patterns":
            for pattern in rule["patterns"]:
                if pattern not in final_content:
                    merge_errors.append(f"Merged SRS missing pattern '{pattern}' — {rule.get('description', '')}")
        elif rule["check"] == "min_length":
            if len(final_content) < rule["chars"]:
                merge_errors.append(
                    f"Merged SRS suspiciously short ({len(final_content)} chars < {rule['chars']})"
                )

    if merge_errors:
        log("[yellow]⚠ Post-merge validation warnings:[/yellow]")
        for err in merge_errors:
            log(f"  [yellow]• {err}[/yellow]")

    out_path = OUTPUT_DIR / "srs.md"
    out_path.write_text(final_content, encoding="utf-8")
    return out_path


# ─────────────────────────────────────────────
# STATUS DISPLAY
# ─────────────────────────────────────────────

def show_status(step_cfg: dict, state: dict):
    all_batches = step_cfg["batches"]
    table = Table(title="Step 1.1 — SRS Batch Status")
    table.add_column("Batch", style="cyan")
    table.add_column("Label")
    table.add_column("Modules")
    table.add_column("Status")
    table.add_column("Output File")

    for batch_key, batch_cfg in all_batches.items():
        n = batch_cfg["number"]
        out_file = OUTPUT_DIR / f"srs-batch-{n}.md"
        if n in state["completed_batches"]:
            status    = "[green]✅ Complete[/green]"
            file_info = f"{out_file.stat().st_size // 1024}KB" if out_file.exists() else "missing!"
        elif n in state["failed_batches"]:
            status    = "[red]❌ Failed[/red]"
            file_info = "—"
        elif out_file.exists():
            status    = "[yellow]⚠ File exists (unvalidated)[/yellow]"
            file_info = f"{out_file.stat().st_size // 1024}KB"
        else:
            status    = "[dim]⏳ Pending[/dim]"
            file_info = "—"

        modules_str = ", ".join(m["code"] for m in batch_cfg["modules"])
        table.add_row(str(n), batch_cfg["label"], modules_str, status, file_info)

    merged_file = OUTPUT_DIR / "srs.md"
    merge_status = f"[green]✅ {merged_file.stat().st_size // 1024}KB[/green]" if merged_file.exists() else "[dim]Not yet merged[/dim]"

    if RICH_AVAILABLE:
        console.print(table)
        console.print(f"\n[bold]Final merged srs.md:[/bold] {merge_status}")
    else:
        print("(Install 'rich' for a formatted table)")
        print(f"Completed batches: {state['completed_batches']}")
        print(f"Merged srs.md: {'exists' if merged_file.exists() else 'not yet created'}")


# ─────────────────────────────────────────────
# MAIN RUN LOGIC
# ─────────────────────────────────────────────

def run_batch(batch_number: int, config: dict, step_cfg: dict, full_rbs: str, state: dict, force: bool = False):
    """Execute a single batch."""
    batch_key = f"batch-{batch_number}"
    batch_cfg = step_cfg["batches"].get(batch_key)
    if not batch_cfg:
        log(f"[red]Batch {batch_number} not found in config.[/red]")
        return False

    output_file = OUTPUT_DIR / f"srs-batch-{batch_number}.md"

    if not force and batch_number in state["completed_batches"]:
        log(f"  [green]Batch {batch_number} already complete. Skipping (use --force to re-run).[/green]")
        return True

    log(f"\n[bold cyan]━━━ Batch {batch_number}/{len(step_cfg['batches'])}: {batch_cfg['label']} ━━━[/bold cyan]")
    modules_str = ", ".join(m["name"] for m in batch_cfg["modules"])
    log(f"  Modules: {modules_str}")

    # 1. Extract RBS section for this batch
    rbs_extract = extract_rbs_for_batch(full_rbs, batch_cfg)
    log(f"  RBS extract: {len(rbs_extract)} chars")

    # 2. Load and resolve prompt template
    template = PROMPT_TEMPLATE.read_text(encoding="utf-8")
    resolved_prompt = resolve_prompt(template, config, step_cfg, batch_cfg, rbs_extract)
    log(f"  Resolved prompt: {len(resolved_prompt)} chars")

    # 3. Call Claude
    try:
        response = call_claude(resolved_prompt, batch_number)
    except Exception as e:
        log(f"  [red]API call failed: {e}[/red]")
        if batch_number not in state["failed_batches"]:
            state["failed_batches"].append(batch_number)
        save_state(state)
        return False

    # 4. Save raw output
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    output_file.write_text(response, encoding="utf-8")
    log(f"  Saved: {output_file} ({len(response)} chars)")

    # 5. Validate
    errors = validate_batch_output(response, batch_cfg, step_cfg)
    if errors:
        log(f"  [yellow]⚠ Validation warnings for batch {batch_number}:[/yellow]")
        for err in errors:
            log(f"    [yellow]• {err}[/yellow]")
        # Don't mark as failed — partial output is better than none
        # but log clearly
        log(f"  [yellow]Saving output despite warnings. Review srs-batch-{batch_number}.md before merging.[/yellow]")
    else:
        log(f"  [green]✅ Batch {batch_number} validated successfully.[/green]")

    # 6. Update state
    if batch_number in state["failed_batches"]:
        state["failed_batches"].remove(batch_number)
    if batch_number not in state["completed_batches"]:
        state["completed_batches"].append(batch_number)
    save_state(state)
    return True


def main():
    parser = argparse.ArgumentParser(description="Prime-AI Step 1.1 — Batched SRS Generator")
    parser.add_argument("--batch",         type=int, help="Run only this batch number")
    parser.add_argument("--merge-only",    action="store_true", help="Skip generation, only merge existing batch files")
    parser.add_argument("--validate-only", action="store_true", help="Validate existing output files without running Claude")
    parser.add_argument("--status",        action="store_true", help="Show batch completion status")
    parser.add_argument("--force",         action="store_true", help="Re-run even if batch is marked complete")
    args = parser.parse_args()

    config, step_cfg = load_config()
    state = load_state()

    if state["started_at"] is None:
        state["started_at"] = datetime.now().isoformat()
        save_state(state)

    if args.status:
        show_status(step_cfg, state)
        return

    if args.merge_only:
        log("\n[bold]Merging all batch outputs into srs.md...[/bold]")
        out = merge_batches(step_cfg)
        log(f"[green]✅ Merged SRS written to: {out}[/green]")
        return

    if args.validate_only:
        log("\n[bold]Validating existing batch outputs...[/bold]")
        full_rbs = load_rbs(config, step_cfg)
        all_passed = True
        for batch_key, batch_cfg in step_cfg["batches"].items():
            n = batch_cfg["number"]
            out_file = OUTPUT_DIR / f"srs-batch-{n}.md"
            if not out_file.exists():
                log(f"  [red]Batch {n}: file not found[/red]")
                all_passed = False
                continue
            content = out_file.read_text(encoding="utf-8")
            errors = validate_batch_output(content, batch_cfg, step_cfg)
            if errors:
                log(f"  [yellow]Batch {n}: {len(errors)} issue(s)[/yellow]")
                for err in errors:
                    log(f"    • {err}")
                all_passed = False
            else:
                log(f"  [green]Batch {n}: ✅ OK ({len(content)} chars)[/green]")
        if all_passed:
            log("[green]\nAll batches passed validation.[/green]")
        return

    # Normal run — load RBS once, then process batches
    full_rbs = load_rbs(config, step_cfg)
    log(f"\n[bold]Prime-AI Step 1.1 — SRS Generation[/bold]")
    log(f"RBS loaded: {len(full_rbs)} chars")
    log(f"Total batches: {len(step_cfg['batches'])}")
    log(f"Model: {MODEL}\n")

    batches_to_run = [args.batch] if args.batch else list(range(1, len(step_cfg["batches"]) + 1))

    success_count = 0
    for n in batches_to_run:
        ok = run_batch(n, config, step_cfg, full_rbs, state, force=args.force)
        if ok:
            success_count += 1
        # Brief pause between batches to avoid rate limiting
        if n != batches_to_run[-1]:
            log("  Pausing 5s before next batch...")
            time.sleep(5)

    log(f"\n[bold]Batches complete: {success_count}/{len(batches_to_run)}[/bold]")

    # Auto-merge if all batches are done
    all_batch_nums  = list(range(1, len(step_cfg["batches"]) + 1))
    all_complete    = all(n in state["completed_batches"] for n in all_batch_nums)

    if all_complete and not args.batch:
        log("\n[bold]All batches complete. Merging into srs.md...[/bold]")
        out = merge_batches(step_cfg)
        log(f"[green]✅ Final SRS ready: {out}[/green]")
        log(f"[green]   Size: {out.stat().st_size // 1024}KB[/green]")
        log(f"\n[bold]Next step:[/bold] Feed output/srs.md into Step 1.2 (Dependency Map).")
    elif args.batch:
        remaining = [n for n in all_batch_nums if n not in state["completed_batches"]]
        if remaining:
            log(f"\n[yellow]Remaining batches: {remaining}[/yellow]")
            log(f"Run: python orchestrator_step_1_1.py --batch {remaining[0]}")
        else:
            log("\n[green]All batches done! Run without --batch flag to merge:[/green]")
            log("  python orchestrator_step_1_1.py --merge-only")


if __name__ == "__main__":
    main()
