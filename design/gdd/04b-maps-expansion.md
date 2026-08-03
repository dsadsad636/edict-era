# GDD 04b · 地图与怪物内容扩充（tier 0–9 / 100 怪）

> 《敕造纪元 · 持牌者》· 工程代号 `Arcanum`
> 版本 v1.0 · 作者：文策渊
> 📌 **本文是 GDD 04 的增补件，不替代它**。GDD 04 §3（ATB / scale / buff 规则）、§5.3（怪物技能表）继续有效且未被修改。
> 📌 本文交付：地图 3 → **10 张**，怪物 27 → **100 只**（新增 73 只）。

---

## 0. 前置勘误（🔴 工程必读，影响落地）

在设计前我核对了 `index.html` L1370–1719 的**实际已实现枚举**，与任务简报给出的清单**不一致**。以下枚举**代码里已经有渲染实现**，不是新增项：

| 类别 | 简报未列出、但代码已实现 | 位置 |
|---|---|---|
| `art.body` | `arcane_weave`、`elemental`、`drake` | `MON_BODIES` L1370–1551（共 **16** 类，非 13 类） |
| `art.feature` | `none`、`horns`、`crown`、`vines`、`crystals`、`wings`、`wings_bone` | `MON_FEATURES` L1552–1719（共 **26** 项，非 19 项） |

✅ **结论：本次 73 只新怪全部使用已实现枚举，`art` 侧新增项为 0**（详见 §5）。工程无需改 `MON_BODIES` / `MON_FEATURES`，直接填数据表即可。

**已实现枚举全集（唯一权威 = 代码，与美术圣经 §7.3/§7.4 一致）：**

```
body(16)   : humanoid_civil, humanoid_brute, humanoid_small, knight,
             beast_quad, beast_biped, skeleton, wraith, construct,
             arcane_weave, elemental, drake, serpent, arachnid, fey_plant, ooze
feature(26): none, horns, crown, vines, antlers, crystals, wings, wings_bone,
             halo, mane, swarm, scales, spikes, flames, chains, runes_orbit,
             helm_great, garb_warrior, garb_caster, garb_rogue, garb_merchant,
             hold_sword, hold_staff, hold_dagger, hold_torch, hold_shield
```

### 0.1 tier3 / tier4 的处理方式

GDD 04 §5.2 已完整设计过 **灰铸厂（tier3）9 只** 与 **禁卷回廊（tier4）9 只**（含 key / 数值 / art / family），只是在 `index.html` L1766–1770 被注释掉未实装。

**本文采纳这 18 只原设计，一字不改数值与 art**，每图仅补 1 只小怪凑满 8 只。理由：避免与 GDD 04 产生双份权威、避免重复造 key、保住已做过的平衡校验。

计数核对：`3（tier0–2 补位）+ 10×7（tier3–9）= 73` 新增；`27 + 73 = 100` ✅
其中 tier3/4 的 18 只属于"已设计未实装"，对 `index.html` 而言仍是新增数据。

---

## 1. 叙事总览

### 1.1 一句话主线

> **玩家从"替制度清理违规者"开始，逐层发现制度本身才是最大的违规者，最终在初敕之座前面对一个事实：敕令登记不是王国发明的，王国只是它的抄写员。**

### 1.2 三幕结构

| 幕 | tier | 玩家认知 | 情绪 |
|---|---|---|---|
| **第一幕 · 执法** | 0–2 | "有人在违规，我去抓。" | 职业性、麻木 |
| **第二幕 · 破裂** | 3–5 | "合法的那一边，做的事更脏。" | 怀疑、共谋感 |
| **第三幕 · 溯源** | 6–9 | "制度不是人立的。我这张牌是谁发的？" | 敬畏、终局 |

### 1.3 逐图叙事位置

| tier | 地图 | 在叙事中的作用 | 关键钩子 |
|---|---|---|---|
| 0 | 界桩荒野 | **制度的边界在漏** | 界桩符文褪色，魔素外逸把野兽拧成别物 |
| 1 | 黑印集市 | **人也会违规** | 第一次杀的是人，不是怪 |
| 2 | 缄默修道院 | **组织也会违规** | 教团把神迹藏进圣骸里逃避登记 |
| 3 | 灰铸厂 | 🔻**第一道裂缝：合法的登记本身就是暴力** | 你亲眼看见"合法锻入"是怎么把活的东西按进兵器 |
| 4 | 禁卷回廊 | **被查封的禁咒没有销毁，只是归档** | 制度囤积它所禁止的东西 |
| 5 | 削籍狱 | 🔻**登记不是许可，是存在本身** | 被划去姓名的人还活着，只是没人记得他们 |
| 6 | 敕墨深坑 | **敕令的墨是从活物里榨出来的** | 你手里那张牌，是用坑底那东西的血写的 |
| 7 | 初录龙冢 | **登记制度是为了拴住龙才发明的** | 编号〇〇一至今还锁在山壁上 |
| 8 | 王庭档案宫 | **发牌的人** | 抽屉里锁着的不是档案，是还没死的名字 |
| 9 | 初敕之座 | 🔻**终局：王庭只是抄写员** | 真正立法的东西一直坐在这张椅子上 |

### 1.4 三个转折点（叙事支柱锚点）

- **tier3 灰铸厂** —— 从"清理违规"转向"共谋"。玩家第一次为合法机构杀人。
- **tier5 削籍狱** —— 从"共谋"转向"恐惧"。玩家意识到自己的持牌资格随时可被划掉，而被划掉 = 不存在。
- **tier9 初敕之座** —— 从"恐惧"转向"选择"。留白：玩家可以继承这张椅子，也可以让所有名字失效。**结局分支不在本次范围，仅埋钩。**

> ⚠️ **支柱漂移检查**：GDD 04 定的核心支柱是"准备是游戏，战斗是结算"。本扩展**只动主题层与数据表，不引入任何战斗内操作**，支柱未漂移 ✅。

---

## 2. 数值曲线设计

### 2.1 增长模型

以 tier2（现有最高实装 tier）为锚点，逐 tier 复利增长：

```
base_hp (t) = base_hp (t−1) × 1.20      // 血量增长最快
base_atk(t) = base_atk(t−1) × 1.18      // 攻击次之
base_def(t) = base_def(t−1) × 1.16      // 防御最慢
```

**为什么是 1.20 / 1.18 / 1.16 这个递减序列：**

1. **hp 最快（1.20）** —— 玩家 DPS 是**乘法叠加**的（等级 × 装备 × 词缀 × 技能倍率），成长远快于线性。hp 若不领先增长，高 tier 会出现"秒杀"体验塌陷。
2. **atk 次之（1.18）** —— 怪物 atk 还要再乘 `scale`，是**双重放大**。若与 hp 同速，玩家在 tier7+ 会被一击带走。压低到 1.18 是给玩家 def/闪避留出反应余量。
3. **def 最慢（1.16）** —— def 是**减法/除法**型防御。增长过快会形成"伤害墙"，直接绞杀低 atk 高频攻速 build（主导策略红线：会逼所有人玩高单击 build）。压到 1.16 保 build 多样性。

### 2.2 锚点校验（与 GDD 04 §5.2 原设计吻合）

| tier | 模型推算 Boss | GDD 04 §5.2 原值 | 结果 |
|---|---|---|---|
| 3 | 2000×1.20 = 2400 / 100×1.18≈118 / 60×1.16≈70 | **2400 / 116 / 66** | ✅ 吻合，采用原值 |
| 4 | 2400×1.20 = 2880 / 116×1.18≈137 / 66×1.16≈77 | **3000 / 140 / 80** | ✅ 吻合，采用原值 |

模型能反推出已存在的两组数据 → 曲线可信，tier5–9 沿用。

### 2.3 tier0–9 完整数值骨架

| tier | 小怪 hp | 小怪 atk | 小怪 def | 精英 hp/atk/def | Boss hp/atk/def |
|---|---|---|---|---|---|
| 0 | 55–90 | 12–20 | 4–14 | 420 / 42 / 26 | 1300 / 72 / 42 |
| 1 | 65–140 | 14–24 | 6–22 | 520 / 54 / 34 | 1700 / 88 / 52 |
| 2 | 80–150 | 18–26 | 8–24 | 600 / 60 / 30 | 2000 / 100 / 60 |
| 3 | 85–150 | 18–30 | 8–24 | 700 / 70 / 38 | 2400 / 116 / 66 |
| 4 | 95–140 | 22–34 | 10–28 | 820 / 82 / 44 | 3000 / 140 / 80 |
| **5** | **115–170** | **26–40** | **12–32** | **980 / 97 / 51** | **3600 / 166 / 92** |
| **6** | **138–205** | **30–47** | **14–38** | **1170 / 114 / 59** | **4400 / 196 / 106** |
| **7** | **165–245** | **36–56** | **17–44** | **1400 / 135 / 68** | **5400 / 232 / 122** |
| **8** | **200–295** | **43–66** | **20–50** | **1680 / 159 / 78** | **6600 / 274 / 140** |
| **9** | **240–355** | **52–78** | **24–58** | **2050 / 190 / 92** | **8400 / 330 / 165** |

> 📎 tier2 精英 def(30) < tier1 精英 def(34) 是**既有数据的非单调点**，本文不改动历史数据，tier3 起恢复单调递增。

### 2.4 `spd` 与 `crit`（不参与 `scale`，故独立设计）

`spd`/`crit` 按 GDD 04 §3.2 **不随 scale 缩放**，因此必须靠基础值本身制造压迫感。

| tier | 小怪 spd | 小怪 crit | 精英 spd/crit | Boss spd/crit |
|---|---|---|---|---|
| 0–2 | 16–44（现有） | .03–.14（现有） | 30–32 / .10–.14 | 34–42 / .15–.20 |
| 3 | 20–44 | .04–.14 | 32 / .16 | 44 / .22 |
| 4 | 20–40 | .06–.18 | 40 / .20 | 46 / .25 |
| **5** | **20–46** | **.05–.16** | **34 / .21** | **44 / .26** |
| **6** | **18–46** | **.06–.18** | **36 / .22** | **42 / .28** |
| **7** | **22–48** | **.07–.19** | **38 / .23** | **44 / .30** |
| **8** | **20–46** | **.07–.20** | **40 / .24** | **46 / .32** |
| **9** | **26–48** | **.10–.22** | **42 / .26** | **48 / .35** |

**设计约束：**
- `spd` **硬上限 48**。玩家 Lv20 spd≈53（GDD 04 §3.1）。若怪物 spd 超过玩家，ATB 会翻转为"怪物连续两次行动"，体感是无法接受的不公平。48 是留出安全余量的天花板。
- `crit` 小怪封顶 **.22**、Boss 封顶 **.35**。这是**方差控制**：放置游戏玩家看不到战斗过程，只看结果，高方差会让"同样配装有时赢有时输"，直接破坏支柱一（出击前能预判胜负）。
- 高 tier 靠**下限抬升**制造压迫（tier9 小怪 spd 最低 26、crit 最低 .10），而非靠上限突破。

### 2.5 🔴 与 `scale` 公式的冲突（**需用户拍板**）

GDD 04 §3.2：`scale = 1 + tier×0.6 + (level−1)×0.10`，MVP 封顶 Lv30。

把 tier9 代入：

| 场景 | scale | 终局 Boss `the_first_edict` 实际值 |
|---|---|---|
| tier9 @ Lv30 | 1 + 5.4 + 2.9 = **9.3** | hp **78,120** / atk **3,069** |

**atk 3069 会秒杀任何 Lv30 角色**（GDD 01 基准 Lv20 玩家 def 64）。`tier×0.6` 在 10 张图的跨度下**完全失控**——tier 项独自贡献了 5.4 倍，压过了玩家等级项（2.9 倍）。这在放置游戏里是反向的：**成长感必须来自"玩"，不能来自"选了张高级地图"**。

**两个方案，请用户选一个：**

| 方案 | 改动 | tier9@满级 scale | 优点 | 代价 |
|---|---|---|---|---|
| **A（推荐）** | 系数降到 `tier×0.35`，等级上限提到 **Lv60** | 1+3.15+5.9 = **10.05** | 等级项主导（5.9 > 3.15），成长来自游玩；总量级与现状相当，不必重做经济 | 需同步改 GDD 01 等级曲线、GDD 05 经济模型 |
| **B（保守）** | 公式不动，等级上限提到 **Lv60** | 1+5.4+5.9 = **12.3** | 零公式改动，工程量最小 | tier 项仍过重；玩家越级挑战体验极差（跳一张图 = +0.6 倍全属性墙） |

⚠️ 本文的 §2.3 数值骨架**在两个方案下都成立**（它只定 base 值，不涉及 scale）。此项不阻塞工程落地数据表，但**上线前必须解决**。

---

## 3. 新增家族说明

现有：`polluted`（污染兽）/ `humanoid`（人型）/ `undead`（亡灵圣械）。
新增 **7 个**，与 7 张新图**一一对应**，延续美术圣经 §7.5「一图一势力」规则。

| # | `family` | 中文 | tier | 世界观来源 | 为什么这个 tier 出现它 |
|---|---|---|---|---|---|
| 1 | `construct` | 构装体 | 3 | 王庭**合法**把魔法锻进兵器的产物（GDD 04 §3.3 已定义） | 玩家刚打完"非法藏匿"（修道院），紧接着看合法产线——制度暴力的第一次正面亮相 |
| 2 | `arcane` | 秘术造物 | 4 | 秘典庭地下书库中，查封禁咒自行凝聚成的实体（GDD 04 §3.3 已定义） | 承接"合法也脏"，升级为"制度囤积它所禁止的东西" |
| 3 | `nameless` | 无名者 | 5 | **被削籍的人**。王国最重的刑罚不是处死，是「除籍」——从登记册上划掉名字。被划掉者不死，但逐渐从世界的记忆与形体中褪去 | 这是全作最重的一次认知转折：**登记 = 存在**。放在中点（第二幕收尾），玩家在此第一次为自己的持牌资格恐惧 |
| 4 | `abyssal` | 渊墨 | 6 | 敕墨矿脉的深处生态。敕令用的墨不是矿物，是坑底某个活物的体液；长期接触者会被墨"改写"成半物 | 第三幕开场。玩家第一次触及**制度的物质基础**——你的执照是用什么写的 |
| 5 | `drakeborn` | 龙裔 | 7 | 龙是**第一批被登记的存在**。整套敕令登记制度最初就是为了拴住龙而发明的，后来才推广到万物 | 溯源第一站：制度的**目的**。龙冢里锁着的编号〇〇一是活证据 |
| 6 | `sealbound` | 敕印者 | 8 | 王庭档案宫的官吏。用印超过一定年限，官吏会与自己的印**长合**——手臂变成印章、躯体与国玺融合。这被视为"最高荣誉"，实际是职业性异化 | 溯源第二站：制度的**执行者**。玩家终于打到"发牌的人"，而他们已经不算人了 |
| 7 | `primordial` | 初敕 | 9 | **早于王国的存在**。初敕之座上的东西不是被王国创造的，是王国围着它建起来的；王庭历代只是它的抄写员 | 终局：制度的**源头**。回答全作第一个问题——"我这张牌到底是谁发的" |

**认知过载检查**：10 张图 = 10 个家族，玩家每图只需认识 1 组视觉语言，且每组有独占配色（§4 各图色板）+ 独占 body 组合。**不存在跨图混用家族**，识别成本恒定 ✅。

**家族技能池**（沿用 GDD 04 §3.3 格式，`construct`/`arcane` 已有，补 5 个新的）：

| 家族 | 小怪池 | 精英附加 |
|---|---|---|
| `nameless` | `mb_howl` `mb_spit` `me_regen` | `me_crush` |
| `abyssal` | `mb_bite` `mb_spit` `me_venom` | `me_venom` |
| `drakeborn` | `mb_claw` `mb_slam` `me_fury` | `me_maul` |
| `sealbound` | `mb_slam` `me_crush` `mb_spit` | `me_crush` |
| `primordial` | `mb_howl` `me_regen` `me_fury` | `mboss_decay`（弱化） |

> ✅ 全部复用 GDD 04 §5.3 既有 16 个技能，**不新增技能 key**，工程零改动。

---

## 4. 逐图设计

### 字段说明（工程解析用）

每只怪的完整结构（与 `index.html` L1731 `mkMon()` 兼容）：

```js
key: mkMon({
  name, emoji, hp, atk, def, spd, crit,
  family,                                    // 见 §3
  art:{ body, feature, feature2, c1, c2, eye },
  elite?:true | boss?:true,
  img:'assets/monsters/<key>.png'            // 命名约定 = key
})
```

> ⚠️ 表中 `feature2` 列为 `—` 表示该槽留空（不写该字段，或写 `'none'`）。
> ⚠️ **`img` 字段必须挂在 `mkMon()` 的顶层对象上，不能写进 `art:{}` 里面**——现有 12 只怪正是因为这个错误注入位置导致立绘不显示（见 Task #1）。新数据请统一放顶层。

---

### 4.1 图 1 · 界桩荒野（tier 0）· 补 1 只

| 字段 | 值 |
|---|---|
| `name` | 界桩荒野 |
| `tier` | 0 |
| `emoji` | 🌲 |
| `desc` | 王国最外圈界桩，符文褪色，逸散魔素把野兽拧成别物 |

**新增怪物（1 只，加入 `pool` 后小怪共 8 只）**

| key | 中文名 | emoji | 类型 | family | hp | atk | def | spd | crit | art.body | art.feature | art.feature2 | c1 | c2 | eye |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `fade_moth` | 褪印蛾 | 🦋 | 小怪 | polluted | 68 | 17 | 5 | 38 | 0.09 | arachnid | swarm | scales | #8a8560 | #46422c | #cfe07a |

**AI 绘图视觉描述**
- **褪印蛾**：灰绿粉翅的巨蛾群，翅面浮着被啃下来的符文碎屑；六只复眼泛黄绿磷光，口器细长如笔尖，正刮食界桩上的漆印。

> 🎭 设计注：这只怪的存在本身就是世界观陈述——**它靠吃"登记标记"为生**。界桩符文褪色不是自然风化，是被啃的。

**更新后 pool**（8）：`border_hound, moss_scaler, rot_pod, thornling, rust_serpent, etch_spider, mud_beast, fade_moth`
精英 `stone_shin` · Boss `rust_stag`

---

### 4.2 图 2 · 黑印集市（tier 1）· 补 1 只

| 字段 | 值 |
|---|---|
| `name` | 黑印集市 |
| `tier` | 1 |
| `emoji` | 🏚️ |
| `desc` | 地下黑市，第一次杀人而不是杀怪 |

**新增怪物（1 只）**

| key | 中文名 | emoji | 类型 | family | hp | atk | def | spd | crit | art.body | art.feature | art.feature2 | c1 | c2 | eye |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `seal_forger` | 伪印匠 | 🖋️ | 小怪 | humanoid | 88 | 19 | 12 | 28 | 0.07 | humanoid_civil | garb_merchant | runes_orbit | #7d6a4a | #3f3626 | #b9d14a |

**AI 绘图视觉描述**
- **伪印匠**：矮胖中年男，皮围裙沾满彩墨，颈上挂着十几枚黄铜印章串；右手举着仍在滴墨的伪造敕印，指缝染成洗不掉的绿黄色。

> 🎭 设计注：`eye` 用毒绿金 `#b9d14a` 而非掮客的敕造金 `#eba43c`——**假货的金是发绿的**。同 body 同装束靠 eye 换色区分变种，零美术成本（美术圣经 §7.6）。

**更新后 pool**（8）：`merc_hire, private_mage, smuggler, broker, mage_init, enforcer, scout, seal_forger`
精英 `black_hand` · Boss `oz_threefinger`

---

### 4.3 图 3 · 缄默修道院（tier 2）· 补 1 只

| 字段 | 值 |
|---|---|
| `name` | 缄默修道院 |
| `tier` | 2 |
| `emoji` | ⛪ |
| `desc` | 教团把神迹藏在圣骸里逃避登记 |

**新增怪物（1 只）**

| key | 中文名 | emoji | 类型 | family | hp | atk | def | spd | crit | art.body | art.feature | art.feature2 | c1 | c2 | eye |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `choir_husk` | 唱诗骸童 | 🎼 | 小怪 | undead | 105 | 25 | 12 | 36 | 0.11 | skeleton | halo | runes_orbit | #d8d2be | #7a745e | #a8e6d0 |

**AI 绘图视觉描述**
- **唱诗骸童**：半人高的童骸，颌骨被铜丝缝死，头顶悬一圈缺角光环；肋腔里回荡着无人张口的圣咏，指骨仍保持翻页姿势。

> 🎭 设计注：`eye` 取淡薄荷 `#a8e6d0`，与缄默骸骨 `#6cd8f0`、圣械守卫 `#ffe9a8` 三色分离，纯黑底下可瞬间辨识。

**更新后 pool**（8）：`silent_bone, reliquary_guard, cloister_wraith, penitent_ghost, rust_construct, cowled_skeleton, relic_sentry, choir_husk`
精英 `stern_elder` · Boss `edna_silent`

---

### 4.4 图 4 · 灰铸厂（tier 3）· 全新实装

| 字段 | 值 |
|---|---|
| `name` | 灰铸厂 |
| `tier` | 3 |
| `emoji` | 🔨 |
| `desc` | 王庭在此把魔法合法锻进兵器，炉火两百年未熄，废件从不外运 |

**色板基调**：熔渣橘 `#ff7a33` + 铁灰 `#7c7466` + 铆甲米 `#b8ae90`

| key | 中文名 | emoji | 类型 | family | hp | atk | def | spd | crit | art.body | art.feature | art.feature2 | c1 | c2 | eye |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `foundry_golem` | 铸厂魔像 | ⚙️ | 小怪 | construct | 120 | 26 | 12 | 36 | 0.10 | construct | spikes | flames | #7c7466 | #453f36 | #ff7a33 |
| `slag_element` | 熔渣元素 | 🔥 | 小怪 | construct | 85 | 24 | 10 | 34 | 0.08 | elemental | flames | — | #ff7a33 | #a33a10 | #ffe9a8 |
| `rivet_guard` | 铆甲卫兵 | 🛡️ | 小怪 | construct | 105 | 20 | 18 | 24 | 0.04 | knight | helm_great | — | #b8ae90 | #6b6248 | #ffe9a8 |
| `forge_doll` | 锻炉傀儡 | 🪆 | 小怪 | construct | 130 | 18 | 20 | 20 | 0.04 | construct | — | — | #7c7466 | #453f36 | #ff7a33 |
| `ash_construct` | 灰烬构装 | 🌋 | 小怪 | construct | 90 | 30 | 8 | 44 | 0.14 | construct | flames | — | #8a7a5a | #453f36 | #ff7a33 |
| `sigil_knight` | 符甲术士 | 📐 | 小怪 | construct | 100 | 24 | 10 | 30 | 0.12 | knight | runes_orbit | — | #9a8a6a | #6b6248 | #5ba3e8 |
| `anvil_ward` | 铁砧卫 | 🔩 | 小怪 | construct | 110 | 22 | 16 | 28 | 0.06 | construct | spikes | — | #6f6a60 | #3f3a36 | #cf9c5c |
| `scrap_remelt` | 回炉废件 | ♻️ | 小怪 | construct | 95 | 28 | 10 | 40 | 0.12 | construct | chains | flames | #9a6a4a | #4a3226 | #ffb347 |
| `live_foreman` | 活甲工头 | 🧑‍🏭 | **精英** | construct | 700 | 70 | 38 | 32 | 0.16 | knight | helm_great | halo | #b8ae90 | #6b6248 | #ffe9a8 |
| `varuk` | **熔印大匠·瓦鲁克** | 🏭 | **BOSS** | construct | 2400 | 116 | 66 | 44 | 0.22 | humanoid_brute | spikes | — | #8a7a66 | #4a4034 | #5ba3e8 |

**AI 绘图视觉描述**
- **铸厂魔像**：由锻造废铁堆叠成的驼背巨人，肩背插满未拔出的凿刃；胸腔炉门半开，橘红火光随呼吸明灭，脚步拖出焦痕。
- **熔渣元素**：没有固定轮廓的橘红熔流人形，表面结着一层黑硬渣壳并不断碎裂；抬手时熔液拉丝，滴落处石地立刻冒烟。
- **铆甲卫兵**：全身覆满粗大铆钉的方正铠甲兵，铠甲是直接铆死在身上的、脱不下来；头盔只有一道横向观察缝，透出昏黄光。
- **锻炉傀儡**：矮胖如水缸的铸铁傀儡，四肢短粗，腹部是一扇上锁的炉门；行动迟缓，关节转动时喷出灰白蒸汽。
- **灰烬构装**：由灰烬压实成型的瘦长人形，一动就簌簌掉粉；躯体裂缝深处透出未熄的暗红余烬，跑动时留下灰色残影。
- **符甲术士**：铠甲表面蚀刻满几何符阵的高瘦骑士，符线泛冷蓝光；手中无武器，靠悬浮在身前的三块符文铁板攻击。
- **铁砧卫**：以整块铁砧为躯干的四足矮构装，背部平面被砸出无数凹坑；没有头，正面一排铸造孔像瞪着人的空洞眼窝。
- **回炉废件**：由报废构装残肢焊合的四臂躯体，接缝溢出橘红熔渣；胸腔嵌着一块划掉编号的登记铭牌，拖着断裂的吊运铁链。
- **活甲工头**（精英）：一具没有内容物却在指挥的工头铠甲，头盔上方悬着象征工籍的铜环光轮；一手持烙铁，另一手托着敕造记录板。
- **熔印大匠·瓦鲁克**（BOSS）：巨大魁梧的赤膊匠人，右半身皮肤已被熔金取代并凝出鳞状硬壳；左眼是嵌进眼窝的王家蓝符石，手持双头锻锤。

> 🎭 叙事注：瓦鲁克是**合法持证的**。玩家杀他不是执法，是"清理资产"。这是全作第一次道德失衡。

---

### 4.5 图 5 · 禁卷回廊（tier 4）· 全新实装

| 字段 | 值 |
|---|---|
| `name` | 禁卷回廊 |
| `tier` | 4 |
| `emoji` | 📜 |
| `desc` | 秘典庭地下书库，查封两百年的禁咒没有销毁，只是编号归档 |

**色板基调**：禁咒紫 `#b08cff` + 羊皮米 `#c9c0a4` + 深墨紫 `#5b4a86`

| key | 中文名 | emoji | 类型 | family | hp | atk | def | spd | crit | art.body | art.feature | art.feature2 | c1 | c2 | eye |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `forbidden_tome` | 禁卷造物 | 📕 | 小怪 | arcane | 130 | 30 | 12 | 38 | 0.14 | arcane_weave | runes_orbit | — | #c9c0a4 | #5b4a86 | #b08cff |
| `corridor_drake` | 卷廊守龙 | 🐲 | 小怪 | arcane | 100 | 32 | 10 | 36 | 0.16 | drake | wings_bone | runes_orbit | #4a5a7a | #242c40 | #5b9bff |
| `page_doll` | 浮页傀偶 | 📄 | 小怪 | arcane | 110 | 24 | 20 | 26 | 0.08 | arcane_weave | — | — | #c9c0a4 | #5b4a86 | #b08cff |
| `spell_thread` | 咒文游丝 | 🧵 | 小怪 | arcane | 120 | 26 | 14 | 34 | 0.12 | elemental | runes_orbit | — | #b08cff | #5b4a86 | #cbb2ff |
| `sealed_idol` | 封印守像 | 🗿 | 小怪 | arcane | 140 | 22 | 28 | 20 | 0.06 | construct | runes_orbit | — | #7c7466 | #453f36 | #b08cff |
| `library_wraith` | 书库怨灵 | 👻 | 小怪 | arcane | 95 | 34 | 12 | 40 | 0.18 | wraith | runes_orbit | — | #4a4560 | #241f38 | #b08cff |
| `forbidden_echo` | 禁咒回响 | 🔊 | 小怪 | arcane | 135 | 28 | 16 | 32 | 0.14 | arcane_weave | halo | — | #c9c0a4 | #5b4a86 | #cbb2ff |
| `errata_wisp` | 勘误游影 | ✏️ | 小怪 | arcane | 118 | 32 | 14 | 42 | 0.16 | elemental | crystals | chains | #8ad4e0 | #2a4a58 | #eaffff |
| `codex_clerk` | 禁卷书记官 | 🖋️ | **精英** | arcane | 820 | 82 | 44 | 40 | 0.20 | humanoid_civil | garb_caster | runes_orbit | #6b5a9e | #2e2448 | #cbb2ff |
| `sevlan` | **大掌典·塞维兰** | 📚 | **BOSS** | arcane | 3000 | 140 | 80 | 46 | 0.25 | humanoid_civil | garb_caster | runes_orbit | #6b5a9e | #2e2448 | #cbb2ff |

**AI 绘图视觉描述**
- **禁卷造物**：一本悬空自行翻页的厚重古籍，书页向外舒展成翅状；书脊处缠着断裂封条，页缝间渗出紫色雾气，无实体躯干。
- **卷廊守龙**：书架大小的青灰细龙，双翼只剩骨架；鳞片由压平的旧书页叠成，游走于书架顶端，口中吐出淡蓝符文串。
- **浮页傀偶**：由上百张散页粘合成的人形纸偶，四肢薄如剪影；面部是一张写满驳回意见的公文，行动时纸页哗哗作响。
- **咒文游丝**：无实体的紫色发光丝线在空中缠成人形轮廓，中央悬着一个跳动的咒文核；被击中时丝线散开又重新编结。
- **封印守像**：半陷入墙体的石质守卫像，双臂交叉抱着一枚镶紫晶的封印；石缝里长出符文苔，转动时石屑与符光同落。
- **书库怨灵**：披着破损学者长袍的半透明幽魂，兜帽下只有一团旋转字符；指尖拖着长长的墨迹，穿墙而过不留声响。
- **禁咒回响**：没有形体的紫白光轮，边缘不断有咒文浮出又湮灭；靠近时会重复播放两百年前施咒者的最后一句话。
- **勘误游影**：半透明的墨色人影，周身悬浮着被朱笔勾销的字句；没有面孔，只有一道不断重写的批注横贯头部，脚下拖着封条锁链。
- **禁卷书记官**（精英）：穿深紫官袍的高瘦文吏，戴多层镜片的审阅目镜；周身悬浮着六本上锁的禁卷，手持长柄封印笔。
- **大掌典·塞维兰**（BOSS）：苍老的紫袍掌典，双眼被两枚封印蜡片盖住；身后展开由数十本禁卷组成的扇形屏障，每本都在自行诵读。

> 🎭 叙事注：塞维兰不隐瞒——他会告诉你禁咒**从未销毁，只是编号归档**。制度囤积它所禁止之物。

---

### 4.6 图 6 · 削籍狱（tier 5）· 🆕

| 字段 | 值 |
|---|---|
| `name` | 削籍狱 |
| `tier` | 5 |
| `emoji` | ⛓️ |
| `desc` | 被划去姓名的人关在这里，狱卒也记不得自己是谁 |

**色板基调**：漂白灰蓝 `#8a8f9c` / `#3a3e48` + 抹除白 `#e8f0ff` + 朱批红 `#f9837c`（划名标记）

| key | 中文名 | emoji | 类型 | family | hp | atk | def | spd | crit | art.body | art.feature | art.feature2 | c1 | c2 | eye |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `unnamed_inmate` | 无名囚 | 🔒 | 小怪 | nameless | 150 | 27 | 24 | 24 | 0.06 | humanoid_civil | garb_rogue | chains | #7d8290 | #33373f | #d8e2f0 |
| `strike_scribe` | 划名书吏 | ✒️ | 小怪 | nameless | 122 | 36 | 14 | 40 | 0.14 | humanoid_civil | garb_caster | hold_dagger | #6a7080 | #2c3038 | #f9837c |
| `gaol_warden` | 缄狱看守 | 🚪 | 小怪 | nameless | 168 | 28 | 32 | 22 | 0.05 | knight | helm_great | hold_shield | #8a8f9c | #3a3e48 | #b9c4d6 |
| `erased_wretch` | 抹形囚 | 🌫️ | 小怪 | nameless | 130 | 34 | 16 | 38 | 0.13 | wraith | swarm | chains | #9aa0ae | #3f4450 | #ffffff |
| `ledger_hound` | 名录猎犬 | 🐕 | 小怪 | nameless | 128 | 38 | 12 | 46 | 0.16 | beast_quad | chains | swarm | #6e7482 | #2e323a | #f9837c |
| `blank_effigy` | 空籍傀 | 🗿 | 小怪 | nameless | 160 | 26 | 28 | 20 | 0.06 | construct | runes_orbit | crystals | #b0b6c2 | #4a4f5a | #dfe8f5 |
| `gag_choir` | 缄口囚群 | 🤐 | 小怪 | nameless | 118 | 32 | 18 | 42 | 0.12 | humanoid_small | swarm | chains | #7d8290 | #33373f | #c7d2e2 |
| `deed_burner` | 焚籍者 | 🔥 | 小怪 | nameless | 165 | 30 | 26 | 26 | 0.08 | humanoid_brute | flames | hold_torch | #8a7d70 | #3c352e | #ff9a4a |
| `warden_nameless` | **无名典狱长** | 🗝️ | **精英** | nameless | 980 | 97 | 51 | 34 | 0.21 | knight | helm_great | chains | #9aa0ae | #3f4450 | #f9837c |
| `null_seventh` | **第七号·无名** | 👤 | **BOSS** | nameless | 3600 | 166 | 92 | 44 | 0.26 | wraith | chains | crown | #c2c8d4 | #4a5060 | #ffffff |

**AI 绘图视觉描述**
- **无名囚**：褴褛囚服的瘦长人形，脸部像被湿布抹过一片模糊；胸口烙着已划去的编号，脚踝拖着刻满他人姓名的铁链。
- **划名书吏**：佝偻的狱吏，戴单片镜，右手握着蘸红墨的刻刀；长袍上密密麻麻钉着待销名牌，眼窝深处只有一点朱红。
- **缄狱看守**：无面全覆铠的看守，头盔面甲是一整块光滑铁板；左手巨盾正面拓印着整页除籍名录，行走时甲缝渗出白灰。
- **抹形囚**：半透明的人形残影，从脚踝往上正褪成白雾；伸出的手只剩轮廓线，嘴部大张却发不出自己被删除的名字。
- **名录猎犬**：皮毛剥落的灰犬，肋骨外露处缠着卷起的名册纸带；口鼻覆着铁制口枷，奔跑时纸带撕裂，飘出通缉者的名字。
- **空籍傀**：石膏色的空白人偶，五官处是三个凹槽等待填名；关节缝里塞满卷曲旧档，周身漂浮着无字的登记签。
- **缄口囚群**：三四个矮小囚徒挤成一团，嘴部被同一条铁链贯穿缝合；共用一副镣铐，动作整齐得像一台被拆开的机器。
- **焚籍者**：壮硕的赤膊囚犯，背上烙着整版被烧穿的名录；双手缠着燃烧的档案纸，火焰是冷白色，烧过之处只留空白。
- **无名典狱长**（精英）：高瘦的黑铁狱长，面甲上刻着自己被划掉的名字；一手提着钥匙串般的姓名铭牌，一手拖着长链。
- **第七号·无名**（BOSS）：只剩牢房编号的存在，白雾人形头顶悬着正在消散的锈铁王冠；每次动作短暂显出不同囚犯的面孔，随即抹平。

> 🎭 叙事注：`null_seventh` 头戴王冠 —— 他曾是某位被彻底除籍的王。**王国史书上没有第七位国王，因为他被划掉了。** 这是本图最重的一记钩子。

---

### 4.7 图 7 · 敕墨深坑（tier 6）· 🆕

| 字段 | 值 |
|---|---|
| `name` | 敕墨深坑 |
| `tier` | 6 |
| `emoji` | 🕳️ |
| `desc` | 敕令用的墨从这里榨出，矿工说坑底那东西还在流血 |

**色板基调**：墨紫 `#4a3a6e` / `#221c2e` + 生物荧光青 `#7ef0d0` + 虹彩油光

| key | 中文名 | emoji | 类型 | family | hp | atk | def | spd | crit | art.body | art.feature | art.feature2 | c1 | c2 | eye |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `ink_hauler` | 驮墨工 | 🪣 | 小怪 | abyssal | 200 | 32 | 30 | 22 | 0.07 | humanoid_brute | chains | hold_torch | #4a4058 | #221c2e | #7ef0d0 |
| `ink_leech` | 汲墨蛭 | 🪱 | 小怪 | abyssal | 145 | 45 | 15 | 46 | 0.18 | serpent | scales | swarm | #3a2f5a | #1c1630 | #7ef0d0 |
| `blot_ooze` | 墨污渗体 | 🫧 | 小怪 | abyssal | 190 | 34 | 24 | 20 | 0.08 | ooze | runes_orbit | crystals | #2e2648 | #16112a | #b08cff |
| `shaft_arachnid` | 井道织墨蛛 | 🕸️ | 小怪 | abyssal | 155 | 42 | 18 | 42 | 0.16 | arachnid | swarm | spikes | #4a3a6e | #241c38 | #ff7a33 |
| `deep_canary` | 坑底哨雀 | 🐦 | 小怪 | abyssal | 140 | 40 | 14 | 44 | 0.17 | beast_biped | wings | flames | #6a5a8a | #32284a | #ffe9a8 |
| `vein_construct` | 墨脉钻机 | ⛏️ | 小怪 | abyssal | 205 | 30 | 38 | 18 | 0.06 | construct | spikes | chains | #5a5060 | #2c2632 | #ff7a33 |
| `quill_elemental` | 笔渊元素 | 🪶 | 小怪 | abyssal | 160 | 46 | 16 | 40 | 0.18 | elemental | runes_orbit | crystals | #7a5ad0 | #362a68 | #cbb2ff |
| `sump_dweller` | 沉墨潜者 | 🦫 | 小怪 | abyssal | 185 | 38 | 26 | 30 | 0.11 | beast_quad | scales | mane | #3a3450 | #1c1828 | #7ef0d0 |
| `ink_overseer` | **墨坑监工** | 🪖 | **精英** | abyssal | 1170 | 114 | 59 | 36 | 0.22 | humanoid_brute | helm_great | chains | #5a4a7a | #2a2240 | #ff7a33 |
| `first_wellspring` | **初墨·涌** | 🌑 | **BOSS** | abyssal | 4400 | 196 | 106 | 42 | 0.28 | ooze | crystals | runes_orbit | #6a4ad0 | #2e1f5e | #ffffff |

**AI 绘图视觉描述**
- **驮墨工**：背负破裂墨桶的矿工，黑墨顺着脊背淌下并生出细须；下半张脸已被墨壳包住，只剩一只透着青光的眼。
- **汲墨蛭**：两米长的环节蛭，体表油亮泛虹彩；无眼，前端是一圈螺旋倒齿的吸口，爬过的岩面留下缓慢自行书写的墨迹。
- **墨污渗体**：缓慢蠕动的黑墨团，内部悬着未溶解的敕令残句；表面不断浮起又沉下人脸的轮廓，边缘结着紫色墨晶。
- **井道织墨蛛**：八条细长节肢的矿井蛛，腹部鼓胀盛满墨液；吐出的不是丝而是成串墨字，在井壁织成一张会读的网。
- **坑底哨雀**：被墨浸透的巨鸟，羽毛结成硬壳般的黑板岩片；喉部裂开发出报警似的尖鸣，鸣叫时口中喷出冷蓝磷火。
- **墨脉钻机**：半陷进岩壁的老式钻掘机，机身缠满渗墨软管；钻头仍在空转，机腹裂口里露出被绞进去的矿工衣料。
- **笔渊元素**：由数百支断裂羽笔悬浮聚成的人形，笔尖全部朝外滴墨；核心是一团旋转紫光，挥臂动作像在书写。
- **沉墨潜者**：四足伏行的无皮兽，肌肉外覆一层流动墨膜；抬头时墨膜滑落，露出下方数十枚发青光的小眼。
- **墨坑监工**（精英）：戴铜制潜水盔的巨汉，盔内灌满黑墨并不断冒泡；一手鞭索由凝墨拧成，一手提着仍在计数的名册。
- **初墨·涌**（BOSS）：填满矿坑底部的活墨深潭，中央隆起一座人形墨柱；柱面浮现全王国的登记条文，如翻页般缓慢更替。

> 🎭 叙事注：玩家的**持牌证书就是用这个东西的体液写的**。打完这图后，玩家每次看自己的执照都会想起坑底。

---

### 4.8 图 8 · 初录龙冢（tier 7）· 🆕

| 字段 | 值 |
|---|---|
| `name` | 初录龙冢 |
| `tier` | 7 |
| `emoji` | 🐉 |
| `desc` | 登记制度是为拴住龙才发明的，第一批编号至今还锁在这 |

**色板基调**：黄铜金 `#b08a4a` + 余烬橘 `#ff9a3c` + 龙骨米白 `#cfc2a0`

| key | 中文名 | emoji | 类型 | family | hp | atk | def | spd | crit | art.body | art.feature | art.feature2 | c1 | c2 | eye |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `barrow_drake` | 冢守幼龙 | 🦎 | 小怪 | drakeborn | 190 | 50 | 22 | 44 | 0.17 | drake | scales | wings_bone | #8a5a3a | #40281a | #ff9a3c |
| `chained_wyrmling` | 拴籍龙雏 | ⛓️ | 小怪 | drakeborn | 175 | 54 | 18 | 46 | 0.19 | drake | chains | horns | #b08a4a | #4e3c1e | #ffd24a |
| `scale_curator` | 鳞录管事 | 📏 | 小怪 | drakeborn | 200 | 40 | 30 | 28 | 0.09 | humanoid_civil | garb_merchant | hold_staff | #9a8a6a | #47402e | #ffd24a |
| `wyrm_bone_knight` | 龙骨敕卫 | 🦴 | 小怪 | drakeborn | 240 | 42 | 44 | 24 | 0.07 | knight | helm_great | hold_sword | #cfc2a0 | #6a604a | #ff7a33 |
| `ember_hatch` | 余烬孵体 | 🥚 | 小怪 | drakeborn | 178 | 52 | 20 | 42 | 0.18 | beast_biped | flames | scales | #c25a2a | #55220e | #ffe9a8 |
| `hoard_wraith` | 藏宝怨魂 | 🪙 | 小怪 | drakeborn | 168 | 48 | 24 | 40 | 0.16 | wraith | crown | runes_orbit | #6a5a3a | #2e2818 | #ffd24a |
| `mausoleum_ooze` | 龙冢腐脂 | 🫗 | 小怪 | drakeborn | 235 | 38 | 34 | 22 | 0.08 | ooze | scales | flames | #7a6a3a | #38301a | #a8c93a |
| `sky_kin_scout` | 天裔哨龙 | 🌬️ | 小怪 | drakeborn | 172 | 56 | 17 | 48 | 0.19 | drake | wings | hold_torch | #4a6a9a | #22334a | #6cd8f0 |
| `seal_bearer_wyrm` | **衔印祖龙** | 🏵️ | **精英** | drakeborn | 1400 | 135 | 68 | 38 | 0.23 | drake | crown | chains | #b8964a | #503c1c | #ff7a33 |
| `vaerith_no1` | **编号〇〇一·瓦厄瑞斯** | 🐲 | **BOSS** | drakeborn | 5400 | 232 | 122 | 44 | 0.30 | drake | horns | chains | #c86a2a | #5a2410 | #ffffff |

**AI 绘图视觉描述**
- **冢守幼龙**：犬马大小的幼龙，鳞片被磨去一半以便刻印；双翼只剩骨架撑着焦黑残膜，颈侧铆着一枚过大的黄铜登记环。
- **拴籍龙雏**：蜷成一团的龙雏，四肢与颈部各锁一条刻字铁链；每挣扎一次链上敕文便亮起，把它按回原地，鳞下透出红光。
- **鳞录管事**：披龙鳞拼缀外袍的老者，脖颈已长出细鳞；手持带钩量尺，腰间挂满从活龙身上取下的编号鳞片。
- **龙骨敕卫**：以龙脊骨拼成铠甲的高大骑士，头盔即龙颅；胸甲正中嵌着一整块登记铭板，剑身是磨利的肋骨。
- **余烬孵体**：刚破壳的半龙半兽体，皮肤下透出流动的橘红火脉；脚印烧焦地面，背脊裂缝不断掉落灼热碎壳。
- **藏宝怨魂**：由散落金币与碎鳞聚成的半透明蛇形怨魂，头戴陷进雾里的破损王冠；游动时叮当作响，沿途落下真金。
- **龙冢腐脂**：从龙尸腹腔漏出的金褐色黏脂，内部沉着未消化的甲胄与登记牌；表面偶尔鼓起龙鳞状硬壳又塌陷。
- **天裔哨龙**：细长如猎隼的青蓝小龙，双翼展开可见半透明血管纹；口衔一盏冷蓝信号灯，飞过之处留下发光航迹。
- **衔印祖龙**（精英）：苍老的巨龙上半身，下半身已石化陷入冢土；口中永远衔着王国第一枚敕印，睁眼时印文与瞳孔同亮。
- **编号〇〇一·瓦厄瑞斯**（BOSS）：覆满剥落金箔的巨龙，全身鳞片都刻着同一串编号；四条主链自山壁牵入胸腔，每次呼吸都拽动整座龙冢。

> 🎭 叙事注：**史上最强的龙，在档案里只是一行"编号〇〇一"。** 官僚黑色幽默的最高点，也是"登记即驯服"的具象证明。

---

### 4.9 图 9 · 王庭档案宫（tier 8）· 🆕

| 字段 | 值 |
|---|---|
| `name` | 王庭档案宫 |
| `tier` | 8 |
| `emoji` | 🏛️ |
| `desc` | 发牌的人住在这里，每一格抽屉里都锁着一个还没死的名字 |

**色板基调**：王家蓝 `#2f5fa8` / `#1c2440` + 黄铜高光 `#e8c579` + 羊皮米 `#d8d0be`

| key | 中文名 | emoji | 类型 | family | hp | atk | def | spd | crit | art.body | art.feature | art.feature2 | c1 | c2 | eye |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `stamp_clerk` | 用印吏 | 🧾 | 小怪 | sealbound | 235 | 48 | 34 | 30 | 0.10 | humanoid_civil | garb_merchant | hold_staff | #4a5578 | #222840 | #e8c579 |
| `file_wraith` | 卷宗游魂 | 🗂️ | 小怪 | sealbound | 205 | 60 | 24 | 44 | 0.19 | wraith | runes_orbit | chains | #4a4560 | #241f38 | #5ba3e8 |
| `seal_knight` | 敕印卫 | 🛡️ | 小怪 | sealbound | 290 | 46 | 50 | 22 | 0.07 | knight | helm_great | hold_shield | #3a4a7a | #1c2440 | #e8c579 |
| `quota_auditor` | 核额监审 | 🧮 | 小怪 | sealbound | 210 | 62 | 26 | 42 | 0.18 | humanoid_civil | garb_caster | runes_orbit | #5a4a86 | #2a2248 | #b08cff |
| `archive_construct` | 档架构装 | 🗄️ | 小怪 | sealbound | 285 | 44 | 46 | 20 | 0.08 | construct | crystals | spikes | #6a6a7a | #32323e | #5ba3e8 |
| `writ_serpent` | 敕条长蛇 | 🐍 | 小怪 | sealbound | 215 | 64 | 22 | 46 | 0.20 | serpent | runes_orbit | scales | #2f5fa8 | #16294a | #e8c579 |
| `sealed_petitioner` | 缄封陈情者 | 📩 | 小怪 | sealbound | 200 | 56 | 20 | 40 | 0.16 | humanoid_small | chains | halo | #8a8270 | #403c30 | #f9837c |
| `court_elemental` | 庭火使 | 🕯️ | 小怪 | sealbound | 240 | 58 | 30 | 36 | 0.15 | elemental | flames | crown | #e8c579 | #6a4a10 | #ffffff |
| `grand_notary` | **大录事·执笔** | 🖊️ | **精英** | sealbound | 1680 | 159 | 78 | 40 | 0.24 | humanoid_civil | garb_caster | hold_staff | #3a4a7a | #1c2440 | #e8c579 |
| `chancellor_maerus` | **掌玺相·迈鲁斯** | 👔 | **BOSS** | sealbound | 6600 | 274 | 140 | 46 | 0.32 | humanoid_brute | crown | runes_orbit | #2f5fa8 | #16294a | #e8c579 |

**AI 绘图视觉描述**
- **用印吏**：王庭制式蓝袍的中年文吏，右臂从肘部起已变成一枚巨大黄铜印章；他不说话，只是抬臂盖章，落印处冒白烟。
- **卷宗游魂**：由散页公文卷成的人形幽魂，纸页边缘泛蓝焰；面部是一张贴歪的封条，移动时不断掉落读不完的判词。
- **敕印卫**：深蓝重铠的宫廷卫士，胸甲即一面凸起的王室封印；面甲无孔，盾牌背面密密刻着历年执行过的处决编号。
- **核额监审**：瘦高的审计官，戴多层单片镜叠成的护目器；周身悬浮一圈自动翻动的账页，指尖划过之处数字变成伤口。
- **档架构装**：由整排移动档案柜改造的六足构装，抽屉不断弹出又收回；顶部一盏读取灯扫描视野，柜内塞满打包好的人名。
- **敕条长蛇**：由一整卷展开的敕令条文构成的长蛇，鳞片即字行；游动时条文重排为新罪名，蛇信是两条摆动的封蜡带。
- **缄封陈情者**：矮小佝偻的陈情人，双手捧着从未被拆封的诉状；口鼻被红色封蜡整个封死，头顶悬一圈残破的受理光环。
- **庭火使**：由焚毁档案的余火凝成的人形，全身金焰中翻卷着烧了一半的公文；头顶火焰自然拧成一顶小小的王冠。
- **大录事·执笔**（精英）：身形被公文卷轴层层裹成塔状的老录事，只露出一只手；那只手握着与人等长的黄铜笔，笔尖蘸的是暗红色。
- **掌玺相·迈鲁斯**（BOSS）：王国掌玺大臣，礼袍下的躯体已与国玺融为一体，胸口是一方转动的巨型玉印；每盖一次印，脚下地面便浮出敕文。

> 🎭 叙事注：迈鲁斯**不是反派**。他会给玩家看档案：玩家自己的持牌记录，以及旁边一栏"预定除籍日期"。

---

### 4.10 图 10 · 初敕之座（tier 9）· 🆕 终局

| 字段 | 值 |
|---|---|
| `name` | 初敕之座 |
| `tier` | 9 |
| `emoji` | 👑 |
| `desc` | 王庭只是抄写员，真正立法的东西一直坐在这张椅子上 |

**色板基调**：白金 `#e8e2d0` / `#ffffff` + 敕金 `#ffd24a` + 虚空黑 `#0f1116` + 违禁朱 `#b5342f`

| key | 中文名 | emoji | 类型 | family | hp | atk | def | spd | crit | art.body | art.feature | art.feature2 | c1 | c2 | eye |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `edict_echo` | 敕文回响 | 📖 | 小怪 | primordial | 265 | 70 | 30 | 42 | 0.19 | arcane_weave | runes_orbit | halo | #e8e2d0 | #6a6250 | #ffd24a |
| `first_clerk` | 初代书记 | 🕊️ | 小怪 | primordial | 250 | 74 | 26 | 44 | 0.20 | humanoid_civil | garb_caster | hold_staff | #cfc6ae | #5e5644 | #ffffff |
| `throne_seraph` | 座前圣仪 | 😇 | 小怪 | primordial | 300 | 62 | 48 | 30 | 0.12 | knight | halo | wings | #f0e8d0 | #7a7058 | #ffd24a |
| `void_unregistered` | 未录之物 | ⬛ | 小怪 | primordial | 350 | 56 | 40 | 26 | 0.11 | ooze | swarm | crystals | #1c1e26 | #0f1116 | #b5342f |
| `writ_drake` | 敕令白龙 | 🐉 | 小怪 | primordial | 275 | 72 | 34 | 46 | 0.21 | drake | scales | runes_orbit | #f0ecdc | #7a7460 | #ffd24a |
| `primal_construct` | 初敕守机 | 🔷 | 小怪 | primordial | 345 | 58 | 58 | 28 | 0.10 | construct | crystals | chains | #d8d0be | #6a6250 | #6cd8f0 |
| `covenant_wraith` | 契文怨影 | 🤝 | 小怪 | primordial | 258 | 76 | 28 | 44 | 0.22 | wraith | chains | crown | #9aa0ae | #3f4450 | #b5342f |
| `sceptre_elemental` | 权杖之炬 | 🔱 | 小怪 | primordial | 268 | 78 | 24 | 48 | 0.22 | elemental | flames | halo | #ffd24a | #8a6410 | #ffffff |
| `seat_warden` | **守座执笔者** | ⚔️ | **精英** | primordial | 2050 | 190 | 92 | 42 | 0.26 | knight | crown | hold_sword | #e8e2d0 | #6a6250 | #b5342f |
| `the_first_edict` | **初敕·万物之名** | 👑 | **BOSS** | primordial | 8400 | 330 | 165 | 48 | 0.35 | arcane_weave | crown | runes_orbit | #ffffff | #8a8270 | #b5342f |

**AI 绘图视觉描述**
- **敕文回响**：悬空的金色字阵人形，没有实体，只有不断自我誊抄的敕令条文；靠近时可听见成千个声音同时朗读同一句话。
- **初代书记**：穿着比王国更古老的白色礼服的书记，面孔平滑无五官；双手各持一支笔，同时书写两份内容相反的登记档。
- **座前圣仪**：六翼白金甲卫，双翼由折叠的敕令石板构成；面甲是一面打磨过的镜子，照出的永远是观者被登记时的模样。
- **未录之物**：一团吞光的漆黑轮廓，形状每秒都在改变且无法被记住；边缘生出红色晶簇，那是被强行赋名时留下的伤口。
- **敕令白龙**：通体象牙白的细长龙，每一片鳞都是一枚已生效的敕印；飞行无声，掠过之处空气里浮现又消散金色条款。
- **初敕守机**：远早于王庭工艺的白石构装，关节以悬浮晶体代替铰链；胸腔空洞中封着一枚仍在缓慢旋转的原初印章。
- **契文怨影**：被自己签下的契约反噬的王者残影，半透明躯体上密布凹陷的手印；头顶王冠倒悬，锁链自冠上垂入胸口。
- **权杖之炬**：由纯白火焰构成的高瘦人形，手中托着一柄不会熄灭的加冕火炬；火焰内部隐约可见历代国王的加冕瞬间。
- **守座执笔者**（精英）：守在王座阶前的白金骑士，剑柄处生出羽笔；甲面浮动着历任守座者的名字，最新一行还是空白，等待填入。
- **初敕·万物之名**（BOSS）：由无穷金色条文盘旋而成的王座与人影合体，看不清彼此边界；每读出一个名字，对应的存在就在战场上短暂显形。

> 🎭 终局注：`void_unregistered`（未录之物）是**全作唯一真正未被登记的存在**——它出现在最后一图，说明"未登记"从来不是玩家追捕的那些走私犯与污染兽，而是这个。玩家花了十张图追捕的"违规者"，其实全都在册。
> 🎭 `seat_warden` 甲面「最新一行还是空白，等待填入」= 给玩家留的位置。结局分支钩子。

---

## 5. 新增 art 枚举提议

### 🟢 无。本次新增 0 项。

73 只新怪全部使用 `index.html` L1370–1719 **已实现**的 16 body + 26 feature。工程**无需改动** `MON_BODIES` / `MON_FEATURES` 任何一行。

**枚举覆盖率自检：**

| 类别 | 全集 | 本次用到 | 未用到 |
|---|---|---|---|
| body | 16 | **15** | `fey_plant`（仅 tier0 `thornling` 使用，保持污染兽独占） |
| feature | 26 | **22** | `none`（空槽语义）、`vines`、`antlers`（tier0 `rust_stag` 独占）、`garb_warrior`（tier1 `merc_hire` 独占）—— 保留给现有怪，避免高 tier 撞脸 |

**配色分离自检**（10 图各自主色域互不重叠）：

| tier | 主色域 | 与相邻 tier 的区分手段 |
|---|---|---|
| 0 | 苔绿 | — |
| 1 | 皮革褐 + 职业色 | 饱和度更低 |
| 2 | 骨白 + 圣金 | 明度跳升 |
| 3 | 铁灰 + 熔渣橘 | 引入高饱和暖色 |
| 4 | 羊皮米 + 禁咒紫 | 冷色反转 |
| 5 | 漂白灰蓝 + 朱批红 | **去饱和**（叙事：褪色 = 被抹除） |
| 6 | 墨紫 + 荧光青 | 明度最低（地下最深） |
| 7 | 黄铜金 + 余烬橘 | 明度回升、暖色回归 |
| 8 | 王家蓝 + 黄铜 | 冷暖对撞、最"体面" |
| 9 | 白金 + 虚空黑 | 极端明度对比（唯一使用纯白 `#ffffff` 作 c1） |

> ✅ **纯白 `#ffffff` 作 `c1` 仅在 tier9 Boss 使用一次**，是刻意保留的"终局视觉特权"。请勿在其他地方使用。
> ✅ 所有 `c1` 在石区背景 `--stone-1 #171a20` / `--stone-2 #2b313d` 上对比度充足；`void_unregistered` 的 `c1 #1c1e26` 是**唯一例外**——它就是要"几乎看不见"，靠 `eye #b5342f` 与 `crystals` 高光定位轮廓。这是设计意图，**不是对比度缺陷，请勿在无障碍审计中修正**。

---

## 6. 工程落地清单

### 6.1 数据表改动点

| 文件位置 | 改动 |
|---|---|
| `index.html` L1732 `MONSTERS` | 新增 **73** 条；3 只补位怪插入对应图分组；解开 L1766–1770 注释并填入 tier3/4 完整数据；追加 tier5–9 共 50 条 |
| `index.html` L1802 `MAPS` | 现有 3 条各在 `pool` 末尾加 1 个 key；新增 **7** 条地图对象 |

### 6.2 `MAPS` 新增条目（可直接复制）

```js
{name:'灰铸厂', tier:3, emoji:'🔨', desc:'王庭在此把魔法合法锻进兵器，炉火两百年未熄，废件从不外运',
  pool:['foundry_golem','slag_element','rivet_guard','forge_doll','ash_construct','sigil_knight','anvil_ward','scrap_remelt'],
  elite:'live_foreman', boss:'varuk'},
{name:'禁卷回廊', tier:4, emoji:'📜', desc:'秘典庭地下书库，查封两百年的禁咒没有销毁，只是编号归档',
  pool:['forbidden_tome','corridor_drake','page_doll','spell_thread','sealed_idol','library_wraith','forbidden_echo','errata_wisp'],
  elite:'codex_clerk', boss:'sevlan'},
{name:'削籍狱', tier:5, emoji:'⛓️', desc:'被划去姓名的人关在这里，狱卒也记不得自己是谁',
  pool:['unnamed_inmate','strike_scribe','gaol_warden','erased_wretch','ledger_hound','blank_effigy','gag_choir','deed_burner'],
  elite:'warden_nameless', boss:'null_seventh'},
{name:'敕墨深坑', tier:6, emoji:'🕳️', desc:'敕令用的墨从这里榨出，矿工说坑底那东西还在流血',
  pool:['ink_hauler','ink_leech','blot_ooze','shaft_arachnid','deep_canary','vein_construct','quill_elemental','sump_dweller'],
  elite:'ink_overseer', boss:'first_wellspring'},
{name:'初录龙冢', tier:7, emoji:'🐉', desc:'登记制度是为拴住龙才发明的，第一批编号至今还锁在这',
  pool:['barrow_drake','chained_wyrmling','scale_curator','wyrm_bone_knight','ember_hatch','hoard_wraith','mausoleum_ooze','sky_kin_scout'],
  elite:'seal_bearer_wyrm', boss:'vaerith_no1'},
{name:'王庭档案宫', tier:8, emoji:'🏛️', desc:'发牌的人住在这里，每一格抽屉里都锁着一个还没死的名字',
  pool:['stamp_clerk','file_wraith','seal_knight','quota_auditor','archive_construct','writ_serpent','sealed_petitioner','court_elemental'],
  elite:'grand_notary', boss:'chancellor_maerus'},
{name:'初敕之座', tier:9, emoji:'👑', desc:'王庭只是抄写员，真正立法的东西一直坐在这张椅子上',
  pool:['edict_echo','first_clerk','throne_seraph','void_unregistered','writ_drake','primal_construct','covenant_wraith','sceptre_elemental'],
  elite:'seat_warden', boss:'the_first_edict'},
```

### 6.3 key 唯一性校验

73 个新 key 已与现有 27 个逐一比对，**无重复** ✅。完整新 key 清单：

```
tier0-2 补位(3): fade_moth, seal_forger, choir_husk
tier3(10): foundry_golem, slag_element, rivet_guard, forge_doll, ash_construct,
           sigil_knight, anvil_ward, scrap_remelt, live_foreman, varuk
tier4(10): forbidden_tome, corridor_drake, page_doll, spell_thread, sealed_idol,
           library_wraith, forbidden_echo, errata_wisp, codex_clerk, sevlan
tier5(10): unnamed_inmate, strike_scribe, gaol_warden, erased_wretch, ledger_hound,
           blank_effigy, gag_choir, deed_burner, warden_nameless, null_seventh
tier6(10): ink_hauler, ink_leech, blot_ooze, shaft_arachnid, deep_canary,
           vein_construct, quill_elemental, sump_dweller, ink_overseer, first_wellspring
tier7(10): barrow_drake, chained_wyrmling, scale_curator, wyrm_bone_knight, ember_hatch,
           hoard_wraith, mausoleum_ooze, sky_kin_scout, seal_bearer_wyrm, vaerith_no1
tier8(10): stamp_clerk, file_wraith, seal_knight, quota_auditor, archive_construct,
           writ_serpent, sealed_petitioner, court_elemental, grand_notary, chancellor_maerus
tier9(10): edict_echo, first_clerk, throne_seraph, void_unregistered, writ_drake,
           primal_construct, covenant_wraith, sceptre_elemental, seat_warden, the_first_edict
```

### 6.4 下游联动（不在本文范围，但会被打到）

| 系统 | 影响 | 需要谁 |
|---|---|---|
| **GDD 02 `BOSS_DROPS`** | 新增 7 个 Boss key 需配唯一装备掉落，否则打完无奖励 | 策划（我）· 后续任务 |
| **GDD 05 经济模型** | 离线收益/金币按 tier 计算，需扩展到 tier9 | 策划（我）· 后续任务 |
| **GDD 01 等级上限** | 🔴 见 §2.5，Lv30 上限撑不住 10 张图 | **需用户拍板** |
| **立绘资产** | 73 张新 PNG，路径 `assets/monsters/<key>.png`；缺图时程序化 SVG 兜底已覆盖（`art` 字段齐全） | 美术 |

---

## 7. 已知风险与待验证假设

| # | 假设 / 风险 | 等级 | 调整方向 |
|---|---|---|---|
| **R1** | 🔴 `scale` 公式 `tier×0.6` 在 tier9 失控（§2.5） | 🔴 高 | 改系数至 0.35 + 提升等级上限，**上线前必须决策** |
| R2 | 1.20/1.18/1.16 复利曲线未经实测 | 🟠 中高 | tier5 起每图实测 TTK，目标 20–90s；超标优先调 base 值不调公式 |
| R3 | 10 个家族对休闲玩家是否过载 | 🟡 中 | 已用"一图一族 + 独占色板"隔离；若仍混淆，强化图内色板纯度 |
| R4 | `spd` 上限 48 vs 玩家 spd 成长 | 🟡 中 | 若高等级玩家 spd 远超 60，高 tier 怪将永远后手，届时需引入 spd 随 tier 微增 |
| R5 | 73 张立绘的美术产能 | 🟠 中高 | 程序化 SVG 兜底已保证可上线；立绘可分批补，建议优先 10 Boss + 10 精英 |
| R6 | tier9 `void_unregistered` 近黑配色在低端屏不可见 | 🟢 低 | 设计意图，靠 eye 与 crystals 定位；若实测完全不可见，c1 提到 `#242730` |
| R7 | 叙事线仅存在于 `desc` 一句话中，玩家可能感知不到 | 🟠 中高 | **建议增加"图间过场文本"或"Boss 击杀后档案条目"**，成本低、收益高；需用户确认是否排期 |

---

## 8. 验收标准

| # | 标准 | 验证方式 |
|---|---|---|
| B1 | `MONSTERS` 共 100 条，key 全局唯一 | `Object.keys(MONSTERS).length === 100` + Set 去重比对 |
| B2 | `MAPS` 共 10 条，tier 0–9 连续无缺 | 遍历检查 |
| B3 | 每图 `pool.length === 8`，且 `elite`/`boss` 各 1 且存在于 `MONSTERS` | 脚本校验引用完整性 |
| B4 | 每只怪 `art` 含 body/c1/c2/eye（feature/feature2 可选） | 逐条查字段 |
| B5 | 所有 `art.body` ∈ `MON_BODIES`，`art.feature*` ∈ `MON_FEATURES` | 脚本比对枚举 |
| B6 | 所有 `img` 字段在 `mkMon()` **顶层**，不在 `art:{}` 内 | 正则搜 `art:{[^}]*img:` 应为 0 命中 |
| B7 | 各 tier 小怪数值落在 §2.3 区间内 | 脚本区间校验 |
| B8 | 精英/Boss 的 hp/atk/def 严格随 tier 单调递增 | 脚本比对 |
| B9 | 所有 `spd ≤ 48`、小怪 `crit ≤ 0.22`、Boss `crit ≤ 0.35` | 脚本校验 |
| B10 | 73 只新怪的 AI 绘图描述均 ≥30 字且互不雷同 | 人工抽查 + 字数统计 |

---

---

## 9. 第六档红色传说「未录」与 BOSS 掉落（合并章节）

> 📌 本任务背景：GDD 04b 原第 4 条（18 个装备阶名）已作废。本章节**取代**它，并**合并**承接"7 个 BOSS 专属掉落"需求——即 tier3–9 的 7 件 BOSS 装备就是本节的 7 件红色传说，不另设两套。
> 📌 本设计应作为 **GDD 02 §3.1 稀有度阶梯**的第 6 项归档（与五档同一张表），此处先以独立章节交付，落地时并入 GDD 02。
> 📌 **数值口径**：沿用现有裸数值口径，基础值即裸数，主要放大交由 `scale`（怪物）/ `baseMult = rarity.mult × (1+tier×0.4)`（装备）负责，**不自行叠倍率**（与 §2 怪物曲线同一原则）。
> 📌 沿用上条消息第 1 条：art 词表禁止自创（本条不涉及 art，仅 equipment 字段）。

### 9.1 第六档定义（追加到 `RARITY`）

```js
// 追加到 index.html L984 之后
{key:'unrecorded', name:'未录', icon:'🔴', color:'#e6443b', affixes:5, mult:2.6},
```

| 字段 | 值 | 说明 |
|---|---|---|
| `key` | `unrecorded` | 英文小写，接在 `legendary` 之后 |
| `name` | **未录** | 见 §9.2 钩子；比"传说"更有制度味 |
| `icon` | 🔴 | 与 ⚪🟢🔵🟣🟠 同序列 |
| `color` | `#e6443b` | 亮饱和红。**区别于**美术圣经 §2.1 纹章朱红 `#b5342f`（仅用于 BOSS 标签/禁令印）与敕造橙 `#ff9f3a`，避免与 BOSS 红混淆 |
| `affixes` | **5** | 比敕造（4）多 1 条随机词缀 |
| `mult` | **2.6** | 比敕造（2.25）高约 15%；真正的价值在独特机制而非数值 |

> ⚠️ **命名冲突预防（呼应 GDD 02 §3.1.1）**：`rarityName:'未录'` 不进入 `equipBaseName()` 拼装串（物品名仍为 `前缀+阶位名+部位名`），因此不会与任何阶位/前缀撞词，A13 守卫仍成立。

### 9.2 世界观钩子：第六档「未录」是什么

前五档（无印→注籍→批准→特许→敕造）是**登记制度的五个层级**——一件物品"被王国承认到什么程度"。

第六档是**这条线之外**的东西：**王国自己都没法登记之物**。

- 王国能给万物盖印，但有一类存在**没有可被登记的名字**：要么是"被除名之后连名字都不剩"的残渣（呼应 tier5 削籍狱的 `nameless`），要么是**比登记制度本身还早、制度没有对应词条**的原初之物（呼应 tier9 `the_first_edict` 与 `void_unregistered` / 未录之物）。
- 红色 = 美术圣经里"删除/禁令/BOSS"的朱红语义的**升格**：敕造是"王庭造的"，未录是"连王庭都不敢造、也不敢销"的。它是整条叙事的**反面印章**——你每拿到一件未录，就等于从制度手里扣下了一件它永远追不回来、也永远不承认你拥有的东西。
- 因此未录装备**天然带"独一性"**：制度不允许"拥有无法登记之物"，所以持有即违规、复制即悖论。

### 9.3 独一性机制

**① 与现有 `genBossUnique()` 的关系**

现有 `genBossUnique()`（L1357）产出的是 `rarity:'legendary'`（敕造）、`unique:true`。未录**不取代**敕造，而是**在其之上加一档**：

- tier0–2 三张老图的 Boss **保留**原有橙色敕造掉落（`rust_crown` / `三指的抽成` / `缄口牌符`），**额外**各补 1 件红色未录（见 §9.5）。即这 3 个 Boss 掉"一橙一红"两档唯一。
- tier3–9 七个新 Boss **只掉红色未录**（即原"7 个 BOSS 专属掉落"升级为本档），不另发敕造。

> 决策理由：老图 Boss 的橙色敕造已在 GDD 02 §5.6 定型且被指名引用，改动会牵动验收 A9，故保留；在其上补红既满足"10 张图各 1 件红色传说"，又不破坏既有内容。

**② 独一性规则（全局唯一，按 Boss 计）**

- 每件未录绑定一个 `bossKey`，存档内**至多持有 1 件该 Boss 的未录**（`G.ownedMythic` 集合持久化）。
- 已持有的 Boss **不再掉落其未录**（loot 判定跳过）；仍可掉技能书 / 常规战利品。
- 不可重复、不可重铸（重铸 UI 对其屏蔽，见 GDD 02 §9 E10 二次确认逻辑沿用）。
- 分解允许但需二次确认；分解后 `G.ownedMythic` **不移除**（已"见过"即不算再次拥有，避免反复刷）。

**③ 获取途径与掉率**

| 途径 | 说明 | 掉率 |
|---|---|---|
| **Boss 击杀（主途径）** | 归属该图 Boss，单次击杀独立掷骰 | **基础 5%** |
| **保底** | 同一 Boss 连续 20 次未出，第 21 次**必出**（`G.bossKillStreak[bossKey]` 计数） | 100%（保底触发时） |
| 合成 / 任务 / 条件 | **本期不做**。未录的"不可登记"设定天然排斥"玩家自己造"，保留稀缺性；若未来要做，建议走"集齐该 Boss 全部常规掉落自动凝结"而非锻造 | — |

> 掉率设计哲学：5% 可刷、带 20 杀保底 → 既稀有又不会永远脸黑；配合"已拥有即停掉"避免仓库塞满重复红装。

### 9.4 装备—技能联动模型「敕令共鸣」

用户点名"做好装备和技能的联动"。我选定**一种做扎实**（不贪多），并说明取舍：

**模型：每件未录绑定一个 `mythic.skill`，装上即「赋予 + 强化 + 改写」三位一体。**

1. **赋予（Grant）**：装备时，绑定技能**自动习得并 +1 级**（复用现有 `skillLv` 词缀的 `skillLevel()` 读取机制；若已更高则取大）。即"穿上就会"。
2. **强化（Strengthen）**：该技能随装备常驻 +1 级，效果自然增强。
3. **改写（Rewrite / 独特属性）**：`mythic.desc` 描述的机制级效果，在战斗结算该技能时**覆盖/追加**其行为（改冷却、改消耗、加触发、或附加反向取舍）。

**为什么选它而不是"套装式联动"**：套装联动（未录 + 特定技能书 = 额外效果）会让成就感依赖"恰好同时拥有两样东西"，对放置游戏的单次掉落体验不友好；而"绑定即生效"让每一件未录**独立成体系**、掉到即用、立刻改变玩法，契合放置游戏的"瞬时正反馈"。套装联动作为**可选扩展**保留（见 §9.7 风险 R4），本期不实现。

**数据结构（在装备实例上新增 `mythic` 字段）**：

```js
{
  uid, slot, name, rarity:'unrecorded', rarityName:'未录', unique:true,
  base:{...}, affixes:[...],            // affixes 仍走 generateAffixes，随机 5 条
  mythic:{ skill:'boundary_wrath',      // 绑定技能 key（见 SKILLS）
           desc:'初敕余响：释放不再耗 CD，改为消耗 15% 当前最大生命…',  // 机制级独特属性
           cost:'每次释放自损生命，残血高风险' },   // 反向取舍（UI 红字提示）
  wType?, armorType?, tierIdx?, reqLv?
}
```

> 战斗侧只需在技能结算处加一句：`if (equippedMythic && equippedMythic.skill===skillId) applyMythic(skillId, ...)`。这是**纯增量**逻辑，不改动既有 `castSkill`/`generateAffixes`。

### 9.5 十件传说装备清单（每图 Boss 各 1 件）

| 归属 Boss (tier) | key | 名称 | slot | reqLv | base（裸数） | 绑定技能 | 反向取舍 |
|---|---|---|---|---|---|---|---|
| `rust_stag` (0) | `myth_rust_crown` | 锈冠·褪印 | head | 10 | `{hp:160,def:30}` | `boundary_wrath` | 每次释放自损 15% 当前最大生命 |
| `oz_threefinger` (1) | `myth_oz_ring` | 三指·脱籍戒 | ring | 18 | `{atk:32,crit:0.06}` | `blackmarket_toxin` | 击杀的非 BOSS 不再掉金币 |
| `edna_silent` (2) | `myth_edna_charm` | 缄口·逆咏牌符 | amulet | 26 | `{hp:190,crit:0.05}` | `silent_hymn` | 技能不再回血，续航全靠护盾 |
| `varuk` (3) | `myth_forge_hammer` | 熔印·锻律锤 | weapon(warhammer) | 28 | `{atk:48}` | `berserk` | 狂暴期自身受伤 +30% |
| `sevlan` (4) | `myth_codex_staff` | 掌典·禁页杖 | weapon(staff) | 36 | `{atk:30}` | `chain_lightning` | 被标记者仇恨转向你 |
| `null_seventh` (5) | `myth_erase_seal` | 削籍·失名印 | ring | 44 | `{atk:30,crit:0.06}` | `uni_guard` | 护盾破裂随机 1 件装备失效 2 回合 |
| `first_wellspring` (6) | `myth_ink_cup` | 初墨·涌源杯 | amulet | 52 | `{hp:200,crit:0.05}` | `heal_light` | 治疗前先自损 8% 当前生命 |
| `vaerith_no1` (7) | `myth_dragon_brand` | 初录·缚龙牌 | amulet | 54 | `{hp:210,crit:0.06}` | `sunder_strike` | 加成仅对龙裔 family 生效 |
| `chancellor_maerus` (8) | `myth_seal_ring` | 掌玺·执印玺 | ring | 57 | `{atk:34,crit:0.06}` | `uni_strike` | 处决仅对残血小怪、25% 看脸 |
| `the_first_edict` (9) | `myth_name_wheel` | 初敕·名轮 | head | 60 | `{hp:220,def:32}` | `aura_cast` | 自身永不被治疗，只能靠吸血/护盾 |

> 注：暴击字段已统一为全局 `crit`（0–1 小数，如 `crit:0.06` = 6% 暴击率），与 `dealDamage` 读取口径一致（BUG-2 修复：原 `critPct` 整数百分点写法作废，本期 6 件带暴击的未录已全部改写为 `crit`）。`weapon` 类 base 为**叠加在武器自身 `WEAPON_TYPES.baseAtk` 之上的裸加值**（与 `genBossUnique` 当前行为一致，不乘 `baseMult`）。

**每件独特属性（机制级，扩充描述）**

1. **锈冠·褪印**（head / `boundary_wrath`）：「初敕余响」——装备即常驻 1 级「界桩之怒」（无需学）。释放时**不再消耗冷却回合，改为消耗当前 15% 最大生命**；施放后本场下一次攻击**无视防御且必定暴击**。
2. **三指·脱籍戒**（ring / `blackmarket_toxin`）：「黑市豁免」——「黑市毒刃」变为**可叠层**（每次命中 +1 层，上限 5），中毒伤害**不再随目标等级衰减**；叠满 5 层时目标攻击力 -15%。
3. **缄口·逆咏牌符**（amulet / `silent_hymn`）：「缄默反唱」——「无声圣咏」伤害**等量转化为护盾而非治疗**；若你本回合未受击，护盾于下回合初炸裂为对全场敌人的真实伤害（上限为你最大生命的 30%）。
4. **熔印·锻律锤**（weapon / `berserk`）：「锻入」——「狂暴」结束后**不进冷却，改为永久 +1 力量上限（整局，上限 30）**；狂暴期间自身受伤 +30%。
5. **掌典·禁页杖**（weapon / `chain_lightning`）：「归档闪击」——「闪电链」命中后将目标标为「已归档」3 回合：期间其受伤 +25%，且**死亡时必定掉一件随机装备（"档案"）**。
6. **削籍·失名印**（ring / `uni_guard`）：「失名庇护」——「通用·守护」护盾量 ×2，且**装备直接无视等级需求（实装为背包 `canEquip` 无条件放行，不再依赖护盾；原 GDD 设计为"护盾存在期间视为满足"，是否收紧为"仅可跨 ≤1 tier"待 team-lead 拍板）**；护盾破裂时随机一件已装备装备暂时失效 2 回合。
7. **初墨·涌源杯**（amulet / `heal_light`）：「以墨续命」——「圣光术」改为**消耗 8% 当前最大生命，换取立即回复 35% 最大生命并净化全部负面状态**；本场首次触发额外写「初墨印记」，使本场所有治疗 +50%。
8. **初录·缚龙牌**（amulet / `sunder_strike`）：「编号权柄」——对**龙裔 family 敌人**伤害 +40%，「破甲击」对其必定触发易伤（无视 20% 上限）；每击杀一条龙裔**永久 +2 最大生命（整局，上限 500）**。
9. **掌玺·执印玺**（ring / `uni_strike`）：「盖章即律」——「通用·重击」命中后 25% 概率判定「已批准」——**直接处决当前生命 <15% 的非 BOSS 敌人**；对 BOSS 则该次伤害 ×2。
10. **初敕·名轮**（head / `aura_cast`）：「万物之名」——被动：你造成伤害时按**敌人当前生命百分比额外造成等量真名伤害**（残血越狠越疼，对 BOSS 同样生效，上限单次攻击 50%）；**你自身永不被任何手段治疗**（含圣光术/急救），只能靠吸血与护盾维生。

**背景故事（20–40 字，钩子味）**

| 装备 | 背景 |
|---|---|
| 锈冠·褪印 | 第一根界桩倒下时，它把没登记完的自己长在了鹿角上。 |
| 三指·脱籍戒 | 奥兹数过三指，把第四指留给永远付不起的账。 |
| 缄口·逆咏牌符 | 她咽下的圣咏，本该是唱给被除名之人的安魂曲。 |
| 熔印·锻律锤 | 把活人按进兵器的手艺，他最后用在了自己身上。 |
| 掌典·禁页杖 | 他给每道禁咒建了档，连死都得走归档流程。 |
| 削籍·失名印 | 第七位国王被划去名字后，连铠甲都认不出他。 |
| 初墨·涌源杯 | 坑底那东西的体液，既能写字，也能把人写活。 |
| 初录·缚龙牌 | 编号〇〇一不是名字，是它被拴住时盖的第一个章。 |
| 掌玺·执印玺 | 他盖下的不是印，是判决；名字落下就成了句号。 |
| 初敕·名轮 | 它念出一个名字，对应的存在便在场上显形——包括你。 |

### 9.6 工程落地清单

**① `RARITY` 追加**（见 §9.1 代码块）。

**② `BOSS_DROPS` 扩展** —— 旧 3 王加 `mythic` 字段，新 7 王加 `mythic`（并补 `book` 见 ③）：

```js
// 旧 3 王：保留原 equip(敕造)，新增 mythic(未录)
BOSS_DROPS.rust_stag.mythic       = {slot:'head',   name:'锈冠·褪印',     reqLv:10, base:{hp:160,def:30},   skill:'boundary_wrath',  desc:'初敕余响：释放不耗CD，改耗15%当前最大生命；施放后下次攻击无视防御且必暴', cost:'每次释放自损生命'};
BOSS_DROPS.oz_threefinger.mythic  = {slot:'ring',   name:'三指·脱籍戒',   reqLv:18, base:{atk:32,crit:0.06}, skill:'blackmarket_toxin',desc:'黑市毒刃可叠层(上限5)且中毒不衰减；满层目标攻击-15%',     cost:'击杀非BOSS不再掉金币'};
BOSS_DROPS.edna_silent.mythic     = {slot:'amulet', name:'缄口·逆咏牌符', reqLv:26, base:{hp:190,crit:0.05}, skill:'silent_hymn',     desc:'无声圣咏伤害转护盾；未受击则下回合炸为全场真伤(上限30%最大生命)', cost:'不再回血'};
// 新 7 王：仅 mythic(未录)
BOSS_DROPS.varuk.mythic           = {slot:'weapon', wType:'warhammer', name:'熔印·锻律锤', reqLv:28, base:{atk:48}, skill:'berserk',          desc:'狂暴结束不进CD，改为永久+1力量上限(整局，上限30)；狂暴期受伤+30%', cost:'狂暴期更脆'};
BOSS_DROPS.sevlan.mythic          = {slot:'weapon', wType:'staff',      name:'掌典·禁页杖', reqLv:36, base:{atk:30}, skill:'chain_lightning', desc:'闪电链命中标\"已归档\"3回合：受伤+25%且死亡必掉1件随机装备', cost:'被标记者仇恨转向你'};
BOSS_DROPS.null_seventh.mythic    = {slot:'ring',   name:'削籍·失名印',   reqLv:44, base:{atk:30,crit:0.06}, skill:'uni_guard',        desc:'守护盾量×2；盾存在期间越级穿装；盾破随机1件装备失效2回合', cost:'盾破即裸奔'};
BOSS_DROPS.first_wellspring.mythic = {slot:'amulet', name:'初墨·涌源杯',   reqLv:52, base:{hp:200,crit:0.05}, skill:'heal_light',       desc:'圣光术改耗8%当前生命换回35%最大生命+净化；首触写初墨印记使本场治疗+50%', cost:'治疗先自损生命'};
BOSS_DROPS.vaerith_no1.mythic     = {slot:'amulet', name:'初录·缚龙牌',   reqLv:54, base:{hp:210,crit:0.06}, skill:'sunder_strike',    desc:'对龙裔伤害+40%；破甲击对其必触发易伤；每杀龙裔永久+2最大生命(整局，上限500)', cost:'仅对龙裔生效'};
BOSS_DROPS.chancellor_maerus.mythic={slot:'ring',   name:'掌玺·执印玺',   reqLv:57, base:{atk:34,crit:0.06}, skill:'uni_strike',       desc:'重击命中25%判\"已批准\"：处决生命<15%非BOSS；对BOSS该次伤害×2', cost:'处决看脸'};
BOSS_DROPS.the_first_edict.mythic = {slot:'head',   name:'初敕·名轮',     reqLv:60, base:{hp:220,def:32},   skill:'aura_cast',       desc:'造成伤害按敌人当前生命%追加等量真名伤害(对BOSS生效,上限50%)；自身永不被治疗', cost:'失去治疗'};
```

**③ tier3–9 七个新 Boss 的 `book` 条目**：现有 3 王各有 `book`（BOSS 禁咒），新 7 王**应对称补 `book`**（各自 1 本 BOSS 专属技能书）以保持掉落结构一致。7 本新 BOSS 技能的设计**不在本任务范围**，列为后续任务（需扩 GDD 03 §5.4）。本期 `mythic` 的 `skill` 已改为绑定**既有通用/属性技能**，故即使 `book` 暂缺，未录装备仍可独立生效。

**④ 掉落裁决（替换原"书 5% / 敕造 3%"逻辑）** —— 单次 Boss 击杀至多 1 件特殊掉落，优先级：

```
function rollBossLoot(bossKey){
  const d = BOSS_DROPS[bossKey]; if(!d) return normalLoot(bossKey);
  // 1) 红色未录（最稀有，已拥有则跳过）
  if(d.mythic && !G.ownedMythic.has(bossKey)){
    if(++G.bossKillStreak[bossKey] >= 20 || Math.random() < 0.05){
      G.bossKillStreak[bossKey]=0; return genMythic(bossKey);   // 标记 owned
    }
  }
  // 2) 技能书 5%
  if(d.book && Math.random() < 0.05) return genSkillBook(d.book);
  // 3) 橙色敕造唯一（仅旧 3 王有 equip）
  if(d.equip && Math.random() < 0.03) return genBossUnique(bossKey);
  // 4) 常规缩放战利品
  return normalLoot(bossKey);
}
```

**⑤ 渲染**：未录沿用敕造的稀有度边框材质，仅换色为 `#e6443b`；`mythic.desc` / `mythic.cost` 在装备 inspect 面板以红字呈现（cost 标"代价"）。

### 9.7 风险与待验证（R 编号续 §7）

| # | 风险 | 等级 | 调整方向 |
|---|---|---|---|
| **R8** | 「万物之名」自损治疗 + 斩杀，可能与高难 Boss 形成**唯一最优解**（主导策略红线） | 🔴 高 | 给真名伤害加**每场战斗触发次数上限**或**对 BOSS 倍率再砍半**；实测后定 |
| R9 | "失名庇护"越级穿装可能让玩家**提前穿满 red**，破坏 tier 进度感 | 🟠 中高 | 实装为**无条件忽略 reqLv**（`canEquip` 直接放行，无护盾门槛），低等级玩家可提前穿满 red；建议收紧为**仅跨 ≤1 tier**（保留"破格"幻想且不崩等级曲线），最终口径待 team-lead 拍板 |
| R10 | 未录 `skill` 绑定既有技能，若今后调整该技能数值会**连带改动未录体验** | 🟡 中 | mythic 改写逻辑独立于技能本体，改技能时同步回归本表 10 条 |
| R11 | 套装式联动未做，放置玩家可能觉得"红装之间无配合" | 🟢 低 | 若反馈弱，再开 `setMythic` 扩展（同 Boss 红装 + 其 `book` = 第二效果） |
| **R12** | 🔴 tier3–9 七王的 `book`（Boss 禁咒）尚未设计，掉落结构不对称 | 🔴 中 | 列为独立后续任务，扩 GDD 03 §5.4；不影响本任务 `mythic` 落地 |
| R13 | 保底 20 杀与"已拥有即停掉"叠加：若玩家在拿到前就刷满 20 杀，保底件直接进背包 | 🟢 低 | 保底仅在"尚未拥有"分支内计数，已拥有不触发，逻辑自洽 |

### 9.8 验收标准（续 §8，编号 C）

| # | 标准 | 验证方式 |
|---|---|---|
| C1 | `RARITY` 共 6 项，末项 `key:'unrecorded'`、`mult` 2.6、`affixes` 5 | 查表 |
| C2 | 10 件未录的 `key` 全局唯一且与 27 怪 / 现有装备 key 不撞 | Set 比对 |
| C3 | 每件未录 `mythic.skill` ∈ `SKILLS` keys | 查表 |
| C4 | 每件未录 `base` 为裸数、量级与现有 BOSS_DROPS（如 `{hp:150,def:24}`）同档 | 区间比对 |
| C5 | `G.ownedMythic` 含某 Boss 后，该 Boss 不再掉其未录 | 控制台模拟 30 杀 |
| C6 | 未拥有时单杀掉率 ≈5%，连续 20 杀必出（保底） | 蒙特卡洛 1e4 次 |
| C7 | 装备未录后，绑定技能自动 +1 级且 `mythic.desc` 机制在战斗中生效 | 逐件装备实测 |
| C8 | 未录不可重铸、`rarityName` 不进入物品名（A13 守卫仍成立） | 查 `equipBaseName` 输出 |
| C9 | 旧 3 王仍掉橙色敕造（不回归 A9） | 控制台强制掉落 |

---

*GDD 04b 结束 · 10 图 / 100 怪 / 10 家族 / 0 新增 art 枚举 / 1 新增稀有度档（未录）*
