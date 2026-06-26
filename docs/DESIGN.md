# Design

## Goal

MoonFlowGraph is a small MoonBit library for reproducible research and agent workflow planning. It models tasks, dependency edges, execution plans, and provenance events.

The design deliberately stays below a full runtime. A larger system can use MoonFlowGraph to decide what should run and how to report it, while keeping model calls, shell execution, scheduling, and storage outside this package.

In a DeepScientist-style workflow, this package is the "plan and evidence ledger" layer: it can describe the task graph and record what happened, but it does not decide scientific hypotheses, call models, run experiments, or judge final claims.

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

The first implementation uses arrays rather than a map-heavy internal model. That keeps the package readable for contest review and simple enough to port across MoonBit targets. A later version can add indexes once the public API is stable.

## Planning Model

The planner exposes two complementary views:

- `topological_sort()` returns a serial order that satisfies dependencies.
- `execution_batches()` returns layers of tasks that can run in parallel once previous layers have completed.

The demo intentionally uses two independent starting tasks (`collect_papers` and `prepare_dataset`) so the first batch shows real parallelism. Later batches converge into `compare_metrics`, which mirrors common research workflows where literature-derived claims and experimental metrics must meet before writing a report.

`ready_tasks(done)` is a smaller incremental primitive for callers that do their own scheduling. Given a set of completed task ids, it returns tasks whose predecessors are all complete and that are not already done.

## Error Model

Errors are readable by design:

- duplicate task id;
- missing task;
- missing dependency endpoint;
- cycle detected.

This makes CLI/demo output useful without a separate diagnostic layer.

Cycle errors carry a readable path, for example `a -> b -> a`. Missing endpoints keep the original dependency edge so callers can explain which relation is invalid.

## Export Model

Markdown export is optimized for human handoff and contest review. JSON export is optimized for downstream tooling and includes:

- order and batches;
- task id, title, description, status, inputs, outputs, and tags;
- dependency edges;
- trace events.

The current JSON writer is deliberately dependency-free and compact. It escapes common JSON string characters and keeps schema shape stable enough for tests and future CLI work.

## Relationship To DeepScientist-Style Workflows

The project idea is informed by prior work on automated research agents: a research quest needs a clear task plan, inspectable state transitions, and a handoff record. MoonFlowGraph captures that reusable substrate in MoonBit without copying any DeepScientist runtime or plugin code.

That boundary is important for originality and feasibility. A full research agent includes model routing, prompt policies, browser or shell actions, experiment runners, memory stores, and paper-writing loops. MoonFlowGraph extracts only the reusable infrastructure that such systems repeatedly need:

- explicit task decomposition;
- dependency sanity checks before execution;
- parallel-ready planning;
- trace records for reproducibility;
- portable Markdown/JSON handoff artifacts.

This makes the v0.1 product small enough to validate with unit tests while still connecting naturally to the author's previous research automation experience.
