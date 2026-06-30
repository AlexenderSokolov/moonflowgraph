///|
fn sample_graph() -> FlowGraph {
  let graph = FlowGraph::new()
  let _ = graph.add_task(
    TaskNode::new("collect_papers", "Collect papers")
    .with_outputs(["paper_index.md"])
    .with_tags(["research", "input"]),
  )
  let _ = graph.add_task(
    TaskNode::new("prepare_dataset", "Prepare dataset")
    .with_outputs(["dataset.parquet"])
    .with_tags(["data", "input"]),
  )
  let _ = graph.add_task(
    TaskNode::new("extract_claims", "Extract claims")
    .with_inputs(["paper_index.md"])
    .with_outputs(["claims.json"]),
  )
  let _ = graph.add_task(
    TaskNode::new("run_baseline", "Run baseline")
    .with_inputs(["dataset.parquet"])
    .with_outputs(["baseline_metrics.json"]),
  )
  let _ = graph.add_task(
    TaskNode::new("compare_metrics", "Compare metrics")
    .with_inputs(["claims.json", "baseline_metrics.json"])
    .with_outputs(["comparison.md"]),
  )
  let _ = graph.add_task(
    TaskNode::new("write_report", "Write report")
    .with_inputs(["comparison.md"])
    .with_outputs(["report.md"])
    .with_tags(["report"]),
  )
  let _ = graph.add_dependency(
    TaskId::new("collect_papers"),
    TaskId::new("extract_claims"),
  )
  let _ = graph.add_dependency(
    TaskId::new("prepare_dataset"),
    TaskId::new("run_baseline"),
  )
  let _ = graph.add_dependency(
    TaskId::new("extract_claims"),
    TaskId::new("compare_metrics"),
  )
  let _ = graph.add_dependency(
    TaskId::new("run_baseline"),
    TaskId::new("compare_metrics"),
  )
  let _ = graph.add_dependency(
    TaskId::new("compare_metrics"),
    TaskId::new("write_report"),
  )
  graph
}

///|
test "add task succeeds" {
  let graph = FlowGraph::new()
  let result = graph.add_task(TaskNode::new("a", "A"))
  debug_inspect(result is Ok(_), content="true")
  debug_inspect(graph.task_count(), content="1")
}

///|
test "duplicate task fails" {
  let graph = FlowGraph::new()
  let _ = graph.add_task(TaskNode::new("a", "A"))
  let result = graph.add_task(TaskNode::new("a", "A again"))
  guard result is Err(DuplicateTask(id)) else { fail("expected duplicate") }
  debug_inspect(id.value, content="\"a\"")
}

///|
test "missing dependency endpoint fails validation" {
  let graph = FlowGraph::new()
  let _ = graph.add_task(TaskNode::new("a", "A"))
  let _ = graph.add_dependency(TaskId::new("a"), TaskId::new("missing"))
  let result = graph.validate()
  debug_inspect(result is Err(MissingDependencyEndpoint(_)), content="true")
}

///|
test "duplicate dependency is rejected" {
  let graph = FlowGraph::new()
  let _ = graph.add_task(TaskNode::new("a", "A"))
  let _ = graph.add_task(TaskNode::new("b", "B"))
  let _ = graph.add_dependency(TaskId::new("a"), TaskId::new("b"))
  let result = graph.add_dependency(TaskId::new("a"), TaskId::new("b"))
  guard result is Err(err) else { fail("expected duplicate dependency") }
  guard err is DuplicateDependency(dep) else {
    fail("expected duplicate dependency error")
  }
  debug_inspect(dep.before.value, content="\"a\"")
  debug_inspect(dep.after.value, content="\"b\"")
  debug_inspect(graph.dependency_count(), content="1")
  debug_inspect(err.message(), content="\"duplicate dependency: a -> b\"")
}

///|
test "topological sort follows dependencies" {
  let graph = sample_graph()
  let result = graph.topological_sort()
  guard result is Ok(order) else { fail("expected valid order") }
  debug_inspect(order[0].value, content="\"collect_papers\"")
  debug_inspect(order[5].value, content="\"write_report\"")
  debug_inspect(graph.dependency_count(), content="5")
}

///|
test "parallel batches group ready tasks" {
  let graph = FlowGraph::new()
  let _ = graph.add_task(TaskNode::new("collect_papers", "Collect papers"))
  let _ = graph.add_task(TaskNode::new("collect_datasets", "Collect datasets"))
  let _ = graph.add_task(TaskNode::new("write_report", "Write report"))
  let _ = graph.add_dependency(
    TaskId::new("collect_papers"),
    TaskId::new("write_report"),
  )
  let _ = graph.add_dependency(
    TaskId::new("collect_datasets"),
    TaskId::new("write_report"),
  )
  let result = graph.execution_batches()
  guard result is Ok(batches) else { fail("expected batches") }
  debug_inspect(batches.length(), content="2")
  debug_inspect(batches[0].length(), content="2")
  debug_inspect(batches[1][0].value, content="\"write_report\"")
}

///|
test "cycle detection returns readable path" {
  let graph = FlowGraph::new()
  let _ = graph.add_task(TaskNode::new("a", "A"))
  let _ = graph.add_task(TaskNode::new("b", "B"))
  let _ = graph.add_dependency(TaskId::new("a"), TaskId::new("b"))
  let _ = graph.add_dependency(TaskId::new("b"), TaskId::new("a"))
  let result = graph.validate()
  guard result is Err(err) else { fail("expected cycle") }
  guard err is CycleDetected(path) else { fail("expected cycle error") }
  debug_inspect(path.length() >= 2, content="true")
  debug_inspect(err.message().contains("a -> b -> a"), content="true")
}

///|
test "self cycle returns readable path" {
  let graph = FlowGraph::new()
  let _ = graph.add_task(TaskNode::new("a", "A"))
  let _ = graph.add_dependency(TaskId::new("a"), TaskId::new("a"))
  let result = graph.validate()
  guard result is Err(err) else { fail("expected self cycle") }
  debug_inspect(err.message().contains("a -> a"), content="true")
}

///|
test "status update changes existing task" {
  let graph = sample_graph()
  let result = graph.update_status(TaskId::new("collect_papers"), Succeeded)
  debug_inspect(result is Ok(_), content="true")
  guard graph.find_task(TaskId::new("collect_papers")) is Some(task) else {
    fail("expected task")
  }
  debug_inspect(task.status.label(), content="\"succeeded\"")
}

///|
test "status update rejects missing task" {
  let graph = sample_graph()
  let result = graph.update_status(TaskId::new("missing"), Running)
  guard result is Err(MissingTask(id)) else { fail("expected missing task") }
  debug_inspect(id.value, content="\"missing\"")
}

///|
test "predecessors and successors return immediate neighbors" {
  let graph = sample_graph()
  guard graph.predecessors(TaskId::new("compare_metrics")) is Ok(preds) else {
    fail("expected predecessors")
  }
  debug_inspect(preds.length(), content="2")
  debug_inspect(preds[0].value, content="\"extract_claims\"")
  debug_inspect(preds[1].value, content="\"run_baseline\"")
  guard graph.successors(TaskId::new("collect_papers")) is Ok(succs) else {
    fail("expected successors")
  }
  debug_inspect(succs.length(), content="1")
  debug_inspect(succs[0].value, content="\"extract_claims\"")
}

///|
test "roots and leaves identify workflow boundaries" {
  let graph = sample_graph()
  guard graph.roots() is Ok(roots) else { fail("expected roots") }
  debug_inspect(roots.length(), content="2")
  debug_inspect(roots[0].value, content="\"collect_papers\"")
  debug_inspect(roots[1].value, content="\"prepare_dataset\"")
  guard graph.leaves() is Ok(leaves) else { fail("expected leaves") }
  debug_inspect(leaves.length(), content="1")
  debug_inspect(leaves[0].value, content="\"write_report\"")
}

///|
test "roots and leaves reject invalid graphs" {
  let graph = FlowGraph::new()
  let _ = graph.add_task(TaskNode::new("a", "A"))
  let _ = graph.add_dependency(TaskId::new("a"), TaskId::new("missing"))
  debug_inspect(
    graph.roots() is Err(MissingDependencyEndpoint(_)),
    content="true",
  )
  debug_inspect(
    graph.leaves() is Err(MissingDependencyEndpoint(_)),
    content="true",
  )
}

///|
test "ready tasks identify parallel work" {
  let graph = sample_graph()
  guard graph.ready_tasks([]) is Ok(first_ready) else {
    fail("expected ready tasks")
  }
  debug_inspect(first_ready.length(), content="2")
  debug_inspect(first_ready[0].value, content="\"collect_papers\"")
  debug_inspect(first_ready[1].value, content="\"prepare_dataset\"")
  guard graph.ready_tasks([TaskId::new("collect_papers")]) is Ok(next_ready) else {
    fail("expected next ready tasks")
  }
  debug_inspect(next_ready.length(), content="2")
  debug_inspect(next_ready[0].value, content="\"prepare_dataset\"")
  debug_inspect(next_ready[1].value, content="\"extract_claims\"")
}

///|
test "disconnected dag starts with multiple ready tasks" {
  let graph = FlowGraph::new()
  let _ = graph.add_task(TaskNode::new("a", "A"))
  let _ = graph.add_task(TaskNode::new("b", "B"))
  let _ = graph.add_task(TaskNode::new("c", "C"))
  let _ = graph.add_dependency(TaskId::new("a"), TaskId::new("c"))
  guard graph.execution_batches() is Ok(batches) else {
    fail("expected batches")
  }
  debug_inspect(batches[0].length(), content="2")
  debug_inspect(batches[0][0].value, content="\"a\"")
  debug_inspect(batches[0][1].value, content="\"b\"")
}

///|
test "trace preserves append order" {
  let trace = Trace::new()
  trace.record(TraceEvent::new(TaskId::new("a"), Started, "start", "t1"))
  trace.record(TraceEvent::new(TaskId::new("a"), Completed, "done", "t2"))
  debug_inspect(trace.events()[0].event_type.label(), content="\"started\"")
  debug_inspect(trace.events()[1].event_type.label(), content="\"completed\"")
}

///|
test "trace filters events and renders summary" {
  let trace = Trace::new()
  trace.record(TraceEvent::new(TaskId::new("a"), Started, "start", "t1"))
  trace.record(TraceEvent::new(TaskId::new("b"), Note, "side note", "t2"))
  trace.record(TraceEvent::new(TaskId::new("a"), Completed, "done", "t3"))
  let events = trace.events_for(TaskId::new("a"))
  debug_inspect(events.length(), content="2")
  debug_inspect(events[1].message, content="\"done\"")
  let summary = trace.summary_markdown()
  debug_inspect(summary.contains("Trace Summary"), content="true")
  debug_inspect(summary.contains("a completed: done"), content="true")
}

///|
test "trace returns count and latest task event" {
  let trace = Trace::new()
  trace.record(TraceEvent::new(TaskId::new("a"), Started, "start", "t1"))
  trace.record(TraceEvent::new(TaskId::new("b"), Note, "side note", "t2"))
  trace.record(TraceEvent::new(TaskId::new("a"), Completed, "done", "t3"))
  debug_inspect(trace.event_count(), content="3")
  guard trace.latest_for(TaskId::new("a")) is Some(latest) else {
    fail("expected latest event")
  }
  debug_inspect(latest.message, content="\"done\"")
  debug_inspect(latest.timestamp, content="\"t3\"")
  debug_inspect(
    trace.latest_for(TaskId::new("missing")) is None,
    content="true",
  )
}

///|
test "markdown and json export include core fields" {
  let graph = sample_graph()
  guard graph.plan() is Ok(plan) else { fail("expected plan") }
  let trace = Trace::new()
  trace.record(
    TraceEvent::new(TaskId::new("collect_papers"), Planned, "queued", "t0"),
  )
  let markdown = graph.to_markdown(plan, trace)
  let json = graph.to_json(plan, trace)
  debug_inspect(markdown.contains("collect_papers"), content="true")
  debug_inspect(markdown.contains("Trace"), content="true")
  debug_inspect(json.contains("\"order\""), content="true")
  debug_inspect(json.contains("collect_papers"), content="true")
  debug_inspect(json.contains("\"dependencies\""), content="true")
  debug_inspect(json.contains("\"inputs\""), content="true")
  debug_inspect(json.contains("paper_index.md"), content="true")
  debug_inspect(json.contains("research"), content="true")
  debug_inspect(json.contains("\"trace\""), content="true")
  debug_inspect(json.contains("\"schema_version\""), content="false")
}

///|
test "mermaid export includes nodes and dependencies" {
  let graph = sample_graph()
  guard graph.to_mermaid() is Ok(mermaid) else { fail("expected Mermaid") }
  debug_inspect(mermaid.has_prefix("flowchart TD"), content="true")
  debug_inspect(
    mermaid.contains("collect_papers: Collect papers"),
    content="true",
  )
  debug_inspect(mermaid.contains("task_0 --> task_2"), content="true")
}

///|
test "mermaid export validates and escapes labels" {
  let graph = FlowGraph::new()
  let _ = graph.add_task(TaskNode::new("quoted", "Read \"notes\" & compare"))
  guard graph.to_mermaid() is Ok(mermaid) else { fail("expected Mermaid") }
  debug_inspect(
    mermaid.contains("&quot;notes&quot; &amp; compare"),
    content="true",
  )

  let invalid = FlowGraph::new()
  let _ = invalid.add_task(TaskNode::new("a", "A"))
  let _ = invalid.add_dependency(TaskId::new("a"), TaskId::new("missing"))
  debug_inspect(
    invalid.to_mermaid() is Err(MissingDependencyEndpoint(_)),
    content="true",
  )
}

///|
test "safe snapshots do not expose graph or trace arrays" {
  let graph = sample_graph()
  let tasks = graph.tasks_snapshot()
  tasks[0].outputs.push("mutated.txt")
  tasks.push(TaskNode::new("external", "External"))
  debug_inspect(graph.task_count(), content="6")
  guard graph.find_task(TaskId::new("collect_papers")) is Some(original) else {
    fail("expected original task")
  }
  debug_inspect(original.outputs.length(), content="1")
  original.outputs.push("also-mutated.txt")
  guard graph.find_task(TaskId::new("collect_papers")) is Some(unchanged) else {
    fail("expected unchanged task")
  }
  debug_inspect(unchanged.outputs.length(), content="1")

  let dependencies = graph.dependencies_snapshot()
  dependencies.push({
    before: TaskId::new("external"),
    after: TaskId::new("collect_papers"),
  })
  debug_inspect(graph.dependency_count(), content="5")

  guard graph.plan() is Ok(plan) else { fail("expected plan") }
  let plan_copy = plan.snapshot()
  let _ = plan_copy.order.pop()
  let _ = plan_copy.batches[0].pop()
  debug_inspect(plan.order.length(), content="6")
  debug_inspect(plan.batches[0].length(), content="2")

  let trace = Trace::new()
  trace.record(
    TraceEvent::new(TaskId::new("collect_papers"), Planned, "queued", "t0"),
  )
  let events = trace.events_snapshot()
  events.push(TraceEvent::new(TaskId::new("external"), Note, "local", "t1"))
  debug_inspect(trace.event_count(), content="1")
}

///|
test "adding a task detaches caller-owned metadata arrays" {
  let graph = FlowGraph::new()
  let outputs = ["result.json"]
  let node = TaskNode::new("a", "A").with_outputs(outputs)
  let _ = graph.add_task(node)
  outputs.push("mutated.json")
  guard graph.find_task(TaskId::new("a")) is Some(stored) else {
    fail("expected stored task")
  }
  debug_inspect(stored.outputs.length(), content="1")
}

///|
test "checked status transitions reject invalid jumps and allow retry" {
  let graph = FlowGraph::new()
  let _ = graph.add_task(TaskNode::new("a", "A"))
  debug_inspect(
    graph.transition_status(TaskId::new("a"), Succeeded)
    is Err(InvalidStatusTransition(_, _, _)),
    content="true",
  )
  debug_inspect(
    graph.transition_status(TaskId::new("a"), Running) is Ok(_),
    content="true",
  )
  debug_inspect(
    graph.transition_status(TaskId::new("a"), Failed("temporary")) is Ok(_),
    content="true",
  )
  debug_inspect(
    graph.transition_status(TaskId::new("a"), Ready) is Ok(_),
    content="true",
  )
  debug_inspect(
    graph.transition_status(TaskId::new("missing"), Ready)
    is Err(TransitionMissingTask(_)),
    content="true",
  )
}

///|
test "runnable tasks use graph status and block failed predecessors" {
  let graph = sample_graph()
  guard graph.runnable_tasks() is Ok(first) else {
    fail("expected runnable tasks")
  }
  debug_inspect(first.length(), content="2")
  let _ = graph.update_status(TaskId::new("collect_papers"), Succeeded)
  let _ = graph.update_status(
    TaskId::new("prepare_dataset"),
    Failed("missing data"),
  )
  guard graph.runnable_tasks() is Ok(next) else {
    fail("expected runnable tasks")
  }
  debug_inspect(next.length(), content="1")
  debug_inspect(next[0].value, content="\"extract_claims\"")
}

///|
test "snapshot validation rejects stale plans and unknown trace tasks" {
  let graph = sample_graph()
  guard graph.plan() is Ok(plan) else { fail("expected plan") }
  let trace = Trace::new()
  trace.record(TraceEvent::new(TaskId::new("missing"), Note, "orphan", "t0"))
  debug_inspect(
    graph.validate_trace(trace) is Err(UnknownTraceTask(_)),
    content="true",
  )
  let _ = graph.add_task(TaskNode::new("new_task", "New task"))
  debug_inspect(
    graph.validate_plan(plan) is Err(StaleExecutionPlan),
    content="true",
  )
  debug_inspect(
    graph.to_json_checked(plan, trace) is Err(StaleExecutionPlan),
    content="true",
  )
}

///|
test "json snapshot is versioned structured and valid for control characters" {
  let graph = FlowGraph::new()
  let control = '\u{0001}'
  let _ = graph.add_task(
    TaskNode::new("a", "A").with_status(Failed("bad \{control} value")),
  )
  let trace = Trace::new()
  guard graph.snapshot_json(trace) is Ok(json) else {
    fail("expected JSON snapshot")
  }
  debug_inspect(@json.valid(json), content="true")
  debug_inspect(json.contains("\"schema_version\": 1"), content="true")
  debug_inspect(json.contains("\"status_kind\":\"failed\""), content="true")
  debug_inspect(
    json.contains("\"status_reason\":\"bad \\u0001 value\""),
    content="true",
  )
}

///|
test "empty graph produces a valid checked snapshot" {
  let graph = FlowGraph::new()
  let trace = Trace::new()
  guard graph.snapshot_json(trace) is Ok(json) else {
    fail("expected empty snapshot")
  }
  debug_inspect(@json.valid(json), content="true")
  let expected = "{\n" +
    "  \"schema_version\": 1,\n" +
    "  \"order\": [],\n" +
    "  \"batches\": [],\n" +
    "  \"tasks\": [],\n" +
    "  \"dependencies\": [],\n" +
    "  \"trace\": []\n" +
    "}\n"
  debug_inspect(json == expected, content="true")
}
