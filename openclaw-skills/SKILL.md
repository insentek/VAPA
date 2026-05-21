---
name: vapa
emoji: "🎯"
description: "VAPA Framework CLI for decentralized team collaboration"
---

# VAPA

VAPA (Vision-driven · Async · Proposal-based · Agent-executed) 是一套为AI时代重新设计的去中心化团队协作框架。

## 命令

- `/vapa-init <repo>` — 在指定仓库初始化 VAPA 标签和 Issue 模板
- `/vapa-proposal <subject>` — 在当前仓库发起新提案
- `/vapa-proposal` — 查看当前仓库所有待定提案

## 依赖

- `gh` CLI 已登录且有 repo 权限
- Python 3 + requests（仅标签配置器需要）

## 用法

### /vapa-init

```
/vapa-init owner/repo
```

1. 运行 `scripts/vapa-init.sh` 配置完整标签体系
2. 创建 `.github/ISSUE_TEMPLATE/` 下的四个模板：
   - `feature-proposal.md`
   - `problem-statement.md`
   - `vision-amendment.md`
   - `experiment.md`

### /vapa-proposal <subject>

```
/vapa-proposal "为订单列表增加批量导出能力"
```

1. 在当前仓库创建 Issue
2. 自动应用 `type: feature, status: draft` 标签
3. 使用 feature-proposal 模板填充 body
4. 返回 Issue URL

不带 `<subject>` 时列出所有待定提案：

```
/vapa-proposal
```

返回 `status: draft` + `status: refining` + `status: ready-for-review` 的 Issue 列表。

## 标签体系

| 前缀 | 用途 |
|------|------|
| `type:` | 提案类型（feature/problem/improvement/experiment/technical-debt/research/vision-amendment） |
| `status:` | 状态流转（draft → refining → ready-for-review → in-review → approved → in-progress → in-validation → done） |
| `align:` | 战略对齐（core/adjacent/exploratory/off-track） |
| `size:` | 规模估计（S/M/L/XL） |
| `contrib:` | 贡献角色（proposer/shaper/reviewer/validator/sponsor） |

## 参考

- 框架原文：https://github.com/insentek/VAPA
- 标签配置器：`scripts/vapa-labels.py`
- Issue 模板：`assets/*.md`
