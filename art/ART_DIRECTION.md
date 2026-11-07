# 《假面低语》美术方向

## 项目定位

- 类型：单人、离线、卡牌驱动、轻度牌阵战斗。
- 世界观：原创的《诡秘之主》同人支线，不直接复述原作剧情。
- 使用范围：仅本地私人游玩，不公开分发。
- 核心体验：白天扮演身份，夜晚使用封印力量；力量越强，污染和被注视的压力越高。

## 视觉承诺

画面不是传统奇幻卡牌，而是一册被反复翻阅的私人神秘学档案：

- 十九世纪铜版画和旧报纸的印刷质感。
- 黑色墨迹、泛黄纸张、哑光暗金和少量干涸血红色。
- 人物以剪影、胸像和局部特写为主，脸部细节保持克制。
- 卡面中央是“被封印的证物”，边框与文字由游戏界面绘制。
- 危险效果使用裂纹、套印错位、墨污和不合常理的第二双眼睛表达。

## 色板

| 用途 | 色值 | 说明 |
|---|---|---|
| 旧纸主色 | `#D8C29A` | 卡面与档案底色 |
| 深纸色 | `#AF9165` | 折叠、污渍和次级背景 |
| 墨黑 | `#211D18` | 主体文字与铜版线条 |
| 炭灰 | `#3A3731` | 次级信息、雾和建筑 |
| 暗金 | `#B99750` | 卡框、身份标识、关键装饰 |
| 干血红 | `#7A2828` | 污染、危险、攻击 |
| 冷雾灰 | `#788079` | 灵界、恐惧和异常实体 |
| 骨白 | `#E8DFC9` | 高光与小型标签 |

同一张图最多使用两个强调色。暗金负责秩序与身份，暗红负责危险与禁忌。

## 资产规格

| 类型 | 画布 | 格式 | 使用方式 |
|---|---:|---|---|
| 卡牌完整样张 | 600 x 840 | SVG + PNG | 视觉验收，不直接替代游戏内 UI |
| 卡面插画安全区 | 512 x 400 | 独立图层 | 卡框内裁切使用 |
| 敌人半身像 | 900 x 900 | SVG + PNG | 战斗界面、图鉴 |
| 标题画面 | 1600 x 900 | SVG + PNG | 16:9 启动画面 |
| 仪式场景 | 1600 x 900 | SVG + PNG | 晋升试炼背景 |
| 状态图标 | 64 x 64 | SVG | 程序着色与状态栏 |
| 卡牌边框 | 600 x 840 | SVG | 透明叠加与九宫格改造 |

卡牌内容安全区：左右各留 44 px，顶部标题区约 164 px，底部信息区约 236 px。正式卡面插画不要包含中文文字，文字全部由 Godot 渲染。

## 版式层级

1. 顶部：卡牌类型、稀有度与编号。
2. 中部：唯一的视觉焦点，禁止同时出现多个同等重量的人物或物体。
3. 下方：一句氛围文本、能力说明与 2-3 个短数值。
4. 边框：双层细线、四角折饰和小菱形。禁止厚重发光描边。
5. 稀有度不依赖彩虹色，使用金属线复杂度、印章和纸张破损程度区分。

## 正式插画提示词模板

以下模板遵循 imagegen 技能的 `stylized-concept` 资产类型。生成插画时不要加入文字、水印或现有作品角色。

```text
Use case: stylized-concept
Asset type: collectible card portrait for an offline gothic occult card game
Primary request: <single original subject>
Scene/backdrop: aged archive paper, restrained Victorian occult atmosphere
Subject: <silhouette, bust framing, one clear symbolic prop>
Style/medium: original 19th-century copperplate engraving mixed with restrained ink wash
Composition/framing: centered bust or symbolic still life, strong central silhouette, generous safe margins
Lighting/mood: dim gaslight from one side, tense and secretive
Color palette: parchment #D8C29A, ink #211D18, muted gold #B99750, single dried-blood red accent #7A2828
Materials/textures: fine crosshatching, letterpress ink, paper grain, subtle foxing
Constraints: original depiction only; no text; no logos; no watermark; no frame; subject fully inside the safe area
Avoid: modern digital glow, glossy 3D, anime rendering, ornate fantasy armor, excessive particles
```

### 三种主要构图

- 人格牌：肩部以上的匿名胸像，服饰职业特征明显，面部一半隐入阴影。
- 封印物：单件物品居中，占画面 55%-70%，用印章、链条或几何封印限制其轮廓。
- 灵界回响：抽象生物或记忆残片，可以没有完整人形，保留一处可识别的眼睛、手或门。

## 卡框与游戏内 UI

当前 `assets/svg/templates/card-frame.svg` 是完整验收样张的基础。进入 Godot 后建议拆成：

- `paper_base.png`：纸张底色与污渍。
- `frame_normal.svg`：常规卡框。
- `frame_rare.svg`：较复杂的金属线与印章。
- `title_plate.png`：标题底纹。
- `effect_panel.png`：说明区域底纹。

卡牌名称、费用、数值、描述和状态文字不在图片内烘焙。这样替换插画、调整平衡数值和本地化时都不需要重新做图。

## 动效最低标准

- 抽牌：纸片从画面下缘升起，轻微旋转后停住。
- 打出：卡面沿折线飞出，纸张短暂发白，墨线留下 0.15 秒残影。
- 污染：屏幕边缘出现暗红套印错位，第二次印刷轮廓向侧方偏移。
- 被注视：画面短暂降低饱和度，角落出现第二个镜头裁切。
- 晋升：卡框向内折叠，露出新的金属印章。

不需要逐帧角色动画，也不使用大面积粒子。

## 生产顺序

1. 锁定色板和 600 x 840 卡框。
2. 完成 3 张人格牌、2 张封印物牌和 1 个敌人作为风格锚点。
3. 用同一提示词模板生成 8-12 张普通卡，随机替换主体但保持构图规则。
4. 制作状态图标与卡牌背面。
5. 最后补标题画面、晋升仪式和首领。

## 版权与来源

本项目仅供本地私人使用。正式 AI 插画可以使用生成的原创内容；公版铜版画和纹理必须记录来源与授权。不要将官方小说插画、官方封面或来源不明图片作为最终美术资产。

