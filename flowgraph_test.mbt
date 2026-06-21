///|
fn sample_graph() -> FlowGraph {
  let graph = FlowGraph::new()
  let _ = graph.add_task(TaskNode::new("collect_papers", "Collect papers"))
  let _ = graph.add_task(TaskNode::new("extract_claims", "Extract claims"))
  let _ = graph.add_task(TaskNode::new("run_baseline", "Run baseline"))
  let _ = graph.add_task(TaskNode::new("compare_metrics", "Compare metrics"))
  let _ = graph.add_task(TaskNode::new("write_report", "Write report"))
  let _ = graph.add_dependency(TaskId::new("collect_papers"), TaskId::new("extract_claims"))
  let _ = graph.add_dependency(TaskId::new("extract_claims"), TaskId::new("run_baseline"))
  let _ = graph.add_dependency(TaskId::new("run_baseline"), TaskId::new("compare_metrics"))
  let _ = graph.add_dependency(TaskId::new("compare_metrics"), TaskId::new("write_report"))
  graph
}

///|
test "add task succeeds" {
  let graph = FlowGraph::new()
  let result = graph.add_task(TaskNode::new("a", "A"))
  debug_inspect(result is Ok(_), content="true")
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
test "topological sort follows dependencies" {
  let graph = sample_graph()
  let result = graph.topological_sort()
  guard result is Ok(order) else { fail("expected valid order") }
  debug_inspect(order[0].value, content="\"collect_papers\"")
  debug_inspect(order[4].value, content="\"write_report\"")
}

///|
test "parallel batches group ready tasks" {
  let graph = FlowGraph::new()
  let _ = graph.add_task(TaskNode::new("collect_papers", "Collect papers"))
  let _ = graph.add_task(TaskNode::new("collect_datasets", "Collect datasets"))
  let _ = graph.add_task(TaskNode::new("write_report", "Write report"))
  let _ = graph.add_dependency(TaskId::new("collect_papers"), TaskId::new("write_report"))
  let _ = graph.add_dependency(TaskId::new("collect_datasets"), TaskId::new("write_report"))
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
  guard result is Err(CycleDetected(path)) else { fail("expected cycle") }
  debug_inspect(path.length() >= 2, content="true")
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
test "markdown and json export include core fields" {
  let graph = sample_graph()
  guard graph.plan() is Ok(plan) else { fail("expected plan") }
  let trace = Trace::new()
  trace.record(TraceEvent::new(TaskId::new("collect_papers"), Planned, "queued", "t0"))
  let markdown = graph.to_markdown(plan, trace)
  let json = graph.to_json(plan, trace)
  debug_inspect(markdown.contains("collect_papers"), content="true")
  debug_inspect(markdown.contains("Trace"), content="true")
  debug_inspect(json.contains("\"order\""), content="true")
  debug_inspect(json.contains("collect_papers"), content="true")
}
