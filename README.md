# MoonFlowGraph

MoonFlowGraph is a MoonBit task graph and provenance trace library for reproducible research automation and agent workflows.

It helps a developer describe a workflow as a directed acyclic graph, validate dependencies, generate an execution plan, and export a compact trace report for handoff, review, or experiment reproduction.

Chinese documentation for contest review is available in [README.zh.md](README.zh.md).

## Who It Is For

- Researchers who split experiments into data, baseline, comparison, and report tasks.
- Agent builders who need a lightweight task graph before connecting real model calls.
- MoonBit developers who want a reusable workflow/provenance component rather than a one-off demo.

## What It Does

- Defines task nodes with inputs, outputs, tags, and status.
- Tracks dependency edges and validates missing endpoints.
- Detects cycles and returns readable paths.
- Produces topological order and parallel-ready execution batches.
- Queries predecessors, successors, ready tasks, and graph size.
- Updates task status during a run or replay.
- Records provenance events in append order.
- Filters trace events by task and exports Markdown/JSON reports.

## What It Does Not Do

- It does not call LLM APIs.
- It does not execute shell commands.
- It does not replace a full agent runtime.
- It does not store secrets or credentials.

MoonFlowGraph is the small reproducibility layer underneath a larger automation system.

## Quick Start

```bash
moon check
moon test
moon run cmd/demo
```

Minimal API shape:

```moonbit
let graph = FlowGraph::new()
let _ = graph.add_task(TaskNode::new("collect_papers", "Collect papers"))
let _ = graph.add_task(TaskNode::new("write_report", "Write report"))
let _ = graph.add_dependency(TaskId::new("collect_papers"), TaskId::new("write_report"))

guard graph.plan() is Ok(plan) else { fail("invalid graph") }
```

The demo builds this workflow:

```text
collect_papers   prepare_dataset
      |                 |
      v                 v
extract_claims    run_baseline
      \                 /
       v               v
          compare_metrics -> write_report
```

It prints a Markdown report and a JSON snapshot with execution order, parallel batches, task metadata, dependencies, and trace events.

## Project Layout

```text
moonflowgraph/
|-- flowgraph.mbt        # task graph, validation, DAG planning
|-- trace.mbt            # provenance events and readable labels
|-- export.mbt           # Markdown and JSON export
|-- flowgraph_test.mbt   # core behavior tests
|-- cmd/demo/            # runnable demo
|-- docs/                # design and roadmap
|-- README.zh.md         # Chinese contest-facing documentation
`-- PROJECT.md           # project memory and acceptance checklist
```

## Contest Positioning

MoonFlowGraph is intended for the MoonBit domestic open-source ecosystem contest. It is an original project inspired by common DAG workflow, task planning, and provenance trace ideas. It does not directly port a specific upstream project. If later versions reuse code, test data, or algorithms from a concrete upstream source, the source and license will be documented.

## License

Apache-2.0. See [LICENSE](LICENSE).
