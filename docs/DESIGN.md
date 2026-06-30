# Design

## Goal

MoonFlowGraph is a small MoonBit library for reproducible research and agent workflow planning. It models tasks, dependency edges, execution plans, and provenance events.

The project comes from a practical maintenance problem. In research automation tools, a plan is often readable before execution, but the relationship between that plan and the evidence produced by a run becomes difficult to inspect later. MoonFlowGraph keeps both pieces close: the DAG describes the intended work, and the trace records the evidence left by that work.

The package stays below a full runtime. A larger system can use it as a plan and evidence ledger while keeping model calls, shell execution, scheduling, and storage in the layer that already owns those concerns.

## Core Boundary

MoonFlowGraph owns:

- task identity and metadata;
- dependency validation;
- cycle detection;
- topological order;
- parallel-ready batches;
- append-only trace events;
- Markdown/JSON export.

MoonFlowGraph does not own:

- LLM provider calls;
- command execution;
- distributed scheduling;
- persistent databases;
- secret management;
- browser or UI integration.

## Data Model

- `TaskId` wraps a string id so public APIs are explicit.
- `TaskNode` stores title, description, inputs, outputs, tags, and status.
- `Dependency` is a directed edge from `before` to `after`.
- `FlowGraph` stores tasks and dependencies.
- `ExecutionPlan` stores both serial order and batch order.
- `TraceEvent` stores task id, event type, message, and timestamp.

The first implementation uses arrays rather than a map-heavy internal model. The expected graphs are small research workflows, and arrays keep mutation and traversal behavior straightforward while the public API settles. A later version can add indexes without changing callers.

The published 0.1 surface exposed those arrays through `pub(all)` types and compatibility accessors. Detached `*_snapshot()` accessors now provide a safe path without breaking 0.1 callers. Making graph internals private is deliberately deferred to 0.2 because it changes the public API.

## Planning Model

The planner exposes two complementary views:

- `topological_sort()` returns a serial order that satisfies dependencies.
- `execution_batches()` returns layers of tasks that can run in parallel once previous layers have completed.

The demo uses two independent starting tasks (`collect_papers` and `prepare_dataset`). Later batches converge into `compare_metrics`, mirroring a common research workflow: literature-derived criteria and experimental measurements have to meet before a report can make a defensible comparison.

`ready_tasks(done)` is a smaller incremental primitive for callers that do their own scheduling. Given a set of completed task ids, it returns tasks whose predecessors are all complete and that are not already done.

`runnable_tasks()` is the state-aware counterpart. It only returns pending or ready tasks whose predecessors are `Succeeded`; failed and skipped predecessors block downstream work. Checked execution uses `transition_status`, while unrestricted `update_status` is retained for importing or replaying historical state.

## Error Model

Errors are readable by design:

- duplicate task id;
- missing task;
- missing dependency endpoint;
- cycle detected.

This makes CLI/demo output useful without a separate diagnostic layer.

Cycle errors carry a readable path, for example `a -> b -> a`. Missing endpoints keep the original dependency edge so callers can explain which relation is invalid.

## Export Model

Markdown export is meant for a person picking up or reviewing a run. JSON export is meant for downstream tooling and includes:

- order and batches;
- task id, title, description, status, inputs, outputs, and tags;
- dependency edges;
- trace events.

The current JSON writer has no external dependency. Checked snapshots use schema version 1, documented as a JSON Schema; all control characters are escaped, and tests parse generated output with MoonBit's core JSON parser. The legacy `to_json` method preserves the unversioned 0.1 shape. Version 1 keeps the display-oriented `status` field and adds `status_kind` plus `status_reason` for future round trips.

Checked export treats the graph, plan, and trace as one consistency boundary. It rejects plans generated before a structural graph change and events that refer to unknown tasks. Raw export remains available for 0.1 compatibility but should not be used by new callers.

## Origin In Research Automation Work

The project idea is informed by maintaining research automation plugins. Those systems repeatedly need a clear task plan, inspectable state transitions, and a handoff record, even when their model providers, runners, and storage choices are completely different.

MoonFlowGraph extracts only the infrastructure that can be useful across those systems:

- explicit task decomposition;
- dependency sanity checks before execution;
- parallel-ready planning;
- trace records for reproducibility;
- portable Markdown/JSON handoff artifacts.

This keeps the library small enough to reason about and validate with unit tests. It also leaves room for callers to choose their own execution, storage, and model layers instead of inheriting a second runtime.
