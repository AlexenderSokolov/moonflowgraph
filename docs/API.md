# Public API

MoonFlowGraph keeps its public surface small. A caller builds a graph, validates or plans it, records events during execution, and exports the result.

## Graph construction

- `FlowGraph::new()` creates an empty graph.
- `TaskNode::new(id, title)` creates a pending task; `with_description`, `with_inputs`, `with_outputs`, `with_tags`, and `with_status` add metadata.
- `add_task(node)` rejects duplicate task ids.
- `add_dependency(before, after)` rejects duplicate edges. Missing endpoints are reported by `validate()`, which allows callers to finish constructing a graph before checking it.

## Validation and planning

- `validate()` checks dependency endpoints and cycles.
- `topological_sort()` returns one serial order that satisfies every dependency.
- `execution_batches()` groups tasks that can run in parallel after earlier batches finish.
- `plan()` returns both views as an `ExecutionPlan`.
- `ready_tasks(done)` returns unfinished tasks whose predecessors are all present in the caller-provided `done` set.

## Queries and status

- `task_count()` and `dependency_count()` return graph size.
- `roots()` and `leaves()` return tasks without incoming or outgoing edges.
- `predecessors(id)` and `successors(id)` return immediate neighbors.
- `find_task(id)` returns a task snapshot when the id exists.
- `tasks_snapshot()` and `dependencies_snapshot()` return detached arrays that callers can safely mutate.
- `tasks()` and `dependencies()` remain compatibility APIs and expose backing arrays; new code should avoid them.
- `transition_status(id, status)` enforces normal execution transitions.
- `update_status(id, status)` remains an unrestricted compatibility/replay API.
- `runnable_tasks()` reads node statuses and returns pending/ready tasks whose predecessors succeeded.

The checked transition model accepts idempotent updates and these edges:

- `Pending -> Ready | Running | Skipped`
- `Ready -> Running | Skipped`
- `Running -> Succeeded | Failed`
- `Failed -> Ready` for retry

Succeeded and skipped tasks are terminal in the checked model. Importers and replay tools can deliberately use `update_status` when reconstructing historical state.

`ready_tasks(done)` remains a pure planning primitive. It trusts the caller-provided completion set and does not inspect task status. This is intentionally distinct from `runnable_tasks()`.

## Snapshot consistency

- `validate_plan(plan)` rejects a stale or foreign execution plan.
- `validate_trace(trace)` rejects events that refer to unknown task ids.
- `validate_snapshot(plan, trace)` performs both checks.
- `ExecutionPlan::snapshot()` returns a detached copy, including nested batches.

## Trace

- `Trace::record(event)` appends an event.
- `events()` returns all events in append order.
- `events_snapshot()` returns a detached event array; new code should prefer it over `events()`.
- `events_for(task_id)` filters events without changing their order.
- `event_count()` returns the number of events.
- `latest_for(task_id)` returns the most recently appended event for that task.
- `summary_markdown()` renders a compact event list.

Timestamps are strings supplied by the caller. They may be wall-clock timestamps, logical steps, or deterministic replay identifiers.

## Export

- `to_markdown(plan, trace)` creates a human-readable execution report.
- `to_json(plan, trace)` preserves the unversioned 0.1 JSON shape for compatibility.
- `to_markdown_checked(plan, trace)` and `to_json_checked(plan, trace)` reject stale plans and unknown trace tasks.
- `snapshot_markdown(trace)` and `snapshot_json(trace)` generate a fresh plan before exporting.
- `to_mermaid()` validates the graph and creates a Mermaid `flowchart TD` definition. Synthetic node ids keep arbitrary task ids out of Mermaid syntax, while labels preserve task ids and titles.

JSON produced by `to_json_checked` and `snapshot_json` contains `schema_version: 1`. Task status keeps the legacy human-readable `status` field and adds machine-readable `status_kind` plus nullable `status_reason`. The contract is documented in `run-snapshot-v1.schema.json`.

## Errors

`GraphError` distinguishes duplicate tasks, duplicate dependencies, missing tasks, missing dependency endpoints, and cycles. `StatusTransitionError` reports missing tasks and illegal status edges. `SnapshotError` reports invalid graphs, stale plans, and unknown trace tasks. Every error type provides `message()`.
