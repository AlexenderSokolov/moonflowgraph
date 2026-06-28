///| Event type for provenance trace.
pub(all) enum TraceEventType {
  Planned
  Started
  Completed
  FailedEvent
  SkippedEvent
  Note
} derive(Eq, Debug)

///| A single trace event. Timestamp is a string so users can choose wall-clock,
/// logical, or deterministic timestamps.
pub(all) struct TraceEvent {
  task_id : TaskId
  event_type : TraceEventType
  message : String
  timestamp : String
} derive(Eq, Debug)

///| Mutable trace log.
pub(all) struct Trace {
  mut events : Array[TraceEvent]
} derive(Debug)

///| Build an empty trace log.
pub fn Trace::new() -> Trace {
  { events: [] }
}

///| Build a trace event.
pub fn TraceEvent::new(
  task_id : TaskId,
  event_type : TraceEventType,
  message : String,
  timestamp : String,
) -> TraceEvent {
  { task_id, event_type, message, timestamp }
}

///| Append an event.
pub fn Trace::record(self : Trace, event : TraceEvent) -> Unit {
  self.events.push(event)
}

///| Return events in append order.
pub fn Trace::events(self : Trace) -> Array[TraceEvent] {
  self.events
}

///| Return events for a single task id in append order.
pub fn Trace::events_for(self : Trace, task_id : TaskId) -> Array[TraceEvent] {
  let out : Array[TraceEvent] = []
  for event in self.events {
    if event.task_id == task_id {
      out.push(event)
    }
  }
  out
}

///| Render a compact Markdown summary of trace events.
pub fn Trace::summary_markdown(self : Trace) -> String {
  let out = StringBuilder()
  out <+ "## Trace Summary\n\n"
  if self.events.is_empty() {
    out <+ "- No trace events recorded.\n"
    return out.to_string()
  }
  for event in self.events {
    out <+ "- `\{event.timestamp}` \{event.task_id.value} "
    out <+ "\{event.event_type.label()}: \{event.message}\n"
  }
  out.to_string()
}

///| Return a stable human-readable task status label.
pub fn TaskStatus::label(self : TaskStatus) -> String {
  match self {
    Pending => "pending"
    Ready => "ready"
    Running => "running"
    Succeeded => "succeeded"
    Failed(reason) => "failed: \{reason}"
    Skipped(reason) => "skipped: \{reason}"
  }
}

///| Return a stable human-readable event type label.
pub fn TraceEventType::label(self : TraceEventType) -> String {
  match self {
    Planned => "planned"
    Started => "started"
    Completed => "completed"
    FailedEvent => "failed"
    SkippedEvent => "skipped"
    Note => "note"
  }
}

///| Return a readable diagnostic message for a graph error.
pub fn GraphError::message(self : GraphError) -> String {
  match self {
    DuplicateTask(id) => "duplicate task: \{id.value}"
    DuplicateDependency(dep) =>
      "duplicate dependency: \{dep.before.value} -> \{dep.after.value}"
    MissingTask(id) => "missing task: \{id.value}"
    MissingDependencyEndpoint(dep) =>
      "dependency endpoint missing: \{dep.before.value} -> \{dep.after.value}"
    CycleDetected(path) => {
      let rendered = format_id_list(path, " -> ")
      "cycle detected: \{rendered}"
    }
  }
}

fn format_id_list(ids : Array[TaskId], sep : String) -> String {
  let out = StringBuilder()
  for i = 0; i < ids.length(); i = i + 1 {
    if i > 0 {
      out.write_string(sep)
    }
    out.write_string(ids[i].value)
  }
  out.to_string()
}
