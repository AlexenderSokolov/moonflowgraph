///|
/// Validate a supplied plan and trace before rendering Markdown.
pub fn FlowGraph::to_markdown_checked(
  self : FlowGraph,
  plan : ExecutionPlan,
  trace : Trace,
) -> Result[String, SnapshotError] {
  match self.validate_snapshot(plan, trace) {
    Err(err) => Err(err)
    Ok(_) => Ok(self.to_markdown(plan, trace))
  }
}

///|
/// Build a fresh plan, validate trace references, and render Markdown.
pub fn FlowGraph::snapshot_markdown(
  self : FlowGraph,
  trace : Trace,
) -> Result[String, SnapshotError] {
  match self.plan() {
    Err(err) => Err(SnapshotGraphError(err))
    Ok(plan) => self.to_markdown_checked(plan, trace)
  }
}

///|
/// Render a graph, plan, and trace as a Markdown execution report.
///
/// This compatibility API trusts the supplied plan. New code should prefer
/// `to_markdown_checked` or `snapshot_markdown`.
pub fn FlowGraph::to_markdown(
  self : FlowGraph,
  plan : ExecutionPlan,
  trace : Trace,
) -> String {
  let out = StringBuilder()
  out <+ "# MoonFlowGraph Report\n\n"
  out <+ "## Execution Order\n\n"
  for i = 0; i < plan.order.length(); i = i + 1 {
    out <+ "\{i + 1}. \{plan.order[i].value}\n"
  }
  out <+ "\n## Parallel Batches\n\n"
  for i = 0; i < plan.batches.length(); i = i + 1 {
    out <+ "- Batch \{i + 1}: "
    let ids = join_ids(plan.batches[i], ", ")
    out.write_string(ids)
    out <+ "\n"
  }
  out <+ "\n## Tasks\n\n"
  for task in self.tasks() {
    out <+ "### \{task.id.value}: \{task.title}\n\n"
    if task.description != "" {
      out <+ "\{task.description}\n\n"
    }
    out <+ "- Status: \{task.status.label()}\n"
    let inputs = join_strings(task.inputs, ", ")
    let outputs = join_strings(task.outputs, ", ")
    let tags = join_strings(task.tags, ", ")
    out <+ "- Inputs: \{inputs}\n"
    out <+ "- Outputs: \{outputs}\n"
    out <+ "- Tags: \{tags}\n\n"
  }
  out <+ "## Trace\n\n"
  for event in trace.events() {
    out <+ "- `\{event.timestamp}` \{event.task_id.value} "
    out <+ "\{event.event_type.label()}: \{event.message}\n"
  }
  out.to_string()
}

///|
/// Validate a supplied plan and trace before rendering JSON.
pub fn FlowGraph::to_json_checked(
  self : FlowGraph,
  plan : ExecutionPlan,
  trace : Trace,
) -> Result[String, SnapshotError] {
  match self.validate_snapshot(plan, trace) {
    Err(err) => Err(err)
    Ok(_) => Ok(self.render_json(plan, trace, versioned=true))
  }
}

///|
/// Build a fresh plan, validate trace references, and render JSON.
pub fn FlowGraph::snapshot_json(
  self : FlowGraph,
  trace : Trace,
) -> Result[String, SnapshotError] {
  match self.plan() {
    Err(err) => Err(SnapshotGraphError(err))
    Ok(plan) => self.to_json_checked(plan, trace)
  }
}

///|
/// Render a compact JSON string for tooling or snapshot artifacts.
///
/// This compatibility API trusts the supplied plan. New code should prefer
/// `to_json_checked` or `snapshot_json`.
pub fn FlowGraph::to_json(
  self : FlowGraph,
  plan : ExecutionPlan,
  trace : Trace,
) -> String {
  self.render_json(plan, trace, versioned=false)
}

///|
fn FlowGraph::render_json(
  self : FlowGraph,
  plan : ExecutionPlan,
  trace : Trace,
  versioned~ : Bool,
) -> String {
  let out = StringBuilder()
  out <+ "{\n"
  if versioned {
    out <+ "  \"schema_version\": 1,\n"
  }
  out <+ "  \"order\": ["
  for i = 0; i < plan.order.length(); i = i + 1 {
    if i > 0 {
      out <+ ", "
    }
    let id = escape_json(plan.order[i].value)
    out <+ "\"\{id}\""
  }
  out <+ "],\n"
  out <+ "  \"batches\": ["
  for i = 0; i < plan.batches.length(); i = i + 1 {
    if i > 0 {
      out <+ ", "
    }
    out <+ "["
    for j = 0; j < plan.batches[i].length(); j = j + 1 {
      if j > 0 {
        out <+ ", "
      }
      let id = escape_json(plan.batches[i][j].value)
      out <+ "\"\{id}\""
    }
    out <+ "]"
  }
  out <+ "],\n"
  out <+ "  \"tasks\": ["
  for i = 0; i < self.tasks().length(); i = i + 1 {
    if i > 0 {
      out <+ ", "
    }
    let task = self.tasks()[i]
    out <+ "{"
    let id = escape_json(task.id.value)
    let title = escape_json(task.title)
    let description = escape_json(task.description)
    let status = escape_json(task.status.label())
    let status_kind = escape_json(task.status.kind())
    out <+ "\"id\":\"\{id}\","
    out <+ "\"title\":\"\{title}\","
    out <+ "\"description\":\"\{description}\","
    out <+ "\"status\":\"\{status}\","
    if versioned {
      out <+ "\"status_kind\":\"\{status_kind}\","
      out <+ "\"status_reason\":"
      match task.status.reason() {
        Some(reason) => {
          let escaped_reason = escape_json(reason)
          out <+ "\"\{escaped_reason}\""
        }
        None => out <+ "null"
      }
      out <+ ","
    }
    out <+ "\"inputs\":"
    write_json_strings(out, task.inputs)
    out <+ ",\"outputs\":"
    write_json_strings(out, task.outputs)
    out <+ ",\"tags\":"
    write_json_strings(out, task.tags)
    out <+ "}"
  }
  out <+ "],\n"
  out <+ "  \"dependencies\": ["
  for i = 0; i < self.dependencies().length(); i = i + 1 {
    if i > 0 {
      out <+ ", "
    }
    let dep = self.dependencies()[i]
    let before = escape_json(dep.before.value)
    let after = escape_json(dep.after.value)
    out <+ "{\"before\":\"\{before}\",\"after\":\"\{after}\"}"
  }
  out <+ "],\n"
  out <+ "  \"trace\": ["
  for i = 0; i < trace.events().length(); i = i + 1 {
    if i > 0 {
      out <+ ", "
    }
    let event = trace.events()[i]
    out <+ "{"
    let task_id = escape_json(event.task_id.value)
    let event_type = escape_json(event.event_type.label())
    let timestamp = escape_json(event.timestamp)
    let message = escape_json(event.message)
    out <+ "\"task_id\":\"\{task_id}\","
    out <+ "\"event_type\":\"\{event_type}\","
    out <+ "\"timestamp\":\"\{timestamp}\","
    out <+ "\"message\":\"\{message}\""
    out <+ "}"
  }
  out <+ "]\n"
  out <+ "}\n"
  out.to_string()
}

///|
/// Render a validated task graph as a Mermaid flowchart.
pub fn FlowGraph::to_mermaid(self : FlowGraph) -> Result[String, GraphError] {
  match self.validate() {
    Err(err) => Err(err)
    Ok(_) => {
      let tasks = self.tasks()
      let out = StringBuilder()
      out <+ "flowchart TD\n"
      for i = 0; i < tasks.length(); i = i + 1 {
        let label = escape_mermaid("\{tasks[i].id.value}: \{tasks[i].title}")
        out <+ "  task_\{i}[\"\{label}\"]\n"
      }
      for dep in self.dependencies() {
        let before = task_position(tasks, dep.before)
        let after = task_position(tasks, dep.after)
        out <+ "  task_\{before} --> task_\{after}\n"
      }
      Ok(out.to_string())
    }
  }
}

///|
fn write_json_strings(out : StringBuilder, values : Array[String]) -> Unit {
  out <+ "["
  for i = 0; i < values.length(); i = i + 1 {
    if i > 0 {
      out <+ ", "
    }
    let value = escape_json(values[i])
    out <+ "\"\{value}\""
  }
  out <+ "]"
}

///|
fn join_ids(ids : Array[TaskId], sep : String) -> String {
  let out = StringBuilder()
  for i = 0; i < ids.length(); i = i + 1 {
    if i > 0 {
      out.write_string(sep)
    }
    out.write_string(ids[i].value)
  }
  out.to_string()
}

///|
fn join_strings(items : Array[String], sep : String) -> String {
  if items.is_empty() {
    return "-"
  }
  let out = StringBuilder()
  for i = 0; i < items.length(); i = i + 1 {
    if i > 0 {
      out.write_string(sep)
    }
    out.write_string(items[i])
  }
  out.to_string()
}

///|
fn escape_json(s : String) -> String {
  let out = StringBuilder()
  for ch in s {
    match ch {
      '"' => out <+ "\\\""
      '\\' => out <+ "\\\\"
      '\n' => out <+ "\\n"
      '\r' => out <+ "\\r"
      '\t' => out <+ "\\t"
      _ => {
        let code = ch.to_int()
        if code < 0x20 {
          out <+ "\\u00"
          out.write_string(hex_digit(code / 16))
          out.write_string(hex_digit(code % 16))
        } else {
          out <+ "\{ch}"
        }
      }
    }
  }
  out.to_string()
}

///|
fn hex_digit(value : Int) -> String {
  match value {
    0 => "0"
    1 => "1"
    2 => "2"
    3 => "3"
    4 => "4"
    5 => "5"
    6 => "6"
    7 => "7"
    8 => "8"
    9 => "9"
    10 => "a"
    11 => "b"
    12 => "c"
    13 => "d"
    14 => "e"
    15 => "f"
    _ => abort("hex digit out of range")
  }
}

///|
fn task_position(tasks : Array[TaskNode], id : TaskId) -> Int {
  for i = 0; i < tasks.length(); i = i + 1 {
    if tasks[i].id == id {
      return i
    }
  }
  -1
}

///|
fn escape_mermaid(s : String) -> String {
  let out = StringBuilder()
  for ch in s {
    match ch {
      '&' => out <+ "&amp;"
      '"' => out <+ "&quot;"
      '\n' => out <+ " "
      '\r' => continue
      _ => out <+ "\{ch}"
    }
  }
  out.to_string()
}
