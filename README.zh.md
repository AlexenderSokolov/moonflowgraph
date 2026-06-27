# MoonFlowGraph

我在维护科研自动化插件时，经常遇到一个不太显眼、但很影响复现的问题：任务清单写在计划里，依赖关系藏在代码里，运行结果又散落在日志和临时文件中。流程短的时候还能靠记忆串起来；一旦同时包含文献检索、数据准备、baseline、指标比较和报告撰写，就很难回答三个简单的问题：下一步能做什么，哪些步骤可以并行，这次运行到底留下了哪些证据。

MoonFlowGraph 是我对这个问题的一次小范围拆解。它用 MoonBit 提供任务图、DAG 校验、执行批次和 provenance trace，只负责把流程和证据说清楚，不替调用者执行模型或命令。

## 它适合解决什么

- 把科研实验拆成可检查的步骤，并在运行前发现缺失依赖或循环依赖。
- 为 Agent 或自动化脚本生成稳定的拓扑顺序和可并行批次。
- 记录每一步的输入、输出、状态与事件，形成便于复查和交接的 Markdown/JSON 记录。

## 核心能力

- 定义任务节点：id、标题、描述、输入、输出、标签和状态。
- 定义依赖边：表达 `before -> after` 的执行约束。
- DAG 校验：检查缺失任务、缺失依赖端点、循环依赖。
- 执行规划：生成拓扑顺序和可并行批次。
- 状态管理：更新任务状态，查询任务数量、依赖数量、前驱、后继和当前 ready 任务。
- Provenance trace：按追加顺序记录事件，并支持按任务过滤。
- 导出结果：生成 Markdown 报告和 JSON 快照，便于实验日志、Agent handoff 或运行复查。

## 它刻意不做什么

MoonFlowGraph 不是完整 Agent runtime。当前版本刻意不做这些事情：

- 不调用 LLM API。
- 不执行 shell 命令。
- 不管理分布式调度。
- 不保存密钥或凭证。
- 不提供 UI 或数据库持久化。

这些能力更适合由上层 runtime 负责。MoonFlowGraph 保持在“描述计划、检查依赖、记录证据”这一层，因而可以单独测试，也容易嵌入现有工具。

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

## 一个具体例子

仓库里的 demo 模拟一次从文献和数据准备走向实验报告的流程：

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

trace 不只写“任务完成”，还会记录检索范围、数据快照、baseline 配置和比较依据。demo 最终输出：

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

## 当前状态

- `moon check` 通过。
- `moon test` 通过，当前覆盖 DAG 构建、重复任务、缺失依赖、循环检测、拓扑排序、并行批次、状态更新、ready 任务、trace 查询和导出。
- `moon run cmd/demo` 可以直接运行，并展示 Markdown 与 JSON 两种结果。
- GitHub Actions 会执行相同的检查、测试和 demo。

## 项目链接

- GitHub: <https://github.com/AlexenderSokolov/moonflowgraph>
- GitLink: <https://gitlink.org.cn/SpringBack_25/moonflowgraph>

## 开发说明

项目为原创 MoonBit 实现，参考的是通用的 DAG、workflow 和 provenance 思路，不直接移植某个上游项目。开发过程中使用了 AI 辅助代码实现、测试和文档整理；选题、功能取舍、验收与提交由项目作者负责。

## 许可证

Apache-2.0。详见 [LICENSE](LICENSE)。
