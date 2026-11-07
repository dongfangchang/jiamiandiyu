# v0.5.0 遭遇内容

- `encounter.first_hunt`：路线首战。
- `encounter.mirror_pursuit`：镜中猎犬回声精英战。
- `encounter.mirror_baron`：镜厅男爵首领战。

三个遭遇共用既有卡牌定义；实际战斗牌组由成长层按已拥有卡牌过滤。数据层需要支持敌人/遭遇内容包引用 `base_cards_version`，避免复制卡牌事实源。
