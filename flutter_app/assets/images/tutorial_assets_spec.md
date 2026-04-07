# 教學模式素材需求清單

## 角色 — 爺爺（點心爺爺）

| 檔案名稱 | 長寬比 | 名稱 | 描述 | Prompt | 類型 | 用途 |
|----------|--------|------|------|--------|------|------|
| `avatar_grandpa.png` | 1:1 | 爺爺頭像 | 對話框左側小頭像，取代 👴 emoji | Chibi-style avatar of a warm elderly cat baker wearing a white chef hat and apron, round face, gentle smile, warm orange background, game UI icon, clean flat illustration | 頭像 (icon) | Phase 0~3 所有爺爺對話框 |
| `char_grandpa.png` | 2:3 | 爺爺立繪 | 半身立繪，用於開場敘事和對話場景 | Half-body portrait of a kindly elderly cat baker, white chef hat, flour-dusted apron, holding a wooden spoon, warm grandfatherly expression, soft bakery lighting, anime game character art style | 立繪 (character) | Phase 0 開場 / Phase 1~3 對話演出 |

## 背景 — Phase 0 開場敘事

| 檔案名稱 | 長寬比 | 名稱 | 描述 | Prompt | 類型 | 用途 |
|----------|--------|------|------|--------|------|------|
| `bg_tutorial_town.png` | 9:16 | 甜點街全景 | 第一張投影片背景，取代 🏘️ emoji + 漸層 | A charming pastel-colored dessert street with small bakeries, candy shops and ice cream parlors, cobblestone road, warm sunset glow, Studio Ghibli inspired, mobile game background, vertical composition | 背景 | Phase 0 投影片 1 |
| `bg_tutorial_night.png` | 9:16 | 月夜甜點街 | 第二張投影片背景，取代 🌙 emoji + 漸層 | Same dessert street at night, moonlit, some shop lights dimmed, mysterious purple glow from basements, slightly eerie but cute atmosphere, mobile game background, vertical composition | 背景 | Phase 0 投影片 2 |
| `bg_tutorial_letter.png` | 9:16 | 信件特寫 | 第三張投影片背景，取代 ✉️ emoji + 漸層 | Close-up of an old parchment letter on a wooden table, wax seal with a cookie stamp, warm candlelight, flour scattered, cozy bakery atmosphere, mobile game scene, vertical composition | 背景 | Phase 0 投影片 3 |

## 背景 — Phase 1 放置頁教學

| 檔案名稱 | 長寬比 | 名稱 | 描述 | Prompt | 類型 | 用途 |
|----------|--------|------|------|--------|------|------|
| `bg_tutorial_door.png` | 9:16 | 麵包店門口 | 進入商店的場景（已有 `bg_ch1_shop.png` 可考慮復用） | Entrance of an old cozy bakery, wooden door slightly ajar, warm light spilling out, "Grandpa's Bakery" sign, inviting atmosphere, mobile game background, vertical | 背景 | Phase 1 開門進店 |

## 背景 — Phase 2 過場（預留）

| 檔案名稱 | 長寬比 | 名稱 | 描述 | Prompt | 類型 | 用途 |
|----------|--------|------|------|--------|------|------|
| `bg_tutorial_basement.png` | 9:16 | 地下室入口 | 地下室階梯入口（目前 Phase 2 跳過，未來可能恢復） | Dark stone staircase leading down to a bakery basement, cobwebs, faint green glow, mysterious but not scary, cute game art style, mobile game background, vertical | 背景 | Phase 2 過場 |

## 角色 — 其他教學角色

| 檔案名稱 | 長寬比 | 名稱 | 描述 | Prompt | 類型 | 用途 |
|----------|--------|------|------|--------|------|------|
| `avatar_kitten.png` | 1:1 | 小貓(玩家)頭像 | 玩家角色對話頭像，取代 🐱 emoji | Chibi-style avatar of a young adventurous orange tabby kitten with bright curious eyes, small backpack, warm yellow background, game UI icon, clean flat illustration | 頭像 (icon) | Phase 2~3 小貓對話框 |
| `avatar_letter.png` | 1:1 | 信件圖示 | 信件對話頭像，取代 ✉️ emoji | Chibi-style sealed envelope with a cookie-shaped wax seal, parchment color, warm cream background, game UI icon, clean flat illustration | 頭像 (icon) | Phase 0 信件對話框 |
| `avatar_narrator.png` | 1:1 | 旁白圖示 | 旁白對話頭像，取代 📖 emoji | Chibi-style open storybook with golden sparkles, warm brown leather cover, soft cream background, game UI icon, clean flat illustration | 頭像 (icon) | Phase 0 旁白對話框 |

## 總覽

| 類別 | 數量 |
|------|------|
| 角色頭像 (avatar) | 4 |
| 角色立繪 (character) | 1 |
| 教學背景 (tutorial bg) | 5 |
| **合計** | **10** |

### 優先級

1. `avatar_grandpa.png` — 爺爺對話出現 30+ 次，影響最大
2. `char_grandpa.png` — 開場演出核心角色
3. `bg_tutorial_town.png` / `bg_tutorial_night.png` / `bg_tutorial_letter.png` — Phase 0 三張背景
4. `avatar_kitten.png` / `avatar_letter.png` / `avatar_narrator.png` — 對話框頭像
5. `bg_tutorial_door.png` / `bg_tutorial_basement.png` — 可後續製作

### 輸出位置

- 頭像 → `assets/images/output/avatars/`
- 立繪 → `assets/images/output/characters/`
- 背景 → `assets/images/output/background/`
