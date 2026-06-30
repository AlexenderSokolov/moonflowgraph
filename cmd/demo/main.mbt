///|
fn require_graph_step(
  result : Result[Unit, @moonflowgraph.GraphError],
  action : String,
) -> Unit {
  match result {
    Ok(_) => ()
    Err(err) => abort("\{action}: \{err.message()}")
  }
}

///|
fn require_transition(
  result : Result[Unit, @moonflowgraph.StatusTransitionError],
  action : String,
) -> Unit {
  match result {
    Ok(_) => ()
    Err(err) => abort("\{action}: \{err.message()}")
  }
}

///|
fn main {
  let graph = @moonflowgraph.FlowGraph::new()
  require_graph_step(
    graph.add_task(
      @moonflowgraph.TaskNode::new("collect_papers", "Collect papers")
      .with_description(
        "Record the search scope and collect papers for the research question.",
      )
      .with_outputs(["search_protocol.md", "paper_index.md"])
      .with_tags(["research", "input"]),
    ),
    "add collect_papers",
  )
  require_graph_step(
    graph.add_task(
      @moonflowgraph.TaskNode::new("prepare_dataset", "Prepare dataset")
      .with_description("Freeze the dataset snapshot used by the baseline run.")
      .with_outputs(["dataset.parquet", "dataset_card.md"])
      .with_tags(["data", "input"]),
    ),
    "add prepare_dataset",
  )
  require_graph_step(
    graph.add_task(
      @moonflowgraph.TaskNode::new("extract_claims", "Extract claims")
      .with_description(
        "Map paper claims and assumptions to measurable evaluation criteria.",
      )
      .with_inputs(["search_protocol.md", "paper_index.md"])
      .with_outputs(["claims.json"])
      .with_tags(["agent", "analysis"]),
    ),
    "add extract_claims",
  )
  require_graph_step(
    graph.add_task(
      @moonflowgraph.TaskNode::new("run_baseline", "Run baseline")
      .with_description(
        "Run the baseline with a recorded configuration and random seed.",
      )
      .with_inputs(["dataset.parquet"])
      .with_outputs(["baseline_config.json", "baseline_metrics.json"])
      .with_tags(["experiment"]),
    ),
    "add run_baseline",
  )
  require_graph_step(
    graph.add_task(
      @moonflowgraph.TaskNode::new("compare_metrics", "Compare metrics")
      .with_description(
        "Compare results against the criteria extracted from the literature.",
      )
      .with_inputs(["claims.json", "baseline_metrics.json"])
      .with_outputs(["comparison.md"])
      .with_tags(["evaluation"]),
    ),
    "add compare_metrics",
  )
  require_graph_step(
    graph.add_task(
      @moonflowgraph.TaskNode::new("write_report", "Write report")
      .with_description("Produce a Markdown handoff report.")
      .with_inputs(["comparison.md"])
      .with_outputs(["report.md"])
      .with_tags(["report"]),
    ),
    "add write_report",
  )

  require_graph_step(
    graph.add_dependency(
      @moonflowgraph.TaskId::new("collect_papers"),
      @moonflowgraph.TaskId::new("extract_claims"),
    ),
    "connect collect_papers -> extract_claims",
  )
  require_graph_step(
    graph.add_dependency(
      @moonflowgraph.TaskId::new("prepare_dataset"),
      @moonflowgraph.TaskId::new("run_baseline"),
    ),
    "connect prepare_dataset -> run_baseline",
  )
  require_graph_step(
    graph.add_dependency(
      @moonflowgraph.TaskId::new("extract_claims"),
      @moonflowgraph.TaskId::new("compare_metrics"),
    ),
    "connect extract_claims -> compare_metrics",
  )
  require_graph_step(
    graph.add_dependency(
      @moonflowgraph.TaskId::new("run_baseline"),
      @moonflowgraph.TaskId::new("compare_metrics"),
    ),
    "connect run_baseline -> compare_metrics",
  )
  require_graph_step(
    graph.add_dependency(
      @moonflowgraph.TaskId::new("compare_metrics"),
      @moonflowgraph.TaskId::new("write_report"),
    ),
    "connect compare_metrics -> write_report",
  )

  let plan = match graph.plan() {
    Ok(plan) => plan
    Err(err) => {
      println("failed to build plan: \{err.message()}")
      return
    }
  }
  require_transition(
    graph.transition_status(
      @moonflowgraph.TaskId::new("collect_papers"),
      Running,
    ),
    "start collect_papers",
  )
  require_transition(
    graph.transition_status(
      @moonflowgraph.TaskId::new("collect_papers"),
      Succeeded,
    ),
    "complete collect_papers",
  )
  require_transition(
    graph.transition_status(
      @moonflowgraph.TaskId::new("prepare_dataset"),
      Running,
    ),
    "start prepare_dataset",
  )
  require_transition(
    graph.transition_status(
      @moonflowgraph.TaskId::new("prepare_dataset"),
      Succeeded,
    ),
    "complete prepare_dataset",
  )
  require_transition(
    graph.transition_status(
      @moonflowgraph.TaskId::new("extract_claims"),
      Running,
    ),
    "start extract_claims",
  )
  require_transition(
    graph.transition_status(
      @moonflowgraph.TaskId::new("extract_claims"),
      Succeeded,
    ),
    "complete extract_claims",
  )
  require_transition(
    graph.transition_status(@moonflowgraph.TaskId::new("run_baseline"), Running),
    "start run_baseline",
  )
  require_transition(
    graph.transition_status(
      @moonflowgraph.TaskId::new("run_baseline"),
      Succeeded,
    ),
    "complete run_baseline",
  )
  require_transition(
    graph.transition_status(
      @moonflowgraph.TaskId::new("compare_metrics"),
      Ready,
    ),
    "mark compare_metrics ready",
  )

  let trace = @moonflowgraph.Trace::new()
  trace.record(
    @moonflowgraph.TraceEvent::new(
      @moonflowgraph.TaskId::new("collect_papers"),
      Planned,
      "search query and inclusion criteria recorded",
      "t0",
    ),
  )
  trace.record(
    @moonflowgraph.TraceEvent::new(
      @moonflowgraph.TaskId::new("prepare_dataset"),
      Planned,
      "dataset source and target split recorded",
      "t0",
    ),
  )
  trace.record(
    @moonflowgraph.TraceEvent::new(
      @moonflowgraph.TaskId::new("collect_papers"),
      Started,
      "literature search started with the recorded scope",
      "t1",
    ),
  )
  trace.record(
    @moonflowgraph.TraceEvent::new(
      @moonflowgraph.TaskId::new("prepare_dataset"),
      Started,
      "dataset snapshot and checksum are being prepared",
      "t1",
    ),
  )
  trace.record(
    @moonflowgraph.TraceEvent::new(
      @moonflowgraph.TaskId::new("collect_papers"),
      Completed,
      "paper index and search protocol saved",
      "t2",
    ),
  )
  trace.record(
    @moonflowgraph.TraceEvent::new(
      @moonflowgraph.TaskId::new("prepare_dataset"),
      Completed,
      "dataset snapshot saved with checksum",
      "t2",
    ),
  )
  trace.record(
    @moonflowgraph.TraceEvent::new(
      @moonflowgraph.TaskId::new("extract_claims"),
      Started,
      "claim extraction started from the recorded paper index",
      "t2",
    ),
  )
  trace.record(
    @moonflowgraph.TraceEvent::new(
      @moonflowgraph.TaskId::new("run_baseline"),
      Started,
      "baseline started from the frozen dataset snapshot",
      "t2",
    ),
  )
  trace.record(
    @moonflowgraph.TraceEvent::new(
      @moonflowgraph.TaskId::new("extract_claims"),
      Completed,
      "claims mapped to assumptions and evaluation metrics",
      "t3",
    ),
  )
  trace.record(
    @moonflowgraph.TraceEvent::new(
      @moonflowgraph.TaskId::new("run_baseline"),
      Completed,
      "baseline metrics saved with configuration and seed",
      "t3",
    ),
  )
  trace.record(
    @moonflowgraph.TraceEvent::new(
      @moonflowgraph.TaskId::new("compare_metrics"),
      Note,
      "comparison criteria satisfied; report can cite both evidence branches",
      "t4",
    ),
  )

  match graph.to_markdown_checked(plan, trace) {
    Ok(markdown) => println(markdown)
    Err(err) => {
      println("failed to render Markdown: \{err.message()}")
      return
    }
  }
  println("--- MERMAID ---")
  match graph.to_mermaid() {
    Ok(mermaid) => println(mermaid)
    Err(err) => println("failed to render Mermaid: \{err.message()}")
  }
  println("--- JSON ---")
  match graph.to_json_checked(plan, trace) {
    Ok(json) => println(json)
    Err(err) => println("failed to render JSON: \{err.message()}")
  }
}
