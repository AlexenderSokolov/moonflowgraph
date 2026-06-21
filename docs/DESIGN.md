# Design

## Goal

MoonFlowGraph is a small MoonBit library for reproducible research and agent workflow planning. It models tasks, dependency edges, execution plans, and provenance events.

The design deliberately stays below a full runtime. A larger system can use MoonFlowGraph to decide what should run and how to report it, while keeping model calls, shell execution, scheduling, and storage outside this package.

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

## Error Model

Errors are readable by design:

- duplicate task id;
- missing task;
- missing dependency endpoint;
- cycle detected.

This makes CLI/demo output useful without a separate diagnostic layer.

## Relationship To DeepScientist-Style Workflows

The project idea is informed by prior work on automated research agents: a research quest needs a clear task plan, inspectable state transitions, and a handoff record. MoonFlowGraph captures that reusable substrate in MoonBit without copying any DeepScientist runtime or plugin code.
