### 7.2 ★ 直接回答：`humanoid` 与 `arcane construct` 的覆盖情况（对齐 GDD 04 §3.3 / §4.2）

**结论：v1.1 曾误补 `humanoid_civil` + `arcane_weave` 两个 body，现依据 GDD 04 §4.2「10 类 `body` 硬枚举、禁止新增未列枚举」撤回。5 大家族已按 body 映射完成，人型与秘术造物均在枚举内，无需新 body。**

| 家族 | GDD 绑定 `body` | v1.1 误判 | 修正 |
|---|---|---|---|
| **人型**（脱牌者打手 / 私法者打手 / 妖化人形） | `imp`（人形小妖） | 误以为需 `humanoid_civil` 才能“穿衣服” | ✅ 用 `imp` 基体 + `feature`（wings / horns / crystals）区分个体剪影 |
| **秘术造物**（世界树残骸 / 奥术植物） | `treant`（树形） | 误以为需 `arcane_weave` 悬浮碎片 | ✅ 用 `treant` 基体 + `feature`（vines）+ `aura`（BOSS）表达 |

> ⚠️ **撤回理由**：GDD 04 §4.2 是「美术出图硬约束」（§7 横向依赖、E6「新游戏只保留上表 10 类；旧枚举映射或报错」）。`humanoid_civil` / `arcane_weave` 不在枚举内，渲染会触发 E6 报错。人型敌人“与守夜人最大的差异”已由「人型家族的存在」本身满足（守夜人几乎无人形敌），无需另开 body。

#### 人型剪影差异由 `imp` + `feature` 槽承担（GDD §5.1 实证）

| GDD 怪物 | `body` + `feature` | 剪影差异 |
|---|---|---|
| `deadcrow` 枯爪渡鸦 | `imp` + `wings` | 双翼小妖 |
| `bliz_crow` 暴雪渡鸦 | `imp` + `wings` | 双翼小妖（冷色变体） |
| `ice_crawler` 冰蛛 | `imp` + `crystals` | 结晶附体小妖 |
| `shade_imp` 暗影小鬼 | `imp` + `horns` | 独角小妖 |

✅ 四种特征在 `imp` 基体上产生可辨识剪影差（翼 / 角 / 结晶），验收通过。若后续确需更强的职业区分（如“穿袍术士 vs 持械打手”），走 GDD `family` 行为层 + `feature` 组合，不另开 body。

### 7.3 `MON_BODIES` 全表（10 种 · 严格对齐 GDD 04 §4.2）

| # | Key | 中文（GDD 命名） | 家族 | 剪影要点 |
|---|---|---|---|---|
| 1 | `beast` | 四足兽 | 污染兽 | 侧身四足，低头，背脊隆起 |
| 2 | `spore` | 孢菌 | 污染兽 | 圆团 + 孢子囊，无肢 |
| 3 | `husk` | 壳/刺猬类 | 污染兽 | 硬壳球，尖刺外扩 |
| 4 | `serpent` | 蛇 | 污染兽 | S 形躯干，无肢，扁头 |
| 5 | `imp` | 人形小妖 | **人型** | 直立小妖，大头尖耳，四肢 |
| 6 | `wraith` | 怨灵 | 亡灵圣械 | 无腿飘散下摆，兜帽空洞 |
| 7 | `revenant` | 回响亡魂 | 亡灵圣械 | 直立残躯，破碎甲片 |
| 8 | `golem` | 魔像 | 构装体 | 几何块拼接，胸口核心，着地 |
| 9 | `crystal` | 晶体 | 构装体 | 多面体晶体簇，微浮 |
| 10 | `treant` | 树形 | **秘术造物** | 树干躯干，枝冠，根足 |

**迁移成本**：10 body 全部沿用骨架 `MON_BODIES`（仅按 GDD §4.2 重命名主题），`monsterSVG(def, px)` 函数签名与调用方式**完全不变**。五家族 → body 映射见 GDD §3.3。

### 7.4 `MON_FEATURES`（GDD §5.1 实证特征集）

| 组 | Key | 中文 | 出处（GDD §5.1） |
|---|---|---|---|
| **点缀**（6 + none） | `none` `vines` `wings` `crystals` `horns` `halo` `blight` | 无 / 藤蔓 / 翼 / 结晶 / 角 / 神环 / 疫斑 | `treant`=vines、`imp`=wings/crystals/horns、`wraith`=halo、`beast`=blight |
| **BOSS 可选** | `crown` `antlers` | 王冠 / 鹿角 | 增强首领辨识，仍属 feature 不新增 body |

⚠️ 特征集锚定 GDD §5.1 已填值；若要新增点缀特征，须先入 GDD `art.feature` 池（不构成 body 枚举变更）。**已删除 v1.1 的 `garb_*` 装束组**——人型职业差异改由 `imp` + 上述特征表达。

### 7.5 五族群 × 地图映射（对齐 GDD §3.3 / §5.1）

| 家族 | 绑定 `body` | MVP 分布地图（§5.1） |
|---|---|---|
| 污染兽 | `beast` `spore` `husk` `serpent` | 三图均有（kuyi / thornling / snow_husk / void_husk …） |
| **人型** | `imp` | 界桩荒野(deadcrow) / 黑印集市(ice_crawler, bliz_crow) / 缄默修道院(shade_imp) |
| 亡灵圣械 | `wraith` `revenant` | 界桩荒野(mud_wisp, rot_mother) / 黑印集市(frost_wisp, winter_god) / 缄默修道院(abyss_wraith, void_revenant) |
| 构装体 | `golem` `crystal` | 黑印集市(frost_golem, frost_titan) / 缄默修道院(ruin_golem) |
| **秘术造物** | `treant` | 界桩荒野(grove_warden, corrupted_root, tree_heart) |

> ⚠️ 地图与家族**非 1:1**（GDD §5.1 实为跨图混编）。美术按 `family→body` 出图即可，不必为每图锁定单一 body。

### 7.6 组合矩阵示例（取自 GDD §5.1 真实 27 只 MVP，色值直接复用）

| GDD 怪物 | 地图 | body | feature | c1 | c2 | eye |
|---|---|---|---|---|---|---|
| `kuyi` 癞斑猎犬 | 界桩荒野 | `beast` | `blight` | #7a8a55 | #45512e | #d6ff6a |
| `thornling` 荆棘幼体 | 界桩荒野 | `husk` | `vines` | #6b6f3a | #3c3f1f | #c9ff5a |
| `deadcrow` 枯爪渡鸦 | 界桩荒野 | `imp` | `wings` | #4a4a55 | #22222b | #ff6a6a |
| `grove_warden` 界桩守望（精英） | 界桩荒野 | `treant` | `vines` | #6f8a4a | #3e5230 | #ffe070 |
| `rot_mother` 林朽母（BOSS） | 界桩荒野 | `wraith` | `vines` | #5f7d3a | #2f3f1f | #ff5a4a |
| `ice_crawler` 冰蛛 | 黑印集市 | `imp` | `crystals` | #b8d4e6 | #5a7e96 | #dff6ff |
| `bliz_crow` 暴雪渡鸦 | 黑印集市 | `imp` | `wings` | #6a7a90 | #2a3645 | #ff8a8a |
| `frost_golem` 私铸魔像 | 黑印集市 | `golem` | `crystals` | #b0c8d8 | #4a6478 | #cfefff |
| `shade_imp` 暗影小鬼 | 缄默修道院 | `imp` | `horns` | #6a4a8a | #2f1f4a | #ff7aff |
| `winter_god` 黑市之主（BOSS） | 缄默修道院 | `wraith` | `halo` | #9fd0ec | #2f5f86 | #ff7a5a |
| `void_revenant` 虚空回响（BOSS） | 缄默修道院 | `revenant` | `halo` | #7a5ac0 | #2f1f5a | #ff5aff |
| `tree_heart` 世界树枯心（精英） | 缄默修道院 | `treant` | `vines` | #8a6aae | #3f2f56 | #ff7aff |

✅ 上述 `c1/c2/eye` 全部取自 GDD §5.1（守夜人原值、按地图冷色系分好），**直接复用，不另取值**。色值已在冷石战场 `#171a20`/`#2b313d` 上校过（亮眼色作发光，中调 c1/c2 作填充，均满足 ≥3:1 图形识别）。

### 7.7 组合空间估算（10 body 版）

| 层级 | 计算 | 数量 |
|---|---|---|
| 单特征剪影 | 10 body × 7 feature | 70 |
| 双特征（若未来开放第二槽） | 10 body × C(7,2)=21 | 210 |
| 剪影总量 | — | **70**（保守）～ **280**（含双槽） |
| 再乘预设配色（按地图冷色系）× `scale`(3) × `flip`(2) | — | **≥ 400 视觉变体** |

**需求侧**：GDD §5.1 三图 **27 只** MVP（含 3 BOSS + 3 精英）。
✅ **70+ 独立形象对 27 只需求，余量充足**；且允许“同 body 换 `eye` 色”做元素变种，成本为零。

### 7.8 技术美术预算

| 项 | 预算 |
|---|---|
| 单 body 函数 SVG 元素数 | ≤ 12（10 body 统一预算，无例外） |
| 单 feature 函数元素数 | ≤ 5 |
| 单怪物同屏渲染节点 | ≤ 20 |
| 战斗区同屏怪物 | ≤ 5（即 ≤100 节点） |
| 特征溢出 viewBox | 允许，⚠️ 必须显式 `overflow="visible"` |
