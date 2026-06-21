# MoonFlowGraph Executable Examples

```mbt check
///|
test {
  let graph = FlowGraph::new()
  let _ = graph.add_task(TaskNode::new("collect_papers", "Collect papers"))
  let _ = graph.add_task(TaskNode::new("write_report", "Write report"))
  let _ = graph.add_dependency(TaskId::new("collect_papers"), TaskId::new("write_report"))
  guard graph.plan() is Ok(plan) else { fail("expected valid graph") }
  debug_inspect(plan.order.length(), content="2")
  debug_inspect(plan.batches.length(), content="2")
}
```
