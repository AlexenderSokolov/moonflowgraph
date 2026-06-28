///| Task identifier used by the public graph API.
pub(all) struct TaskId {
  value : String
} derive(Eq, Debug)

///| Execution status tracked for each task node.
pub(all) enum TaskStatus {
  Pending
  Ready
  Running
  Succeeded
  Failed(String)
  Skipped(String)
} derive(Eq, Debug)

///| A node in a reproducible research or agent workflow.
pub(all) struct TaskNode {
  id : TaskId
  title : String
  description : String
  inputs : Array[String]
  outputs : Array[String]
  tags : Array[String]
  status : TaskStatus
} derive(Eq, Debug)

///| Directed dependency edge: `before` must finish before `after`.
pub(all) struct Dependency {
  before : TaskId
  after : TaskId
} derive(Eq, Debug)

///| A validated execution plan with serial order and parallel-ready batches.
pub(all) struct ExecutionPlan {
  order : Array[TaskId]
  batches : Array[Array[TaskId]]
} derive(Eq, Debug)

///| Graph errors retain the ids and edges needed for useful diagnostics.
pub(all) enum GraphError {
  DuplicateTask(TaskId)
  DuplicateDependency(Dependency)
  MissingTask(TaskId)
  MissingDependencyEndpoint(Dependency)
  CycleDetected(Array[TaskId])
} derive(Eq, Debug)

///| Mutable workflow graph.
pub(all) struct FlowGraph {
  mut tasks : Array[TaskNode]
  mut dependencies : Array[Dependency]
} derive(Debug)

///| Build a task id.
pub fn TaskId::new(value : String) -> TaskId {
  { value, }
}

///| Build a basic pending task.
pub fn TaskNode::new(id : String, title : String) -> TaskNode {
  {
    id: TaskId::new(id),
    title,
    description: "",
    inputs: [],
    outputs: [],
    tags: [],
    status: Pending,
  }
}

///| Add a short description.
pub fn TaskNode::with_description(self : TaskNode, description : String) -> TaskNode {
  { ..self, description }
}

///| Add input labels or artifacts.
pub fn TaskNode::with_inputs(self : TaskNode, inputs : Array[String]) -> TaskNode {
  { ..self, inputs }
}

///| Add output labels or artifacts.
pub fn TaskNode::with_outputs(self : TaskNode, outputs : Array[String]) -> TaskNode {
  { ..self, outputs }
}

///| Add topic tags.
pub fn TaskNode::with_tags(self : TaskNode, tags : Array[String]) -> TaskNode {
  { ..self, tags }
}

///| Override status.
pub fn TaskNode::with_status(self : TaskNode, status : TaskStatus) -> TaskNode {
  { ..self, status }
}

///| Create an empty flow graph.
pub fn FlowGraph::new() -> FlowGraph {
  { tasks: [], dependencies: [] }
}

///| Return a snapshot of task nodes.
pub fn FlowGraph::tasks(self : FlowGraph) -> Array[TaskNode] {
  self.tasks
}

///| Return a snapshot of dependency edges.
pub fn FlowGraph::dependencies(self : FlowGraph) -> Array[Dependency] {
  self.dependencies
}

///| Return the number of task nodes.
pub fn FlowGraph::task_count(self : FlowGraph) -> Int {
  self.tasks.length()
}

///| Return the number of dependency edges.
pub fn FlowGraph::dependency_count(self : FlowGraph) -> Int {
  self.dependencies.length()
}

///| Add a task node. Duplicate ids return `DuplicateTask`.
pub fn FlowGraph::add_task(self : FlowGraph, node : TaskNode) -> Result[Unit, GraphError] {
  if self.contains_task(node.id) {
    return Err(DuplicateTask(node.id))
  }
  self.tasks.push(node)
  Ok(())
}

///| Add a dependency edge. Duplicate edges are rejected; endpoint existence is
/// checked by `validate`.
pub fn FlowGraph::add_dependency(
  self : FlowGraph,
  before : TaskId,
  after : TaskId,
) -> Result[Unit, GraphError] {
  let dep = { before, after }
  for current in self.dependencies {
    if current == dep {
      return Err(DuplicateDependency(dep))
    }
  }
  self.dependencies.push(dep)
  Ok(())
}

///| Update the status of an existing task.
pub fn FlowGraph::update_status(
  self : FlowGraph,
  id : TaskId,
  status : TaskStatus,
) -> Result[Unit, GraphError] {
  for i = 0; i < self.tasks.length(); i = i + 1 {
    if self.tasks[i].id == id {
      self.tasks[i] = { ..self.tasks[i], status }
      return Ok(())
    }
  }
  Err(MissingTask(id))
}

///| Return immediate predecessor ids for a task.
pub fn FlowGraph::predecessors(self : FlowGraph, id : TaskId) -> Result[Array[TaskId], GraphError] {
  if !self.contains_task(id) {
    return Err(MissingTask(id))
  }
  let out : Array[TaskId] = []
  for dep in self.dependencies {
    if dep.after == id {
      out.push(dep.before)
    }
  }
  Ok(out)
}

///| Return immediate successor ids for a task.
pub fn FlowGraph::successors(self : FlowGraph, id : TaskId) -> Result[Array[TaskId], GraphError] {
  if !self.contains_task(id) {
    return Err(MissingTask(id))
  }
  Ok(self.successor_ids(id))
}

///| Return tasks whose predecessors are all in `done`.
pub fn FlowGraph::ready_tasks(self : FlowGraph, done : Array[TaskId]) -> Result[Array[TaskId], GraphError] {
  match self.validate() {
    Err(err) => Err(err)
    Ok(_) => {
      for id in done {
        if !self.contains_task(id) {
          return Err(MissingTask(id))
        }
      }
      let ready : Array[TaskId] = []
      for task in self.tasks {
        if !contains_id(done, task.id) && self.all_predecessors_consumed(task.id, done) {
          ready.push(task.id)
        }
      }
      Ok(ready)
    }
  }
}

///| Validate all edge endpoints and cycle freedom.
pub fn FlowGraph::validate(self : FlowGraph) -> Result[Unit, GraphError] {
  for dep in self.dependencies {
    if !self.contains_task(dep.before) || !self.contains_task(dep.after) {
      return Err(MissingDependencyEndpoint(dep))
    }
  }
  match self.find_cycle() {
    Some(path) => Err(CycleDetected(path))
    None => Ok(())
  }
}

///| Return a topological execution order.
pub fn FlowGraph::topological_sort(self : FlowGraph) -> Result[Array[TaskId], GraphError] {
  match self.validate() {
    Err(err) => Err(err)
    Ok(_) => {
      let consumed : Array[TaskId] = []
      let order : Array[TaskId] = []
      while order.length() < self.tasks.length() {
        let mut progressed = false
        for task in self.tasks {
          if !contains_id(order, task.id) && self.all_predecessors_consumed(task.id, consumed) {
            order.push(task.id)
            consumed.push(task.id)
            progressed = true
          }
        }
        if !progressed {
          return Err(CycleDetected(order))
        }
      }
      Ok(order)
    }
  }
}

///| Return parallel-ready batches. Tasks in the same batch have no dependencies between them.
pub fn FlowGraph::execution_batches(self : FlowGraph) -> Result[Array[Array[TaskId]], GraphError] {
  match self.validate() {
    Err(err) => Err(err)
    Ok(_) => {
      let done : Array[TaskId] = []
      let batches : Array[Array[TaskId]] = []
      while done.length() < self.tasks.length() {
        let batch : Array[TaskId] = []
        for task in self.tasks {
          if !contains_id(done, task.id) && self.all_predecessors_consumed(task.id, done) {
            batch.push(task.id)
          }
        }
        if batch.is_empty() {
          return Err(CycleDetected(done))
        }
        for id in batch {
          done.push(id)
        }
        batches.push(batch)
      }
      Ok(batches)
    }
  }
}

///| Create a full execution plan.
pub fn FlowGraph::plan(self : FlowGraph) -> Result[ExecutionPlan, GraphError] {
  match self.topological_sort() {
    Err(err) => Err(err)
    Ok(order) =>
      match self.execution_batches() {
        Err(err) => Err(err)
        Ok(batches) => Ok({ order, batches })
      }
  }
}

///| Find a task by id.
pub fn FlowGraph::find_task(self : FlowGraph, id : TaskId) -> TaskNode? {
  for task in self.tasks {
    if task.id == id {
      return Some(task)
    }
  }
  None
}

fn FlowGraph::contains_task(self : FlowGraph, id : TaskId) -> Bool {
  self.find_task(id) is Some(_)
}

fn FlowGraph::all_predecessors_consumed(
  self : FlowGraph,
  id : TaskId,
  consumed : Array[TaskId],
) -> Bool {
  for dep in self.dependencies {
    if dep.after == id && !contains_id(consumed, dep.before) {
      return false
    }
  }
  true
}

fn FlowGraph::successor_ids(self : FlowGraph, id : TaskId) -> Array[TaskId] {
  let out : Array[TaskId] = []
  for dep in self.dependencies {
    if dep.before == id {
      out.push(dep.after)
    }
  }
  out
}

fn FlowGraph::find_cycle(self : FlowGraph) -> Array[TaskId]? {
  let visiting : Array[TaskId] = []
  let visited : Array[TaskId] = []
  for task in self.tasks {
    match self.visit_for_cycle(task.id, visiting, visited) {
      Some(path) => return Some(path)
      None => continue
    }
  }
  None
}

fn FlowGraph::visit_for_cycle(
  self : FlowGraph,
  id : TaskId,
  visiting : Array[TaskId],
  visited : Array[TaskId],
) -> Array[TaskId]? {
  if contains_id(visited, id) {
    return None
  }
  if contains_id(visiting, id) {
    return Some(cycle_suffix(visiting, id))
  }
  visiting.push(id)
  for next in self.successor_ids(id) {
    match self.visit_for_cycle(next, visiting, visited) {
      Some(path) => return Some(path)
      None => continue
    }
  }
  let _ = visiting.pop()
  visited.push(id)
  None
}

fn contains_id(ids : Array[TaskId], id : TaskId) -> Bool {
  for current in ids {
    if current == id {
      return true
    }
  }
  false
}

fn cycle_suffix(ids : Array[TaskId], repeated : TaskId) -> Array[TaskId] {
  let out : Array[TaskId] = []
  let mut found = false
  for id in ids {
    if id == repeated {
      found = true
    }
    if found {
      out.push(id)
    }
  }
  out.push(repeated)
  out
}
