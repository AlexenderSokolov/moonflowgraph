# MoonFlowGraph

MoonFlowGraph is a MoonBit task graph and provenance trace library for reproducible research automation and agent workflows.

The project grew out of a recurring problem I ran into while maintaining research automation plugins: the task list lived in a plan, dependencies were implicit in code, and the evidence from a run was scattered across logs and temporary files. That works for a short script. It becomes hard to reason about once literature search, data preparation, baselines, metric comparison, and report writing start to overlap.

MoonFlowGraph extracts that small but useful layer into a standalone library. It describes what should happen, checks whether the dependency graph is sound, shows what can run in parallel, and records what happened. It does not execute the workflow itself.

Chinese documentation is available in [README.zh.md](README.zh.md).

## What It Does

- Defines task nodes with inputs, outputs, tags, and status.
- Tracks dependency edges and validates missing endpoints.
- Rejects duplicate dependency edges.
- Detects cycles and returns readable paths.
- Produces topological order and parallel-ready execution batches.
- Queries roots, leaves, predecessors, successors, ready tasks, and graph size.
- Provides checked task-status transitions plus an unrestricted replay API.
- Returns detached graph and trace snapshots for safe caller-side inspection.
- Records provenance events in append order.
- Filters trace events by task and returns the latest event for a task.
- Rejects stale plans and unknown trace task ids during checked export.
- Exports Markdown reports, versioned JSON snapshots, and Mermaid flowcharts.

## What It Deliberately Leaves Out

- It does not call LLM APIs.
- It does not execute shell commands.
- It does not replace a full agent runtime.
- It does not store secrets or credentials.

Those concerns belong to an upper-level runtime. Keeping them outside this package makes the planning and evidence layer independently testable and reusable.

## Quick Start

```bash
moon fmt --check
moon check
moon test
moon run cmd/demo
```

Minimal API shape:

```moonbit
let graph = FlowGraph::new()
guard graph.add_task(TaskNode::new("collect_papers", "Collect papers")) is Ok(_) else { fail("add task") }
guard graph.add_task(TaskNode::new("write_report", "Write report")) is Ok(_) else { fail("add task") }
guard graph.add_dependency(TaskId::new("collect_papers"), TaskId::new("write_report")) is Ok(_) else { fail("add dependency") }

guard graph.plan() is Ok(plan) else { fail("invalid graph") }
let trace = Trace::new()
guard graph.to_json_checked(plan, trace) is Ok(snapshot) else { fail("invalid snapshot") }
```

The demo follows a concrete path from literature and dataset preparation to a research report:

```text
collect_papers   prepare_dataset
      |                 |
      v                 v
extract_claims    run_baseline
      \                 /
       v               v
          compare_metrics -> write_report
```

Its trace records useful evidence such as the search scope, dataset snapshot, baseline configuration, and comparison rationale. It prints a Markdown report, a JSON snapshot, and a Mermaid flowchart.

The full public surface and error behavior are listed in [docs/API.md](docs/API.md).
The version 1 snapshot contract is defined by [docs/run-snapshot-v1.schema.json](docs/run-snapshot-v1.schema.json).

## Project Layout

```text
moonflowgraph/
|-- flowgraph.mbt        # task graph, validation, DAG planning
|-- trace.mbt            # provenance events and readable labels
|-- export.mbt           # Markdown and JSON export
|-- flowgraph_test.mbt   # core behavior tests
|-- cmd/demo/            # runnable demo
|-- docs/                # API, design, roadmap, and JSON schema
|-- CHANGELOG.md         # unreleased and versioned changes
|-- README.zh.md         # Chinese documentation
`-- PROJECT.md           # project memory and acceptance checklist
```

## Repositories

- GitHub: <https://github.com/AlexenderSokolov/moonflowgraph>
- GitLink: <https://gitlink.org.cn/SpringBack_25/moonflowgraph>

## Development Note

MoonFlowGraph is an original MoonBit implementation based on general DAG, workflow, and provenance ideas rather than a port of a particular upstream project. AI tools assisted with implementation, testing, and documentation; project selection, scope decisions, acceptance, and submission remain the author's responsibility.

## License

Apache-2.0. See [LICENSE](LICENSE).
