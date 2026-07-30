<!-- Lightweight defect issue template. Used for defects discovered AFTER the
     source issue's PR has merged. Defects found before merge go through the
     defect-comment channel on the source issue instead (see vapa-exec,
     Defect Handling). This template may later be promoted to a repository
     issue template via vapa-init. -->

# [缺陷标题:什么操作导致什么异常]
> 示例:「导出按钮在空列表状态下点击后页面白屏」

---

## 🐞 现象

[实际发生了什么。包含报错文本、截图或录屏链接(如有)]

## ✅ 期望行为

[应该发生什么]

## 🔁 复现步骤

1. [第一步]
2. [第二步]
3. [观察到现象]

**环境**:[版本 / 分支 / 浏览器等,如相关]

---

## 📎 来源

- **验证对象**:#<issue-number>(在哪个 issue 的验证过程中发现)
- **来源评论**:<comment-link>(记录该缺陷的评论)

---

## 验收标准

现象消除且不回归(相关测试全部通过,受影响区域无新失败)。

---

- **提案人**:@username
- **建议 Size**:S(缺陷通常应能在单会话内修复;大于 S 说明它不只是缺陷)
