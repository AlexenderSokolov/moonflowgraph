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
  guard graph.roots() is Ok(roots) else { fail("expected roots") }
  guard graph.leaves() is Ok(leaves) else { fail("expected leaves") }
  debug_inspect(roots[0].value, content="\"collect_papers\"")
  debug_inspect(leaves[0].value, content="\"write_report\"")
  guard graph.to_mermaid() is Ok(mermaid) else { fail("expected Mermaid") }
  debug_inspect(mermaid.contains("task_0 --> task_1"), content="true")
}
```
