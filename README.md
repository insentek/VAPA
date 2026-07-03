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
| **战略对齐 / 规模 / 贡献角色** | 组织 | Issue Fields | `Align`、`Size`、`Shaper`、`Reviewed By`、`Validator`、`Sponsor` |
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

| 标签 | 颜色 | 触发条件 |
|------|------|---------|
| `status: draft` | `#ededed` | 提案创建时自动标记 |
| `status: refining` | `#fbca04` | 收到实质性讨论后 |
| `status: ready-for-review` | `#0e8a16` | 提案人主动声明 |
| `status: in-review` | `#006b75` | Steward确认启动评审 |
| `status: approved` | `#0075ca` | 评审通过 |
| `status: in-progress` | `#e4e669` | Agent开始执行 |
| `status: in-validation` | `#d93f0b` | 等待验收 |
| `status: done` | `#0e8a16` | 验收通过，关闭 |
| `status: deferred` | `#ededed` | 延期，保留价值 |
| `status: rejected` | `#b60205` | 已拒绝，附原因 |

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
> 提案人自己还没想清楚的部分。诚实列出，邀请讨论。

- [ ] [问题 1]
- [ ] [问题 2]

---

## 🔗 相关上下文
- 相关 Issue：#
- 参考资料：
- 历史讨论：

---

## 📊 提案元数据
| 字段 | 内容 |
|------|------|
| 提案人 | @username |
| 提案日期 | YYYY-MM-DD |
| 期望进入 Roadmap | YYYY-QX |
| 预估规模 | S / M / L / XL |
```

---

#### 模板二：Problem Statement（问题陈述）

> 文件路径：`.github/ISSUE_TEMPLATE/problem-statement.md`

```markdown
---
name: "🔍 Problem Statement"
about: "陈述一个你观察到的问题。不需要提供解法。"
labels: "status: draft"
type: "Problem"
---

# [问题标题：描述现象，不含解法]

---

## 我观察到了什么
[具体的现象描述。第一人称。何时、何地、何人、发生了什么]

## 这个问题影响了谁
[受影响的角色]

## 我认为这可能很重要，因为
[连接到团队愿景或战略重心。或者说明为什么即使没有明确对齐也值得关注]

## 我目前不知道的
[诚实列出你的信息盲区。这有助于他人贡献补充]

## 我期望从这个 Issue 得到什么
- [ ] 确认：其他人是否也观察到了类似现象
- [ ] 讨论：问题的根本原因是什么
- [ ] 提案：有人愿意基于此发起 Feature Proposal 吗
```

---

#### 模板三：Vision Amendment（愿景修正）

> 文件路径：`.github/ISSUE_TEMPLATE/vision-amendment.md`

```markdown
---
name: "🧭 Vision Amendment"
about: "对 VISION.md 提出修正。注意：此类提案门槛更高。"
labels: "status: draft"
type: "Vision Amendment"
---

# [修正标题：说明你想改变什么]

---

## 当前表述
> 引用 VISION.md 中你认为需要修正的原文

```
[原文]
```

## 提议修改为
```
[新表述]
```

## 修改的理由
[为什么现有表述不再准确或不再适用？]

## 如果不修改，可能产生的误导
[现有表述可能导致哪些方向错误的提案或决策？]

## 我认为需要讨论的核心问题
- [ ] [核心问题 1]
- [ ] [核心问题 2]
```

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

### 5.1 Agent 执行准入检查

在将提案委托给 AI Coding Agent 之前，必须完成以下准入检查。此检查由提案人或验收志愿者执行，以评论形式记录在 Issue 中。

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

### 5.2 人机协作分工原则

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

### 5.3 PR 规范

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

## Claude Code Skills

本仓库包含两个 Claude Code 项目级 Skill，安装后可通过 `/` 命令直接调用：

| 命令 | 用途 | 示例 |
|------|------|------|
| `/vapa-init` | 检测当前仓库的 VAPA 配置（Issue Type / Issue Fields / 状态标签 / 模板 / VISION.md）；不存在则初始化，存在则询问更新或重置 | `/vapa-init` |
| `/vapa-proposal [subject] [type]` | AI 辅助创建提案：推断类型、澄清缺失信息、生成完整正文、预览确认后提交；不带参数时列出待定提案 | `/vapa-proposal "让VAPA变得可被一键安装，推广VAPA的理念和SKILLS"` |

Skill 文件位于：

```
.claude/skills/
├── vapa-init/
│   ├── SKILL.md
│   ├── scripts/
│   │   ├── vapa-init.sh
│   │   └── vapa-labels.py
│   └── references/
│       ├── experiment.md
│       ├── feature-proposal.md
│       ├── problem-statement.md
│       └── vision-amendment.md
└── vapa-proposal/
    ├── SKILL.md
    ├── scripts/
    │   └── vapa-proposal.sh
    └── references/
        ├── experiment.md
        ├── feature-proposal.md
        ├── problem-statement.md
        └── vision-amendment.md
```

### 前置条件

- 已安装并登录 [GitHub CLI (`gh`)](https://cli.github.com/)，且对目标仓库有写权限。
- `/vapa-init` 依赖 Python 3 与 `requests` 库。

### 调用方式

在 Claude Code 中输入 `/vapa-init` 或 `/vapa-proposal` 即可触发对应 Skill。两个 Skill 均设置为仅手动调用（`disable-model-invocation: true`），不会自动执行。

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
