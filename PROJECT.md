# MoonFlowGraph 项目记忆

## 研究背景

MoonFlowGraph 来自维护科研自动化插件时反复遇到的问题：任务计划、代码中的实际依赖和运行后留下的证据经常分散在不同位置。流程一旦包含文献收集、数据准备、claim 抽取、baseline 运行、指标比较和报告撰写，就很难快速确认哪些步骤可以并行、一次运行用了什么输入、最终结论由哪些记录支持。

本项目将这部分能力抽象为 MoonBit 基础库，重点提供 DAG 任务图、执行规划和 provenance trace，而不是实现完整 Agent runtime。

## 基本假设

- 任务依赖可以表示为有向图，合法工作流应当是 DAG。
- 任务输入、输出和标签只做轻量字符串记录，先服务可读性和导出，不做强 schema 约束。
- trace 事件按追加顺序记录，timestamp 由调用方传入，可以是墙钟时间、逻辑时间或可复现实验编号。
- 当前服务的主要是小型科研工作流，因此内部数据结构先使用数组；图规模变大或查询成为瓶颈后再增加索引。

## 分析目标

- 帮助开发者判断一个科研/Agent 工作流是否存在缺失依赖或循环依赖。
- 给出串行拓扑顺序和可并行批次，支撑后续调度器或人工执行。
- 记录任务级事件，生成可复现的 Markdown 报告、JSON 快照和 Mermaid 任务图。
- 明确区分“任务图与追踪基础设施”和“模型调用、shell 执行、分布式调度”等更大 runtime 能力。

## 工作流程

1. 使用 `FlowGraph::new()` 创建任务图。
2. 用 `TaskNode::new()` 和 `with_*` 方法添加任务元数据。
3. 用 `add_dependency(before, after)` 添加依赖边。
4. 运行 `validate()`、`topological_sort()`、`execution_batches()` 或 `plan()` 生成可执行结构，并用 `roots()` / `leaves()` 检查工作流边界。
5. 在执行或回放过程中用 `update_status()` 更新任务状态，用 `Trace::record()` 记录事件，用 `latest_for()` 查询任务的最近记录。
6. 用 `to_markdown()`、`to_json()` 或 `to_mermaid()` 导出结果。

## 代码结构

- `flowgraph.mbt`：核心公开 API、任务节点、依赖边、DAG 校验、拓扑排序、并行批次、ready 任务查询。
- `trace.mbt`：trace 事件类型、事件记录、任务状态标签、错误消息和 trace 摘要。
- `export.mbt`：Markdown、JSON 和 Mermaid 导出。
- `flowgraph_test.mbt`：核心行为测试。
- `cmd/demo/main.mbt`：科研/Agent 工作流 demo。
- `docs/DESIGN.md`：设计边界和取舍。
- `docs/ROADMAP.md`：当前能力和后续路线。
- `README.md` / `README.zh.md`：英文与中文项目说明。

## 运行流程

```bash
moon check
moon test
moon run cmd/demo
```

`run_check.sh` 用于一键检查；`run_demo.sh` 用于运行示例。Windows 下若没有 bash，可以直接运行上面的 `moon` 命令。

## 验收标准

- `moon check` 无错误。
- `moon test` 全部通过。
- `moon run cmd/demo` 能输出并行批次、任务状态、trace、Markdown 报告、JSON 快照和 Mermaid 任务图。
- 文档能从实际问题出发说明项目动机、适用场景、非目标和 API 示例。
- 仓库不提交本地工具链 `.moon/`、构建产物 `_build/`、个人报名材料或隐私信息。

## 设计决策

- 当前内部使用数组而不是哈希表，因为目标工作流规模较小，数组实现的遍历和可变状态更直接；后续可在不改变公共 API 的前提下增加索引。
- `add_dependency` 暂不立即拒绝缺失端点，统一由 `validate()` 给出 `MissingDependencyEndpoint`，方便先构建再校验。
- `add_dependency` 立即拒绝完全相同的重复边，避免依赖计数和导出结果重复。
- cycle error 返回可读路径，例如 `a -> b -> a`，便于 CLI/demo 直接展示。
- JSON 导出先使用手写字符串生成，保证无额外依赖；后续若 MoonBit JSON 生态成熟，可替换为结构化序列化。

## 已废弃或暂缓方向

- 不继续使用 `moon-md` 作为主要参赛方向，因为 Markdown 工具方向与个人科研自动化背景关联较弱，且生态重复度更高。
- 暂缓完整记忆图或 Agent 框架，保持任务图与执行追踪这一层可以被独立理解、测试和复用。
- 暂不做 CLI 文件解析器、shell runner、模型调用和数据库持久化，这些可以作为 v0.2 之后的扩展。
