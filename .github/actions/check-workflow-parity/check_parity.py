#!/usr/bin/env python3
"""Compare two GitHub Actions workflow jobs and fail on drift.

Catches CI drift like runner mismatches or missing steps between PR
and main workflows. Allows specific keys to differ (e.g. extra-tag).
"""

import argparse
import json
import sys
from pathlib import Path

import yaml


def load_workflow(path: Path) -> dict[str, object]:
    """Load and parse a GitHub Actions workflow YAML file."""
    return yaml.safe_load(path.read_text())  # type: ignore[return-value]


def normalize_job(job: dict[str, object], allowed_diffs: set[str]) -> dict[str, object]:
    """Strip allowed-diff keys from publish-image ``with:`` blocks."""
    steps: list[dict[str, object]] = []
    for step in job.get("steps", []):
        step_dict: dict[str, object] = dict(step)  # type: ignore[arg-type]
        if "with" in step_dict:
            with_block = step_dict["with"]
            if isinstance(with_block, dict):
                step_dict["with"] = {
                    k: v for k, v in with_block.items() if k not in allowed_diffs
                }
        steps.append(step_dict)
    return {
        "runs-on": job.get("runs-on"),
        "permissions": job.get("permissions"),
        "steps": steps,
    }


def main() -> int:
    """Compare two workflow jobs and exit 1 on drift."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--workflow-a", default=".github/workflows/pull_request.yml")
    parser.add_argument("--workflow-b", default=".github/workflows/push_to_main.yml")
    parser.add_argument("--job", default="build_and_publish", help="Job name to compare")
    parser.add_argument(
        "--allowed-diffs",
        default="",
        help="Comma-separated 'with' keys that may differ",
    )
    args = parser.parse_args()
    workflow_a: str = args.workflow_a
    workflow_b: str = args.workflow_b
    job_name: str = args.job

    allowed: set[str] = {k.strip() for k in args.allowed_diffs.split(",") if k.strip()}

    wf_a: dict[str, object] = load_workflow(Path(workflow_a))
    wf_b: dict[str, object] = load_workflow(Path(workflow_b))

    jobs_a: dict[str, object] = wf_a.get("jobs", {})  # type: ignore[assignment]
    jobs_b: dict[str, object] = wf_b.get("jobs", {})  # type: ignore[assignment]
    job_a: dict[str, object] | None = jobs_a.get(job_name)  # type: ignore[assignment]
    job_b: dict[str, object] | None = jobs_b.get(job_name)  # type: ignore[assignment]

    if job_a is None:
        print(f"ERROR: job '{job_name}' not found in {workflow_a}")
        return 1
    if job_b is None:
        print(f"ERROR: job '{job_name}' not found in {workflow_b}")
        return 1

    norm_a = normalize_job(job_a, allowed)
    norm_b = normalize_job(job_b, allowed)

    if json.dumps(norm_a, sort_keys=True) != json.dumps(norm_b, sort_keys=True):
        print(f"FAIL: job '{job_name}' differs between:")
        print(f"  {workflow_a}")
        print(f"  {workflow_b}")
        print(f"Update {workflow_b} to match {workflow_a}.")
        return 1

    print(f"OK: job '{job_name}' matches in both workflows")
    return 0


if __name__ == "__main__":
    sys.exit(main())
