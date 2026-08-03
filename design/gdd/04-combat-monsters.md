# GDD 04 · 战斗与怪物系统

> 《敕造纪元 · 持牌者》· 工程代号 `Arcanum`
> 覆盖 system-breakdown：**D1–D8**
> 版本 v1.1 · 作者：文策渊
> ⚔️ 沿用守夜人 ATB 引擎与 `enemyUnit` 缩放公式；主题层按概念文档 §6.3/§6.6 与美术圣经 §7 重写（v1.0 因"换皮源图 + 自定 body 枚举"被 P2-G 打回，本次修正）

---

## 1. 概述

战斗是**结算环节**（支柱一：准备是游戏，战斗是结算）。玩家不操作战斗，引擎按 ATB 自动裁决。本系统负责：
1. ✅ **沿用** 650ms/tick 的 ATB 自动战斗引擎（`tickBattle` / `effSpd` / `unitAct` / `dealDamage`）
2. 🔧 **主题层彻底重写**（v1.0 失败点）：五张图 = **五个势力据点**（概念 §6.3），不是五个生物群系；怪物是"人对人 / 违禁造物"，不是源作的雪原/虚空换皮
3. 🆕 **Boss 对齐概念 §6.6**：3 个 MVP Boss = **锈冠牡鹿 / 「三指」奥兹 / 缄默圣女·艾德娜**（与 GDD 02 §5.6 唯一装备、GDD 03 §5.4 禁咒一一对应）
4. ✅ **沿用** `enemyUnit` 缩放公式 `scale = 1 + tier×0.6 + (level−1)×0.10`（源码 L2455）
5. 🔧 **body 枚举改用美术圣经 §7.3 的 16 类**（`humanoid_civil` / `arcane_weave` 是美术专门补的）。**v1.0 我自定的 10 类枚举已作废**，详见 §4.2

> ⚠️ **P2-G 打回的三处根因（已修正）**：① 第 2/3 组直接换皮源作雪原/虚空图；② 图 2 Boss 错写成"黑市之主"而非「三指」奥兹；③ §4.2 自定 10 类 body 否决了美术已交付的 16 类、且缺 `humanoid_civil`，导致人型敌人无法表现。本次全部修正，**数值骨架与三项验算成果原样保留**。

---

## 2. 设计目标

| # | 目标 | 对应支柱 / 红线 |
|---|---|---|
| G1 | 玩家在出击前能预判胜负（靠 CP 对标，见 GDD 01 §5.5） | 支柱一 |
| G2 | 怪物**族群可区分且叙事成立**：人型=黑市活人、亡灵圣械=修道院圣骸 | 认知过载红线 |
| G3 | 三张图难度平滑递增，靠 def/mdef 分布而非突然跳数值 | 支柱二 |
| G4 | Boss 是"通缉名单上的人"（概念 §6.6），机制上也要越界（吸血/狂怒） | 支柱三 |
| G5 | 美术在 **16 类 `body`**（美术圣经 §7.3）上稳定出图 | ↔ 美术对齐 |

---

## 3. 机制规则

### 3.1 ATB 节奏（✅ 沿用）

| 参数 | 值 | 说明 |
|---|---|---|
| tick 间隔 | **650ms** | `setInterval(tickBattle, 650)` |
| 行动阈值 | `time ≥ 100` | 满 100 出手一次 |
| 充能速率 | `effSpd(u) = u.spd × (1+spdBoost) × (1−slow)` | 攻速 buff/debuff 实时生效 |
| 出手顺序 | `time` 高者先；平局玩家优先 | 保证 ATB 公平 |

> 玩家 `spd` ≈ 53（Lv20 + 手斧），约 **1.23 秒/行动**；怪物 `spd` 16–46（见 §5）。
> 单场 5 敌战斗约 **15–40 秒**，含清怪与拾取约 45 秒/场（GDD 05 §6 经济模型采用此值）。

### 3.2 怪物缩放公式（✅ 沿用 `enemyUnit`）

```
scale = 1 + tier×0.6 + (player.level − 1)×0.10
hp/atk/def/mdef = 基础值 × scale      （取整）
matk = round(def.atk × 0.6 × scale)    （怪物无 int，魔法伤害取物理的 0.6 折算）
mdef = round(def.def × 0.7 × scale)
spd / crit / critDmg / hit / eva 不随 scale 变化（固定基准）
```

> ⚠️ **MVP 封顶 Lv30**：tier2（修道院）在 Lv20 时 `scale = 1+1.2+1.9 = 4.1`，
> 缄默圣女·艾德娜 boss hp = 2000×4.1 = **8200**。需与 GDD 01 §5.6 的 Lv20 预期 CP 3400 联调（§5.4）。

### 3.3 五大家族与技能池（🆕 对齐概念 §6.3）

`family` 是**设计分组 + 行为分组**，不进伤害公式（与 GDD 03 的 `school` 同属表现/行为层）。五家族 = 概念 §6.3 的五个势力族群，**与地图一一对应**（美术圣经 §7.5）：

| `family` | 对应据点 | 怪物主体 | 主用 `body`（美术 §7.3/§7.5） |
|---|---|---|---|
| **污染兽** | 界桩荒野（tier0） | 魔素污染的走兽/植物 | `beast_quad` `beast_biped` `serpent` `arachnid` `ooze` `fey_plant` |
| **人型** | 黑印集市（tier1） | 走私犯/私法术士/雇佣兵（活人） | `humanoid_civil`（4 装束）`humanoid_small` `humanoid_brute` |
| **亡灵圣械** | 缄默修道院（tier2） | 教团圣骸与怨灵 | `skeleton` `wraith` `knight` `construct` |
| **构装体** | 灰铸厂（tier3，V1） | 王庭合法锻入兵器的造物 | `construct` `elemental` `knight` |
| **秘术造物** | 禁卷回廊（tier4，V1） | 悬浮书页/符文构成体 | `arcane_weave` `elemental` `drake` |

**家族技能池**（精英/小怪从中抽取；Boss 固定用 Boss 池）：

| 家族 | 小怪池 | 精英附加 |
|---|---|---|
| 污染兽 | `mb_bite` `mb_spit` `me_maul` | `me_venom` |
| 人型 | `mb_claw` `mb_slam` `me_fury` | `me_maul` |
| 亡灵圣械 | `mb_howl` `mb_spit` `me_regen` | `me_venom` |
| 构装体 | `mb_slam` `me_crush` `me_fury` | `me_crush` |
| 秘术造物 | `mb_spit` `me_regen` `me_venom` | `mboss_decay`（弱化） |

> 抽取数：小怪 1，精英 2–3，Boss 3–4（沿用 `enemyUnit` 的 `rand` 逻辑）。

### 3.4 Buff / Debuff 规则（✅ 与玩家共用一套状态机）

怪物释放的减益**复用玩家同一套 buff 状态机**（`unitAct` → `castSkill`），规则一致：

| 类型 | 字段 | 对玩家效果 | 持续 |
|---|---|---|---|
| 减速 `slow` | `slow` / `slowTurns` | `effSpd × (1−slow)` | `slowTurns` 回合 |
| 易伤 `vuln` | `vuln` / `vulnTurns` | 玩家承伤 × `(1+vuln)` | `vulnTurns` 回合 |
| 眩晕 `stun` | `stun` / `stunTurns` | 跳过玩家本次行动（CD 不递减，沿用 GDD 03 E9） | `stunTurns` 回合 |
| 增益 `val` | `val` / `turns` | 怪物 `atk × (1+val)` | `turns` 回合 |
| 生命汲取 | `lifesteal=0.35` | Boss 带 `mboss_drain` 时按自身输出回血 | 常驻 |

### 3.5 遭遇构成（🔧 MVP 假设）

一次"委托/遭遇"默认 **5 个敌人**：4 普通 + 0.5 精英（按地图 8 槽含 1 精英的概率折算）。Boss 为独立特殊遭遇（每图 1 只，手动触发）。该假设驱动 GDD 05 的经济模型，须在实测后校准。

---

## 4. 数据结构与字段

### 4.1 `MONSTERS` 条目（✅ 结构不变 + 🆕 `family`）
```
{name, emoji, hp, atk, def, spd, crit,
 family:'polluted'|'humanoid'|'undead'|'construct'|'arcane',   // 🆕 五大家族
 art:{body, feature, feature2, c1, c2, eye, scale?, flip?, aura?},  // 结构同美术圣经 §7.1
 elite?:true, boss?:true}
```

### 4.2 `art.body` —— 采用美术圣经 §7.3 的 **16 类**（🔧 作废 v1.0 的 10 类）

> ⚠️ **v1.0 错误已纠正**：我此前在 §4.2 自定了 10 类枚举并让美术"请勿新增"，这是错的——美术圣经 v1.1（§7.2/§7.3）已交付 **16 类**，其中专门补了 `humanoid_civil`（人型·常民）与 `arcane_weave`（秘术造物）。**GDD 04 现在以美术圣经 §7.3 为唯一权威**，下表即其原文。

| # | Key | 中文 | 类别 | 本作主要出场 |
|---|---|---|---|---|
| 1 | `humanoid_civil` | 人型·常民 | 人形 | **图2 黑印集市核心**（4 装束见 §4.3） |
| 2 | `humanoid_brute` | 巨人形 | 人形 | 图2 脱牌打手 / 图4 半人半构装 Boss |
| 3 | `humanoid_small` | 小人形 | 人形 | 图2 私法学徒 |
| 4 | `knight` | 甲胄人形 | 人形 | 图3 圣械守卫 / 图4 铆甲卫兵 |
| 5 | `beast_quad` | 四足兽 | 兽类 | **图1 污染兽核心** |
| 6 | `beast_biped` | 兽人形 | 兽类 | 图1 苔甲蜥等 |
| 7 | `skeleton` | 骸骨 | 亡灵 | **图3 亡灵圣械核心**（圣骸） |
| 8 | `wraith` | 幽魂 | 亡灵 | 图3 修道院幽魂 |
| 9 | `construct` | 构装体 | 构装 | 图3/图4 构装造物 |
| 10 | `arcane_weave` | 秘术造物 | 秘术 | **图5 禁卷回廊核心** |
| 11 | `elemental` | 元素体 | 元素 | 图4/图5 |
| 12 | `drake` | 龙裔 | 龙 | 图5 卷廊守龙 |
| 13 | `serpent` | 蛇形 | 兽类 | 图1 锈鳞蛇 |
| 14 | `arachnid` | 节肢 | 兽类 | 图1 蚀壳蛛 |
| 15 | `fey_plant` | 植物精 | 自然 | 图1 荆棘幼体 |
| 16 | `ooze` | 软泥 | 异怪 | 图1 腐囊菌 |

### 4.3 `humanoid_civil` 的 4 种职业装束（`garb_*`，美术 §7.2A，图2 专用）

| Key | 职业 | 剪影特征 | `eye` 取向 |
|---|---|---|---|
| `garb_warrior` | 雇佣兵 | 倒三角（上宽下窄） | 王家蓝 `#5ba3e8` |
| `garb_caster` | 私法术士 | 下宽梯形 + 尖顶兜帽 | 私法紫 `#b08cff` |
| `garb_rogue` | 走私犯 | 窄身 + 单侧不对称斗篷 | 自然绿 `#62c26a` |
| `garb_merchant` | 黑市掮客 | 圆胖 + 侧后背包凸起 | 敕造金 `#eba43c` |

> 装束占 `feature` 槽，`feature2` 留给持物（`hold_sword`/`hold_staff`/`hold_dagger`/`hold_torch`），职业与武装自由重组（美术 §7.2A）。

### 4.4 `MONSTER_SKILLS`（✅ 沿用全部字段，仅重命名）
```
{name, type:'dmg'|'dot'|'buff'|'heal', mult?, cd, hits?, turns?,
 slow?, slowTurns?, vuln?, vulnTurns?, stun?, stunTurns?, shield?, heal?, val?, spdBoost?}
```

---

## 5. 完整数值表

> 数值骨架（hp/atk/def/spd/crit）**沿用源作各槽位原值**（平衡已验证），仅替换名称 / `family` / `art`。`c1/c2/eye` 取自美术圣经 §7.6 组合矩阵（同族换 `eye` 色做变种，零成本）。

### 5.1 MVP 三图 27 怪全表（含 `art` 与 `family`）

**图1 · 界桩荒野（tier0 · 污染兽）** —— 王国最外圈界桩，符文褪色，逸散魔素把野兽拧成别物：

| key | 名称 | family | body | feature | feature2 | c1 | c2 | eye | hp | atk | def | spd | crit | 角色 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| border_hound | 界桩癞犬 | 污染兽 | beast_quad | mane | swarm | #6f8a52 | #3d4d2c | #a8c93a | 80 | 18 | 8 | 30 | .06 | 普通 |
| moss_scaler | 苔甲蜥 | 污染兽 | beast_biped | scales | — | #5f7d4a | #36512a | #a8c93a | 70 | 16 | 6 | 36 | .05 | 普通 |
| rot_pod | 腐囊菌 | 污染兽 | ooze | — | — | #8fae5a | #4d6b2e | #a8c93a | 60 | 12 | 5 | 24 | .08 | 普通 |
| thornling | 荆棘幼体 | 污染兽 | fey_plant | spikes | — | #6b6f3a | #3c3f1f | #62c26a | 90 | 14 | 12 | 22 | .04 | 普通 |
| rust_serpent | 锈鳞蛇 | 污染兽 | serpent | — | — | #7a6a4a | #3d3128 | #ff7a33 | 55 | 20 | 4 | 42 | .10 | 普通 |
| etch_spider | 蚀壳蛛 | 污染兽 | arachnid | — | flames | #4a3d55 | #241d2c | #ff7a33 | 75 | 15 | 6 | 28 | .05 | 普通 |
| mud_beast | 泥怨兽 | 污染兽 | beast_quad | swarm | — | #6b5a45 | #3a2f22 | #a8c93a | 85 | 13 | 14 | 20 | .03 | 普通 |
| stone_shin | 界桩看守·石胫 | 污染兽 | beast_quad | spikes | — | #5a6b4a | #2e3a26 | #cf9c5c | 420 | 42 | 26 | 30 | .10 | **精英** |
| rust_stag | **锈冠牡鹿** | 污染兽 | beast_quad | antlers | — | #6f8a52 | #3d4d2c | #ff7a33 | 1300 | 72 | 42 | 34 | .15 | **BOSS** |

**图2 · 黑印集市（tier1 · 人型）** —— 地下黑市，第一次杀人而不是杀怪（概念 §6.3）：

| key | 名称 | family | body | feature | feature2 | c1 | c2 | eye | hp | atk | def | spd | crit | 角色 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| merc_hire | 雇佣兵 | 人型 | humanoid_civil | garb_warrior | hold_sword | #8a7a66 | #4a4034 | #5ba3e8 | 95 | 20 | 10 | 34 | .08 | 普通 |
| private_mage | 私法术士 | 人型 | humanoid_civil | garb_caster | runes_orbit | #5b4a86 | #2e2448 | #b08cff | 70 | 18 | 8 | 40 | .06 | 普通 |
| smuggler | 走私犯 | 人型 | humanoid_civil | garb_rogue | hold_dagger | #5a5148 | #2c2722 | #62c26a | 100 | 16 | 16 | 24 | .04 | 普通 |
| broker | 黑市掮客 | 人型 | humanoid_civil | garb_merchant | hold_torch | #7d6a4a | #3f3626 | #eba43c | 85 | 22 | 9 | 30 | .12 | 普通 |
| mage_init | 私法学徒 | 人型 | humanoid_small | — | — | #6a4a8a | #2f1f4a | #b08cff | 65 | 24 | 6 | 44 | .12 | 普通 |
| enforcer | 脱牌打手 | 人型 | humanoid_brute | — | — | #8a7a66 | #4a4034 | #8a8578 | 140 | 20 | 22 | 16 | .05 | 普通 |
| scout | 黑印哨探 | 人型 | humanoid_civil | garb_rogue | hold_dagger | #5a5148 | #2c2722 | #5ba3e8 | 72 | 14 | 7 | 26 | .05 | 普通 |
| black_hand | 黑印打手 | 人型 | humanoid_brute | hold_sword | — | #7a6a56 | #3f3626 | #8a8578 | 520 | 54 | 34 | 30 | .12 | **精英** |
| oz_threefinger | **「三指」奥兹** | 人型 | humanoid_civil | garb_merchant | hold_torch | #7d6a4a | #3f3626 | #eba43c | 1700 | 88 | 52 | 40 | .18 | **BOSS** |

**图3 · 缄默修道院（tier2 · 亡灵圣械）** —— 教团把"神迹"藏在圣骸里逃避登记（概念 §6.3）：

| key | 名称 | family | body | feature | feature2 | c1 | c2 | eye | hp | atk | def | spd | crit | 角色 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| silent_bone | 缄默骸骨 | 亡灵圣械 | skeleton | hold_sword | hold_shield | #d8d2be | #7a745e | #6cd8f0 | 100 | 22 | 10 | 32 | .10 | 普通 |
| reliquary_guard | 圣械守卫 | 亡灵圣械 | knight | helm_great | halo | #b8ae90 | #6b6248 | #ffe9a8 | 110 | 18 | 16 | 24 | .06 | 普通 |
| cloister_wraith | 修道院幽魂 | 亡灵圣械 | wraith | — | chains | #4a4560 | #241f38 | #b08cff | 80 | 24 | 8 | 40 | .12 | 普通 |
| penitent_ghost | 苦修怨灵 | 亡灵圣械 | wraith | — | runes_orbit | #4a4560 | #241f38 | #cbb2ff | 95 | 26 | 10 | 34 | .12 | 普通 |
| rust_construct | 锈械魔像 | 亡灵圣械 | construct | spikes | flames | #7c7466 | #453f36 | #ff7a33 | 150 | 22 | 24 | 18 | .05 | 普通 |
| cowled_skeleton | 持戒骷髅 | 亡灵圣械 | skeleton | hold_staff | — | #d8d2be | #7a745e | #6cd8f0 | 90 | 24 | 10 | 32 | .14 | 普通 |
| relic_sentry | 圣骸哨兵 | 亡灵圣械 | knight | hold_shield | — | #b8ae90 | #6b6248 | #ffe9a8 | 120 | 20 | 14 | 26 | .05 | 普通 |
| stern_elder | 苦修长老 | 亡灵圣械 | knight | helm_great | halo | #b8ae90 | #6b6248 | #ffe9a8 | 600 | 60 | 30 | 32 | .14 | **精英** |
| edna_silent | **缄默圣女·艾德娜** | 亡灵圣械 | skeleton | halo | chains | #d8d2be | #7a745e | #ffe9a8 | 2000 | 100 | 60 | 42 | .20 | **BOSS** |

### 5.2 V1 两图 18 怪简表（tier3–4，不在 MVP 范围）

**图4 · 灰铸厂（tier3 · 构装体）** —— 王庭合法把魔法锻进兵器（概念 §6.3）：

| key | 名称 | family | body | feature | feature2 | c1 | c2 | eye | hp | atk | def | spd | crit | 角色 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| foundry_golem | 铸厂魔像 | 构装体 | construct | spikes | flames | #7c7466 | #453f36 | #ff7a33 | 120 | 26 | 12 | 36 | .10 | 普通 |
| slag_element | 熔渣元素 | 构装体 | elemental | flames | — | #ff7a33 | #a33a10 | #ffe9a8 | 85 | 24 | 10 | 34 | .08 | 普通 |
| rivet_guard | 铆甲卫兵 | 构装体 | knight | helm_great | — | #b8ae90 | #6b6248 | #ffe9a8 | 105 | 20 | 18 | 24 | .04 | 普通 |
| forge_doll | 锻炉傀儡 | 构装体 | construct | — | — | #7c7466 | #453f36 | #ff7a33 | 130 | 18 | 20 | 20 | .04 | 普通 |
| ash_construct | 灰烬构装 | 构装体 | construct | flames | — | #8a7a5a | #453f36 | #ff7a33 | 90 | 30 | 8 | 44 | .14 | 普通 |
| sigil_knight | 符甲术士 | 构装体 | knight | runes_orbit | — | #9a8a6a | #6b6248 | #5ba3e8 | 100 | 24 | 10 | 30 | .12 | 普通 |
| anvil_ward | 铁砧卫 | 构装体 | construct | spikes | — | #6f6a60 | #3f3a36 | #cf9c5c | 110 | 22 | 16 | 28 | .06 | 普通 |
| live_foreman | 活甲工头 | 构装体 | knight | helm_great | halo | #b8ae90 | #6b6248 | #ffe9a8 | 700 | 70 | 38 | 32 | .16 | **精英** |
| varuk | **熔印大匠·瓦鲁克** | 构装体 | humanoid_brute | spikes | — | #8a7a66 | #4a4034 | #5ba3e8 | 2400 | 116 | 66 | 44 | .22 | **BOSS** |

**图5 · 禁卷回廊（tier4 · 秘术造物）** —— 秘典庭地下书库，查封两百年的禁咒都在这里（概念 §6.3）：

| key | 名称 | family | body | feature | feature2 | c1 | c2 | eye | hp | atk | def | spd | crit | 角色 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| forbidden_tome | 禁卷造物 | 秘术造物 | arcane_weave | runes_orbit | — | #c9c0a4 | #5b4a86 | #b08cff | 130 | 30 | 12 | 38 | .14 | 普通 |
| corridor_drake | 卷廊守龙 | 秘术造物 | drake | wings_bone | runes_orbit | #4a5a7a | #242c40 | #5b9bff | 100 | 32 | 10 | 36 | .16 | 普通 |
| page_doll | 浮页傀偶 | 秘术造物 | arcane_weave | — | — | #c9c0a4 | #5b4a86 | #b08cff | 110 | 24 | 20 | 26 | .08 | 普通 |
| spell_thread | 咒文游丝 | 秘术造物 | elemental | runes_orbit | — | #b08cff | #5b4a86 | #cbb2ff | 120 | 26 | 14 | 34 | .12 | 普通 |
| sealed_idol | 封印守像 | 秘术造物 | construct | runes_orbit | — | #7c7466 | #453f36 | #b08cff | 140 | 22 | 28 | 20 | .06 | 普通 |
| library_wraith | 书库怨灵 | 秘术造物 | wraith | runes_orbit | — | #4a4560 | #241f38 | #b08cff | 95 | 34 | 12 | 40 | .18 | 普通 |
| forbidden_echo | 禁咒回响 | 秘术造物 | arcane_weave | halo | — | #c9c0a4 | #5b4a86 | #cbb2ff | 135 | 28 | 16 | 32 | .14 | 普通 |
| codex_clerk | 禁卷书记官 | 秘术造物 | humanoid_civil | garb_caster | runes_orbit | #6b5a9e | #2e2448 | #cbb2ff | 820 | 82 | 44 | 40 | .20 | **精英** |
| sevlan | **大掌典·塞维兰** | 秘术造物 | humanoid_civil | garb_caster | runes_orbit | #6b5a9e | #2e2448 | #cbb2ff | 3000 | 140 | 80 | 46 | .25 | **BOSS** |

### 5.3 怪物技能数值（✅ 沿用，仅重命名）

| key | 名称 | type | 数值 | 来源 |
|---|---|---|---|---|
| mb_bite | 撕咬 | dmg | mult 1.25, cd 2 | 小怪 |
| mb_claw | 利爪 | dmg | mult 1.40, cd 3 | 小怪 |
| mb_slam | 横扫 | dmg | mult 1.30, cd 3 | 小怪 |
| mb_spit | 毒唾 | dot | mult 0.35, turns 3, vuln 0.10, cd 4 | 小怪 |
| mb_howl | 嚎叫 | buff | val 0.12, turns 3, cd 5 | 小怪 |
| me_crush | 粉碎击 | dmg | mult 1.70, cd 4, slow 0.20/2 | 精英 |
| me_venom | 剧毒喷吐 | dot | mult 0.55, turns 4, vuln 0.15, cd 5 | 精英 |
| me_regen | 再生 | heal | heal 0.14, cd 6 | 精英 |
| me_fury | 狂怒 | buff | val 0.25, spdBoost 0.15, turns 3, cd 7 | 精英 |
| me_maul | 猛扑 | dmg | mult 1.55, cd 3, vuln 0.10/2 | 精英 |
| mboss_smash | 灭世重击 | dmg | mult 2.40, cd 5 | BOSS |
| mboss_quake | 震地 | dmg | mult 1.50, cd 4, stun 1/1 | BOSS |
| mboss_barrier | 护体结界 | dmg | mult 0.80, cd 6, shield 0.22 | BOSS |
| mboss_drain | 生命汲取 | dmg | mult 1.30, cd 4, **lifesteal 0.35** | BOSS |
| mboss_wrath | 毁灭怒吼 | buff | val 0.35, spdBoost 0.20, turns 3, cd 7 | BOSS |
| mboss_decay | 腐蚀吐息 | dot | mult 0.70, turns 4, vuln 0.20, cd 5 | BOSS |

### 5.4 难度曲线与 CP 对标（🔧 联调项）

取基准角色（GDD 01 §5.6：Lv20，CP≈3400，atk 408，def 64）。各图 Boss 缩放后对标（Boss key 已对齐概念 §6.6 / GDD 02 §5.6 / GDD 03 §5.4）：

| 图 | tier | scale@Lv20 | 精英 hp/atk | Boss（名称 / key） | hp/atk@Lv20 | 对 CP3400 预期 |
|---|---|---|---|---|---|---|
| 界桩荒野 | 0 | 3.1 | 1302 / 130 | 锈冠牡鹿 / `rust_stag` | 4030 / 223 | 碾压（练手） |
| 黑印集市 | 1 | 3.7 | 1924 / 200 | 「三指」奥兹 / `oz_threefinger` | 6290 / 326 | 势均（需配装） |
| 缄默修道院 | 2 | 4.1 | 2460 / 246 | 缄默圣女·艾德娜 / `edna_silent` | 8200 / 410 | 挑战（需套装/禁咒） |

> ⚠️ 修道院 Boss `edna_silent` 缩放后 hp 8200 / atk 410。基准角色每秒约 1.23 次行动、单次期望伤害取决于 build。
> 若实测 TTK > 90 秒或玩家被秒，**优先调 Boss 基础值而非 scale 公式**（公式牵动全体）。

---

## 6. 边界与异常

| # | 场景 | 处理 |
|---|---|---|
| **E1** | 🔴 **组队分支未剥离** | `tickBattle` 的 `partyMode` 分支、`startPartyBattle`/`sendPB`/`MMO` 全部移除（system-breakdown G 组）。**上线级阻断** |
| E2 | 怪物 `scale` 使 hp 极大 | 仍是整数范围；TTK 由 §5.4 校准 |
| E3 | 眩晕期间玩家 CD 不递减 | 沿用 `processStartBuffs` 行为（GDD 03 E9） |
| E4 | 多段 `hits` 与玩家吸血 | 每段独立结算（GDD 02 H1 吸血超模在多段被放大，此处同理） |
| E5 | Boss `mboss_drain` 吸血 | `lifesteal=0.35` 常驻；若 Boss 战过易，下调至 0.20 |
| E6 | `art.body` 渲染缺失 | **只可用美术圣经 §7.3 的 16 类**；`humanoid_civil` 专用于图2 人型敌人，`arcane_weave` 专用于图5 秘术造物 |
| E7 | 玩家等级 > 30（V1 扩展） | `scale` 公式 `(level−1)×0.10` 继续线性增长，需复查是否过头 |
| E8 | 同一家族两种 dot 叠加 | `mb_spit` + `me_venom` 独立计时，可并存 |
| E9 | 怪物 `matk` 折算 | 固定 `atk×0.6`，不随属性变化；法系玩家承伤略低（已计入 GDD 01 家族效能） |

---

## 7. 与其他系统的依赖

| 方向 | 系统 | 关系 |
|---|---|---|
| ⬆️ 依赖 | **GDD 01** | 玩家 `atk/def/crit/hit/eva`、CP 对标、等级决定 `scale` |
| ⬆️ 依赖 | **GDD 03** | 共用 buff/debuff 状态机；玩家技能对怪物结算；Boss 禁咒来源（GDD 03 §5.4） |
| ⬆️ 依赖 | **概念文档 §6.3/§6.6** | 五图=五势力、Boss 名录（锈冠牡鹿/三指奥兹/艾德娜）的唯一权威 |
| ⬆️ 依赖 | **美术圣经 §7** | `art.body` 16 类、`humanoid_civil`/`arcane_weave`、`c1/c2/eye` 调色板 |
| ⬇️ 被依赖 | **GDD 05** | `generateLoot` 金币/掉落按 `isElite`/`isBoss`；离线收益按 tier；Boss key 对齐 `BOSS_DROPS`（GDD 02 §5.6） |
| ↔️ 横向 | 美术 | **§4.2 的 16 类 `body` 是美术出图硬约束**（美术圣经 §7.3）；图2 人型敌人必须用 `humanoid_civil` |
| ↔️ 横向 | 程序 | 🔴 **E1 组队剥离是必改代码**；`enemyUnit` 公式保留；`MONSTERS` 表替换为新名与新 key（`rust_stag`/`oz_threefinger`/`edna_silent` 等，须与 GDD 02 `BOSS_DROPS` 同 key） |

---

## 8. 验收标准

| # | 标准 | 验证方式 |
|---|---|---|
| A1 | 650ms/tick，玩家约 1.2s/行动 | 计时战斗日志 |
| A2 | 三图 27 怪 `art` 字段齐全（body/feature/feature2/c1/c2/eye） | 逐只查表 |
| A3 | `family` 与概念 §6.3 一致：图1 污染兽 / 图2 人型 / 图3 亡灵圣械 | 查表 |
| A4 | 图2 人型敌人全部用 `humanoid_civil`（含 4 装束），无 imp/raven 冒充当人型 | 查 §5.1 图2 行 |
| A5 | 三图 Boss 名 = 锈冠牡鹿 / 「三指」奥兹 / 缄默圣女·艾德娜，key 对齐 GDD 02 `BOSS_DROPS` | 跨文档比对 |
| A6 | `scale` 公式：tier0/1/2 在 Lv20 缩放 3.1/3.7/4.1 | 手算比对 |
| A7 | 减速/易伤/眩晕对玩家生效（共用状态机） | 让 Boss 震地，观察玩家跳行动 |
| A8 | 怪物吸血（Boss）按输出回血 | 看 Boss 战 Boss 血线 |
| A9 | 🔴 无任何 `partyMode`/`MMO`/`sendPB` 残留 | 搜代码确认 |
| A10 | 三图难度递增且 §5.4 对标合理（TTK 20–90s） | 基准角色逐图实测 |
| A11 | `body` 仅取自美术圣经 §7.3 的 16 类 | 查表 + 美术验收 |
| A12 | 数值骨架（hp/atk/def/spd/crit）与 v1.0 槽位一致、三项验算不受影响 | diff 比对 |

---

## 9. 待验证假设

| # | 假设 | 风险 | 调整方向 |
|---|---|---|---|
| H1 | 🔴 遭遇构成 5 敌（4+0.5 精英）代表真实刷怪 | 🔴 高 | 实测后调 GDD 05 经济模型 |
| H2 | 🔴 `scale` 公式对三图难度梯度合适 | 🟡 中 | 调 `tier×0.6` 系数（0.5–0.7） |
| H3 | 修道院 Boss 不被秒也不超时 | 🟠 中高 | 优先调 Boss 基础值 |
| H4 | 5 族行为差异玩家可感知 | 🟢 低 | 强化家族技能池区分度 |
| H5 | `matk = atk×0.6` 折算对法系玩家公平 | 🟡 中 | 若法系承伤过低，分离 `matk` 独立基础值 |
| H6 | 纯单机剥离组队无遗留引用 | 🔴 高 | 全仓搜 `MMO`/`partyMode`/`sendPB` |
| H7 | `humanoid_civil` 4 装束剪影在纯黑下互不混淆 | 🟢 低 | 美术 §7.2A 已论证，验收确认 |
| H8 | 图2 用真实人型敌人（非兽化）能立住"人对人"基调 | 🟡 中 | 若观感弱，强化 `garb_*` 职业差异 |

---

*GDD 04 结束（v1.1 · 主题层重写，数值骨架与三项验算保留）*
