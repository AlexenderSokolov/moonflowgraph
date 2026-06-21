///|
fn main {
  let graph = @moonflowgraph.FlowGraph::new()
  let _ = graph.add_task(
    @moonflowgraph.TaskNode::new("collect_papers", "Collect papers")
    .with_description("Search and collect papers for the research question.")
    .with_outputs(["paper_index.md"])
    .with_tags(["research", "input"]),
  )
  let _ = graph.add_task(
    @moonflowgraph.TaskNode::new("extract_claims", "Extract claims")
    .with_description("Extract claims, assumptions, and evaluation metrics.")
    .with_inputs(["paper_index.md"])
    .with_outputs(["claims.json"])
    .with_tags(["agent", "analysis"]),
  )
  let _ = graph.add_task(
    @moonflowgraph.TaskNode::new("run_baseline", "Run baseline")
    .with_description("Run the reproducible baseline experiment.")
    .with_inputs(["claims.json"])
    .with_outputs(["baseline_metrics.json"])
    .with_tags(["experiment"]),
  )
  let _ = graph.add_task(
    @moonflowgraph.TaskNode::new("compare_metrics", "Compare metrics")
    .with_description("Compare baseline and candidate metrics.")
    .with_inputs(["baseline_metrics.json"])
    .with_outputs(["comparison.md"])
    .with_tags(["evaluation"]),
  )
  let _ = graph.add_task(
    @moonflowgraph.TaskNode::new("write_report", "Write report")
    .with_description("Produce a Markdown handoff report.")
    .with_inputs(["comparison.md"])
    .with_outputs(["report.md"])
    .with_tags(["report"]),
  )

  let _ = graph.add_dependency(@moonflowgraph.TaskId::new("collect_papers"), @moonflowgraph.TaskId::new("extract_claims"))
  let _ = graph.add_dependency(@moonflowgraph.TaskId::new("extract_claims"), @moonflowgraph.TaskId::new("run_baseline"))
  let _ = graph.add_dependency(@moonflowgraph.TaskId::new("run_baseline"), @moonflowgraph.TaskId::new("compare_metrics"))
  let _ = graph.add_dependency(@moonflowgraph.TaskId::new("compare_metrics"), @moonflowgraph.TaskId::new("write_report"))

  let plan = match graph.plan() {
    Ok(plan) => plan
    Err(err) => {
      println("failed to build plan: \{err.message()}")
      return
    }
  }
  let trace = @moonflowgraph.Trace::new()
  trace.record(@moonflowgraph.TraceEvent::new(@moonflowgraph.TaskId::new("collect_papers"), Planned, "queued by demo", "t0"))
  trace.record(@moonflowgraph.TraceEvent::new(@moonflowgraph.TaskId::new("collect_papers"), Started, "paper search started", "t1"))
  trace.record(@moonflowgraph.TraceEvent::new(@moonflowgraph.TaskId::new("collect_papers"), Completed, "paper index generated", "t2"))

  println(graph.to_markdown(plan, trace))
}
