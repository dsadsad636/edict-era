# GDD 03 · 技能系统

> 《敕造纪元 · 持牌者》· 工程代号 `Arcanum`
> 覆盖 system-breakdown：**C1–C6**
> 版本 v2.0 · 作者：文策渊（v1.0）/ 欧尼酱（v2.0 重设计）
> ⚖️ **本 GDD 含 team-lead 指定的跨成员裁决：§3.6「元素学派 vs 属性三系」关系结论**

---

## 1. 概述

技能是**武器选择的兑现方式**——换武器就是换技能池，这是本作 build 分叉的主开关（支柱一）。
v2.0 共 **61 个技能**：三系 51（每系 17）+ 通用 3 + 光环 4 + 禁咒 3。

**字段结构 100% 沿用 `SKILLS` 既有字段**，不新增任何影响公式的字段（`school` 与 `license` 为纯表现层字段）。

### v2.0 设计目标：双路线 Build 分化

每系 17 技能 = **7 共享核心** + **2 × 5 路线专属**。路线在高阶（mid/high tier）完全分化，玩家通过技能书掉落和主动学习选择走哪条路线。

| 力量系 | A · 铁壁守卫 | 护盾堆叠 / 减伤 / 控制 | B · 狂怒武者 | 爆发 / 自增益 / 高伤 |
| 敏捷系 | A · 影刃刺客 | 毒伤 / 暴击 / 连击 | B · 猎手游侠 | 控制 / 减速 / 多重 |
| 智力系 | A · 元素毁灭者 | 火雷爆发 / 范围 | B · 圣言守护者 | 治疗 / 护盾 / 光系 |

### 🔴 本 GDD 的关键发现（v2.0 已修复）

| # | 发现 | 影响 |
|---|---|---|
| 1 | 🐛 **增益/治疗技能几乎永远不会释放**（v1.0 已修复：§3.3 优先级方案） | 修复后 buff/heal/shield 等 25+ 非伤害技能正常参与技能轮转 |
| 2 | 🐛 **治疗技能会在满血时释放**（v1.0 已修复：hp≥85% 不释放） | |
| 3 | 🛡️ **护盾无上限叠加**（v2.0 已修复：上限 maxHp×50%） | 防止铁壁守卫路线无敌 |

---

## 2. 设计目标

| # | 目标 | 对应支柱 / 红线 |
|---|---|---|
| G1 | 换武器 = 换玩法，而非换数字 | 支柱一 |
| G2 | 技能自动释放的结果**可预测**，玩家能在出击前推演 | 支柱一（"你不操作战斗，你设计战斗"） |
| G3 | 三系技能池强度相当，无主导流派 | 🔴 红线：主导策略 |
| G4 | 禁咒（Boss 技）是"抢来的违禁法术"，机制上也要"越界" | 支柱三 |
| G5 | 光环提供无操作的长线成长感 | 支柱二 |

---

## 3. 机制规则

### 3.1 技能获取 ✅

- 技能书掉落 → 学习（等级 1）
- 重复技能书 → 等级 +1
- 技能等级效果：`实际倍率 = mult + (等级 − 1) × 0.08`
- 装备 `skillLv` 词缀可额外 +等级（沿用 `skillLevel()`）

### 3.2 武器绑定 ✅（核心机制，不改）

`weapons` 数组列出可释放该技能的武器类型；`null` = 不限。
不匹配时：**技能保留、等级保留、战斗中不释放**（`skillWeaponOk()`）。

> 💡 这是 G1 的全部实现。玩家从骑士剑换成长弓，力量系 5 技全部熄火、敏捷系 5 技全部点亮——
> 这个"整套玩法切换"的瞬间就是本作最重要的决策时刻。

### 3.3 释放优先级 🔧（🐛 必须修复）

**引擎现状**（`unitAct()` L2633）：
```
ready = 技能.filter(cd<=0 && mp>=cost).sort((a,b) => b.mult − a.mult)
释放 ready[0]，否则普通攻击
```
`buff`/`heal` 类技能**没有 `mult` 字段** → 排序值取 0 → **永远排在所有伤害技能之后**。

**后果**（v2.0）：61 技能中约 35%（21 个 buff / heal / shield 类技能）会在旧引擎中实质失效。

**修复方案 🔧（新增 `prio` 字段 + 条件判定，约 15 行代码）**：

| 优先级 | 条件 | 说明 |
|---|---|---|
| **P0 紧急治疗** | `type='heal'` 且 `hp < 40%` | 最高优先，救命 |
| **P1 护盾** | `type='buff'` 且有 `shield` 且 `hp < 70%` 且无护盾 | 预防性减伤 |
| **P2 增益** | `type='buff'` 且**未在生效中** | 上 buff，且**不重复叠加** |
| **P3 伤害** | `type='dmg'/'dot'` | 按 `mult` 降序（沿用原逻辑） |
| **P4 普通攻击** | 无可用技能 | 兜底 |

**治疗技能追加约束**：`hp ≥ 85%` 时**不释放**（避免满血浪费）。

> 📌 这是本 GDD 唯一要求的代码改动，但它是**必须的**——不改则 1/3 的技能内容是死的，
> 玩家花时间学到的增益技完全不生效，直接违反 G2（可预测性）。

### 3.4 法力消耗 ✅

`cost = 8 + cd × 3`；每次行动自然回复 **+3** 法力（沿用）。

### 3.5 光环 ✅

`type:'aura'`，常驻被动，**不占施法轮次**，不进 `ready` 队列。效果按等级线性叠加（`auraBonuses()`）。

### 3.6 ⚖️ 裁决：元素学派 与 属性三系 的关系

> **team-lead 指定必须给出结论的问题**：美术定义了 9 个元素学派色相（火/冰/雷/土/圣/暗/自然/奥术/毒），
> 而我的 C 组是力/敏/智三系。二者是什么关系？

#### 结论：**正交双标签。`attr` 进数值，`school` 只进表现层与叙事，不进任何公式。**

| 标签 | 字段 | 层级 | 作用 | 是否影响数值 |
|---|---|---|---|---|
| **属性归属** | `attr`（`str`/`agi`/`int`/`null`） | 数值层 | 决定用 `atk` 还是 `matk` 结算；决定武器绑定 | ✅ **是**（骨架既有） |
| **元素学派** | `school`（9 选 1 + `physical`） | 表现层 + 叙事层 | 决定图标色相、特效配色、文案用词、合法性标签 | ❌ **否**（🆕 纯数据字段） |

#### 为什么学派不进数值——三条理由

| # | 理由 | 说明 |
|---|---|---|
| **R1** | **会引入一整套抗性系统** | 学派若影响伤害，就必须有怪物火抗/冰抗/暗抗…… 9 条抗性 × 27 只怪 = 243 个新数值，且 `dealDamage()` 只有 `def`/`mdef` 两条减伤通道，要改核心公式。**MVP 撑不住** |
| **R2** | 🔴 **触碰认知过载红线** | 玩家已需同时管理：属性归属、武器绑定、CD、tier、技能等级。再加 9 学派 × 抗性克制 = 认知崩溃。概念文档 §9 明确把认知过载列为红线 |
| **R3** | **收益与成本不成比例** | 学派克制的乐趣需要"换技能应对不同怪"，但本作是**自动战斗**——玩家不能临场换技能，克制关系只会变成"出击前查表"的负担，而非乐趣 |

#### 学派实际承担的两个职责（都很有价值）

**职责一 · 视觉识别**：9 色相给美术总监完整的技能图标配色依据，不浪费他的设计。

**职责二 · 叙事分类（支柱三的落点）** —— 学派决定该咒文的**注册状态**：

| 注册状态 | 学派 | 叙事 |
|---|---|---|
| ✅ **注册咒文** | 火 · 冰 · 雷 · 土 · 圣 | 秘典庭批准的五个公开学派，有编号 |
| ⚠️ **限制咒文** | 自然 · 奥术 | 需特许状，越级使用属违规 |
| 🔴 **私法咒文** | 暗 · 毒 | **未注册即违法**。禁咒全部属于此类 |
| ⚪ 无学派 | 物理 | 纯武技，不需登记（"挥剑不犯法"） |

> 💡 **这让"越强越违法"从口号变成可见的数据**：玩家技能面板上，高阶技能明显更多地标着 🔴 私法。
> 零机制成本，纯靠标签实现支柱三。**这也是 Later「越权通缉度」机制的数据基础**——届时只需读这个已存在的字段。

#### 给美术总监的对齐要点

1. ✅ 9 色相**全部采用**，无浪费
2. 🆕 需补第 10 类 **「物理/无学派」** 的中性色（建议：钢灰 `#8a97a6`，与板甲同源）
3. 🆕 三种注册状态需要**边框差异**：注册=规整实线框 / 限制=虚线框 / 私法=**歪斜手写感边框且盖不上章**（呼应概念文档 §10.3 的"两套符文语言"）

---

## 4. 数据结构与字段

### 4.1 `SKILLS` 条目（✅ 沿用全部字段 + 🆕 2 个纯数据字段）

```
{
  name, cd, type:'dmg'|'dot'|'buff'|'heal'|'aura',
  mult, hits, turns, val, shield, heal,
  stun, stunTurns, slow, slowTurns, vuln, vulnTurns,
  spdBoost, auraStat,
  attr:'str'|'agi'|'int'|null,     // 数值层
  weapons:[...]|null,               // 武器绑定
  icon, tier:'base'|'mid'|'high'|'aura'|'boss', desc,
  school:'fire'|'ice'|...|'physical',   // 🆕 表现层，不进公式
  license:'registered'|'restricted'|'illicit'|'none'  // 🆕 叙事层，不进公式
}
```

### 4.2 字段语义速查

| 字段 | 含义 | 单位 |
|---|---|---|
| `cd` | 冷却，**按行动次数递减**（非 tick） | 次 |
| `mult` | 伤害倍率（乘 `atk` 或 `matk`） | 倍 |
| `hits` | 连击次数 | 次 |
| `turns` | 持续回合 | 回合 |
| `val` | 增益幅度（攻击力提升） | 比率 |
| `shield` | 护盾量（占最大生命比） | 比率 |
| `heal` | 治疗量（占最大生命比） | 比率 |
| `stunTurns` / `slowTurns` / `vulnTurns` | 控制/减速/易伤持续 | 回合 |
| `slow` / `vuln` | 减速率 / 易伤加成 | 比率 |
| `spdBoost` | 攻速提升 | 比率 |

---

## 5. 完整数值表（v2.0 · 61技能）

### 5.1 力量系（`attr:'str'`，`weapons`：手斧/骑士剑/十字大剑/双刃战斧/钉头锤）· 17技能

**共享核心（7）：**

| `key` | 名称 | `tier` | `cd` | `type` | 数值 | `school` | 注册 |
|---|---|---|---|---|---|---|---|
| `heavy_slash` | **重斩** | base | 3 | dmg | `mult:2.2` | physical | none |
| `sunder_strike` | **破甲击** | base | 4 | dmg | `mult:1.6, vuln:0.20, vulnTurns:2` | physical | none |
| `war_cry` | **战吼** | base | 5 | buff | `turns:3, val:0.20` | physical | none |
| `shield_bash` | **盾击** | mid | 6 | dmg | `mult:1.3, stun:1, stunTurns:1` | physical | none |
| `cleave` | **横扫** | mid | 4 | dmg | `mult:1.5, hits:2` | physical | none |
| `iron_forge` | **锻体** | mid | 6 | buff | `turns:2, shield:0.15` | physical | none |
| `executioner` | **处决** | high | 8 | dmg | `mult:3.0` | physical | none |

**路线A · 铁壁守卫（5）：**

| `key` | 名称 | `tier` | `cd` | `type` | 数值 | `school` | 注册 |
|---|---|---|---|---|---|---|---|
| `bastion_wall` | **壁垒** | mid | 6 | buff | `turns:2, shield:0.25` | earth | none |
| `resolve` | **坚毅** | mid | 7 | buff | `turns:3, val:0.20, shield:0.12` | physical | none |
| `unyielding` | **不屈** | mid | 7 | heal | `heal:0.15` | physical | none |
| `quake_strike` | **地裂击** | high | 6 | dmg | `mult:2.0, slow:0.25, slowTurns:2` | earth | restricted |
| `adamant` | **金刚壁垒** | high | 8 | buff | `turns:3, shield:0.35` | earth | restricted |

**路线B · 狂怒武者（5）：**

| `key` | 名称 | `tier` | `cd` | `type` | 数值 | `school` | 注册 |
|---|---|---|---|---|---|---|---|
| `blood_frenzy` | **血怒** | mid | 6 | buff | `turns:2, val:0.35, spdBoost:0.15` | physical | none |
| `reckless_smash` | **鲁莽猛击** | mid | 5 | dmg | `mult:2.5` | physical | none |
| `rampage` | **狂暴突进** | mid | 5 | dmg | `mult:1.8, hits:2` | physical | none |
| `death_wish` | **死愿** | high | 7 | buff | `turns:2, val:0.45, spdBoost:0.25` | dark | illicit |
| `obliterate` | **湮灭** | high | 8 | dmg | `mult:3.5` | dark | illicit |

### 5.2 敏捷系（`attr:'agi'`，`weapons`：短匕/双刺/紫杉长弓/钢弩）· 17技能

**共享核心（7）：**

| `key` | 名称 | `tier` | `cd` | `type` | 数值 | `school` | 注册 |
|---|---|---|---|---|---|---|---|
| `quick_shot` | **连击** | base | 2 | dmg | `mult:1.4, hits:2` | physical | none |
| `poison_edge` | **淬毒刃** | base | 3 | dot | `mult:0.6, turns:3` | poison | illicit |
| `shadow_dance` | **影舞** | base | 6 | buff | `turns:3, spdBoost:0.30` | physical | none |
| `piercing_shot` | **穿透击** | mid | 4 | dmg | `mult:2.0` | physical | none |
| `snare_trap` | **缚足陷阱** | mid | 5 | dmg | `mult:1.1, slow:0.25, slowTurns:2` | ice | registered |
| `evasive_step` | **闪避步** | mid | 5 | buff | `turns:2, spdBoost:0.15, shield:0.10` | physical | none |
| `fatal_strike` | **致命一击** | high | 7 | dmg | `mult:2.8` | physical | none |

**路线A · 影刃刺客（5）：**

| `key` | 名称 | `tier` | `cd` | `type` | 数值 | `school` | 注册 |
|---|---|---|---|---|---|---|---|
| `venom_brand` | **剧毒烙印** | mid | 5 | dot | `mult:0.8, turns:4, vuln:0.15` | poison | illicit |
| `assassination` | **暗杀** | mid | 6 | dmg | `mult:2.2, hits:2` | dark | illicit |
| `poison_mist` | **毒雾** | mid | 4 | dot | `mult:0.7, turns:4` | poison | illicit |
| `reap` | **收割** | high | 7 | dmg | `mult:3.0` | dark | illicit |
| `death_mark` | **死亡标记** | high | 6 | buff | `turns:3, val:0.30` | dark | illicit |

**路线B · 猎手游侠（5）：**

| `key` | 名称 | `tier` | `cd` | `type` | 数值 | `school` | 注册 |
|---|---|---|---|---|---|---|---|
| `frost_trap` | **冰霜陷阱** | mid | 5 | dmg | `mult:1.3, slow:0.35, slowTurns:2` | ice | registered |
| `multi_shot` | **多重射击** | mid | 5 | dmg | `mult:1.5, hits:3` | physical | none |
| `blinding_powder` | **致盲粉** | mid | 7 | dmg | `mult:0.8, stun:1, stunTurns:1` | nature | restricted |
| `sticky_trap` | **粘性陷阱** | high | 6 | dmg | `mult:1.0, slow:0.25, vuln:0.20` | nature | restricted |
| `hunters_call` | **猎杀时刻** | high | 7 | buff | `turns:4, val:0.25, spdBoost:0.25` | nature | restricted |

### 5.3 智力系（`attr:'int'`，`weapons`：印杖/仪杖/咒律书/禁卷）· 17技能

**共享核心（7）：**

| `key` | 名称 | `tier` | `cd` | `type` | 数值 | `school` | 注册 |
|---|---|---|---|---|---|---|---|
| `fireball` | **火球术** | base | 3 | dmg | `mult:1.7` | fire | registered |
| `frost_nova` | **霜新星** | base | 4 | dmg | `mult:2.0, slow:0.20, slowTurns:2` | ice | registered |
| `heal_light` | **圣光术** | base | 5 | heal | `heal:0.18` | holy | registered |
| `chain_lightning` | **闪电链** | mid | 5 | dmg | `mult:1.9, vuln:0.15, vulnTurns:2` | lightning | registered |
| `ice_barrier` | **寒冰护盾** | mid | 5 | buff | `turns:1, shield:0.15` | ice | registered |
| `arcane_missile` | **奥术飞弹** | mid | 3 | dmg | `mult:1.3, hits:3` | arcane | registered |
| `arcane_rupture` | **禁咒·破** | high | 7 | dmg | `mult:2.5, vuln:0.25, vulnTurns:2` | arcane | restricted |

**路线A · 元素毁灭者（5）：**

| `key` | 名称 | `tier` | `cd` | `type` | 数值 | `school` | 注册 |
|---|---|---|---|---|---|---|---|
| `firestorm` | **烈焰风暴** | mid | 6 | dmg | `mult:2.3, vuln:0.20, vulnTurns:2` | fire | registered |
| `thunderbolt` | **雷击** | mid | 7 | dmg | `mult:2.5, stun:1, stunTurns:1` | lightning | registered |
| `meteor` | **陨石术** | high | 8 | dmg | `mult:3.2` | fire | restricted |
| `elemental_overload` | **元素过载** | high | 6 | buff | `turns:3, val:0.35` | arcane | restricted |
| `elemental_torrent` | **元素洪流** | high | 5 | dmg | `mult:2.0, hits:2` | lightning | restricted |

**路线B · 圣言守护者（5）：**

| `key` | 名称 | `tier` | `cd` | `type` | 数值 | `school` | 注册 |
|---|---|---|---|---|---|---|---|
| `hallow_heal` | **圣言·愈** | mid | 6 | heal | `heal:0.25` | holy | registered |
| `hallow_shield` | **圣言·盾** | mid | 6 | buff | `turns:2, shield:0.30` | holy | registered |
| `hallow_bless` | **圣言·佑** | mid | 7 | buff | `turns:3, val:0.15, shield:0.18` | holy | registered |
| `purify` | **净化** | high | 5 | heal | `heal:0.12` | holy | registered |
| `holy_judgment` | **神圣审判** | high | 6 | dmg | `mult:2.2, heal:0.10` | holy | registered |

### 5.4 禁咒（Boss 专属，`attr:null`，`weapons:null`，`tier:'boss'`）

| `key` | 名称 | 来源 Boss | `cd` | `type` | 数值 | `school` | 注册 |
|---|---|---|---|---|---|---|---|
| `boundary_wrath` | **界桩之怒** | 锈冠牡鹿 | 6 | dmg | `mult:2.6, stun:1, stunTurns:1` | nature | restricted |
| `blackmarket_toxin` | **黑市毒刃** | 「三指」奥兹 | 4 | dot | `mult:0.70, turns:4, vuln:0.20` | poison | illicit |
| `silent_hymn` | **无声圣咏** | 缄默圣女·艾德娜 | 7 | dmg | `mult:2.4, heal:0.10` | dark | illicit |

### 5.5 通用技与光环

**通用技**（`attr:null`, `weapons:null`, `tier:'base'`）：

| `key` | 名称 | `cd` | `type` | 数值 | `school` |
|---|---|---|---|---|---|
| `uni_strike` | **通用·重击** | 3 | dmg | `mult:1.8` | physical |
| `uni_guard` | **通用·守护** | 5 | buff | `turns:1, shield:0.12` | physical |
| `uni_mend` | **通用·急救** | 5 | heal | `heal:0.12` | holy |

**光环**（`type:'aura'`, `cd:0`, `tier:'aura'`）：

| `key` | 名称 | `auraStat` | `val`/级 | `school` |
|---|---|---|---|---|
| `aura_atk` | **加攻光环** | `atk` | 0.03 | arcane |
| `aura_spd` | **疾行光环** | `spd` | 0.02 | arcane |
| `aura_cast` | **通咒光环** | `skillDmg` | 0.04 | arcane |
| `aura_crit` | **破绽光环** | `crit` | 0.01 | arcane |

### 5.6 三系强度校验（v2.0 初估，待实测精算）

v2.0 技能池大幅扩展，加权倍率需真机实测后重新精算。当前保守估算三系 DPS 偏差预计在 ±12% 内，可通过掉落率与技能书 tier 分布微调平衡。

---

## 6. 边界与异常

| # | 场景 | 处理 |
|---|---|---|
| 🐛 **E1** | **增益/治疗永不释放** | 🔴 必修，见 §3.3 优先级方案 |
| 🐛 **E2** | **满血时释放治疗** | `hp ≥ 85%` 不释放 |
| **E3** | 增益重复叠加 | 同类 buff 生效中不重复释放（P2 规则）；若强制释放则**刷新持续时间**而非叠加数值 |
| **E4** | 法力不足 | 该技能不进 `ready`，退化为普通攻击。**不报错、不卡死** |
| **E5** | 法力枯竭（约 48 秒后） | 设计内行为。由法力药剂（GDD 05 §6）续航；无药剂则纯普攻，战斗仍可完成 |
| **E6** | 未装备武器 | 所有 `weapons≠null` 技能失效，仅通用技 + 禁咒可用。**UI 需灰显并提示原因** |
| **E7** | 武器不匹配 | 同上；技能列表显示"需要：手斧/骑士剑/…" |
| **E8** | `hits` 多段与吸血 | 每段独立结算吸血与暴击（沿用），注意 GDD 02 H1 的吸血超模风险**在多段技上被放大** |
| **E9** | 眩晕期间 CD | `processStartBuffs()` 先递减 buff，被眩晕则跳过行动 → **CD 不递减**（沿用原行为） |
| **E10** | 技能等级溢出 | 无上限设计；`mult + (lv−1)×0.08`，10 级时 +0.72 倍率。**MVP 实测若过强则设 10 级上限** |
| **E11** | 护盾叠加 | `a.shield += sh` 累加，无上限。⚠️ 建议夹取为 `min(maxHp×0.5, shield)` |
| **E12** | dot 与目标死亡 | 目标死亡则 dot 失效，不结算残余伤害 |
| **E13** | 禁咒未学习时掉落重复书 | 等级 +1（沿用普通技能书逻辑） |

---

## 7. 与其他系统的依赖

| 方向 | 系统 | 关系 |
|---|---|---|
| ⬆️ 依赖 | **GDD 01** | `atk`/`matk`/`skillDmg` 来源；法力池公式 |
| ⬆️ 依赖 | **GDD 02** | `weapons` 引用 `WEAPON_TYPES` key；`skillLv` 词缀；`aura` 与套装 `skillDmg` 叠加 |
| ⬇️ 被依赖 | **GDD 04 战斗** | `castSkill()` 消费全部字段；增益/减益状态机 |
| ⬇️ 被依赖 | **GDD 05 经济** | 技能书掉落率（base 6% / mid 2% / aura 5% 精英 / 禁咒 5% Boss） |
| ↔️ 横向 | 美术 | 🆕 9 学派色相 + 第 10 类"物理"中性色；3 种注册状态的边框差异 |
| ↔️ 横向 | 程序 | 🔴 **§3.3 优先级重排是必改代码**（约 15 行） |

---

## 8. 验收标准

| # | 标准 | 验证方式 |
|---|---|---|
| A1 | 25 个技能全部可学习、可升级 | 逐个给书 |
| A2 | 🐛 **增益技能会实际释放** | 装备力量武器只学 `war_cry`+`heavy_slash`，观察 30 回合内战吼是否触发 |
| A3 | 🐛 **满血不释放治疗** | 满血携带 `heal_light`，确认不触发 |
| A4 | 低于 40% 血量时优先治疗 | 扣血至 30% 观察 |
| A5 | 换武器后技能池正确切换 | 骑士剑 ↔ 长弓互换，查技能面板灰显状态 |
| A6 | 未装备武器时仅通用技+禁咒可用 | 卸武器观察 |
| A7 | 技能等级提升倍率 `+0.08/级` | 1 级与 5 级同技能伤害对比 |
| A8 | 4 个光环常驻生效且不占行动 | 面板对比 + 战斗日志确认无光环施法记录 |
| A9 | 3 个禁咒不受武器限制 | 任意武器下均可释放 |
| A10 | 三系加权倍率差 ≤10% | 三套 build 各打 20 场统计总伤 |
| A11 | 法力耗尽后退化为普攻不报错 | 持续战斗至 MP=0 |
| A12 | `school`/`license` 字段在 UI 正确显示 | 技能面板查看 |

---

## 9. 待验证假设

| # | 假设 | 风险 | 调整方向 |
|---|---|---|---|
| **H1** | 🔴 §3.3 的 5 级优先级能产生"可预测"的战斗 | 🔴 **高** | 本 GDD 最核心的改动。若实测行为仍难预测，改为**玩家可手动排序技能优先级**（更符合支柱一"你设计战斗"） |
| H2 | `aura_spd` 0.03/级过强 | 🟠 中高 | 建议先降至 0.02 实测 |
| H3 | 法力 48 秒枯竭的节奏合适 | 🟡 中 | 若过快，调 `cost` 公式或提高自然回复 |
| H4 | 技能等级无上限不会失控 | 🟡 中 | 若 10 级以上过强，设上限 10 |
| H5 | 三系加权倍率估算准确 | 🟡 中 | 该估算未计入控制/易伤的间接收益，需实测校正 |
| H6 | 25 技对 MVP 内容量足够 | 🟢 低 | 不足则从 V1 的 high tier 前移 |
| H7 | 学派不进数值不会让玩家觉得"元素是假的" | 🟡 中 | 若反馈强烈，V1 加**轻量**克制（仅 ±10%，只对少数怪） |
| H8 | 护盾无上限叠加不会破坏平衡 | 🟡 中 | E11 建议的 50% 上限需实测确认 |

---

*GDD 03 结束*
