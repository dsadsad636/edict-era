# ADR-004 · Auth 守卫剥离契约

| 项 | 值 |
|---|---|
| 状态 | ✅ **建议采纳**（待用户审批） |
| 日期 | Phase 3 |
| 记录者 | 程基岩 |
| 影响范围 | `00-singleplayer-migration.md` §S1 / §S6、`01-main-architecture.md` §7 |
| 关联 | `00-singleplayer-migration.md`、`01-main-architecture.md` §5 / §6 |

---

## 1. 背景

### 1.1 一个被低估的事实

《守夜人·凋零纪元》是**联网游戏**，`Auth` 不仅管登录，还被复用为**"游戏是否可运行"的运行时门禁**。

我独立复核（对 `nightwatch/index.html` 逐符号 `grep`）发现，`Auth.isLoggedIn()` 被用作 **5 处运行时守卫**——它返回 `false` 时，游戏的关键循环会**直接 `return`，不抛任何异常**：

| 行号 | 函数 | 原始守卫形态 | 失败后果 |
|---|---|---|---|
| L2525 | `tickBattle()` | `if(!G||!Auth.isLoggedIn()) return;` | 战斗主循环停摆 |
| L2783 | `enterMap()` | `if(!Auth.isLoggedIn()||!G){ toast('请先登录账号'); return; }` | 无法进入地图 |
| L2792 | `nextEncounter()` | `if(!Auth.isLoggedIn()||!G) return;` | 无法触发下一波 |
| L3402 | `save()` | `if(!Auth.isLoggedIn()||!G) return; Auth.saveGame(G);` | 无法存档 |
| L3654 | `renderAll()` | `if(!Auth.isLoggedIn()||!G) return;` | 整个界面不刷新 |

### 1.2 为什么这是「致命」而非「普通」

- **静默失效**：`isLoggedIn()` 返回 `false` 时**没有抛异常、没有走 error 分支**，只是默默 `return`。开发者打开浏览器看到的是"游戏卡住了"，console 里可能**一条报错都没有**。
- **依赖耦合**：这 5 处里 3 处（tickBattle / renderAll / save）是游戏的**心脏循环**。只要其中一处漏改，剥离 `Auth` 的工程中游戏就不可能跑起来。
- **触发极易**：`isLoggedIn()` 的返回值 = `Auth.user` 是否非空。剥离过程中任何时刻只要 `Auth.user` 被清空（删登录链、清 session、重构出错），三循环同时静默停摆。

### 1.3 策划勘察的遗漏

策划的勘察报告**完全没有提到这 5 处守卫**，其清单里"剥离联机层"的步骤只有"删除 MMO 脚本块 / 删除 Auth 对象"。按那份清单执行，会在 `tickBattle()` 第一行就 brick——且极难定位（因为没有报错）。这是 `00-singleplayer-migration.md` 把 **S1（守卫中性化）排在最前**的根本原因。

---

## 2. 决策

> ## ✅ **采用「先中性化、后删除」的两阶段契约：S1 先把 5 处守卫摘成恒真，确认解耦后，S6 才能安全地删 `Auth`/`CloudSave`。**

**核心原则**：剥离联机层的顺序必须**从「被依赖」到「依赖」**，而不是从「易」到「难」。守卫是「被依赖方」，必须最先处理。

### 2.1 中性化契约（S1 的硬规则）

| 行号 | 中性化前 | 中性化后 | 验收 |
|---|---|---|---|
| L2525 | `if(!G||!Auth.isLoggedIn()) return;` | `if(!G) return;` | 删除 `!Auth.isLoggedIn()` 判定 |
| L2783 | `if(!Auth.isLoggedIn()||!G){ toast('请先登录账号'); return; }` | `if(!G) return;` | **连 toast 文案一起删**（单机下"请先登录"是废话） |
| L2792 | `if(!Auth.isLoggedIn()||!G) return;` | `if(!G) return;` | — |
| L3402 | `function save(){ if(!Auth.isLoggedIn()||!G) return; Auth.saveGame(G); }` | `function save(){ if(!G) return; Save.write(G); }` | 存档路径一并换（见 §2.2） |
| L3654 | `function renderAll(){ if(!Auth.isLoggedIn()||!G) return; ...}` | `function renderAll(){ if(!G) return; ...}` | 总渲染入口 |

**中性化阶段只改守卫判定，不删 `Auth` 对象本身**（它此时仍被其他 41 处引用）。目的是让后续所有删除动作都**不会触发静默失效**。

### 2.2 与存档路径的协同（S1 必须顺手做）

L3402 的中性化不只是去掉守卫——它还把 `Auth.saveGame(G)` 换成 `Save.write(G)`。这一步把"存档出口"从联机层（`Auth`/`CloudSave`）迁到本地存档层（`Save`，由 ADR-002 定义）。**必须在 S1 一并改掉**，否则 S6 删 `Auth` 时此处会变成 `ReferenceError`。

### 2.3 删除契约（S6 的前置门禁）

S6 只有在**满足以下全部条件**后才能执行：

| # | 门禁 | 验证方式 |
|---|---|---|
| G1 | 5 处守卫已全部中性化（见 §2.1） | `grep -n "Auth.isLoggedIn" index.html` 结果为空 |
| G2 | `grep "Auth\."` 结果中已无运行时调用（仅剩 `Auth` 对象的**定义**） | 剩余命中只能是对象声明 |
| G3 | 存档出口已切到 `Save.write` | L3402 不包含 `Auth.saveGame` |
| G4 | R0 回归验证已通过（见 §3） | 手动验证通过 |

---

## 3. 验证与回归（契约的可执行性）

### 3.1 R0 · 守卫已解耦（S1 完成后立即执行）

> 目标：证明「Auth 的状态不再影响游戏运行」。

| 步骤 | 操作 | 期望 |
|---|---|---|
| 1 | 游戏运行中，控制台执行 `Auth.user=''` | 不报错 |
| 2 | 继续战斗、切换地图、保存 | ✅ 战斗继续 tick、界面继续刷新、`localStorage` 时间戳继续更新 |
| 3 | 重载页面，加载存档 | ✅ 进度完整、无丢失 |

这一条通过，说明守卫已解耦——后面怎么删 `Auth` 都不会 brick。

### 3.2 S6 完成后的 DoD

- `grep -n "Auth\."` 结果为空
- `grep -n "CloudSave"` 结果为空
- `grep -n "CLOUD_ENDPOINT"` 结果为空（**彻底删除**，不留空常量——见 `00-singleplayer-migration.md` §4.3）
- `grep -n "sendPB"` 结果为空（配合 S4/S5）

---

## 4. 备选方案

| 方案 | 说明 | 否决理由 |
|---|---|---|
| A. 直接删 `Auth` 对象，靠全局替换修引用 | 看似最快 | 🔴 删到一半时 `Auth.user` 变空会让心脏循环静默停摆，无法继续调试，且报错位置与根因脱节 |
| B. 保留 `Auth` 对象只删登录 UI | 留个空壳 | 🔴 死代码；后续维护者会误以为还有联机能力，且 `Auth.saveGame` 仍指向已删的 `CloudSave` |
| C. ✅ 两阶段中性化（本 ADR） | 先摘守卫再删对象 | 安全、可逐步验证、每一步都可独立回归 |

---

## 5. 后果

| 类型 | 项 |
|---|---|
| ✅ 正面 | 剥离过程**零静默失效风险**；每一步可独立回归；R0 提供明确的可执行验证 |
| ⚠️ 代价 | S1 是策划清单上**原本没有的额外工作**（约 0.5h），但相比它规避的「brick 难定位」风险，性价比极高 |
| ✅ 协同 | 与 ADR-002（`Save.write` 接管存档）、`00-singleplayer-migration.md` §S1 顺序完全对齐 |
| 🔴 风险 | **若跳过 S1 直接做 S6**：5 处守卫中任一漏改 → 游戏静默 brick，且无报错可定位（RK-2，严重度🔴） |

---

*文档结束 · 关联：`00-singleplayer-migration.md` §S1 / §S6、`01-main-architecture.md` §7、ADR-002*
