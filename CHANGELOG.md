# Changelog

## Unreleased

- Add detached task, dependency, plan, and trace snapshot accessors.
- Add checked task-status transitions and status-derived runnable-task queries.
- Validate stale execution plans and unknown trace task references before export.
- Add checked Markdown/JSON snapshot export helpers.
- Version checked JSON snapshots and expose structured status kind and reason fields while preserving legacy `to_json` output.
- Escape every JSON control character and parse generated snapshots in tests.
- Make the demo handle graph and transition errors explicitly.

## 0.1.0

- Reject duplicate dependency edges with a readable diagnostic.
- Query workflow roots and leaves.
- Query trace event counts and the latest event for a task.
- Export validated task graphs as Mermaid flowcharts.
- Show Mermaid output in the research workflow demo.
- Define task nodes, dependency edges, task status, and provenance events.
- Validate DAGs and report missing endpoints or readable cycle paths.
- Generate topological order and parallel-ready execution batches.
- Export Markdown and JSON reports.
- Provide a research workflow demo, tests, and CI.
