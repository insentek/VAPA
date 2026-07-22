# VAPA Framework
### Vision-driven · Async · Proposal-based · Agent-executed

*一套为AI时代重新设计的去中心化团队协作框架*

---

> **当前版本**：v0.1-draft　｜　**状态**：Open for Discussion　｜　**许可**：CC BY-SA 4.0

---

## Table of Contents

- Why VAPA [<sup>1</sup>](#why-vapa)
- Core Philosophy [<sup>2</sup>](#core-philosophy)
- System Architecture [<sup>3</sup>](#system-architecture)
- Layer 1 · Vision — 北极星系统 [<sup>4</sup>](#layer-1--vision--北极星系统)
- Layer 2 · Proposal — 提案体系 [<sup>5</sup>](#layer-2--proposal--提案体系)
- Layer 3 · Review — 评审机制 [<sup>6</sup>](#layer-3--review--评审机制)
- Layer 4 · Roadmap — 战略可视化 [<sup>7</sup>](#layer-4--roadmap--战略可视化)
- Layer 5 · Execution — Agent执行协议 [<sup>8</sup>](#layer-5--execution--agent执行协议)
- Layer 6 · Contribution — 贡献可见性系统 [<sup>9</sup>](#layer-6--contribution--贡献可见性系统)
- Getting Started [<sup>10</sup>](#getting-started)
- Design Risks [<sup>11</sup>](#design-risks)
- Contributing to VAPA [<sup>12</sup>](#contributing-to-vapa)

---

## Why VAPA

传统敏捷开发建立在一个隐含假设之上：**思考与执行需要分离**。PO负责定义"做什么"，工程师负责"怎么做"。这个分工在人力资源有限的时代有其合理性。

但这个假设正在失效。

当AI Coding Agent可以承担大量执行工作，团队真正稀缺的资源不再是实现能力，而是**判断力**——判断什么问题值得解决，判断什么方向值得押注。

VAPA的核心主张是：

```
在AI时代，每一个团队成员都应当是意义的判断者
               而不只是任务的执行者
```

VAPA不是对敏捷的修补，而是一次根本性的重新设计。它借鉴开源社区的RFC文化、学术界的同行评审机制，以及GitHub原生的协作工具，构建一套**去中心化、异步、提案驱动**的协作系统。

---

## Core Philosophy

VAPA建立在四条不可妥协的原则之上。所有流程设计均从这四条原则推导而来。

| # | 原则 | 含义 |
|---|------|------|
| 1 | **贡献不等于执行** | 发现问题、完善提案、质疑假设，与写代码具有同等价值 |
| 2 | **规范是自由的前提** | 开放提案的权利，必须以清晰的规范为代价 |
| 3 | **AI是实现者，人是判断者** | Agent负责执行，人负责决定什么值得执行 |
| 4 | **透明度替代汇报** | 贡献的可见性来自公开记录，而非向上汇报 |

---

## System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     VAPA Framework                       │
├─────────────────────────────────────────────────────────┤
│                                                          │
│   ┌──────────┐                                          │
│   │  VISION  │  ← 北极星：所有提案的合法性来源            │
│   └────┬─────┘                                          │
│        │ 对齐检验                                        │
│   ┌────▼─────────────────────────────┐                  │
│   │           PROPOSAL               │                  │
│   │  draft → refining → ready        │  ← 任何人可发起   │
│   └────┬─────────────────────────────┘                  │
│        │ 完整性门槛                                       │
│   ┌────▼─────┐                                          │
│   │  REVIEW  │  ← Steward + 成员评审委员会               │
│   └────┬─────┘                                          │
│        │ 准入决策                                         │
│   ┌────▼─────┐                                          │
│   │ ROADMAP  │  ← 战略优先级排序                         │
│   └────┬─────┘                                          │
│        │ 执行委托                                         │
│   ┌────▼─────────────────────────────┐                  │
│   │           EXECUTION              │                  │
│   │     AI Agent + Human Review      │  ← 人机协作       │
│   └────┬─────────────────────────────┘                  │
│        │ 验收归档                                         │
│   ┌────▼──────────┐                                     │
│   │ CONTRIBUTION  │  ← 贡献可见性记录                    │
│   └───────────────┘                                     │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

---

## Layer 1 · Vision — 北极星系统

### 概述

Vision层是整个VAPA系统的根基。所有提案的合法性，都来自于与Vision的对齐关系。

Vision不是公司使命陈述，而是**可操作的坐标系**——它必须具体到可以被用来判断一个提案是否值得做。

### VISION.md 规范

`VISION.md` 存放于仓库根目录，受保护分支管理，仅可通过提案流程修改。

```markdown
# Team Vision

## 我们在解决谁的什么问题
[具体人群] 在 [具体场景] 中面临 [具体痛点]
我们选择现在解决这个问题，因为 [时机判断]

## 我们明确不做什么
> 边界与排除项同样重要。清晰的"不做"防止提案无限扩张。

- 不做：[排除项A，及原因]
- 不做：[排除项B，及原因]

## 当前阶段战略重心（每季度更新）
| 重心 | 描述 | 权重 |
|------|------|------|
| 重心 A | [描述] | 40% |
| 重心 B | [描述] | 35% |
| 重心 C | [描述] | 25% |

## 12个月后，成功看起来是什么样子
> 必须是可观测的具体状态，不接受"用户满意度提升"类表述

- [可观测状态 1]
- [可观测状态 2]

## 当前开放问题
> 团队尚未想清楚的部分。这些是最欢迎提案探索的领域。

- [ ] [开放问题 A]
- [ ] [开放问题 B]

---
_最后更新：YYYY-MM-DD　｜　下次评审：YYYY-MM-DD_
_修改历史见：[<sup>13</sup>](./VISION-CHANGELOG.md)_
```

### Vision Amendment（愿景修正提案）

修改 `VISION.md` 本身是合法的，但门槛高于普通提案：

- 必须使用 `Vision Amendment` Issue Type
- 讨论期延长至 **14天**（普通提案为7天）
- 评审需要 **全员参与**，而非抽样委员会
- 通过门槛：无明确反对，而非简单多数

---

## Layer 2 · Proposal — 提案体系

### 2.1 Issue 元数据结构

VAPA 使用三层原生 GitHub 机制来管理提案元数据：

| 维度 | 层级 | 机制 | 说明 |
|---|---|---|---|
| **提案类型** | 组织 | Issue Type | `Feature` / `Problem` / `Vision Amendment` / `Experiment` / `Improvement` / `Technical Debt` / `Research` |
| **战略对齐 / 规模 / 贡献角色** | 组织 | Issue Fields | `Align`、`Size`、`Shaper`、`Reviewed By`、`Validator`、`Sponsor`；其中贡献角色字段为单选，选项来自组织成员 |
| **提案人** | Issue | 作者 | 提案 Issue 的创建者即为 Proposer，不单独设置字段 |
| **提案状态** | 仓库 | Label | `status: *` 生命周期标签 |

#### 提案状态 `status:`

```
draft → refining → ready-for-review → in-review → approved
                                                 → deferred
                                                 → rejected
                                    (approved) →
                        in-progress → in-validation → done
```

| 标签 | 颜色 | 说明 |
|------|------|------|
| `status: draft` | `#ededed` | 草稿，欢迎讨论 |
| `status: refining` | `#fbca04` | 讨论中，正在完善 |
| `status: ready-for-review` | `#0e8a16` | 提案人认为已完整，等待评审 |
| `status: in-review` | `#006b75` | 正式评审进行中 |
| `status: approved` | `#0075ca` | 评审通过，进入 Roadmap |
| `status: in-progress` | `#e4e669` | Agent 正在执行实现 |
| `status: in-validation` | `#d93f0b` | 实现完成，等待验收 |
| `status: done` | `#0e8a16` | 验收通过，已关闭 |
| `status: deferred` | `#c5def5` | 延期，保留价值，等待时机 |
| `status: rejected` | `#b60205` | 已拒绝，见评论中的拒绝理由 |

> **注意**：旧版 VAPA 用标签表达类型（`type:`）、对齐（`align:`）、规模（`size:`）和贡献角色（`contrib:`）。当前版本已迁移到更原生的 **Issue Type** 和 **Issue Fields**，只有状态流保留为标签。 `/vapa-init` 会在重置时清理旧版标签。
---

### 2.2 Issue 模板

#### 模板一：Feature Proposal（功能提案）

> 文件路径：`.github/ISSUE_TEMPLATE/feature-proposal.md`

```markdown
---
name: "🚀 Feature Proposal"
about: "提出一个新能力或改善提案"
labels: "status: draft"
type: "Feature"
---
<!-- NOTE: Keep in sync with the copy in the sibling skill's references/ directory. -->

# [提案标题：动词 + 对象 + 价值]
> 示例：「为订单列表增加批量导出能力，使运营人员摆脱逐条下载」

---

## 🔭 愿景对齐声明
> 本提案支撑 VISION.md 中的哪个战略重心？
> 请引用具体表述，而非泛泛而谈。

**对齐的战略重心**：[引用 VISION.md 原文]
**对齐的逻辑**：[一到两句话说明]

如果本提案无法明确对齐现有战略重心，请在此说明仍然值得做的理由：
> [说明]

---

## 📍 问题陈述

**谁在遭受这个问题？**
[具体的角色/用户群体，不接受"所有用户"这类表述]

**他们的真实处境是什么？**
[描述当前状态。不要跳到解法。用第一人称陈述你观察到的现象]

**问题有多严重或频繁？**
[可观测的证据。定性描述可接受，但要具体]
> 示例：「每周约有3名运营人员在群里询问如何批量获取数据」

**如果不解决，会怎样？**
[不作为的代价。连接到团队或用户的真实损失]

---

## 💡 提案内容

**核心想法**
[用非技术语言描述。目标读者是不了解技术实现的人。一段话]

**这不是什么**
[明确排除项。防止范围在执行过程中蔓延]
- 不包括：
- 不包括：

---

## ✅ 验收标准

> 完成后，我们如何知道这个提案成功了？
> 必须是可观测、可验证的状态。

- [ ] [验收标准 1]
- [ ] [验收标准 2]
- [ ] [验收标准 3]

---

## 🤔 开放性问题

> 团队尚未想清楚、需要讨论的部分。

- [ ] [开放问题 1]
- [ ] [开放问题 2]

---

## 📎 附加信息

- **建议 Size 字段**：S / M / L / XL
- **提案人**：@username
- **相关提案**：#issue-number
```

---

#### 模板二：Problem Statement（问题陈述）

> 文件路径：`.github/ISSUE_TEMPLATE/problem-statement.md`

```markdown
---
name: problem-statement
about: 纯问题陈述，不含解法
labels: "status: draft"
type: "Problem"
---
<!-- NOTE: Keep in sync with the copy in the sibling skill's references/ directory. -->

# [问题标题：谁在什么场景下遇到什么]
> 示例：「运营人员每周需要手动整理3份Excel报表，耗时2小时」

---

## 📍 问题观察

**受影响的角色**
[具体的用户/角色，不接受"所有人"]

**具体场景**
[在什么时间、什么工具、什么流程中发生]

**现象描述**
[用第一人称陈述你观察到的。不要跳到原因或解法]

**频率/规模**
[多久发生一次？影响多少人？]

---

## 🔍 已知的上下文

**尝试过什么**
[目前已有的 workaround 或临时方案]

**相关系统/流程**
[这个问题涉及哪些现有功能或流程]

---

## 🤔 为什么值得现在关注

**不做会怎样**
[3个月、6个月、12个月后的代价]

**与战略的关系**
[这个问题是否指向 VISION.md 中某个开放问题？]

---

## 📎 附加信息

- **提案人**：@username
- **相关提案**：#issue-number
- **建议 Align 字段**：core / adjacent / exploratory
```

---

#### 模板三：Vision Amendment（愿景修正）

> 文件路径：`.github/ISSUE_TEMPLATE/vision-amendment.md`

```markdown
---
name: vision-amendment
about: 对 VISION.md 的修正提案（最高门槛）
labels: "status: draft"
type: "Vision Amendment"
---
<!-- NOTE: Keep in sync with the copy in the sibling skill's references/ directory. -->

# [修正标题：调整什么 + 为什么现在]
> 示例：「将Q3战略重心从'用户增长'调整为'留存优化'，因为数据反馈显示获客成本已不可持续」

---

## 📍 当前 VISION.md 的哪个部分

**引用原文**
> [粘贴需要修改的 VISION.md 原文段落]

**所在章节**
[例如：当前阶段战略重心 / 我们明确不做什么 / 12个月后的成功标准]

---

## 💡 修正内容

**修改后的文本**
> [新的表述]

**修改理由**
[为什么现有表述不再适用？发生了什么变化？]

---

## 🔍 影响评估

**对现有提案的影响**
[哪些已批准的提案可能需要重新评估？]

**对执行中工作的影响**
[是否有正在进行的执行需要调整方向？]

---

## ✅ 通过标准

> Vision Amendment 需要全员参与，14天讨论期，无明确反对方可通过。

- [ ] 已通知所有团队成员
- [ ] 讨论期已满14天
- [ ] 无明确反对意见

---

## 📎 附加信息

- **提案人**：@username
- **上次 Vision 评审日期**：YYYY-MM-DD
```

---

#### 模板四：Experiment（实验验证）

> 文件路径：`.github/ISSUE_TEMPLATE/experiment.md`

```markdown
---
name: experiment
about: 假设验证型提案
labels: "status: draft"
type: "Experiment"
---
<!-- NOTE: Keep in sync with the copy in the sibling skill's references/ directory. -->

# [实验标题：验证什么假设 + 预期结果]
> 示例：「验证'简化注册流程'假设：将步骤从5步减至2步可提升30%转化率」

---

## 🔬 假设陈述

**我们假设**
[清晰的、可证伪的陈述]

**如果假设成立**
[我们会看到什么具体现象？]

**如果假设不成立**
[我们会看到什么？Plan B 是什么？]

---

## 📊 验证方法

**实验设计**
[A/B测试？原型验证？用户访谈？数据回溯？]

**成功指标**
[必须是可量化的。例如：「注册转化率从12%提升至15%」]

**实验周期**
[预计需要多长时间获得可信结论？]

---

## 📍 与战略的关系

**对齐的重心**
[引用 VISION.md 中的战略重心]

**为什么是现在做这个实验**
[时机判断]

---

## ✅ 验收标准

- [ ] [实验完成的具体标志]
- [ ] [结论记录的位置]
- [ ] [后续行动决策]

---

## 📎 附加信息

- **建议 Size 字段**：S / M / L / XL
- **提案人**：@username
```

> **注意**：`Research` 类型 Issue 没有单独模板，直接复用 `feature-proposal.md` 模板，将“问题陈述”改写为研究问题、“提案内容”改写为预期产出与方法、“验收标准”改写为可交付成果标准即可。

---

### 2.3 提案质量自检清单

在将 `status` 从 `draft` 更新为 `ready-for-review` 之前，提案人应完成以下自检：

```
□ 问题陈述中，有具体的人，不是泛指"用户"
□ 问题陈述中，有可观测的证据，不只是主观感受
□ 验收标准是可验证的状态，不是意图或方向
□ 明确写出了"这不是什么"
□ 愿景对齐声明引用了 VISION.md 的具体表述
□ 我已经回应了评论区中所有实质性问题
```

---

## Layer 3 · Review — 评审机制

### 3.1 Steward 角色

Steward 是 VAPA 中唯一的常设角色，但它**不是决策者**，而是**流程守护者**。

```
Steward 的职责
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ 确保提案评审按时发生
✓ 在评审中代表战略对齐视角提出质疑
✓ 维护 VISION.md 的内部一致性
✓ 维护标签规范，确保流程可追溯

Steward 没有的权力
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✗ 单独否决任何提案
✗ 决定提案的优先级排序
✗ 修改他人提案的内容

轮值机制
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
- 周期：每月轮换
- 资格：完成过至少一次完整提案流程的成员
- 交接：必须撰写当月 Steward 日志
```

### 3.2 评审委员会构成

每次正式评审的委员会由以下成员构成：

```
┌─────────────────────────────────────────┐
│             评审委员会                   │
├─────────────────────────────────────────┤
│  当值 Steward        × 1（必须参与）      │
│  随机抽取成员         × 2（系统随机）      │
│  领域志愿者           × 1（自愿报名）      │
├─────────────────────────────────────────┤
│  提案人               × 1（旁听，不投票） │
└─────────────────────────────────────────┘
```

### 3.3 评审核心问题

评审不是"我喜不喜欢这个提案"，而是协作回答以下五个问题：

```
Q1  这个提案解决的问题是真实存在的吗？
    ——证据是否充分，是否有人能反驳"这个问题不存在"？

Q2  验收标准是否可观测、可验证？
    ——验收者是否能在不询问提案人的情况下独立判断是否完成？

Q3  这个提案与当前战略重心的关系是什么？
    ——是 core / adjacent / exploratory？为什么现在做？

Q4  是否有重大的未知风险或隐藏依赖？
    ——有没有提案人没有考虑到的技术、产品或资源约束？

Q5  现在是做这个的合适时机吗？
    ——即使提案本身是好的，时序上是否正确？
```

### 3.4 评审结果与处理

| 结果 | 后续动作 |
|------|---------|
| **Approved** | 标记 `status: approved`，进入 Roadmap |
| **Deferred** | 标记 `status: deferred`，注明重启条件 |
| **Rejected** | 标记 `status: rejected`，**必须**写明：①拒绝理由 ②重新提案的条件（如果存在） |

> **关于拒绝的设计原则**：拒绝一个提案不是终点。评审委员会有义务说明：在什么条件下，这个提案可以重新被接受。

---

## Layer 4 · Roadmap — 战略可视化

### GitHub Projects 配置

VAPA 使用 GitHub Projects 作为 Roadmap 的承载工具，推荐配置三个视图：

#### Board 视图（执行看板）

```
│   Backlog    │  This Cycle  │  Agent Running  │  Validation  │  Done  │
│  (approved)  │              │                 │              │        │
```

#### Roadmap 视图（战略时间线）

- 按季度展示 `status: approved` 的提案
- 颜色编码对应 `Align` Issue Field
- 时间跨度由 `Size` Issue Field 驱动估算

#### Table 视图（贡献追踪）

自定义字段：

| 字段 | 类型 | 说明 |
|------|------|------|
| `Shaper` | Single Select (org members) | 实质贡献的完善者 |
| `Reviewed By` | Single Select (org members) | 正式评审参与者 |
| `Validator` | Single Select (org members) | 验收执行者 |
| `Sponsor` | Single Select (org members) | 战略背书人 |
| `Align` | Single Select | core / adjacent / exploratory / off-track |
| `Size` | Single Select | S / M / L / XL |

---

## Layer 5 · Execution — Agent执行协议

Agent 加速执行，也会加速错误假设的扩散。因此 VAPA 的执行层不是一个“把 Issue 丢给 AI”的步骤，而是一套**可审计、可追踪、可返工**的执行编排协议。

VAPA 推荐使用多 Agent 执行：不同 Agent 分别承担上下文整理、计划、实现、测试、审计和 PR 整理。对于小型提案，也可以由单一 Session inline 执行，但仍必须按相同的阶段产出执行记录。

```
approved
  → readiness-check
  → context-ready
  → plan-ready
  → implemented
  → tested
  → audit-ready
```

`audit-ready` 表示 `vapa-exec` 已完成实现与测试，并生成了 PR 草稿。此后进入 `vapa-audit` 进行独立审计，审计结论为 `READY_FOR_PR`、`NEEDS_REVISION` 或 `BLOCKED_FOR_HUMAN_DECISION`。

### 5.1 Agent 执行准入检查

在将提案委托给 AI Coding Agent 之前，必须完成以下准入检查。此检查由提案人、Steward 或验收志愿者执行，以评论形式记录在 Issue 中。

未通过准入检查时，Agent 不得开始实现，只能生成执行缺口报告。

```markdown
## Agent 执行准入检查

### 技术准入
- [ ] 验收标准已转化为具体的测试用例描述
- [ ] 依赖的上下文（相关代码、API、数据结构）已在 Issue 中标注或链接
- [ ] 边界约束已明确（不能修改什么，必须兼容什么）
- [ ] `Size: M` 及以上的提案已拆解为 `Size: S` 的子 Issue

### 信息准入
- [ ] 提案人确认当前技术环境与提案撰写时一致
- [ ] 没有新出现的信息使该提案的核心假设失效

### 输出规范
- [ ] Agent 需要产出的文件 / 接口 / 行为已有明确描述
- [ ] 预期的 PR 结构和关联方式已说明（关联 Issue 编号）

准入检查人：@username　｜　检查日期：YYYY-MM-DD
```

### 5.2 执行工作区

每次 Agent 执行必须创建一个项目内工作区，用于保存可提交的执行账本：

```text
.vapa/vapa-exec-<issue-id>/workspace/
  issue.json
  comments/
  images/
  issue-brief.md
  source-map.md
  readiness-report.md
  VAPA_EXEC_PLAN.md
  VAPA_EXEC_LOG.md
  TEST_REPORT.md
  PR_DRAFT.md
```

`VAPA_AUDIT.md` 由 `vapa-audit` skill 在 `vapa-exec` 完成后独立生成，不放在执行工作区初始清单中。

该目录默认可以提交到 GitHub，用于追踪 Agent 如何理解、计划、实现和验收一个提案。团队可以在其中复盘 Agent 的决策质量，改进后续提案模板、执行协议和技能设计。

执行工作区不应包含密钥、私有用户数据、生产数据导出或无法公开的第三方资料。如 Issue 或评论中包含敏感信息，Agent 必须在 `source-map.md` 中记录引用来源，并在提交前进行脱敏或改用摘要。

### 5.3 多 Agent 执行角色

| 角色 | 职责 | 主要产物 |
|------|------|---------|
| Orchestrator | 检查准入、创建工作区、分派阶段、决定返工或升级给人类 | `readiness-report.md` |
| Context Agent | 抓取 Issue、评论、图片、相关文档和仓库上下文 | `issue-brief.md`、`source-map.md` |
| Planner Agent | 将验收标准转化为可执行计划和测试策略 | `VAPA_EXEC_PLAN.md` |
| Implementation Agent | 按计划实现，记录关键判断和偏离点 | 代码变更、`VAPA_EXEC_LOG.md` |
| Test Agent | 根据验收标准设计并运行验证 | `TEST_REPORT.md` |
| PR Agent | 整理 PR 标题、正文、验收映射和贡献记录 | `PR_DRAFT.md` |

独立审计由 `vapa-audit` skill 承担，不属于 `vapa-exec` 的执行角色。

不同 Size 使用不同执行策略：

| Size | 执行模式 |
|------|---------|
| S | 可使用单 Session inline 执行，但必须保留计划、日志、测试和审计产物 |
| M | 推荐至少分离 Planner / Implementation / Audit 角色 |
| L | 必须拆解为 Size: S 的子 Issue 后执行 |
| XL | 必须回到 Proposal / Review 层重新拆分，不允许直接委托 Agent |

### 5.4 执行计划与记录

`VAPA_EXEC_PLAN.md` 必须包含：

- 目标与非目标
- 验收标准到实现步骤的映射
- 预期文件影响范围
- 测试策略和命令
- 已知风险与回滚方式
- 需要人类判断的节点

`VAPA_EXEC_LOG.md` 必须记录：

- 实际修改了哪些文件
- 与计划不一致的地方及原因
- Agent 自行做出的关键判断
- 阻塞、返工和人工确认记录

### 5.5 独立审计与验收

实现完成后，必须进入独立审计。审计可以由专门的 `vapa-audit` skill 执行，也可以由另一个 Agent Session 承担；对于 Size: S 的低风险提案，可以由同一 Session 切换到 Audit 角色执行，但必须明确记录审计结论。

审计结论只能是三种之一：

| 结论 | 含义 | 后续动作 |
|------|------|---------|
| `READY_FOR_PR` | 实现、测试和 PR 草稿足以进入人工验收 | 标记 `status: in-validation` |
| `NEEDS_REVISION` | 存在可由 Agent 修复的问题 | 回到 Implementation / Test 阶段 |
| `BLOCKED_FOR_HUMAN_DECISION` | 需要人类判断方向、范围或验收标准 | 暂停执行并在 Issue 中说明阻塞点 |

Agent audit gives confidence. Human validation gives authority.

### 5.6 人机协作分工原则

```
直接委托 Agent
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
· 根据明确规格实现功能代码
· 根据验收标准生成测试用例
· 对结构清晰的代码进行重构
· 生成文档、注释、变更日志初稿

Agent 执行，人工决策节点
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
· 验收标准的边缘情况判断
· 实现过程中发现原提案假设有误时的方向决策
· 跨提案的影响范围评估

人工主导，Agent 不参与决策
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
· 愿景层的方向取舍
· 拒绝一个已通过评审的提案
· 修改已通过评审的验收标准
· 判断一个问题是否值得解决
```

### 5.7 PR 规范

Agent 提交或辅助提交的 PR，必须遵循以下规范：

```markdown
## PR 标题格式
[Issue编号] 动词 + 对象描述
示例：[#42] Add batch export for order list

## PR Body 必填字段
### 关联提案
Closes #[Issue编号]

### 实现说明
[Agent 或人工对实现方式的简要说明]

### 验收标准对照
| 验收标准 | 实现位置 | 状态 |
|---------|---------|------|
| [标准1] | [文件/函数] | ✅ |
| [标准2] | [文件/函数] | ✅ |

### 已知局限
[如果有无法完全覆盖的边缘情况，必须在此说明]

### 执行记录
- VAPA workspace: `.vapa/vapa-exec-<issue-id>/workspace/`
- Audit verdict: READY_FOR_PR / NEEDS_REVISION / BLOCKED_FOR_HUMAN_DECISION
```

---

## Layer 6 · Contribution — 贡献可见性系统

> VAPA 不使用 KPI 一词。KPI 暗示从上到下的管控逻辑。
> VAPA 追求的是**贡献可见性**——让每个人的真实贡献被团队看见。

### 6.1 贡献类型地图

```
发现类贡献
  · 提出高质量的 Problem Statement
  · 在他人提案的讨论中发现关键盲点
  · 提供来自用户的第一手观察证据

塑造类贡献
  · 将模糊想法完善为符合规范的可执行提案
  · 在讨论中提出使提案质量实质性提升的问题
  · 将 L / XL 提案合理拆解为可执行子提案

执行类贡献
  · 配合 Agent 完成实现，处理 Agent 无法独立解决的部分
  · 独立完成 Agent 不适合处理的实现工作

验收类贡献
  · 设计高质量的验收方案
  · 执行验收并给出清晰的通过 / 不通过结论
  · 在验收过程中发现验收标准之外的重要问题

知识类贡献
  · 撰写提案完成后的复盘文档
  · 维护 VISION.md、模板、规范文档
  · 帮助新成员理解并使用 VAPA 流程
```

### 6.2 贡献积分参考

> 积分系统是贡献可见性的量化辅助工具，不是排名竞争机制。

| 贡献角色 | 基础分 | 质量乘数 | 乘数来源 |
|---------|-------|---------|---------|
| Proposer（提案人） | 10 | × 0.5 – 2.0 | 初稿质量（修改轮次越少，乘数越高） |
| Shaper（塑造者） | 5 | × 0.5 – 2.0 | 提案人在关闭时公开评价 |
| Reviewer（评审人） | 3 | × 1.0（固定） | — |
| Validator（验收者） | 5 | × 0.5 – 2.0 | 是否发现标准外的重要问题 |
| Sponsor（背书人） | 2 | × 1.0（固定） | — |

**关键设计**

```
被拒绝的提案：提案人仍获得基础分的 50%
——我们鼓励提案，不惩罚失败。

Problem Statement 被他人转化为 Feature Proposal：
原 Problem 提案人获得 Shaper 基础分。
```

### 6.3 月度团队健康度报告

每月由 Steward 生成并公示：

```
团队贡献健康度指标
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
提案参与广度    参与提案成员 / 总成员数
提案通过率      进入 Roadmap 的提案 / 提交评审的提案
验收质量        验收后重开的 Issue / 总验收次数（越低越好）
讨论深度        平均每提案有效评论数
愿景对齐度      `Align = core` + `Align = adjacent` 的提案 / 全部通过提案

本月贡献者展示（按类型，不以分数排序）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔭 最佳问题发现者
🏗️  最佳提案塑造者
🎯 最佳验收执行者
📚 最佳知识贡献者
```

---

## Agent Skills

本仓库的可安装技能位于 `skills/`，可通过 Skills CLI 安装到本地 Agent 环境：

```bash
npx skills add insentek/VAPA
```

| Skill | 用途 |
|------|------|
| `vapa-init` | 检测当前仓库的 VAPA 配置（Issue Type / Issue Fields / 状态标签 / 模板 / VISION.md）；不存在则初始化，存在则询问更新或重置 |
| `vapa-proposal` | AI 辅助创建提案：推断类型、澄清缺失信息、生成完整正文、预览确认后提交；不带参数时列出待定提案 |
| `vapa-review` | 通读提案 Issue 完整正文与全部评论，对照评审五问与质量自检清单生成结构化评审评论并自动发布，按阶段同步 `status:*` 标签；仅提供建议，不做通过/拒绝决策 |
| `vapa-exec` | 对已批准提案进行可追踪 Agent 执行，生成 `.vapa/vapa-exec-<issue-id>/workspace/` 执行账本 |
| `vapa-audit` | 独立审计 Agent 实现、测试、范围、可追踪性与 PR 准备状态 |

### 前置条件

- 已安装并登录 [GitHub CLI (`gh`)](https://cli.github.com/)，且对目标仓库有写权限。
- `vapa-init` 依赖 Python 3 与 `requests` 库。
- 组织级 Issue Type 与 Issue Fields 需由组织管理员预先创建；`/vapa-init` 会检查它们是否存在。若贡献者字段（`Shaper`、`Reviewed By`、`Validator`、`Sponsor`）尚未绑定组织成员，可运行 `/vapa-init --init-fields` 进行初始化。

---

## Getting Started

### 对于团队负责人

```
Week 1  打地基
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
□ 组织全团队共同起草 VISION.md 第一版
  （不要一个人写，每个人都需要经历过这个讨论）
□ 在仓库中创建 Issue 模板（见 Layer 2.2）
□ 按规范创建全套标签
□ 指定第一任 Steward（建议由最熟悉业务方向的人开始）

Week 2  第一批提案
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
□ 要求每位成员提交至少 1 个 Problem Statement
  （降低门槛，不强制要求 Feature Proposal）
□ 用这批 Issue 测试讨论和标签流程
□ 收集对模板和规范的反馈，及时迭代

Month 1 末  第一次完整循环
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
□ 选出 2-3 个最成熟的提案进行正式评审
□ 让至少 1 个提案走完完整流程直至验收关闭
□ 团队复盘：流程中什么在起作用，什么需要调整

Quarter 1 末  系统迭代
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
□ 更新 VISION.md（基于过去 3 个月的学习）
□ 精简标签体系（删除没用到的，补充新需要的）
□ 发布第一份团队贡献可见性报告
□ 评估 Steward 轮换机制是否运转正常
```

### 对于普通成员

```
你可以做的第一件事：
提交一个 Problem Statement。

不需要有解法。
不需要完美。
只需要你真实观察到的一个问题。
```

---

## Design Risks

VAPA 的设计者认为，诚实地暴露系统的脆弱点，比假装它没有缺陷更重要。

### Risk 1：VISION.md 空洞化

**风险描述**：愿景文档随时间演变为无人真正相信的口号，失去对提案的过滤能力。

**对抗措施**：季度强制评审；允许任何人对愿景提案；Steward 有义务在评审中援引 VISION.md。

### Risk 2：提案通货膨胀

**风险描述**：贡献积分驱动"为提案而提案"，噪音压过信号。

**对抗措施**：被拒绝提案仍得 50% 基础分（降低对失败的恐惧，但不鼓励无意义尝试）；质量乘数使高质量初稿比反复修改更划算。

### Risk 3：验收疲劳

**风险描述**：Agent 实现质量不稳定，验收者频繁面对需要大量人工修正的结果，导致流程堵塞。

**对抗措施**：严格的 Agent 执行准入检查；`Size: S` 作为 Agent 执行的标准单元，大提案必须拆解。

### Risk 4：系统性冷漠

**风险描述**：团队成员将 VAPA 视为额外的行政负担，而非真正的协作工具。

**对抗措施**：第一个月只要求 Problem Statement，不强制 Feature Proposal；让一个真实提案快速走完全流程，制造可见的成功案例。

---

## Contributing to VAPA

VAPA 本身是一个开放演化的框架。对本文档的任何修改建议，请按照 Vision Amendment 流程提交 Issue。

```
本仓库即 VAPA 实践的第一个试验场。
提出对 VAPA 本身的改进提案，也是对 VAPA 最好的验证。
```

---

<div align="center">

**VAPA Framework** · v0.1-draft

*为AI时代重新设计协作*

提交提案 [<sup>14</sup>](../../issues/new/choose) · 查看 Roadmap [<sup>15</sup>](../../projects) · 阅读 VISION.md [<sup>16</sup>](./VISION.md)

---

Licensed under CC BY-SA 4.0 [<sup>17</sup>](https://creativecommons.org/licenses/by-sa/4.0/)

</div>
