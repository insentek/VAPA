> **当前执行协议（2026-10-21）**：以下 v1.0 内容保留为历史设计说明。执行以 [vapa-exec](../skills/vapa-exec/SKILL.md) 及其 [状态/事件契约](../skills/vapa-exec/references/execution-state.md) 为准，尤其是下列已替换规则：
>
> - 状态采用 version 1 固定结构；`events.jsonl` 保存实际事件，phase、Worker 活跃状态、审计、集成和 tracker 标签分开记录。旧记录显式迁移，不补造历史。
> - 拆分前比较独立验收、并行或风险隔离收益与计划、测试、审计、合入成本。Issue 是交付单元，Agent 内部步骤无需各建 Issue；原有单层级、S 边界及人类批准仍保留。
> - 按依赖就绪调度，取消历史“整波合回后才解锁下一波”的屏障。前置已审计并合入、无冲突且有槽位即可启动，工作树从当前父分支建立。
> - tracker 状态标签互斥并回读；父 PR 提交后，父和全部已集成子议题进入 in-validation。关闭/done 遵循人工验收与仓库策略，不等于 Agent 完工。
> - 本地事件不逐条发布到 GitHub。协调者在实质进展时发布授权范围内的简洁汇总。
> - 执行策略不再由 Size 决定：Inline、辅助 Agent 或 tracker 拆分按工作本身选择。只有需要人单独查看、验收或隔离风险的交付才建子 Issue；Agent 内部细分与并行无需 Issue 和批准。子任务超出预估但契约不变时继续执行，不再因规模停下。取消按阶段的角色交接，返工按进展而非固定次数升级。

# VAPA 父子 Issue 执行模型设计

### 分解执行 · 双入口 · 单分支 · 缺陷回路

*vapa-exec / vapa-audit / vapa-review 修改方案*

---

> **版本**:v1.0 ｜ **状态**:已确认,待实施 ｜ **日期**:2026-07-28

---

## Table of Contents

- [背景与问题](#背景与问题)
- [设计决策总览](#设计决策总览)
- [核心模型](#核心模型)
- [完整闭环](#完整闭环)
- [逐文件修改方案](#逐文件修改方案)
- [明确不改动的部分](#明确不改动的部分)
- [已淘汰方案及原因](#已淘汰方案及原因)
- [实施顺序](#实施顺序)

---

## 背景与问题

现有 `vapa-exec` 的 Large Task Protocol 只规定了**工作区层**的父子关联(`decomposition.md` + 子 issue 回链),留下五个问题:

1. **Tracker 层无关联**:GitHub 上看不到父子层级,工作区文件是唯一记录;
2. **入口未定义**:隐含"每个子 issue 各自喂给 exec",缺少统一编排入口;
3. **PR/合并粒度未定义**:子 issue 各自开 PR 还是父 issue 统一开 PR,集成整体在哪份代码上审计,闭环在最后一公里断开;
4. **缺陷无正式通道**:验证期发现的缺陷只有"就地默默修"或"口头交代"两种下场;
5. **post-audit 改动无规则**:audit 通过后修缺陷,旧裁决即失效,但没有重审机制。

本方案在不改动非分解任务任何流程的前提下,补齐上述闭环。

---

## 设计决策总览

| # | 决策点 | 结论 | 理由 |
|---|--------|------|------|
| 1 | 父子 issue 是否关联 | 三层关联:工作区层 + tracker 层 + 状态层 | tracker 关联给人看,工作区工件是执行真相 |
| 2 | tracker 关联方式 | GitHub 原生 sub-issue 功能;非 GitHub 平台文本降级 | 层级与进度聚合免费获得,CLI 可自动化 |
| 3 | 分解深度 | **单层级**,子 issue 禁止再拆 | 递归拆分使工作区树与审计链复杂化 |
| 4 | 子 issue 批准 | 父批准覆盖 `decomposition.md` 已列子 issue(含 scope 护栏) | 避免逐个人工批准的流程重量 |
| 5 | exec 入口 | **双入口**:父 issue(编排)与子 issue(单兵)都可独立 exec/review/audit | 子 issue 出问题可单独返工,不必重跑父编排 |
| 6 | 分支模型 | **单分支**:一个父 issue 一个分支,子任务 worktree 并行、编排器合回 | 任何时刻分支上是完整整体,可端到端测试 |
| 7 | 进度同步 | **方案 A**:子 issue 详记 + 父 issue 每次阶段转换新发汇总 comment | 完整时间线,符合"透明度替代汇报" |
| 8 | 缺陷通道 | 合入前:comment + re-exec 父(方案 B);合入后:独立主 issue(方案 C) | 按缺陷"重量"分流,淘汰缺陷子 issue 方案 |
| 9 | post-audit 改动 | 触发 delta re-audit,出修订版 VAPA_AUDIT.md | 旧裁决对新代码无效 |
| 10 | 子任务并行调度 | 显式 DAG(`depends_on` / `conflicts_with`)+ 拓扑分层波次执行 | 依赖从散文推断变为机器可校验,恢复与阻塞传播精确化 |

---

## 核心模型

### 1. 双入口执行

```
exec(父issue URL)  → 编排模式:状态对账 → 按依赖调度子任务 → 集成测试 → 父级audit
exec(子issue URL)  → 单兵模式:只执行该子issue,但必须先读父工作区的
                      decomposition.md 与父计划跨任务契约
review/audit       → 父子 issue 均可独立作为对象
```

- **状态对账**:`exec(父)` 启动时以 tracker 关联 + 各子工作区 `state.json` 为准重建聚合视图;发现漂移以子工作区为准,修正并记录于 `VAPA_EXEC_LOG.md`。
- 单兵模式下本地无父工作区时,引导先跑 `exec(父)` 建立编排上下文。
- 对子 issue 的 review 发现问题时,问题归属父 issue 的分解方案,升级回父层面处理,子 issue 不得自行改向。

### 2. 单层级分解 + 人确认

- 分解深度 = 1。子 issue 执行中发现自身过大 → 停止,报 `BLOCKED_FOR_HUMAN_DECISION`,**禁止递归拆分**。
- readiness gate 阶段产出 `decomposition.md` 后,**先向人类展示拆分方案并获批**,才在 tracker 创建子 issue 并挂载父子关系。创建动作记入 `VAPA_EXEC_LOG.md`。
- 父批准覆盖 `decomposition.md` 已列出的子 issue;执行中发现清单之外的新子 issue = scope 变化 → human decision。

### 3. 单分支模型

```
分支 vapa/<父id>-<slug> (唯一分支)
  ├── 子issue 实现(顺序提交 或 worktree并行 → 编排器合回)
  ├── 缺陷修复(合入前,comment驱动)
  └── .vapa/ 全部工作区(父 + 各子)
        ↓ 全部子issue READY_TO_INTEGRATE 且合回后
  集成测试 → 父级audit → 唯一PR合入main → 所有issue统一关闭
```

- **不变量:每个被 exec 的 issue = 一个分支、一个工作区、一次 audit、一个 PR。**
- 并行机制:子任务各自在 worktree 工作,子 audit 通过(`READY_TO_INTEGRATE`)后**由编排器合回父分支**;子 Agent 不直接写父分支。
- **父工作区单写者**:父 `state.json` 与父 issue 汇总 comment 只由编排器写;子 Agent 只写自己的工作区与子 issue comment。子工作区路径互不相交,合回时 `.vapa` 几乎不冲突。
- 代价:PR 较大。缓解:`PR_DRAFT.md` 按子 issue 组织变更说明,人类可分段审查。

### 3a. DAG 并行调度

子 issue 的依赖关系显式建模为 DAG,而不是散文形式的"依赖顺序":

```markdown
### Sub-issue #43: 后端导出接口
- delivers: /api/export 端点 + 单测
- depends_on: [#41]          # 逻辑依赖:#41 的产出是 #43 的输入
- conflicts_with: [#44]      # 物理冲突:改动同一批文件,不得并行(可选)
```

编排器据此执行:

1. **入环校验**:`decomposition.md` 人确认时验证无环;
2. **拓扑分层 = 执行波次**:in-degree 为 0 的节点构成当前波,波内并行(各自 worktree),波完成后全部合回,解锁下一波;
3. **菱形等待**:多父节点必须等所有依赖合回后才启动。

与单分支模型的咬合规则:

> **波 N+1 的 worktree 从"波 N 已全部合回后的父分支"拉出。**

依赖因此不仅是逻辑顺序,还物化为代码现实(后续波的 worktree 里真实包含前序波的产出)。

两种"不能并行"分开建模:`depends_on`(逻辑依赖,顺序固定)与 `conflicts_with`(文件冲突,序列化但顺序任意)。混为一谈会过度序列化。多数文件冲突应已被"跨任务契约定义在前"消解,`conflicts_with` 是兜底。

**阻塞传播沿边走**:某节点 blocked → 沿 DAG 边可达的下游节点暂停调度,兄弟节点继续;父 issue 汇总 comment 说明波及范围。

DAG 只活在工作区(`decomposition.md` + `state.json`);GitHub 原生 sub-issue 不表达依赖,tracker 层不承载。实际分解通常很浅(3-6 节点),不要建成通用调度器:depends_on 列表 + 拓扑分层 + 环境并发上限即可。

### 4. 双向渐进进度同步(方案 A)

| 层级 | 内容 | 粒度 |
|------|------|------|
| 子 issue comment | 完整执行记录:启动(分支/工作区)、阻塞(所需决策)、测试完成、audit 裁决 | 每个有意义的阶段转换一条 |
| 父 issue comment | 浓缩进度:子 issue 编号 + 阶段结论 + 指向子 comment 的链接 | 每次转换新发一条(引用不复制) |

- **阻塞传播**:子 blocked → 父 `state.json` 标记该子项、停止调度依赖它的后续子项、父 comment 写明所需人类决策。
- 全部完成 + 父级 audit 后,父 issue 发最终汇总 comment:子 issue 裁决清单、集成测试结果、父级裁决、工作区路径。

### 5. 两级 audit

- **子级裁决 `READY_TO_INTEGRATE`**(可合回父分支);父级保留 `READY_FOR_PR`。
- **未就绪前置检查**:audit 父 issue 时若存在未 `READY_TO_INTEGRATE` 的子 issue → 返回未就绪清单,不写 `VAPA_AUDIT.md`、不动 `revision_count`——这不是正式裁决。
- **delta re-audit**:post-audit 代码改动触发增量重审(审变更部分 + 回归结论),出修订版报告;不占用 `revision_count`(缺陷修复轮由 `defect_fix_rounds` 计量)。
- `revision_count` 作用域:子工作区记子级轮次,父工作区记集成轮次,独立计数、独立触发升级。

### 6. 缺陷回路(方案 B + C)

| 时机 | 通道 | 处理 |
|------|------|------|
| 父 PR **合入前**(验证期) | 父 issue 的缺陷 comment | re-exec 父 issue 进入**缺陷修复轮**:清点新评论 → 人类确认修复清单 → 父分支修复 → 回复缺陷评论(commit + 验证证据)→ delta re-audit |
| 父 PR **合入后** | **独立主 issue**(轻量缺陷模板) | 标准 exec 流水线:自己的分支、工作区、audit、PR;正文引用来源 issue,可选挂 tracker 关联 |

边界规则:

- exec 自测发现的问题**就地修**(Step 7→6 循环不变),不建缺陷通道;
- audit `NEEDS_REVISION` 走现有修订循环,不升格为缺陷通道;
- `defect_fix_rounds` 达 3 轮仍有新缺陷 → 升级人类(说明实现或验收标准有系统性问题);
- 缺陷 issue 模板:现象 / 期望行为 / 复现步骤 / 来源(验证对象 issue + comment 链接);批准流程不变,验收标准为"现象消除且不回归"。

---

## 完整闭环

```
proposal(approved, L)
  → exec(父): readiness gate → decomposition.md →【人确认】→ 建子issue(tracker关联)
  → 编排器在父分支上按 DAG 拓扑波次调度 ── 或 ── 用户单独exec(子)
       子exec(worktree) → 子audit(READY_TO_INTEGRATE) → 编排器合回父分支(波内全部完成后开下一波)
       每阶段: 子issue详细comment + 编排器发父issue汇总comment(方案A)
  → 验证期缺陷 → comment → re-exec(父): 清点+人确认 → 父分支修复 → 回执 → delta re-audit
  → 全部子issue合回 → 集成测试 → 父级audit(前置检查) → READY_FOR_PR
  → 唯一PR合入main → 全部issue关闭 → status: in-validation
  → (合入后新缺陷 → 独立主issue,标准流水线,带父链)
```

中断恢复:任意入口(父/子/新会话)均可从 `state.json` + tracker 关联重建状态。

---

## 逐文件修改方案

### 一、`skills/vapa-exec/SKILL.md`(改动最大)

**1. state.json schema 扩展(现 81-97 行)**

非分解任务 schema 不变。分解任务父工作区增加:

```json
{
  "mode": "decomposed",
  "sub_issues": {
    "43": {"workspace": ".vapa/vapa-exec-43/", "phase": "audited", "audit": "READY_TO_INTEGRATE", "depends_on": ["41"]},
    "44": {"workspace": ".vapa/vapa-exec-44/", "phase": "implemented", "audit": null, "depends_on": []}
  },
  "integration_phase": "pending | integrating | tested",
  "defect_fix_rounds": 0
}
```

子工作区 `state.json` 增加 `"parent": "42"` 字段。新增状态对账规则(见核心模型 1)。

**2. Readiness Gate 补充(现 120-136 行)**

- 批准检查:"Issue 为 `status: approved`;或它是已批准父 issue 的 `decomposition.md` 中列出的子 issue;或用户显式授权。"
- 缺陷修复轮入口检查:枚举自上次执行以来的新缺陷评论,列出修复清单,人类确认后才进入实现。

**3. Large Task Protocol 重写(现 257-275 行)→ Decomposition Protocol**

写入七条规则:单层级分解、人确认后建 issue、批准覆盖含护栏、单分支模型、DAG 拓扑分层调度(含波间合回、沿边阻塞传播)、双入口、父工作区单写者(见核心模型 1-3a)。

**4. Git discipline 修改(现 202-206 行)**

分支规则改为"一个 issue 一个分支";补充 worktree 合回纪律(合回提交引用子 issue 编号)。

**5. Status Sync 扩展(现 318-325 行)**

双向渐进同步(方案 A)、阻塞传播、缺陷回执、最终汇总 comment(见核心模型 4、6)。

**6. 新增 Defect Handling 一节**

按核心模型 6 写入,含三条边界规则。

**7. Handoff to Audit 修改(现 335-357 行)**

两级 audit(`READY_TO_INTEGRATE` / `READY_FOR_PR`)、delta re-audit、`revision_count` 作用域(见核心模型 5)。

**8. PR_DRAFT.md 要求补充(Step 8)**

分解任务的 PR 草案按子 issue 组织变更说明。

**9. Common Mistakes 新增红旗**

- 递归拆分子 issue,而不是停下来上报;
- 借"父批准覆盖"自行新增 `decomposition.md` 之外的子 issue;
- 单兵执行子 issue 时不读父计划的跨任务契约;
- 子 Agent 直接写父分支或父 `state.json`;
- 子 issue 未全部 `READY_TO_INTEGRATE` 就做父级汇总/提交 PR;
- 缺陷修复后跳过 delta re-audit;
- tracker 上的父子关联与 `decomposition.md` 漂移且未修正。

### 二、`skills/vapa-audit/SKILL.md`

1. **Verdicts 表**:新增 `READY_TO_INTEGRATE`(仅分解模式子级),含义"可合回父分支",下一步"编排器合回"。
2. **前置检查(Step 1 之前)**:父 issue 存在未 `READY_TO_INTEGRATE` 的子 issue → 返回未就绪清单,不写 `VAPA_AUDIT.md`、不动 `revision_count`。
3. **Step 5b 扩展**:验证 tracker 父子关联与 `decomposition.md` 一致;每个子 issue 有完整工作区 + 子级 audit;抽查父 issue 汇总 comment 与实际状态一致;合回顺序与依赖关系被遵守。
4. **Delta re-audit 规则**:post-audit 改动 → 审增量 + 回归,出修订版报告,`revision_count` 不增加。
5. **Red flags 新增**:子未全部通过就审父并给 `NEEDS_REVISION`(应返回未就绪);只看工件不验证 tracker 关联;忽略 post-audit 改动直接沿用旧裁决。

### 三、`skills/vapa-review/SKILL.md`(小改)

- review 对象是子 issue 时,发现的问题归属父 issue 的分解方案,建议升级回父层面处理。
- 识别缺陷类 issue(轻量模板),评审重点放在"现象是否可复现、验收是否可验证"。

### 四、配套模板

- `decomposition.md` 模板字段定型:子 issue 清单、**每子项 `depends_on` / `conflicts_with`(DAG 边)**、交付物、集成标准、tracker 关联方式、跨任务契约指针。
- 缺陷 issue 轻量模板:现象 / 期望行为 / 复现步骤 / 来源(放置位置实施时定:`vapa-init/references/` 或 `vapa-exec/references/`)。

---

## 明确不改动的部分

- 非分解任务(S/M 直接执行)的全部流程、工作区结构、state.json schema;
- `decomposition.md` 作为执行真相来源的地位——tracker 关联只是可见性层;
- `vapa-audit` 的三种现有裁决及其语义;修订预算机制本身;
- `vapa-proposal`、`vapa-init` 全部内容。

---

## 已淘汰方案及原因

记录讨论中否决的路径,避免日后重提:

| 淘汰方案 | 淘汰原因 |
|----------|----------|
| 子 issue 各自开 PR 合 main(顺序合并) | 父级 audit 卡在"木已成舟"之后,发现问题代价高;半成品提前落地 |
| 子分支 → 集成分支 → 父 PR(双层分支) | 比单分支模型多一层合并,无对应收益 |
| 缺陷也建子 issue 共享父分支(缺陷方案 A) | 引入双写 comment、父级调度、新裁决等全套复杂度,而其价值(同 PR 修复)被 comment 回路覆盖;合入后场景又退化为独立任务 |
| 所有缺陷都走 comment(纯方案 B) | comment 无状态语义(无法关闭/延期/分派),合入后缺陷无处理通道 |
| 递归拆分(子 issue 可再拆) | 工作区树与审计链复杂化;子 issue 过大应上报人类而非自行再拆 |
| 父 issue 维护单条总览 comment 原地更新(进度方案 B) | 原地编辑丢失历史,与"透明度替代汇报"有张力 |
| exec 加 base branch / stacked PR 支持合入前缺陷独立 issue | 引入 stacked PR 复杂度,收益被 comment 回路覆盖 |

---

## 实施顺序

1. `skills/vapa-exec/SKILL.md`(核心模型,第 1-9 项)
2. `skills/vapa-audit/SKILL.md`(对接新模型)
3. `skills/vapa-review/SKILL.md`(两条小改)
4. 缺陷模板 + `decomposition.md` 模板定型
5. 全部技能文件以英文撰写,与现有文件风格一致;逐文件提交
