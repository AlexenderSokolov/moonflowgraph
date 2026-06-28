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
- `update_status(id, status)` updates an existing task or returns `MissingTask`.

## Trace

- `Trace::record(event)` appends an event.
- `events()` returns all events in append order.
- `events_for(task_id)` filters events without changing their order.
- `event_count()` returns the number of events.
- `latest_for(task_id)` returns the most recently appended event for that task.
- `summary_markdown()` renders a compact event list.

Timestamps are strings supplied by the caller. They may be wall-clock timestamps, logical steps, or deterministic replay identifiers.

## Export

- `to_markdown(plan, trace)` creates a human-readable execution report.
- `to_json(plan, trace)` creates a dependency-free JSON snapshot for tooling.
- `to_mermaid()` validates the graph and creates a Mermaid `flowchart TD` definition. Synthetic node ids keep arbitrary task ids out of Mermaid syntax, while labels preserve task ids and titles.

## Errors

`GraphError` distinguishes duplicate tasks, duplicate dependencies, missing tasks, missing dependency endpoints, and cycles. `message()` returns a readable diagnostic; cycle errors include the detected path.
