# MoonFlowGraph

MoonFlowGraph 是一个用 MoonBit 实现的轻量级任务图与 provenance trace 库，面向科研自动化、实验复现和 Agent 工作流编排。

它解决的问题很具体：当一个科研或 Agent 流程被拆成多个子任务时，开发者需要清楚描述“哪些任务先做、哪些任务可以并行、每一步产生了什么证据、最后如何生成可复现记录”。MoonFlowGraph 不负责调用模型或执行命令，而是提供这层可验证、可导出的任务图基础设施。

## 适用人群

- 需要把科研实验拆成数据准备、文献分析、baseline、指标比较、报告撰写等步骤的开发者。
- 正在构建 Agent 系统，但希望先获得一个可测试的任务图和执行追踪组件的人。
- 希望用 MoonBit 编写工程基础库，而不是只做一次性 demo 的比赛评审或开发者。

## 核心能力

- 定义任务节点：id、标题、描述、输入、输出、标签和状态。
- 定义依赖边：表达 `before -> after` 的执行约束。
- DAG 校验：检查缺失任务、缺失依赖端点、循环依赖。
- 执行规划：生成拓扑顺序和可并行批次。
- 状态管理：更新任务状态，查询任务数量、依赖数量、前驱、后继和当前 ready 任务。
- Provenance trace：按追加顺序记录事件，并支持按任务过滤。
- 导出结果：生成 Markdown 报告和 JSON 快照，便于实验日志、Agent handoff 或评审验收。

## 边界

MoonFlowGraph 不是完整 Agent runtime。当前版本刻意不做这些事情：

- 不调用 LLM API。
- 不执行 shell 命令。
- 不管理分布式调度。
- 不保存密钥或凭证。
- 不提供 UI 或数据库持久化。

这样的边界让项目更容易在比赛周期内做扎实：核心目标是“可复现任务图 + 可审计执行追踪”，而不是把完整科研 Agent 框架一次性做完。

## 快速运行

需要本机已安装 MoonBit 工具链，并确保 `moon` 在 `PATH` 中。

```bash
moon check
moon test
moon run cmd/demo
```

也可以运行仓库内脚本：

```bash
bash run_check.sh
bash run_demo.sh
```

## Demo 工作流

示例构造了一个科研/Agent 自动化流程：

```text
collect_papers   prepare_dataset
      |                 |
      v                 v
extract_claims    run_baseline
      \                 /
       v               v
          compare_metrics -> write_report
```

第一批 `collect_papers` 和 `prepare_dataset` 可以并行；第二批 `extract_claims` 和 `run_baseline` 可以并行；之后汇合到 `compare_metrics`，最后进入 `write_report`。

demo 会输出：

- Markdown 报告：包含执行顺序、并行批次、任务元数据、状态和 trace。
- JSON 快照：包含任务、依赖、批次、输入输出、标签和 trace 事件，便于后续工具消费。

## API 示例

```moonbit
let graph = FlowGraph::new()
let _ = graph.add_task(TaskNode::new("collect_papers", "Collect papers"))
let _ = graph.add_task(TaskNode::new("write_report", "Write report"))
let _ = graph.add_dependency(TaskId::new("collect_papers"), TaskId::new("write_report"))

guard graph.plan() is Ok(plan) else { fail("invalid graph") }
```

常用查询：

```moonbit
let _ = graph.update_status(TaskId::new("collect_papers"), Succeeded)
let _ = graph.predecessors(TaskId::new("write_report"))
let _ = graph.successors(TaskId::new("collect_papers"))
let _ = graph.ready_tasks([TaskId::new("collect_papers")])
```

## 验收标准

- `moon check` 通过。
- `moon test` 通过，当前覆盖 DAG 构建、重复任务、缺失依赖、循环检测、拓扑排序、并行批次、状态更新、ready 任务、trace 查询和导出。
- `moon run cmd/demo` 可以直接运行，并展示 Markdown 与 JSON 两种结果。
- README、中文 README、设计文档和路线图能清楚说明项目价值、边界和后续方向。

## 比赛定位

MoonFlowGraph 适合作为 MoonBit 工程基础设施方向的参赛项目。它吸收了科研自动化和 Agent 工作流中的任务编排经验，但当前实现是原创 MoonBit 项目，不直接移植任何上游项目代码。若未来引入外部算法、测试数据或实现片段，应在文档中补充来源和许可证。

## 许可证

Apache-2.0。详见 [LICENSE](LICENSE)。
