# Roadmap

## v0.1

- Core task graph model.
- Task metadata: description, inputs, outputs, tags, and status.
- Dependency validation.
- Duplicate dependency rejection.
- Cycle detection.
- Topological ordering.
- Parallel-ready execution batches.
- Incremental ready-task query.
- Predecessor and successor queries.
- Root and leaf task queries.
- Task status updates.
- Provenance trace log.
- Per-task trace filtering and trace Markdown summary.
- Trace event counts and latest-event lookup.
- Markdown, JSON, and Mermaid export with tasks, dependencies, batches, and trace events.
- Demo workflow for research/agent automation with real parallel batches.
- English and Chinese documentation, design notes, project memory, and CI.
- Detached snapshot accessors for graph and trace collections.
- Checked task-status transitions and status-derived runnable tasks.
- Checked exports that reject stale plans and unknown trace task ids.
- Versioned JSON snapshots with structured status fields and parser-backed tests.

## v0.1 Acceptance Checklist

- `moon check` passes.
- `moon test` passes.
- `moon run cmd/demo` prints Markdown and JSON outputs.
- The demo shows `collect_papers` and `prepare_dataset` running in the first parallel batch.
- Documentation explains the boundary between a task graph library and a full Agent runtime.
- The trace demonstrates why a task ran and which artifacts it left, not only that it completed.

## v0.2

- Import/export round trips for workflow descriptions.
- CLI command for reading a small workflow file.
- Private graph/trace internals after a documented compatibility migration.
- Optional graph indexes for faster lookup in larger DAGs.
- Additional tests for larger disconnected graphs and error diagnostics.
- Mooncakes package publishing polish.

## v0.x Not Planned Yet

- LLM calls.
- Shell execution.
- Background daemon.
- Database persistence.
- UI surface.
- Secret or credential management.
