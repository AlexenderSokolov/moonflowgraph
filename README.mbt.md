# MoonFlowGraph Executable Examples

```mbt check
///|
test {
  let graph = FlowGraph::new()
  guard graph.add_task(TaskNode::new("collect_papers", "Collect papers"))
    is Ok(_) else {
    fail("expected first task")
  }
  guard graph.add_task(TaskNode::new("write_report", "Write report")) is Ok(_) else {
    fail("expected second task")
  }
  guard graph.add_dependency(
      TaskId::new("collect_papers"),
      TaskId::new("write_report"),
    )
    is Ok(_) else {
    fail("expected dependency")
  }
  guard graph.plan() is Ok(plan) else { fail("expected valid graph") }
  debug_inspect(plan.order.length(), content="2")
  debug_inspect(plan.batches.length(), content="2")
  guard graph.roots() is Ok(roots) else { fail("expected roots") }
  guard graph.leaves() is Ok(leaves) else { fail("expected leaves") }
  debug_inspect(roots[0].value, content="\"collect_papers\"")
  debug_inspect(leaves[0].value, content="\"write_report\"")
  guard graph.to_mermaid() is Ok(mermaid) else { fail("expected Mermaid") }
  debug_inspect(mermaid.contains("task_0 --> task_1"), content="true")
  let trace = Trace::new()
  guard graph.to_json_checked(plan, trace) is Ok(snapshot) else {
    fail("expected checked JSON")
  }
  debug_inspect(snapshot.contains("\"schema_version\": 1"), content="true")
}
```
