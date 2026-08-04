# 交接文档：敕造纪元·持牌者（美术 / 代码管线）

> **这是给"另一个你"（接手本项目的 AI 实例）的完整上下文。读完你就能完全接手，且不会破坏现有成果。**
> 生成时间：2026-08-04。最新线上 commit：`a99aebd`。

---

## 一、你现在的角色与铁律（违反会让游戏跑不起来）

你是接手网页游戏《敕造纪元·持牌者》开发的 AI 助手。前一位 AI（与你同源）已完成大量工作。**你的第一条原则是"不破坏"。**

**绝对铁律：**

1. **任何改动先给方案 → 等用户确认 → 再动手。** 不要自作主张删文件、删代码、大改结构。
2. **绝对不要删除任何代码或资源文件**，除非用户明确说"删"。
   - 历史惨痛教训：曾因"图片对不上号"把所有美术图删光，导致游戏无立绘；曾误删本地 `assets/origins`、`assets/player` 导致职业立绘丢失。删东西前先确认：仓库里是否还有、是否影响运行、用户是否真的要删。
3. **美术图文件名必须严格等于游戏内 `key`**：`assets/monsters/{key}.png`。命名错一个字符，图鉴/战斗就加载不到，回落到程序化 SVG（不是破图，但没立绘）。
4. **图片不要重新生成（除非用户要求）**。去实底用本地 `rembg` 抠图，零 ImageGen 额度。
5. **绝不在 push 前跳过 pre-push 美术校验钩子。**

---

## 二、项目事实（先认清楚环境）

- **游戏**：纯静态单文件 HTML 网页游戏《敕造纪元·持牌者》，POE 风格词缀系统。
- **主文件**：`C:\Users\Biostar\OneDrive\edict-era\index.html`（约 6000+ 行；所有逻辑、样式、数据都在这一个文件里）。**不要拆分它、不要整体重写它。**
- **部署**：GitHub Pages，仓库 `dsadsad636/edict-era`，线上 `https://dsadsad636.github.io/edict-era/`。
  - 推送用 **SSH**（`git@github.com:dsadsad636/edict-era.git`）。HTTPS 被墙，不可用。
  - 推送命令：`git push origin main`。
- **美术暂存与管线目录**：`C:\Users\Biostar\OneDrive\edict-art\`，含 `artlib.py` / `gen_monster_art.py` / `verify_art.py` / `STYLE_GUIDE.md`。**该目录不进游戏仓库、不进部署**，只是本地生成工具。
- **注意路径**：OneDrive 路径在两台电脑可能不同（另一台若是本地磁盘而非 OneDrive，注意路径映射）。游戏仓库用相对路径引用资源，clone 后结构一致即可。

---

## 三、美术数据机制（关键，别改坏）

- 怪物定义在 `MONSTERS` 对象，每只怪有 `key` + `art` 字段（`body` / `feature` / `c1` / `c2` / `eye`）。
- **注入循环**（约 2825 行）自动推导：
  ```js
  Object.keys(MONSTERS).forEach(function(k){
    MONSTERS[k].key = k;
    if(!MONSTERS[k].img) MONSTERS[k].img = 'assets/monsters/'+k+'.png';
  });
  ```
  共 **101 只怪**，img 全部按 key 自动推导。
- **渲染函数 `monsterSVG(def, px)`**：优先用 `def.img`（PNG 立绘）；加载失败走 `onerror` 回落程序化 SVG（`monsterSVGFallback`）。**这是兜底机制，绝对不要删。** 没有 PNG 也不会崩，只是显示程序化图形。
- **职业立绘**：`o.img` → `assets/origins/{warrior,mage,tank,healer,assassin}.png`；玩家立绘 `assets/player/player.png`。
- **图鉴页** `tabBestiary` 用 `monsterSVG(def,56)` 渲染立绘；**战斗**用 `monsterSVG(e,72)` 渲染敌人、用 `assets/player/player.png` 渲染玩家。
- **选职业界面是手风琴**（不是常显）：
  ```css
  .origin-row .or-body{display:none;}            /* 默认收缩 */
  .origin-row.sel .or-body{display:block;}       /* 选中才展开立绘 */
  ```
  默认全收缩，点哪个职业、哪个展开显示立绘，其余收缩。

---

## 四、已完成的修改（commit 历史，全部已推 main）

| commit | 内容 |
|---|---|
| `aa56b38` | 修复"二次创建角色不弹窗"（createConfirmMask 加 `z-index:300`，盖过 #authGate 的 200） |
| `597c365` / `24980ad` | 删除旧 27 张错位图；用零错位管线生成图1 十张怪物图 |
| `f80938f` | 恢复 `assets/origins` + `assets/player` 六张职业/玩家图（`git checkout`）；图鉴接入 `monsterSVG` |
| `4982b70` | 选职业界面显示职业立绘（**已被 `66672f1` 撤销回手风琴**） |
| `30b77fe` | 全 16 张图压缩 21.5MB→1.4MB（Pillow 缩到 ≤384px + 量化）；战斗/角色面板接入 `player.png` |
| `66672f1` | 恢复手风琴：`.or-body` 改回 `display:none` |
| `a99aebd` | 图1 十张怪图本地 `rembg` 去实底（透明 PNG，零额度） |

---

## 五、当前线上状态（2026-08-04，commit `a99aebd`）

- 本地 = 远端 `main` = `a99aebd`，工作树干净。
- **图1（map 1）10 只怪有透明立绘**；其余 90 只怪仍回落程序化 SVG（不是破图）。
- 职业立绘（5 张）+ 玩家（1 张）为仓库旧版实底图，已接入显示。
- 选职业为手风琴式。

---

## 六、零错位美术管线（新增图时必须用，避免"对不上号"）

三层防护：内容层（提示词自数据派生，无转写）→ 文件名层（脚本强制 key 命名 + 校验拦拼错）→ 接收层（外部图必须带 key 才收）。

- **提示词派生**：`artlib.py` 解析 `index.html` 的怪数据，逐字生成提示词；地图基调锁在 `STYLE_GUIDE.md`（图1=墨绿魔素；图3修道院/图8龙冢/图10之座=sacred 圣光；其余 grim）。精英加大加厚甲+微弱威压不发光；BOSS 必带地图属性色光效。
- **生成脚本**：`gen_monster_art.py --map N --dry-run` 先预览提示词再烧额度。
- **必须串行生成**，即时 `mv` 成 `{key}.png`。⚠️ 曾因并行生成，后端秒级时间戳+同前缀导致文件名冲突，10 张全覆盖成 1 张。
- **校验**：`verify_art.py` 扫描 `assets/monsters/` 与 key 比对，抓孤儿文件（大小写/连字符/拼错），exit 1 拦部署。
- **pre-push 钩子**：`.git/hooks/pre-push` 推送前自动跑 `verify_art.py`，0 孤儿才放行。

---

## 七、去实底方法（rembg，零额度，不要重生成图）

- 怪图背景是 AI 渲染出的场景底（**非纯色**）。Pillow 色键会留一圈底色、还会啃到怪身，必须用 ML 抠图（`rembg`）。
- managed Python 3.13 装 `rembg` 踩坑：`pip install rembg` 直接装会 `ResolutionImpossible`（依赖锁死）。正确做法：
  ```
  pip install --no-deps rembg
  pip install numpy scipy scikit-image imageio filetype pooch tqdm jsonschema pymatting onnxruntime
  ```
- 首次运行下载 `u2net` 模型 ~176MB（断点续传，网慢但能成，缓存于 `~/.u2net/`）。模型已缓存，后续 90 只怪补图后直接复用，不用再下。
- 抠图后核验：PIL 读图，`im.mode` 应为 `RGBA`，统计 alpha<10 的像素占比确认真抠掉了背景。

---

## 八、已知未决 / 待办（不要当成 bug 乱改）

1. 怪物图透明已实现（仅图1）。图2–10 共 90 只怪仍回落 SVG，待分批补图 + 去实底。
2. `fade_moth` 按数据生成为蜘蛛状（`body:arachnid`）；若想真像蛾，需改 `index.html` 的 art 字段（属数据改动，先确认）。
3. 职业/玩家 6 张为仓库旧版实底图，未用新管线重画（用户暂未要求）。
4. 词缀通俗化（矩防/铁律/索求）仍待跟进；图鉴其余 9 图的 lore 仍空白。
5. 若用户**有旧存档**，点"开始缉私"会弹"确认创建"覆盖框，要点"确认创建"才进——这是防误删档设计，不是卡死。

---

## 九、接手后第一件事（自检）

```bash
cd <仓库根>
git status            # 应为干净
git log -1 --oneline  # 应看到 a99aebd
git rev-parse origin/main  # 应与本地一致
```
确认无误后，**不要动已正常工作的代码**。用户提需求时，先复述方案、列清影响范围，等用户确认再动手。

---

## 十、不要重复踩的坑（血泪清单）

- ❌ 不要为"让立绘常显"把手风琴 `.or-body` 改成 `display:block`（会破坏手风琴，且旧图大时卡死整个选职业界面）。
- ❌ 不要并行生成图（文件名冲突覆盖成 1 张）。
- ❌ 不要删 `assets/` 下任何文件（尤其别因"对不上号"就全删重来——用零错位管线修，别删）。
- ❌ 不要在 push 前跳过 pre-push 校验（`git push --no-verify`）。
- ❌ 不要重新 AI 生图去实底（扣额度且风格漂移）；用本地 rembg。
- ❌ 不要整体重写 `index.html`；局部改动用 Edit，改完在真机/线上硬刷新验证。

---

**这份文档就是给"另一个你"的完整上下文。遵守铁律，你就不会重蹈覆辙。**
