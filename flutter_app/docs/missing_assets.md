# 缺少素材清單

以下為目前仍使用 emoji/placeholder 或尚未上傳的素材。
已有素材均已整合至程式碼中。

---

## 一、敵人素材（仍缺 15 個獨立圖片）

目前 5 個通用怪圖片已複用到所有敵人類型，以下為建議補充的獨立敵人圖：

| # | 素材名稱 | 檔名 | 尺寸 | 目前複用 | Prompt 建議 |
|---|---------|------|------|---------|------------|
| 1 | 鼠幫老大 (Ch1 Boss) | `enemy_rat_boss.png` | 256×256px | boss_ch1 | A large cartoon rat boss, gang leader outfit, menacing, game monster style |
| 2 | 可疑店長 (Ch2 Boss) | `enemy_shop_owner.png` | 256×256px | boss_ch2 | A suspicious cartoon fox shopkeeper, cunning expression, game boss style |
| 3 | 海鷗王 (Ch3 Boss) | `enemy_seagull_boss.png` | 256×256px | boss_ch3 | A giant cartoon seagull king, golden crown, fierce, game boss style |
| 4 | 幕後金主 (Ch4 Boss) | `enemy_ceo.png` | 256×256px | boss_ch4 | A sinister cartoon fox CEO, business suit, game boss style |
| 5 | 暗影指揮官 (Ch5 Boss) | `enemy_shadow_commander.png` | 256×256px | boss_ch5 | A dark cartoon cat commander, military outfit, shadowy aura, game boss style |
| 6 | 暗影首領 (Ch6 Boss) | `enemy_final_boss.png` | 256×256px | boss_ch6 | A powerful dark lord cat, glowing eyes, ominous aura, final boss style |
| 7 | 寵物店打手 | `enemy_pet_shop_guard.png` | 256×256px | fox | A raccoon-like guard, defensive stance, game monster style |
| 8 | 捕獸陷阱 | `enemy_trap_device.png` | 256×256px | snake | A mechanical trap device, gears and springs, game monster style |
| 9 | 碼頭幫派 | `enemy_dock_worker.png` | 256×256px | fox | A tough otter dock worker, muscular, game monster style |
| 10 | 保全機器人 | `enemy_security_bot.png` | 256×256px | fox | A cartoon security robot, mechanical, game monster style |
| 11 | 雷射陷阱 | `enemy_laser_trap.png` | 256×256px | snake | A high-tech laser device, glowing beams, game monster style |
| 12 | 精英保全 | `enemy_elite_security.png` | 256×256px | fox | An armored security guard, elite gear, game monster style |
| 13 | 暗影特工 | `enemy_shadow_agent.png` | 256×256px | fox | A stealthy cat agent in dark outfit, game monster style |
| 14 | 暗影狙擊手 | `enemy_shadow_sniper.png` | 256×256px | hawk | A sniper cat with scope, crouching pose, game monster style |
| 15 | 基地守衛 | `enemy_elite_guard.png` | 256×256px | bear | A heavily armored guard, shield bearer, game monster style |
| 16 | 重裝機器人 | `enemy_heavy_bot.png` | 256×256px | bear | A large military robot, heavy armor, game monster style |

---

## 二、UI 元素（建議用 Flutter 程式碼實作，或日後補圖）

| # | 素材名稱 | 檔名 | 尺寸 | 說明 |
|---|---------|------|------|------|
| 1 | 主按鈕背景 (紫色) | `btn_primary.9.png` | 192×64px | 9-patch 按鈕 |
| 2 | 次按鈕背景 (深藍) | `btn_secondary.9.png` | 192×64px | 9-patch 按鈕 |
| 3 | 警告按鈕 (紅色) | `btn_danger.9.png` | 192×64px | 9-patch 按鈕 |
| 4 | 卡牌背景面板 | `panel_card.9.png` | 256×128px | 9-patch 面板 |
| 5 | 木紋頂欄 | `bar_wood_top.png` | 全寬×64px | 目前用 Flutter gradient |
| 6 | 木紋底欄 | `bar_wood_bottom.png` | 全寬×64px | 目前用 Flutter gradient |
| 7 | HP 血條背景 | `bar_hp_bg.png` | 128×16px | 目前用 LinearProgressIndicator |
| 8 | HP 血條填充 | `bar_hp_fill.png` | 128×16px | 目前用 LinearProgressIndicator |
| 9 | 技能能量環 | `ui_skill_ring.png` | 96×96px | 目前用 CustomPaint |
| 10 | 技能就緒光效 | `vfx_skill_ready.png` | 128×128px | 目前用 Container glow |
| 11 | 經驗值條背景 | `bar_exp_bg.png` | 256×12px | 目前用 LinearProgressIndicator |
| 12 | 經驗值條填充 | `bar_exp_fill.png` | 256×12px | 目前用 LinearProgressIndicator |
| 13 | 稀有度框 ×4 | `frame_rarity_{n/r/sr/ssr}.png` | 128×128px | 參考 Rarity_frames_and_buttons_v2.md |

---

## 三、VFX 特效（建議用 Flutter 動畫實作）

| # | 素材名稱 | 檔名 | 說明 |
|---|---------|------|------|
| 1 | 方塊消除爆破 | `vfx_block_explode.png` | 建議用 Flutter 粒子系統 |
| 2 | 連鎖波紋效果 | `vfx_chain_ripple.png` | 建議用 Flutter 動畫 |
| 3 | 勝利煙火特效 | `vfx_victory_firework.png` | 建議用 Flutter 粒子系統 |
| 4 | 升級光柱特效 | `vfx_levelup_pillar.png` | 建議用 Flutter 動畫 |
| 5 | 方塊消除粒子 ×5 | `vfx_block_particle_{color}.png` | 每色各一，或用 Flutter 實作 |

---

## 四、音效 SFX（全部缺少）

| # | 素材名稱 | 檔名 | 說明 |
|---|---------|------|------|
| 1 | 方塊消除音效 | `sfx_block_clear.ogg` | ≤1秒 |
| 2 | 連鎖消除音效 ×4 | `sfx_chain_{2/3/4/5}.ogg` | ≤1秒 ×4 |
| 3 | 方塊落下音效 | `sfx_block_drop.ogg` | ≤0.5秒 |
| 4 | 方塊移動音效 | `sfx_block_move.ogg` | ≤0.5秒 |
| 5 | 按鈕點擊音效 | `sfx_ui_tap.ogg` | ≤0.3秒 |
| 6 | 技能發動音效 | `sfx_skill_activate.ogg` | ≤2秒 |
| 7 | 攻擊命中音效 | `sfx_hit.ogg` | ≤1秒 |
| 8 | 暴擊音效 | `sfx_critical.ogg` | ≤1秒 |
| 9 | 勝利音效 | `sfx_victory.ogg` | 2-3秒 |
| 10 | 失敗音效 | `sfx_defeat.ogg` | 2-3秒 |
| 11 | 金幣獲得音效 | `sfx_coin.ogg` | ≤1秒 |
| 12 | 寶箱開啟音效 | `sfx_chest_open.ogg` | 1-2秒 |
| 13 | 升級音效 | `sfx_levelup.ogg` | 1-2秒 |
| 14 | 進化音效 | `sfx_evolve.ogg` | 2-3秒 |
| 15 | 錯誤音效 | `sfx_error.ogg` | ≤0.5秒 |
| 16 | 頁面切換音效 | `sfx_page_switch.ogg` | ≤0.5秒 |

---

## 五、背景音樂 BGM（全部缺少）

| # | 素材名稱 | 檔名 | 說明 |
|---|---------|------|------|
| 1 | 主頁面 BGM | `bgm_home.ogg` | 60-120秒 loop |
| 2 | 戰鬥 BGM (一般) | `bgm_battle.ogg` | 60-120秒 loop |
| 3 | 戰鬥 BGM (Boss) | `bgm_boss.ogg` | 60-120秒 loop |
| 4 | 商店 BGM | `bgm_shop.ogg` | 60-90秒 loop |
| 5 | 勝利結算 BGM | `bgm_victory.ogg` | 10-15秒 |
| 6 | 失敗結算 BGM | `bgm_defeat.ogg` | 5-10秒 |

---

## 六、字型（全部缺少）

| # | 素材名稱 | 檔名 | 說明 |
|---|---------|------|------|
| 1 | NotoSansTC-Regular | `NotoSansTC-Regular.ttf` | 主要 UI 文字 |
| 2 | NotoSansTC-Bold | `NotoSansTC-Bold.ttf` | 標題/強調文字 |

---

## 七、其他仍用 Emoji 的項目

| 位置 | Emoji 用途 | 建議 |
|------|-----------|------|
| 素材系統 (material.dart) | 各種素材圖標 (🔥💧🌿⚡🌑 等) | 需素材圖標素材 |
| 天賦樹分支 (talent_tree_widget.dart) | 分支 emoji (⚔🛡💊) | 可用 role icons 替代 |
| 進化素材顯示 (evolution_widget.dart) | 屬性 emoji + 素材 emoji | 屬性已替換，素材待補 |
| 技能強化 (skill_enhance_widget.dart) | 素材 emoji | 待補素材圖標 |
| 被動技能 (passive_skill_widget.dart) | 素材 emoji | 待補素材圖標 |
| 背包畫面 (backpack_screen.dart) | 素材 emoji | 待補素材圖標 |
| 商店畫面 (shop_screen.dart) | 商品圖標 (🎫💎) | 待補商品圖 |
| 每日任務 (daily_quest_screen.dart) | 任務圖標 | 待補任務圖標 |
| 方塊 widget 色盲符號 | ● ◆ ▲ ■ ★ | 已內嵌在方塊圖片中 |

---

## 素材統計

| 分類 | 已有 | 缺少 | 狀態 |
|------|------|------|------|
| 角色立繪/頭像/圖示 | 45 | 0 | ✅ 完成 |
| 方塊 (含暗化) | 10 | 0 | ✅ 完成 |
| 背景圖 | 9 | 1 (拼圖面板底圖) | ✅ 基本完成 |
| Boss | 6 | 0 | ✅ 完成 |
| 通用敵人 | 5 | 16 | ⚠️ 複用中 |
| UI 圖示 | 30 | 0 | ✅ 完成 |
| UI 元素 (按鈕/面板/進度條) | 0 | 13 | ❌ 用 Flutter 替代 |
| VFX 特效 | 8 | 5 | ⚠️ 建議 Flutter 實作 |
| 音效 SFX | 0 | 16 | ❌ 全部缺少 |
| 背景音樂 BGM | 0 | 6 | ❌ 全部缺少 |
| 字型 | 0 | 2 | ❌ 全部缺少 |
