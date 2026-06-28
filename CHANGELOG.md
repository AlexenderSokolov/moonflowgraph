# Changelog

## Unreleased

- Reject duplicate dependency edges with a readable diagnostic.
- Query workflow roots and leaves.
- Query trace event counts and the latest event for a task.
- Export validated task graphs as Mermaid flowcharts.
- Show Mermaid output in the research workflow demo.

## 0.1.0

- Define task nodes, dependency edges, task status, and provenance events.
- Validate DAGs and report missing endpoints or readable cycle paths.
- Generate topological order and parallel-ready execution batches.
- Export Markdown and JSON reports.
- Provide a research workflow demo, tests, and CI.
