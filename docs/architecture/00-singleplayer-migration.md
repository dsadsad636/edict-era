# 00 · 单机化剥离方案（手术方案）

> 版本：v1.0 · Phase 3
> 作者：程基岩（技术方向 / 主程序）
> 状态：**待用户审批后执行**
> 前置：`design/concept/system-breakdown.md` G 组
> 关联 ADR：ADR-004（Auth 守卫剥离契约）
> 关联 GDD：`04-combat-monsters.md`（§233 E1 / §267 A7 / §282 H6）｜`05-economy-loop.md`（§220 E1 / §28 / §251 A5）｜`03-skills.md`（§3.3 / §256 E1 / §308 H1）

> 📌 **源码锚点（Phase 4 行号有效性前置校验）**：本迁移文档中**所有行号（L2850 / L2917 / L2708 …）均指向唯一基准文件——
> `c:\Users\Biostar\WorkBuddy\2026-07-31-23-14-34\nightwatch\index.html`
> - 体量：**4831 行**（已逐符号复核；MMO 块 L4518-4829、SAVE_KEY L980 等锚点吻合）
> - ⚠️ **当前工作区 `2026-08-02-12-34-39/` 仅有 23 个 `.md`，不含任何 `.html`**：Phase 4 开工前必须把该源文件拷入本作仓库骨架（见 §3 S0 第 0 步），并**先比对字节数 / SHA256 一致**再信任任何行号
> - 字节数 / SHA256：**Phase 4 开工第一步补算并回填本块**（用 `wc -c` / `sha256sum` 或 `Get-FileHash`），作为行号有效性的硬校验闸

---

## 0. 一句话结论

> **联机层不是"外挂模块"，它是承重墙。**
> `Auth.isLoggedIn()` 被用作 **5 处运行时守卫**（其中包括战斗主循环 `tickBattle()`、存档 `save()`、总渲染 `renderAll()`）。
> 只要有一处漏改，游戏会**静默失效**——不报错、不渲染、不存档。
> 因此本方案的执行顺序**不是"从易到难"，而是"从被依赖到依赖"**。

> 📎 本方案对应 **GDD 04 §233 E1（组队分支未剥离，MVP 上线级阻断）**、**GDD 05 §220 E1（MMO 松散材料未剥离）**、**GDD 03 §3.3（技能优先级必改）**；逐组件步骤见 §3，验收见 §5。

---

## 1. 我的独立复核结果（与策划勘察的差异）

我用 `grep -n` 对 `nightwatch/index.html`（4831 行）逐符号复核，结果如下。**差异项以我的复核为准**。

| 项 | 策划勘察 | 我的复核 | 判定 |
|---|---|---|---|
| `MMO.` 引用 | 35 处 | **35 行 / 56 次出现** | ✅ 一致（策划数的是行） |
| `Auth.` 引用 | — | **41 行 / 51 次出现** | 补充 |
| `partyMode` | 「渗透 5 处核心战斗逻辑」 | **13 次出现，散布 8 个函数** | ⚠️ **偏低** |
| `sendPB()` | 「散落 8+ 处」 | **5 个调用点 + 1 处定义** | ⚠️ **偏高**（实际更轻） |
| `partyMode` 在 `unitAct()` 中 | 列为 5 处之一 | **`unitAct()` 零引用，完全干净** | ❌ **误报** |
| `/api/` 端点 | 6 个 | **7 行**（含 `/api` 探针 `probe()`） | ⚠️ 漏了 `probe()` |

### 🔴 策划勘察**完全遗漏**的三项（本文档的核心价值）

| # | 遗漏项 | 严重度 | 说明 |
|---|---|---|---|
| **M1** | **`Auth.isLoggedIn()` 被用作 5 处运行时守卫** | 🔴 **致命** | L2525 `tickBattle()`、L2783 `enterMap()`、L2792 `nextEncounter()`、L3402 `save()`、L3654 `renderAll()`。删 `Auth` 而不处理守卫 → **游戏彻底不可玩** |
| **M2** | **`startBattle()` L2492 是 partyMode 的真正入口，但不含 `partyMode` 字面量** | 🔴 高 | 它判断的是 `MMO.party.members.length`。**`grep partyMode` 搜不到它**。且它引用**裸标识符 `MMO`**——先删 MMO 脚本块会让此处抛 `ReferenceError`，每场战斗都开不了 |
| **M3** | **伤害累加器在 `basicAttack()`（L2668），不在 `unitAct()`** | 🟡 中 | 按策划的清单去改 `unitAct()` 会改错文件位置，同时漏掉 `basicAttack()` |

### 🐛 顺带发现的既有 Bug（不影响剥离，但要记录）

`generateLoot()` L2860 / L2864：

```js
if((isBoss?Math.random()<0.6:isElite?Math.random()<0.3:Math.random()<0.06)*dm){
```

`*dm` **写在比较运算之外**——`(boolean) * 1.25`。由于 `true*n` 恒为真值、`false*n` 恒为 0，组队的 +25% 爆率**对技能书从未真正生效**。
对比 L2855 的正确写法 `if(Math.random()<(...)*dm)`。

> ✅ **对我们是好消息**：删除 `dm` 后这两行变成 `if(isBoss?...:...)`，与单人现状**行为完全等价**（`bool*1 ≡ bool`）。不需要额外验证。
> ⚠️ 但**禁止**在剥离过程中"顺手修这个 bug"——那会改变掉落概率，污染回归验证的基线。留到 Phase 4 数值调整时处理。

---

## 2. 剥离顺序（依赖关系决定，**不可调换**）

```
S0  基线固化 ───────────────► 建立可比对的"改前行为"
      ↓
S1  Auth 守卫中性化 ────────► 【必须最先】否则后续任何删除都会静默 brick
      ↓
S2  startBattle 入口闸门 ──► 【必须早于 S5】否则删 MMO 块会 ReferenceError
      ↓
S3  partyMode 战斗层剥离 ──► 最危险，需逐行手术
      ↓
S3.7 战利品 MMO 松散材料剥离 ─► GDD 05 §220 E1（loot.materials/matAdd 掉落）
      ↓
S4  partyMode UI 层剥离 ───► 依赖 S3 完成（共用 renderBattleScreen）
      ↓
S5  MMO 脚本块整体删除 ────► 此时已无外部引用，可整块删
      ↓
S6  Auth / CloudSave 拆除 ─► 依赖 S1 已把守卫摘干净
      ↓
S7  存档命名空间迁移 ──────► 最后做，避免中途换 key 干扰调试
      ↓
S8  创角流程重写（A2）─────► 依赖 S6 + S7
```

**为什么 S1 必须在最前**：`Auth.isLoggedIn()` 的返回值取决于 `Auth.user` 是否非空。剥离过程中任何时刻只要 `Auth.user` 变空，`tickBattle()` 直接 `return`、`renderAll()` 直接 `return`、`save()` 直接 `return`——**三个最核心的循环同时静默停摆，且不抛任何异常**。这种失败模式极难定位。必须先把守卫变成恒真，再动别的。

---

## 3. 逐组件手术方案

### S0 · 基线固化（0.5h）

在动任何代码前：

0. **定位源码锚点并校验完整性**：从本文件抬头「📌 源码锚点」指定的绝对路径取前作 `index.html`（默认 `c:\Users\Biostar\WorkBuddy\2026-07-31-23-14-34\nightwatch\index.html`）。⚠️ **先比对字节数 / SHA256 与锚点块一致**（Phase 4 补算填入），且行数须为 **4831 行**——不一致则拿到错误 / 被改动版本，**禁止继续**
1. `git checkout -b arcanum-strip` （在**本作仓库**的骨架副本上）
2. 把校验通过的源文件**只读拷贝**为本作 `index.html` 作为起点（⚠️ **绝不修改前作 `nightwatch/` 原文件**）
3. 在浏览器打开，用**离线模式账号**（`CLOUD_ENDPOINT=''` 已经是空，会走 local 分支）注册一个账号 → 创角 → 打通第 1 张图前 10 场遭遇
4. **截图/录屏**保存：角色面板数值、一次多段技能的完整战斗日志、一次护盾技能生效画面、连战自动接战、掉落列表
5. 导出 `localStorage` 快照存档为对照组

> 📌 这份基线是 §5 回归验证清单的**唯一判定依据**。没有基线，"没被破坏"无从证明。

---

### S1 · `Auth` 守卫中性化 🔴 最高优先级（0.5h）

**不删除，只中性化。** 目的是让后续所有删除动作都不会触发静默失效。

| 位置 | 原文 | 改为 | 理由 |
|---|---|---|---|
| L2525 `tickBattle()` | `if(!G\|\|!Auth.isLoggedIn()) return;` | `if(!G) return;` | 战斗主循环，单机下只需 G 存在 |
| L2783 `enterMap()` | `if(!Auth.isLoggedIn()\|\|!G){ toast('请先登录账号'); return; }` | `if(!G) return;` | 连 toast 文案一起删 |
| L2792 `nextEncounter()` | `if(!Auth.isLoggedIn()\|\|!G) return;` | `if(!G) return;` | — |
| L3402 `save()` | `function save(){ if(!Auth.isLoggedIn()\|\|!G) return; Auth.saveGame(G); }` | `function save(){ if(!G) return; Save.write(G); }` | 存档路径同时换掉，见 S7 |
| L3654 `renderAll()` | `function renderAll(){ if(!Auth.isLoggedIn()\|\|!G) return; ...}` | `function renderAll(){ if(!G) return; ...}` | 总渲染入口 |

**验收（S1 完成即可验，不必等全部做完）**：
- ✅ 在控制台执行 `Auth.user=''` 后，战斗**仍在继续**、界面**仍在刷新**、`localStorage` **仍在更新**
- 这一条通过，说明守卫已解耦，后面怎么删 Auth 都不会 brick

> ⚠️ 此时 `Auth` 对象仍然存在，`tickBattle` 等已不再依赖它。**这是安全网，不要提前拆。**

---

### S2 · `startBattle()` 入口闸门（10 min）

**位置 L2490-2494**：

```js
function startBattle(enemyDefOrList, label){
  const defs = Array.isArray(enemyDefOrList) ? enemyDefOrList : [enemyDefOrList];
  if (MMO && MMO.party && MMO.party.members && MMO.party.members.length > 0) {   // ← 删这 3 行
    return startPartyBattle(defs, label);
  }
  const enemies = defs.map(...);   // ← 保留，以下全是单人路径
```

| 动作 | 内容 |
|---|---|
| ❌ 删除 | L2492-2494（3 行 `if` 块） |
| ❌ 删除 | L2507-2523 整个 `startPartyBattle()` 函数（17 行，含唯一的 `partyMode:true` 赋值） |
| ✅ 保留 | L2495 起的全部单人建构逻辑 |

> 🔴 **这是全流程最容易踩的雷**：`MMO` 是**裸标识符**（不是 `window.MMO`、不是 `typeof MMO`）。第二个 `<script>` 块（L4518-4829）里的 `window.MMO = MMO` 是它唯一的来源。
> **若先执行 S5 删除 MMO 块**，此行会抛 `Uncaught ReferenceError: MMO is not defined`，**每一次进战斗都失败**。
> 删掉 L2492-2494 之后，`startPartyBattle` 成为无调用者的孤儿函数，可安全删除。删掉它，`partyMode:true` 在全代码库中就不再有任何写入点——**后续所有 `b.partyMode` 判断恒为 `undefined`（假值）**，这给了我们一层天然保险。

---

### S3 · `partyMode` 战斗层剥离 🔴 最危险（2h）

> **总原则**：`partyMode` 分支**只做两件事**——① 向服务端上报（`sendPB`）② 累加上报用的伤害计数（`_partyDmg` / `_lastSkillId` / `_lastMagical`）。
> 这三个状态字段**只在组队路径内写、只在组队路径内读**，**与单人战斗完全零交集**。
> ✅ **结论：没有任何需要保留的共享状态。** 组队相关的一切都可以删干净。
> ⚠️ **但危险不在"该不该删"，而在"删的边界画在哪一行的哪一段"**——有两行是组队代码和单人代码**写在同一行**的。

#### 3.1 `tickBattle()` L2524-2547 —— 整块删，零风险

```js
function tickBattle(){
  if(!G) return;                       // S1 已改
  const b=G.battle; if(!b||b.over) return;
  if(b.partyMode){                     // ┐
    ...                                // │ ❌ L2527-2547 整块删除（21 行）
    return;                            // │
  }                                    // ┘
  b.player.time+=effSpd(b.player);     // ✅ 单人 ATB 从这里开始
```

**为什么整块删是安全的**：该块内出现的每一个"看起来重要"的调用，在下方单人路径中**都有对应实现**：

| 组队块内的调用 | 单人路径对应位置 | 是否等价 |
|---|---|---|
| `applyFlasks(b.player)` L2541 | L2566 | ✅ 有 |
| `b.turn++` L2542 | L2567 | ✅ 有 |
| `renderBattleScreen()` L2543 | L2568 | ✅ 有 |
| `if(b.player.hp<=0){...endBattle()}` L2544 | L2569 `checkBattleEnd()` | ✅ 更完整（同时处理胜负） |
| `if(b.turn%3===0) scheduleSave()` L2545 | L2573 | ✅ 有 |

> ✅ 删除后**无功能丢失**。

#### 3.2 `unitAct()` L2623-2645 —— ⚠️ **不要碰**

策划清单把 `unitAct()` 列为 5 处渗透点之一，**这是误报**。我逐行复核确认：`unitAct()` 函数体内 **`partyMode` / `sendPB` / `_partyDmg` 出现次数均为 0**。

> ❌ **禁止对 `unitAct()` 做任何编辑。** 它是纯净的单人行动调度器。

#### 3.3 `basicAttack()` L2664-2669 —— 整行删

```js
function basicAttack(a,t){
  const r = dealDamage(a,t,a.atk,false);
  if(r.miss) pushLog(...);                                              // ✅ 保留
  else pushLog(...);                                                    // ✅ 保留
  if(a.side==='player' && G.battle && G.battle.partyMode && r.dmg>0)    // ❌ 删整行 L2668
      G.battle._partyDmg=(G.battle._partyDmg||0)+r.dmg;
}
```
纯累加器，独占一行，删除零风险。

#### 3.4 `castSkill()` L2670-2711 —— 🔴 **本次手术的核心危险区**

这是**唯一存在"组队代码与单人代码同行"**的函数。逐行给出删除边界：

| 行号 | 原文（节选） | 处置 | 危险度 |
|---|---|---|---|
| 2674 | `const partyB = a.side==='player' && G.battle && G.battle.partyMode;` | ❌ 删整行 | 🟢 低 |
| 2675 | `if(partyB){ G.battle._lastSkillId=def.key; G.battle._lastMagical=magical; }` | ❌ 删整行 | 🟢 低 |
| 2683 | `if(partyB && r.dmg>0) G.battle._partyDmg=...;` | ❌ 删整行 | 🟢 低 |
| **2689** | `if(!r2.miss){ pushLog(a.side,'   → 第'+(h+1)+'击 '+...); if(partyB) G.battle._partyDmg=...; }` | ⚠️ **只删行尾 `if(partyB) ...;` 一段，保留 `pushLog`** | 🔴 **高** |
| 2700 | `if(partyB) sendPB({...buffType:'heal'...});` | ❌ 删整行 | 🟢 低（治疗本体在 L2697-2699） |
| 2705 | `if(partyB) sendPB({...buffType:'atkBoost'...});` | ❌ 删整行 | 🟢 低（buff 本体在 L2702-2703） |
| **2708** | `if(def.shield){ const sh=Math.round(a.maxHp*def.shield); a.shield += sh; if(partyB) sendPB({...}); }` | ⚠️ **只删花括号内的 `if(partyB) sendPB({...});`，保留 `const sh=...; a.shield += sh;`** | 🔴 **最高** |
| 2709 | `if(def.stun) t.buffs.push(...)` | ✅ 保留 | — |
| 2710 | `sk.cd=def.cd;` | ✅ 保留 | — |

> 🔴 **L2708 是整个剥离流程中最危险的一行。**
> 理由：护盾赋予（`a.shield += sh`）**没有任何 `pushLog` 输出**。如果误删整行，护盾类技能会**完全静默失效**——战斗日志上看不出任何异常，玩家只会觉得"这技能好像没什么用"。而 QA 如果不专门盯着 `shield` 数值看，也测不出来。
> ✅ 缓解：§5 回归清单 R7 专门为此设计了一条**必须观察 HP 条上 `🛡` 数字变化**的验证场景。

> ⚠️ **L2689 次危险**：误删整行会导致多段技能（`def.hits>1`）的第 2 击及以后**不再打日志**。伤害仍然生效（`dealDamage` 在 L2688 已执行），所以是"伤害对但日志缺"——同样不报错。§5 的 R6 覆盖此项。

#### 3.5 `endBattle()` L2724-2779

| 行号 | 处置 |
|---|---|
| 2730-2733 | ❌ 删除 `if(b.partyMode && b.noLoot){ ... return; }` 整块（4 行） |
| 2751 | 🔧 `generateLoot(b.enemies, b.partyMode)` → `generateLoot(b.enemies)` |
| **2763** | ❌ 删除 `if(b.partyMode){ G.battle=null; save(); showNormalView(); return; }` |

> ⚠️ **L2763 的语义要看清**：它是一个**位于 `chain = !!G.autoChain;`（L2764）之前的提前 return**。
> 也就是说组队胜利会**跳过连战判定**直接回地图。删掉它之后，胜利流程会正常落到 L2764 的连战分支——**这正是单人应有的行为**。
> ✅ 删除是必需的，但删完后**必须验证连战仍然工作**（§5 R4）。

#### 3.6 `generateLoot()` L2846-2864

```js
function generateLoot(enemies, partyMode){   // 🔧 签名改为 generateLoot(enemies)
  if(!Array.isArray(enemies)) enemies=[enemies];
  const dm=(partyMode?1.25:1);               // ❌ 删整行
  ...
  if(Math.random()<(isBoss?1:isElite?0.8:0.35)*dm){          // 🔧 删 `*dm` → 括号内表达式不变
  if((isBoss?Math.random()<0.6:...:Math.random()<0.06)*dm){  // 🔧 删 `*dm`（见 §1 Bug 说明，行为等价）
  if((isBoss?Math.random()<0.3:...:Math.random()<0.02)*dm){  // 🔧 删 `*dm`（同上）
```

> ✅ 三处 `*dm` 删除后行为与 `dm=1` 时**完全等价**，不需要数值回归。
> ❌ **禁止顺手修 §1 记录的那个 bug**——那会改变基线。

#### 3.7 战利品 MMO 松散材料剥离（GDD 05 §220 E1 / §28）🟠 经济层剥离

> **与 `partyMode` 无关，但同属"守夜人联机遗留"**：守夜人怪物会**松散掉落**一种 `common` 通用材料（`loot.materials`），与新作 `DECOMP_YIELD` 印屑体系（refined/blue/purple/orange/common 五类）**不匹配**，且会架空锻造闭环（GDD 05 §28）。本作印屑**只来自分解**（GDD 05 §3.3）。

**精确删除集合**（仅删"掉落"路径，**保留 `matAdd` 函数与分解调用**）：

| 行号 | 原文（节选） | 处置 |
|---|---|---|
| L2850 | `const loot={gold:0,materials:0,items:[],books:[],flasks:[]};` | 🔧 删 `materials:0,` 字段 |
| L2854 | `loot.materials+=isBoss?rand(8,15):isElite?rand(3,6):rand(0,2);` | ❌ 删整行 |
| L2917 | `matAdd('common', loot.materials);` | ❌ 删整行（**保留 `matAdd` 函数 L2133 与分解调用 L2150**） |
| L2918 | `if(loot.materials) pushLog('sys','🪨 获得 '+loot.materials+' 材料', ...);` | ❌ 删整行 |
| L4480 | `if(loot.materials) ls.push('🪨'+loot.materials);` | ❌ 删整行（MMO UI 展示，块外同语义） |

> 🟢 **关键约束**：`matAdd(t,n)` 函数（L2133）**必须保留**——它被 `decompActual()` L2150 调用，是**分解产出印屑的唯一入口**（GDD 05 §3.3 闭环）。只删 `matAdd('common', loot.materials)` 这一处**掉落**调用即可，切勿误删函数定义或分解调用。
> ✅ 验收：§5.3 R17.1。

#### 3.8 🟦 关联必改：技能释放优先级重排（GDD 03 §3.3 / §256 E1 / §308 H1）

> **这不是剥离项，但与 S3 同文件（`castSkill`/`chooseSkill` 均在战斗逻辑区），建议同一代码评审 / 同一 PR 批量处理**，避免二次触碰战斗文件。

**问题（GDD 03 §21）**：引擎按 `mult` 降序选技；增益/治疗技能无 `mult` → 排序值 0 → 永远垫底。**11 个非伤害技能中有 8 个实质永不释放**；且治疗在满血时仍会释放（纯浪费）。

**修复（GDD 03 §3.3，约 15 行）**：改为 5 级优先级 `ready[]` 排序——`P0 紧急治疗(hp<40%)` > `P1 减益` > `P2 增益(未生效中)` > `P3 伤害` > `P4 控场`；治疗追加 `hp≥85%` 不释放；同类 buff 生效中不重复叠加（刷新时长）。释放 `ready[0]`，否则普攻。

**验收（不属于本剥离 DoD，见 GDD 03 A2/A3/A4/A9）**：
- ✅ 装备力量武器只学 `war_cry`+`heavy_slash`，观察 30 回合**战吼实际触发**（A2）
- ✅ 满血携带 `heal_light` **不触发**（A3）
- ✅ 扣血至 <40% **优先治疗**（A4）
- ✅ 3 个禁咒**不受武器限制**可释放（A9）

> ⚠️ 风险：此项若遗漏，战斗"可预测性"支柱（GDD 03 G2）直接崩塌；但与剥离无关，故**不计入 §7 DoD 的 grep 清零项**，单独立项跟踪（RK-8）。
> ✅ **裁定（design-strategist 确认）**：不单开 ADR-006。GDD 03 §3.3 已是权威规格、验收 A2/A3/A4/A9 已齐，迁移文档作统一载体即可；RK-8 风险保留。若后续需独立审计追溯点再按需补。

---

### S4 · `partyMode` UI 层剥离（30 min）

| 位置 | 内容 | 处置 |
|---|---|---|
| L4391-4397 | `let partyHtml=''; if(b.partyMode && b.members...){...}` | ❌ 删除整块（7 行） |
| **L4398-4399** | `document.getElementById('battleBody').innerHTML = partyHtml+playerHtml+'<div class="vs-mark">VS</div>'+...` | ⚠️ **只删拼接串里的 `partyHtml+`**，保留后面全部 |
| L4411-4460 | `totalContrib()` / `syncPartyBattle()` / `onPartyEvent()` / `applyPartyBuff()` / `onPartyEnd()` | ❌ 整段删除（50 行） |
| L1849-1854 | `const Party = { isRemote, members }` 组队预埋接口 | ⚠️ **保留**（V1 的 AI 佣兵 H2 要复用此结构，见 system-breakdown G4） |
| `LEFT_TABS` 中的「组队」项 | F1 | 🔧 注释掉该项而非删除（V1 恢复） |

> ⚠️ L4398 若误删整行，战斗界面**整个消失**——但这个失败是**响亮的**（一眼可见），风险反而低于 L2708。
> ⚠️ L4411-4460 段内调用了 `applyDamage` / `pushLog` / `renderBattleScreen` / `endBattle`——这些是**共享函数，定义在别处**，删除本段不影响它们。

---

### S5 · `MMO` 脚本块整体删除（10 min）✅ 意外地简单

**这是本次剥离最大的好消息**：MMO 层**95% 物理隔离在自己的 `<script>` 块内**。

| 事实 | 数据 |
|---|---|
| MMO 独占脚本块 | **L4518-4829，共 312 行** |
| 该块外部对 MMO 的引用 | 主脚本块 L2492 **仅 1 处**（S2 已删） |
| UI 层引用（在线人数/聊天/好友） | 全部在 L4595-4830 **块内** |
| `window.sendPB` 定义 | L4727，**块内** |
| `Auth.user` 反向引用 | L4734/4735/4821，**块内**（随块一起删） |

**动作**：S2/S3/S4 完成后，直接删除 L4518-4829 整个 `<!-- MMO -->` 注释 + `<script>` 块。

同时清理 HTML 层的 MMO 挂载点（在 L834-974 的 `<body>` 区内）：聊天框、在线列表容器、好友面板、邀请弹窗的 DOM 节点与对应 CSS（L595-612 云端存档状态区附近）。

**验收**：控制台 `typeof MMO === 'undefined'` 且**无任何 WebSocket 相关日志**。

---

### S6 · `Auth` / `CloudSave` 拆除（1h）

S1 已把 5 处运行时守卫摘干净，此时 `Auth` 只剩"登录门禁 UI + 存档读写"两条链。

| 组件 | 位置 | 处置 |
|---|---|---|
| `Auth` 对象 | L3258-3390（133 行） | ❌ 整体删除。**其中 `saveGame/writeLocal/loadSave` 三个方法的本地分支逻辑要迁移到新的 `Save` 模块**（见 S7） |
| 网络方法 `probe/register/login/resume` 的 cloud 分支 | L3267-3345 | ❌ 删除（含全部 6 个 `/api/*` `fetch`） |
| 本机账号库 `_accts/_writeAccts/_persistSession` | L3281-3290 | ❌ 删除（单机不需要账号） |
| `hashPass()` | L3139-3155 | ❌ 删除（仅服务于密码校验） |
| `CloudSave` 代理对象 | L3392-3401（10 行） | ❌ 删除。⚠️ **但 L3406 `scheduleSave()` 用了 `CloudSave._timer` 做防抖锁**——改为模块内私有变量 `let _saveTimer=null;`，**不要漏** |
| `CLOUD_ENDPOINT` 常量 | L982 | ❌ **彻底删除**（见 §4 决策） |
| `TOKEN_KEY` / `USER_KEY` / `ACCOUNTS_KEY` / `SESSION_KEY` / `SESSION_TTL` | L983-988 | ❌ 删除 5 个常量 |
| 登录门禁 UI | L3430-3496 + HTML L910-974 + CSS L613-693 | ❌ 删除（S8 用创角屏替代） |
| `checkCharNameTaken()` / `gateCheckCharName()` | L3512-3538 | ❌ 删除（单机无需角色名查重） |
| `doLogout()` L3572-3580 / 顶栏账号胶囊 L3657-3659 / L4063-4065 账号信息面板 | | ❌ 删除 |
| `applyCompat()` L3583 里的 `Auth.user`/`Auth.mode` | | 🔧 改为固定值，或按 ADR-002 重写整个迁移函数 |
| L3566-3567 `beforeunload`/`visibilitychange` → `Auth.writeLocal(G)` | | 🔧 改为 `Save.write(G)` |
| L4504-4515 `window.onload` 中的 `Auth.probe()` / `Auth.resume()` | | 🔧 改为直接进槽位选择屏 |

---

### S7 · 存档命名空间迁移（1h）

见 §4 与 ADR-002。

---

### S8 · 创角流程重写（A2，2h）

**旧流程**：`注册账号 → 服务端查重角色名 → 绑定 → 进游戏`
**新流程**：`打开 → 槽位选择屏（3 槽）→ [空槽] 输名字 → 选出身 → 开局 / [有档] 直接读档`

| 要点 | 说明 |
|---|---|
| 复用 | L3231-3252 现有的 `openSlotsPanel/renderSlotsPanel` 槽位 UI **骨架可用**，改为启动屏而非弹窗 |
| 复用 | L3497-3511 `showCharCreate()` / `pickOrigin()` 的出身选择 UI **可直接沿用**（`ORIGINS` 结构不变） |
| 删除 | 角色名查重（`gateCheckCharName`）——单机下重名无害 |
| 保留 | `newGame(charName, originKey)` L1922-1954 **完全沿用**，仅去掉 `G.account` 中的 `user/mode` 字段 |
| 新增 | 槽位与存档的 1:1 绑定（ADR-002 §3） |

---

## 4. 存档命名空间迁移方案

### 4.1 前作现状（复核结果）

| 常量 | 值 | 实际写入的 key |
|---|---|---|
| `SAVE_KEY` | `'nightwatch_save_v2'` | ⚠️ **实际不是这个**——`Auth.saveKey()` L3265 返回 `SAVE_KEY+'::'+user`，真实 key 是 `nightwatch_save_v2::alice` |
| `SAVE_SLOTS_KEY` | `'nightwatch_save_slots_v1'` | 存**整个命名空间的快照数组** |
| `TOKEN_KEY`/`USER_KEY`/`ACCOUNTS_KEY`/`SESSION_KEY` | `nightwatch_*` | 账号体系，全删 |
| `nightwatch_legacy_claimed` | 硬编码字符串 L3383 | ⚠️ **未定义为常量**，藏在 `loadSave()` 里，容易漏 |

> ⚠️ **`::user` 后缀是策划摘要里没有的**。它意味着：存档 key 是**运行时拼出来的**，不是静态常量。单机化后必须改成 `::slotIndex`。

### 4.2 本作方案

| 用途 | 新 key | 说明 |
|---|---|---|
| 角色存档 | `arcanum_save_v1::0` / `::1` / `::2` | **后缀从「账号名」换成「槽位号」**，这是 A2 重写的直接产物 |
| 槽位元数据 | `arcanum_slots_v1` | 只存**轻量元信息**（名字/等级/时间戳/出身），⚠️ **不再存全量快照**（见 §6 容量结论） |
| 全局设置 | `arcanum_settings_v1` | 音量、自动分解偏好等，跨槽位共享 |
| ❌ 不再存在 | `TOKEN` / `USER` / `ACCOUNTS` / `SESSION` / `legacy_claimed` | 随账号体系一起消失 |

### 4.3 `CLOUD_ENDPOINT` 的处置

> ## ❌ **决策：彻底删除，不保留留空常量。**

| 备选 | 评估 |
|---|---|
| A. 保留 `const CLOUD_ENDPOINT='';` 作为"未来扩展位" | ❌ **否决** |
| B. 彻底删除 | ✅ **采纳** |

**否决 A 的理由**：

1. **它是一个假的扩展点。** 留空常量本身不提供任何能力，真正的联机能力在被我们删掉的 445 行 `server.js` 里。留一个空字符串常量，等于留一句自我安慰的注释。
2. **它会诱导错误的代码形态。** 只要这个常量存在，后续开发就有理由写 `if(CLOUD_ENDPOINT){...}` 分支——**这正是我们花 8 小时要清除的东西**，一个月后它会重新长回来。
3. **它违反硬约束的字面表述。** 用户拍板的是"零服务端"，不是"暂时不开服务端"。
4. **删除是可逆的。** 真要做联机，`git log` 里有完整的前作实现可以回捞。保留一个空常量并不会让那天更容易。

> ✅ **替代做法**：在 `01-main-architecture.md` 的模块边界一节声明「存档层是唯一的持久化出口，任何网络 I/O 都必须先修改本文档」。**用文档约束，不用死代码占位。**

### 4.4 ⚠️ 前作存档不做迁移

本作是**全新游戏**，前作存档**不导入、不兼容**。`arcanum_*` 与 `nightwatch_*` 命名空间天然隔离，同域名下可共存互不干扰。
`applyCompat()` L3582-3631 那 50 行"防御式补字段"**不要移植**——ADR-002 用版本号 + 迁移链取代它。

---

## 5. 回归验证清单 🔴 交付物的核心

> **判定规则**：每条都以 S0 采集的基线为对照。**任一条 ❌ 即回滚该步骤，不允许"先记着后面再说"。**
> 全部手工可验，不需要自动化测试框架。

### 5.1 冒烟层（S1 之后立即执行）

| # | 场景 | 操作 | 通过判据 |
|---|---|---|---|
| R0 | 守卫已解耦 | 战斗中在控制台执行 `Auth.user=''` | ✅ 战斗继续 tick、界面继续刷新、`localStorage` 时间戳继续更新 |

### 5.2 战斗逻辑回归（S3 之后，**最重要**）

| # | 场景 | 具体操作 | 通过判据 | 针对的危险 |
|---|---|---|---|---|
| **R1** | 单人 ATB 顺序 | 装高攻速武器（短匕 spd 54）打一只低速怪，观察 20 回合 | ✅ 玩家出手频率明显高于怪物；无"双方同时卡住不动" | 3.1 整块删 |
| **R2** | 普攻伤害与日志 | 卸下全部技能书，打满一场 | ✅ 每次普攻都有日志行；暴击有 `暴击!` 后缀；伤害数值区间与基线一致 | 3.3 basicAttack |
| **R3** | 单体伤害技能 | 装一个 `type:'dmg'` 单段技能，打 10 次 | ✅ 日志「施放【X】N级 对 Y 造成 Z」正常；`slow`/`vuln` debuff 图标出现 | 3.4 L2683 |
| **R4** | 🔴 连战链 | 地图内开启自动连战，连打 5 场 | ✅ 胜利后 **450ms 自动接下一场**，不弹回地图、不弹窗 | **3.5 L2763 提前 return** |
| **R5** | 治疗技能 | 装治疗技，打到残血触发 | ✅ HP 回升，日志「恢复 N 生命」 | 3.4 L2700 |
| **R6** | ⚠️ 多段技能日志 | 装一个 `hits>1` 的技能（如 3 段），施放 5 次 | ✅ 日志必须出现「→ 第2击 N」「→ 第3击 N」**逐击成行**；总伤害 = 各击之和 | **3.4 L2689 误删整行** |
| **R7** | 🔴 护盾技能 | 装一个 `def.shield` 技能，施放后**紧盯玩家血条上的 `🛡` 数字** | ✅ `🛡` 数字出现且 >0；再挨一次打时先扣盾后扣血 | **3.4 L2708 静默失效** |
| **R8** | Buff 技能 | 装攻击/攻速 buff 技，施放 | ✅ buff 条出现；`effSpd()` 变化可从出手频率看出 | 3.4 L2705 |
| **R9** | 眩晕 / DoT | 装 stun 与 dot 技 | ✅ 目标「被眩晕，无法行动」；DoT 每回合扣血 | 回归 unitAct 未被误改 |
| **R10** | 药剂自动回复 | 血量降到 70% 以下 | ✅ 血药自动涓流回复；带「急涌」词缀的在 40% 以下爆发回复 | 3.1 applyFlasks |
| **R11** | 战败流程 | 故意打不过 | ✅ 「你倒下了」；HP 恢复到 30%、MP 50%；回到地图 | 3.5 |
| **R12** | 掉落 | 打 30 场普通怪，统计装备掉落次数 | ✅ 掉落率 ≈ 35%（基线同区间，允许 ±10% 随机波动）；技能书偶发 | 3.6 `*dm` |
| **R13** | 精英 / BOSS | 打到精英与 BOSS 各一次 | ✅ 掉落品质提升；BOSS 后解锁下一张图；地图巡回重置 | 3.5 |

### 5.3 联机残留清零（S5 之后）

| # | 场景 | 通过判据 |
|---|---|---|
| **R14** | **控制台零 WebSocket** | 打开 DevTools Console + Network，游玩 5 分钟：✅ 无 `WebSocket connection ... failed`、无 `ws://` 请求、无重连日志 |
| **R15** | **零 fetch** | Network 面板过滤 `Fetch/XHR`：✅ **请求数为 0** |
| **R16** | 全局符号清零 | 控制台执行：✅ `typeof MMO`、`typeof Auth`、`typeof CloudSave`、`typeof sendPB`、`typeof startPartyBattle` **全部返回 `"undefined"`** |
| **R17** | 死分支清零 | 全文搜索：✅ `partyMode` / `sendPB` / `_partyDmg` / `lootWinner` / `aggro` / `noLoot` **命中数为 0** |
| **R17.1** | 战利品 MMO 松散材料清零 | 全文搜索：✅ `loot.materials` 命中数为 0；`matAdd(` 仅剩 L2133 定义 + L2150 分解调用 2 处（**无 `matAdd('common'` 掉落调用**） | GDD 05 §220 E1 / §251 A5 |
| **R18** | 断网 | 关掉网络适配器，硬刷新（Ctrl+Shift+R） | ✅ 完整可玩，控制台零红字 |
| **R19** | `file://` 直开 | 双击 `index.html`（非 http server） | ✅ 完整可玩（前作已有 `IS_FILE` 常量，说明这条前作就支持） |

### 5.4 存档完整性（S7 之后）

| # | 场景 | 通过判据 |
|---|---|---|
| R20 | 冷启动创角 | 清空 localStorage → 打开 → ✅ 直达槽位屏，无登录墙 |
| R21 | 存读一致 | 装备/技能/材料/药剂充能状态 → 刷新 → ✅ 全部一致 |
| R22 | 20s 自动存 | 改变金币后等 25s，不刷新，直接看 `localStorage` → ✅ 已更新 |
| R23 | 战中存档 | 战斗第 3/6/9 回合 → ✅ `scheduleSave` 触发（防抖锁生效，不重复写） |
| R24 | 多槽隔离 | 3 个槽位各建一个角色，来回切 → ✅ 数据不串档 |
| R25 | 崩溃恢复 | 战斗中直接关闭标签页 → 重开 → ✅ `G.battle` 已清空，回到地图，进度不丢（`applyCompat` L3630 现有行为） |
| R26 | 容量护栏 | 人为塞满背包至上限 → ✅ 触发提示而非 `QuotaExceededError` |

---

## 6. 工作量与风险评估

### 6.1 工作量

| 阶段 | 内容 | 工时 | 风险 |
|---|---|---|---|
| S0 | 基线固化 | 0.5h | 🟢 无 |
| **S1** | **Auth 守卫中性化（5 处）** | **0.5h** | 🔴 **高**（漏一处 → 静默 brick） |
| S2 | startBattle 闸门 + 删 startPartyBattle | 0.3h | 🟡 中（顺序错 → ReferenceError） |
| **S3** | **partyMode 战斗层（6 个函数，13 个删除点）** | **2h** | 🔴 **最高** |
| S3.7 | 战利品 MMO 松散材料剥离（GDD 05 §220 E1） | 0.3h | 🟢 低（仅删掉落路径，保留 matAdd） |
| S3.8 | 🟦 技能优先级重排（GDD 03 §3.3，同文件批量） | 0.3h | 🟡 中（非剥离项，独立验收） |
| S4 | partyMode UI 层 | 0.5h | 🟡 中 |
| S5 | MMO 块整体删 + HTML/CSS 清理 | 0.3h | 🟢 低（物理隔离） |
| S6 | Auth/CloudSave 拆除 | 1h | 🟡 中（`CloudSave._timer` 易漏） |
| S7 | 存档命名空间迁移 | 1h | 🟡 中 |
| S8 | 创角流程重写 | 2h | 🟡 中 |
| — | **回归验证 R0-R26 全跑一遍** | **1.5h** | — |
| | **合计** | **≈ 10.2h（约 1.5 个工作日）** | |

> 📌 相比策划的预期，S5（MMO 删除）比想象**简单得多**（物理隔离），但 S1（Auth 守卫）是**清单上原本没有的额外工作**，两者大致抵消。

### 6.2 风险登记

| ID | 风险 | 等级 | 触发条件 | 缓解 |
|---|---|---|---|---|
| **RK-1** | `castSkill` L2708 护盾静默失效 | 🔴 **严重** | 误删整行而非行内片段 | R7 强制观察 `🛡` 数字；建议此行**单独一次提交**，便于回滚 |
| **RK-2** | Auth 守卫漏改 | 🔴 严重 | 5 处只改了 4 处 | S1 独立执行 + R0 验证；`grep -n "Auth.isLoggedIn"` 结果必须为空 |
| **RK-3** | 删除顺序颠倒（先删 MMO 块） | 🟡 中 | 不按 S1→S8 走 | 每场战斗立刻 ReferenceError，**响亮失败**，风险实际可控 |
| **RK-4** | L2689 多段技能日志丢失 | 🟡 中 | 误删整行 | R6 |
| **RK-5** | `CloudSave._timer` 遗漏 | 🟡 中 | S6 删 CloudSave 时没迁移防抖锁 | `scheduleSave` 会抛 `Cannot read property '_timer' of undefined`，**响亮失败** |
| **RK-6** | 存档容量超限 | 🟡 中 | 见 `01-main-architecture.md` §6 | 精简 schema + 背包上限 + 槽位不存全量快照 |
| **RK-7** | 「顺手修 bug」污染基线 | 🟢 低 | 修 §1 的 `*dm` bug | 明令禁止；单独开 Phase 4 issue |
| **RK-8** | 技能优先级重排（S3.8）误伤 `castSkill` | 🟡 中 | 与 S3 同文件改动，误碰护盾/多段逻辑 | 同文件改动前先跑 R1-R13 基线；R7 护盾单独提交；S3.8 独立评审 |

### 6.3 提交粒度建议

按 S0-S8 分 **9 个原子提交**，每个提交后跑对应的回归条目。
🔴 **特别地**：S3 建议再拆成 6 个提交（每函数一个），其中 `castSkill()` 的改动**单独一提交**——它是 RK-1 的唯一载体，需要最细的回滚粒度。

---

## 7. 完成定义（DoD）

本任务视为完成，当且仅当：

- ✅ R0-R26 **全部 26 条通过**，且有基线对照记录
- ✅ `grep` 结果为空：`MMO` / `Auth` / `CloudSave` / `sendPB` / `partyMode` / `_partyDmg` / `CLOUD_ENDPOINT` / `/api/` / `loot.materials`
- ✅ `matAdd(` 调用仅剩 L2150（分解）一处；无 `matAdd('common'` 掉落残留（GDD 05 §220 E1）
- ✅ 技能优先级已按 GDD 03 §3.3 重排（A2/A3/A4/A9 通过）——**独立项，不计入 grep 清零**
- ✅ 断网 + `file://` 双击可完整游玩一张图
- ✅ DevTools Network 面板请求数 = 0
- ✅ localStorage 中只存在 `arcanum_*` 前缀的 key

**只有 DoD 全绿，才允许开始 Phase 4 的任何内容替换工作。**

---

*文档结束 · 关联：`01-main-architecture.md`、`adr/ADR-002`、`adr/ADR-004`*
