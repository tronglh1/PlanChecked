# Vườn Nhà – MVP spec (Phase 1)

Derived reference for programmers. Generated 2026-10-19.

**Sources**
- req: `/mnt/project-files/User Requirement – App Quản lý Trồng & Chăm sóc Cây.md` (v0.1)
- FL: `/mnt/project-files/garden-app/feature-list.md` (MVP = Phase 1)
- AI doc: `/mnt/project-files/garden-app/ai-memory-va-tiet-kiem-token.md`
- plan: `/mnt/project-files/garden-app/ke-hoach-lam-app-android.md` (M0–M8)
- mockup: Design artifact `https://claude.ai/artifact/Kn8ZdLjjXvfo3iTnaD17dK` (v. 1791952697-163e, `project/canvas.json`)

**Conventions**
- Vietnamese UI strings are quoted verbatim.
- Feature IDs (ACC, PRJ, PLT, PLN, CHK, TSK, GAM, HSH, SET) are from FL.
- Mockup badge "P2" = Phase 2 (req P1). Badge "P3" = Phase 3 (req P2). No badge = MVP. See §7.
- Mockup sample data (Minh, Lan, Hùng, "Cà chua bi ban công") is dummy content.
- Items not in the sources are in §7, not invented.
- Suggested token and route names are proposals.

---

## 1. Design tokens

### 1.1 Color

| Token (proposed) | Hex / value | Used for |
|---|---|---|
| `ink` | `#16211A` | primary text, dark pill "Đang trồng", dark buttons "Vào" / "Gửi lời mời", hero card |
| `ink-2` | `#55625A` | secondary text, captions, inactive tab |
| `ink-3` | `#3B463E` | neutral chip text, option description |
| `ink-muted` | `#7D8C81` | inactive stage number |
| `ink-dark-2` / `ink-dark-3` | `#B8C4BB` / `#D2E6D8` | secondary / body text on dark screens |
| `green` | `#1E6B43` | logo tile, avatar "M", progress fill, done circles (plan), active tab, links |
| `green-deep` | `#14502F` | link hover, milestone background, chip text on green tint |
| `green-tint` | `#E3EFE6` | green chips, banners, Owner chip, household illustration |
| `green-mid` / `green-light` | `#7FB08F` / `#9FD3AE` | partial progress segment / dark-screen accent |
| `green-photo` | `#BBD8C1` | photo placeholders |
| `orange-1/2/3` | `#FF9A52` / `#F26A1B` / `#D9510A` | primary CTA gradient |
| `orange` | `#F2600F` | tab underline, Member radio ring |
| `orange-solid` | `#FF8A3D` | solid CTA, progress, medal and XP text on dark |
| `orange-tint` / `orange-tint-ink` | `#FCEBDD` / `#9A4508` | streak and XP chips, leaderboard banner (text `#4D2304`) |
| `orange-chip` / `orange-text` | `#FFE6D6` / `#A63A00` | selected option chip |
| `blue-tint` / `blue-ink` | `#E6EEFA` / `#1D4785` | "Gợi ý từ AI" chip, hint banners, "Phase 2" tags |
| `blue` | `#2457A6` | P2 tag text, avatar "H", Google "G", badge "Vươn cao" |
| `blue-tag-dark` | `#A9C4F0` | P2 tag text on dark |
| `warn-bg` / `warn-ink` / `warn-badge` | `#FFF4D6` / `#6B4200` (`#4D3000` on problem card) / `#FFE7A3` | safety banner, problem card, confidence "trung bình" badge |
| `danger` / `danger-line` | `#B42318` / `#F1C4BF` | "Xóa tài khoản…" button, "Ảnh bị mờ, thiếu sáng" label |
| `line` / `line-soft` / `line-dashed` | `#DCE3DA` / `#EEF1EC` / `#9AA89D` | progress track, dividers, empty checkbox ring, dashed add-photo |
| `toggle-off` | `#B6C1B8` | toggle off track |
| `neutral-chip` | `#F0F2EE` | neutral chip, stepper button, Member chip |
| `purple-tint` / `purple` | `#F1E8F7` / `#6A3F8F` | P3 tag |
| `avatar-L` / `avatar-H` / `badge-purple` / `badge-green-2` | `#C2570C` / `#2457A6` / `#7A4FA0` / `#3D7A3A` | avatars, badges |
| `cam-bg` / `cam-view` / `cam-chip-border` | `#0F1712` / `#26332A` / `#3B4A40` | camera screen |
| `hero-track` | `#2E3B32` | XP track on hero card |

### 1.2 Gradients, glass, shadows

- **Canvas background** (all light screens): `radial-gradient(circle at 8% 4%, rgba(255,175,125,.55) 0, rgba(255,175,125,0) 40%)`, `radial-gradient(circle at 96% 30%, rgba(255,165,135,.5) 0, rgba(255,165,135,0) 42%)`, `radial-gradient(circle at 18% 92%, rgba(150,220,175,.55) 0, rgba(150,220,175,0) 46%)`, over `linear-gradient(170deg, #FBF8EF 0%, #EAF4EA 100%)`.
- **Glass** (cards, inputs, chips, tab bar, bottom bars): `background: rgba(255,255,255,0.62)`; `backdrop-filter: blur(18px) saturate(150%)`; `box-shadow: 0 8px 24px rgba(40,70,50,0.10), inset 0 1px 0 rgba(255,255,255,0.9)`; `border: 1px solid rgba(255,255,255,0.8)`. Bars: same, `border-top` only. Segmented track: `rgba(255,255,255,0.45)`.
- **Primary CTA** (white text 16/600, height 52, radius 14): `linear-gradient(180deg,#FF9A52 0%,#F26A1B 50%,#D9510A 100%)`; `box-shadow: 0 8px 22px rgba(242,96,15,0.45), 0 0 0 1px rgba(255,255,255,0.55), inset 0 1px 0 rgba(255,255,255,0.75)`.
- **Selected option chip** (orange text, not white): `linear-gradient(180deg,#FFFFFF 0%,#FFE6D6 100%)`; `border: 1px solid rgba(255,255,255,0.95)`; `box-shadow: 0 0 0 3px rgba(255,127,50,0.45), 0 6px 18px rgba(242,96,15,0.3), inset 0 1px 0 #FFFFFF`.
- **Search focus glow**: `0 0 0 3px rgba(255,127,50,0.45)`.

### 1.3 Radius, type, spacing

- **Radius:** 28 (logo tile 88), 50% (avatars, check discs, shutter, medal), 20 (viewfinder, cards), 16–18 (section cards), 14 (CTA, rows, day cells), 12 (inputs, secondary buttons, photo tiles), 10 (small buttons, icon tiles), 8 (checkbox 26px), 17–20 (pill chips 34–36 high), 28 (FAB 56 high).
- **Font:** `'Be Vietnam Pro', system-ui, sans-serif`, Google Fonts weights 400/500/600/700.
- **Sizes (px):** 11 tab labels and tiny tags; 12 meta and captions; 13 secondary and eyebrow; 14 small body and secondary buttons; 15 list titles; 16 primary CTA and input text; 17 and 20 stat numbers; 22 sub-screen titles; 24 onboarding and task headings; 26 tab titles; 30 login brand, web H1, milestone H1; 32 XP total; 34 invite code.
- **Weights:** 700 headings and big numbers; 600 buttons and titles; 500 labels; 400 default body. Letter-spacing: brand −0.5; uppercase section labels 0.4; "ĐẠT MỐC MỚI" 1; invite code 4.
- **Layout:** frame 390×844 (web 1280×900). Side padding 20 (24 on login, onboarding, generating, milestone). Gaps 6–28. Tab bar height 76, padding `6px 4px 14px`, item min-width 64, icon 24 stroke 2. Bottom action bar padding `12px 20px 24px`. Icon touch targets 44×44. FAB right 20, bottom 96. Web: nav min-width 220, main padding 32, card grid `repeat(auto-fit,minmax(300px,1fr))`.
- **Icons:** inline SVG, stroke 2, round caps. No icon library named.

### 1.4 Where the color treatments go

- **Orange gradient + white text:** "Tiếp tục" (HoSo), "Nhận mã đăng nhập", "Tạo kế hoạch chăm sóc", "Bắt đầu trồng", "Xong · +10 XP", "Check-in ảnh", "Chụp lại", "Áp dụng N thay đổi", FAB "+ Trồng cây mới", "Mời", "Gửi link mời", "Giao việc", Hôm nay check-in banner, done checkbox, selected day cell, toggle ON track.
- **Green `#1E6B43`:** logo, active tab, progress, done circles, expanded stage number, links. Not used for primary CTAs.
- **Dark screens:** check-in camera (`#0F1712`), milestone (`#14502F`). Dark blocks on light screens: hero card `#16211A`, "Đang trồng · 3" pill, "Vào", "Gửi lời mời", web reminder banner.

---

## 2. Navigation

**Tab bar (mobile, 5 tabs):**

| # | Label | Icon | Route | Screen |
|---|---|---|---|---|
| 1 | "Hôm nay" | sun | `/today` | 04 |
| 2 | "Vườn" | leaf | `/garden` (the app's route; `/projects` redirects to it) | 06 |
| 3 | "Gia đình" | two people | `/household` | 17 |
| 4 | "Thành tích" | trophy | `/achievements` | 20 |
| 5 | "Cài đặt" | gear | `/settings` | 21 |

Active: `#1E6B43`, 600. Inactive: `#55625A`, 500. Shown only on the five tab screens.

**Web left nav** (screen 29): "Hôm nay", "Vườn của tôi", "Lịch chăm sóc", "Gia đình", "Thành tích", "Cài đặt".

**Flows:**
- Onboarding: 01 → 02 "Bước 1/2" → 03 "Bước 2/2" → 04. No OTP entry screen (§7).
- New project: 06 "+ Trồng cây mới" → 07 "Bước 1/3" → 08 "Bước 2/3" → 09 "Bước 3/3" → 10 "Bắt đầu trồng" → 12.
- Daily task: 04 (checkbox) or title → 05 "Xong · +10 XP".
- Check-in: 12 or 04 banner → 13 → 15 (if rejected) → 14 "Áp dụng" → 16 → 12.
- Household: 17 "Mời" → 18; 05 "Đổi" or 12 "Giao việc" → 19.

**Suggested routes:** `/login`, `/onboarding/profile`, `/onboarding/household`, `/today`, `/task/:taskId`, `/task/:taskId/assign`, `/garden` (spec: `/projects`, kept as a redirect), `/projects/new/search`, `/projects/new/context?plant=:id`, `/projects/:id/generating`, `/projects/:id/plan`, `/projects/:id/calendar`, `/projects/:id`, `/projects/:id/checkin`, `/projects/:id/checkin/:checkinId`, `/projects/:id/checkin/retake`, `/projects/:id/milestone/:code`, `/household`, `/household/invite`, `/achievements`, `/settings`, `/web` (not in the mobile MVP; no route).

---

## 3. MVP screens

Canvas numbers from `canvas.json`. "→" = navigation. Screens use the file names in the mockup.

### 01 Đăng nhập — `/login` (Main.dc.html) — ACC-01
- Logo tile 88 (green, leaf icon); H1 "Vườn Nhà" (30/700); tagline "Kế hoạch chăm cây do AI lập riêng cho bạn, việc mỗi ngày rõ ràng, cả nhà cùng chăm." (16/24, centered, max-width 290).
- Glass button "G" + "Tiếp tục với Google" → 02.
- Divider "hoặc"; label "Email"; input placeholder "ban@email.com".
- Primary CTA "Nhận mã đăng nhập" → 02.
- Footer (12/18): "Tiếp tục nghĩa là bạn đồng ý với Điều khoản và Chính sách dữ liệu (theo Nghị định 13/2023/NĐ-CP)."
- No Apple button (FL decision 13/10). States: none drawn.

### 02 Thiết lập hồ sơ — `/onboarding/profile` (HoSo.dc.html) — ACC-02, ACC-03, ACC-04 (P2 badge)
- Top: back → 01, "Bước 1/2". Two progress segments (green, grey).
- H1 "Giới thiệu một chút về bạn" (24/700). Sub: "Vị trí giúp AI tính khí hậu và mùa vụ. App chỉ lưu ở mức tỉnh/thành."
- Avatar 64 with "M" + glass button "Đổi ảnh đại diện".
- "Tên hiển thị" = "Minh". "Bạn trồng cây ở đâu?" = "TP. Hồ Chí Minh" + 48px GPS button (aria "Dùng vị trí hiện tại"). Helper: "Khí hậu nhiệt đới, mùa mưa tháng 5–11".
- "Kinh nghiệm trồng cây" + tag "Phase 2": "Mới bắt đầu" (selected by default) | "Trung bình" | "Thành thạo".
- "Ngôn ngữ": "Tiếng Việt" (dark pill, selected) | "English" (glass).
- CTA "Tiếp tục" → 03. States: none.

### 03 Thiết lập gia đình — `/onboarding/household` (GiaDinhSetup.dc.html) — HSH-01, HSH-02
- Top: back → 02, "Bước 2/2", "Bỏ qua" → 04. Two green progress segments.
- H1 "Chăm cây cùng người nhà?". Sub: "Tạo gia đình để giao việc tưới, bón cho từng người và xem ai đã làm gì. Bạn có thể làm việc này sau."
- Illustration panel (180, `#E3EFE6`) with three overlapping avatars M, L, H.
- Card "Tạo gia đình mới" / "Bạn là chủ nhà (Owner)" → 18.
- Card "Tham gia bằng mã mời" / "Bạn sẽ là thành viên (Member)"; input placeholder "VD: VUON-4821"; dark button "Vào" → 04.
- Footer: "Mỗi người chỉ ở trong một gia đình. App không có kết bạn công khai." States: none.

### 04 Hôm nay — `/today` (HomNay.dc.html) — TSK-01, TSK-02, CHK-01 (tab 1)
- Eyebrow "Thứ Ba, 13/10 · 31°C nắng". H1 "Hôm nay" (26/700). Chips: flame "12 ngày" (orange tint), "{xp} XP" (green tint; sample 1240 + 10 × done).
- "Đã xong {done}/{total} việc" · "+10 XP mỗi việc đúng hạn". Bar 8px.
- Orange banner (when due): "Đến hạn chụp ảnh check-in" / "Cà chua bi ban công · +30 XP" → 13.
- Segmented: "Theo khung giờ" (selected) | "Theo project".
- Group labels (uppercase 13/600): "Sáng sớm · 6–8h", "Chiều mát · 16–18h".
- Task row (glass, 14 radius): checkbox 32 (ring `#9AA89D`; done = orange disc with check; aria "Đánh dấu xong" / "Bỏ đánh dấu xong"); title (15/600) → 05; meta (13) "Cà chua bi ban công · Hữu cơ"; 28px assignee avatar.
- Sample rows: "Tưới nước 300ml/chậu" (M), "Xoay chậu về phía sáng" (M), "Bón phân trùn quế" (L), "Kiểm tra mặt dưới lá" (H), "Tưới phun sương" (H).
- States: none drawn (no empty, loading or offline). Skip and Snooze are not on the row.

### 05 Chi tiết task — `/task/:id` (ChiTietTask.dc.html) — TSK-02, PLN-03, PLN-05, PLN-09; "Thêm ảnh" P2
- Top: back → 04; glass button "Sửa task".
- Eyebrow "Cà chua bi ban công · Giai đoạn Sinh trưởng"; H1 "Bón phân trùn quế" (24/700).
- Three tiles: "Khung giờ" → "Chiều mát"; "Lặp lại" → "14 ngày/lần"; "Nhắc lúc" → "16:30".
- "Giao cho **Lan**" (avatar L) · "Đổi" → 19.
- Card "Cách làm" + badge "Gợi ý từ AI · tin cậy cao". Steps: "Rải 1 nắm tay phân trùn quế quanh gốc, cách thân 5cm." / "Xới nhẹ lớp đất mặt cho phân trộn đều." / "Tưới đẫm nước sau khi bón." "**Vì sao?** Cây đang ra nhiều lá, cần đạm và vi sinh để chuẩn bị ra hoa." "Nguồn: CSDL cây Vườn Nhà (312 đợt trồng thực tế)".
- Warn banner: "Nếu dùng phân bón đóng gói, làm theo liều trên nhãn sản phẩm. App không đưa liều hóa chất cụ thể."
- "Thêm ảnh" (P2).
- Bottom: "Bỏ qua" (72), "Dời lại" (72), "Xong · +10 XP" (orange, flex). States: none. No skip-reason or snooze picker drawn.

### 06 Danh sách project — "Vườn của tôi" — `/garden` (spec `/projects`, redirected) (DanhSachProject.dc.html) — PRJ-01, PRJ-04 (tab 2)
- H1 "Vườn của tôi"; search button (aria "Tìm project").
- Chips: "Đang trồng · 3" (dark), "Đã xong · 1", "Lưu trữ".
- Card (glass, 18): cover 88×104 tint with "Ảnh mới nhất"; name (16/600); kind "Rau quả · 4 chậu · ngày 38"; stage line with dot "Sinh trưởng · sắp ra hoa" / "Cây con · cần check-in"; progress 45% / 30% / 70%; footer "3 việc hôm nay" · "Ảnh: 2 ngày trước" → 12.
- Blue hint: "Vuốt sang trái để lưu trữ, nhân bản hoặc xóa project (Phase 2)."
- FAB "+ Trồng cây mới" → 07. States: none drawn.

### 07 Tìm cây — `/projects/new/search` (TimCay.dc.html) — PLT-01, PLT-02, PLT-03; PLT-05 warn (P2)
- Close X → 06; eyebrow "Trồng cây mới · Bước 1/3"; H1 "Bạn muốn trồng cây gì?".
- Search field (52, focus glow), value "ca chua" (aria "Tên cây").
- Chips: "Tất cả" (dark) | "Rau & quả" | "Cây cảnh trong nhà".
- "3 kết quả cho “cà chua”".
- Result cards: 64 image; name; italic scientific name; chips "Dễ" / "Trung bình", "Thu hoạch ~75 ngày" → 08. Items: Cà chua bi (*Solanum lycopersicum var. cerasiforme*, Dễ, ~75 ngày); Cà chua thường (*S. lycopersicum*, Trung bình, ~90 ngày); Cà chua cherry vàng (Dễ, ~70 ngày).
- Blue card: "Không thấy cây bạn cần?" / "Bạn gõ “ca chua tim”. Có phải bạn muốn nói **Cà chua tím (Indigo Rose)**?" Buttons "Đúng rồi" → 08, "Không phải" (no target).
- Warn card: "**Phase 2:** lá và thân cà chua có độc nhẹ với chó mèo. Cảnh báo này hiện khi bạn khai báo có thú cưng."
- States: none drawn (no results, loading or AI-creation state).

### 08 Thông tin & bối cảnh — `/projects/new/context` (BoiCanh.dc.html) — PRJ-02, PRJ-03
- Back → 07; "Trồng cây mới · Bước 2/3"; H1 "Cà chua bi trồng ở đâu?" (22).
- "Tên project" = "Cà chua bi ban công – 10/2026".
- "Ngày bắt đầu" = "13/10/2026" | "Số chậu" stepper (−, 4, +).
- "Bắt đầu từ": "Hạt giống" (selected) | "Cây con" | "Trưởng thành".
- "Nơi trồng": "Trong nhà" | "Ban công" (selected) | "Sân vườn".
- "Nắng mỗi ngày": "Dưới 3 giờ" | "3–6 giờ" (selected) | "Trên 6 giờ".
- "Chậu / đất" = "Chậu nhựa 20L, đất trộn" | "Cách tưới" = "Tưới tay".
- Dashed row "Thêm ảnh bìa (không bắt buộc)".
- CTA "Tạo kế hoạch chăm sóc" → 09. States: none (no validation).

### 09 AI đang tạo plan — `/projects/:id/generating` (TaoPlan.dc.html) — PLN-01
- Eyebrow "Trồng cây mới · Bước 3/3". Spinner (140 disc, two green arcs, sparkle).
- H1 "Đang lập kế hoạch cho" / "Cà chua bi ban công". "Thường mất dưới 20 giây".
- Step card: ✓ "Đọc dữ liệu chuẩn cà chua bi" (Từ cơ sở dữ liệu cây Vườn Nhà); ✓ "Tính khí hậu TP. Hồ Chí Minh" (Tháng 10, cuối mùa mưa, 26–33°C); ✓ "Chia giai đoạn và mốc" (6 giai đoạn, khoảng 85 ngày); ○ "Tạo việc chăm sóc hằng ngày" (Theo khung giờ sáng sớm / chiều mát).
- Note: "Nếu AI gặp sự cố, app dùng plan mẫu cho cà chua bi để bạn bắt đầu ngay."
- CTA "Xem kế hoạch" → 10 (shown during loading in mockup; see §7).
- State: loading. Error path only as copy.

### 10 Duyệt plan — `/projects/:id/plan` (DuyetPlan.dc.html) — PLN-02, PLN-03, PLN-05, PLN-07, PLN-09; "Tạo lại" P2 (PLN-06)
- Back → 08; H1 "Kế hoạch 85 ngày".
- Chips: "Gợi ý từ AI" (blue), "Tin cậy cao · 86%" (green), "Nguồn: CSDL cây + 2 tài liệu".
- Segmented: "Giai đoạn" | "Lịch" → 11.
- Stage rows (timeline rail): number disc (green when expanded); name (15/600); "Ngày 1–7 · Mốc: Nảy mầm"; count "3 việc". Expanded shows task rows (name · frequency) and "+ Thêm việc".
- Stages: 1 Ươm hạt (Ngày 1–7, Nảy mầm, 3): Ngâm hạt nước ấm 4 giờ (Một lần), Gieo hạt vào khay ươm (Một lần), Phun ẩm khay ươm (Sáng sớm, hằng ngày). 2 Cây con (Ngày 8–25, Ra lá thật, 5): Tưới gốc (Sáng sớm, 2 ngày/lần), Chuyển sang chậu 20L (Ngày 20), Check-in ảnh (5 ngày/lần). 3 Sinh trưởng (Ngày 26–45, Cao 40cm, 6): Cắm cọc, buộc dây (Một lần), Bón phân trùn quế (14 ngày/lần), Tỉa chồi nách (7 ngày/lần). 4 Ra hoa (Ngày 46–60, Ra hoa, 4): Lắc nhẹ cây hỗ trợ thụ phấn (Sáng, hằng ngày). 5 Đậu quả (Ngày 61–75, Đậu quả, 4): Bổ sung vỏ trứng nghiền (Một lần). 6 Thu hoạch (Ngày 76–85, Thu hoạch, 2): Hái quả chín đỏ (2 ngày/lần).
- Bottom: "Tạo lại" (P2, glass) | "Bắt đầu trồng" (orange) → 12. States: none. Code expands stage 1 by default.

### 11 Lịch plan — `/projects/:id/calendar` (LichPlan.dc.html) — PLN-04, PLN-05
- Back → 12; project name eyebrow; H1 "Lịch chăm sóc". Segmented "Giai đoạn" → 10 | "Lịch".
- "Tuần 12–18/10" with buttons "Tuần trước" / "Tuần sau".
- Day cells T2–CN (64 high): weekday (11), date (17/700), "N việc" (10). Selected: orange.
- Banner (`#E3EFE6`): "Giai đoạn 3 · Sinh trưởng (ngày 26–45) · còn 7 ngày".
- Day label "Thứ Ba, 13/10". Task rows: time ("Sáng sớm" / "Chiều mát" / "Cả ngày"), colored 3px bar (meaning not stated), title, meta ("300ml/chậu · Minh", "14 ngày/lần · Lan", "5 ngày/lần · +30 XP") → 05.
- Dashed "+ Thêm việc thủ công". States: no empty day drawn.

### 12 Chi tiết project — `/projects/:id` (ChiTietProject.dc.html) — PRJ-06, TSK-06, HSH-03; menu items P2 (PRJ-05/07)
- Cover 180 (`#F6DED3`, "[Ảnh bìa project]"). Round glass back and "more" buttons (aria "Thêm tùy chọn: lưu trữ, nhân bản, kết thúc project").
- H1 "Cà chua bi ban công". Meta: "Rau quả · 4 chậu · Ban công 3–6 giờ nắng · Chia sẻ với gia đình".
- Tabs: "Tổng quan" (active, orange underline) | "Plan" → 10 | "Lịch" → 11 | "Ảnh" → timeline (P2) | "Thành viên" → 17.
- Stage card: "Giai đoạn 3/6 · Sinh trưởng" · "Ngày 38/85"; six-segment bar; "Mốc tiếp theo: **Ra hoa**, dự kiến khoảng 22/10".
- Stats: "92%" việc đúng hạn · "7" lần check-in · "2/6" mốc đã đạt.
- "Ảnh tăng trưởng" + "Xem tất cả"; tiles "Ngày 5", "Ngày 15", "Ngày 26", "Ngày 36".
- "Lịch sử gần đây": "**Lan** tỉa chồi nách — Hôm qua, 17:10"; "**Minh** check-in ảnh — 11/10, 07:02".
- Bottom: "Giao việc" → 19 (outline) | "Check-in ảnh" (orange, camera) → 13. States: none.

### 13 Check-in: chụp ảnh — `/projects/:id/checkin` (CheckinChup.dc.html, dark) — CHK-01, CHK-02, CHK-03 (tag row P2)
- Top: close X → 12 (aria "Đóng"); "Check-in · Cà chua bi" / "Ảnh 1/2 · Toàn cây"; flash (aria "Bật đèn flash").
- Viewfinder 470 high, radius 20. Dashed oval guide with "Đặt cả cây trong khung". Corner "[Khung camera]" (preview placeholder). Pill "Ánh sáng tốt · Đủ nét" (green).
- Shot pills: "1 · Toàn cây" (active) | "2 · Cận lá" | "Mặt dưới lá".
- "Tình trạng nhanh" (P2 tag) chips: "Lá vàng", "Héo", "Có sâu". FL adds "Đốm" (§7).
- Shutter row: gallery (aria "Chọn từ thư viện ảnh") | shutter ring → 14 | help "?" (aria "Xem mẹo chụp") → 15.
- States: none (no permission-denied state).

### 14 Kết quả check-in — `/projects/:id/checkin/:checkinId` (CheckinKetQua.dc.html) — CHK-04, CHK-05, AI-02, AI-07
- Back → 13; H1 "Kết quả check-in"; chip "+30 XP".
- Summary card: thumbnail "Ảnh ngày 38"; "Gợi ý từ AI"; "**Giai đoạn:** cuối Sinh trưởng, sắp ra hoa *(82%)*"; "**Sức khỏe:** Tốt".
- Problem card (warn): "Nghi thiếu canxi nhẹ" + "Tin cậy trung bình · 58%". "Mép lá non hơi vàng. Có thể do tưới không đều trong đợt nắng gần đây."
- Green note: "Ảnh xác nhận đạt mốc **Cao 40cm**".
- "Đề xuất điều chỉnh plan": rows with checkbox and kind label: "THÊM VIỆC" · "Rải vỏ trứng nghiền quanh gốc" · "Bổ sung canxi tự nhiên, an toàn"; "ĐỔI TẦN SUẤT" · "Tưới: 2 ngày/lần → hằng ngày" · "Giữ ẩm đều trong đợt nắng 33°C"; "DỜI MỐC" · "Ra hoa: 22/10 → 20/10" · "Cây phát triển nhanh hơn dự kiến".
- "Kết quả này có hữu ích?" | "Có" | "Không" (AI-07).
- Bottom: "Để sau" → 12 | "Áp dụng {count} thay đổi" → 16 (count = selected rows). States: none.

### 15 Ảnh chưa đủ rõ — `/projects/:id/checkin/retake` (ChupLai.dc.html) — CHK-06
- Back → 13; H1 "Cần chụp lại".
- Preview 260 (blurred) with label "Ảnh bị mờ, thiếu sáng" (danger text).
- "AI chưa đủ thông tin để đánh giá" / "Để tránh đoán sai, bạn chụp lại giúp mình nhé. Lần chụp này chưa tính vào lượt phân tích trong ngày."
- "Mẹo chụp rõ": "Chụp ban ngày, tránh ngược sáng"; "Giữ máy cách cây 40–60cm, chạm để lấy nét"; "Thêm 1 ảnh cận lá có dấu hiệu lạ".
- CTA "Chụp lại" → 13. State: this is the retake state.

### 16 Chúc mừng milestone — `/projects/:id/milestone/:code` (Milestone.dc.html, dark `#14502F`) — GAM-01, GAM-03, GAM-04
- Decorative shapes; close → 12. Eyebrow "ĐẠT MỐC MỚI". Medal 150 (`#FF8A3D`, award icon, glow ring).
- H1 "Cao 40cm rồi!". "Cà chua bi ban công đã qua mốc thứ 3. Ảnh check-in hôm nay đã xác nhận."
- Reward tiles: "+100 XP" / "Milestone"; "Huy hiệu" / "“Vươn cao”".
- Keepsake card: "Ảnh kỷ niệm"; "Thẻ kỷ niệm ngày 38" / "Ảnh trước–sau, có thể chia sẻ".
- "Chia sẻ ảnh kỷ niệm" (solid `#FF8A3D`); "Xem thành tích" (outline) → 20. States: none.

### 17 Gia đình — `/household` (GiaDinh.dc.html) — HSH-02, HSH-03, HSH-06; leaderboard and "vắng nhà" P2 (tab 3)
- Eyebrow "Gia đình · 3 người"; H1 "Nhà mình"; orange pill "+ Mời" → 18.
- Members: "Minh (bạn)" · "5 việc tuần này" · Owner; "Lan" · "8 việc tuần này" · Member; "Hùng" · "3 việc tuần này · đang vắng nhà" · Member.
- "Project chia sẻ": "Cà chua bi ban công", "Húng quế sân thượng", "+ Chia sẻ thêm".
- Banner (`#FCEBDD`): "**Lan** đang dẫn đầu tuần này · 340 XP" (P2) → Xếp hạng (P2).
- "Hoạt động": "Lan đã tỉa chồi nách · Cà chua bi" 17:10; "Hùng đã tưới phun sương · Húng quế" 16:45; "Minh giao “Bón phân trùn quế” cho Lan" 09:02; "Minh đạt mốc Cao 40cm · Cà chua bi" 07:05. States: none.

### 18 Mời thành viên — `/household/invite` (MoiThanhVien.dc.html) — HSH-01, HSH-02
- Back → 17; H1 "Mời người nhà".
- Code card: "Mã mời của Nhà mình" / "VUON-4821" (34; mockup sample, real codes are `VUON-` + 6 characters since QA round 2) / "Hết hạn sau 7 ngày"; buttons "Sao chép mã", "Gửi link mời".
- Divider "hoặc mời trực tiếp". Input "Số điện thoại hoặc email" (placeholder "09xx xxx xxx").
- "Vai trò" radios: "Member" (selected) "Làm việc được giao, xem project được chia sẻ"; "Owner" "Quản lý thành viên, project và giao việc".
- Dark CTA "Gửi lời mời" → 17. States: none.

### 19 Giao việc — `/task/:id/assign` (GiaoViec.dc.html) — HSH-04; HSH-05 and HSH-07 P2 notes
- Back → 05; H1 "Giao việc". Summary: "Tưới gốc 300ml/chậu" / "Cà chua bi ban công · Sáng sớm · 2 ngày/lần".
- "Cách giao": "Chỉ lần này" | "Cả chuỗi lặp" | "Xoay vòng" (default).
- Label "Thứ tự xoay vòng" (rotation) or "Giao cho" (single modes).
- People: "Minh (bạn)" · "5 việc tuần này"; "Lan" · "8 việc tuần này"; "Hùng" · "Vắng nhà đến 20/10". Marker: order number (rotation) or ✓ (single).
- Hint (blue): rotation "Xoay vòng: {names} → lặp lại. Người vắng nhà được bỏ qua tự động."; series "Mọi lần tưới tiếp theo sẽ giao cho {name}."; once "Chỉ lần tưới sáng 14/10 giao cho {name}."
- P2 note: "Người được giao có thể nhận, từ chối hoặc nhờ đổi."
- CTA "Giao việc" → 17. States: none.

### 20 Thành tích — `/achievements` (ThanhTich.dc.html) — GAM-01, GAM-04; level P2 (tab 4)
- H1 "Thành tích". Hero (`#16211A`): "Tổng điểm" / "1.250 XP" (32); "Level" P2 tag; "Cấp 4 · Người chăm chỉ"; bar 62%; "Còn 250 XP để lên Cấp 5 · Thợ vườn".
- Tiles: "Việc đúng hạn" +620 XP; "Check-in ảnh" +330 XP; "Đạt milestone" +300 XP; "Hôm nay" 60/150 XP.
- Blue banner: "Mỗi ngày tối đa 150 XP từ việc thường. Điểm milestone chỉ cộng khi có ảnh check-in xác nhận."
- "Huy hiệu · 5/16" + "Xếp hạng nhà" (P2).
- Badges (8 drawn). Earned: "Hạt giống đầu tiên", "Nảy mầm", "7 ngày liên tục", "Vươn cao", "Thợ chụp ảnh". Locked (dashed): "Ra hoa", "Thu hoạch đầu tiên", "30 ngày liên tục". States: locked badges only.

### 21 Cài đặt — `/settings` (CaiDat.dc.html) — SET-01, SET-02, ACC-05, HSH-09, TSK-04 (tab 5)
- H1 "Cài đặt". Profile card "M", "Minh", "TP. Hồ Chí Minh · Tiếng Việt", "Sửa" → 02.
- "THÔNG BÁO" toggles: "Nhắc việc chăm cây" (on); "Nhắc chụp check-in" (on); "Được giao việc" (on); "Thành tích & huy hiệu" (on); "Gộp thông báo thành 1 lần/ngày" (off); "Hiện điểm & xếp hạng" (on, P2); "Giờ yên lặng" "22:00–06:00" (P2, not a toggle).
- "KHÁC": "Ngôn ngữ" "Tiếng Việt" (value); "Chế độ vắng nhà" (P2) → web P2 screen; "Thiết bị & cảm biến" (P3) → P3 screen; "Rời gia đình “Nhà mình”".
- Danger button "Xóa tài khoản và toàn bộ dữ liệu". States: none.

### 29 Web – Bảng điều khiển — `/web` (WebDashboard.dc.html, 1280×900) — P0 in canvas; FL §10
- Left nav: logo "Vườn Nhà" (18/700) and six items (active "Hôm nay").
- "Thứ Ba, 13/10 · TP. Hồ Chí Minh 31°C"; H1 "Chào Minh, hôm nay có 5 việc" (30); chips "12 ngày liên tục", "1.250 XP"; "+ Trồng cây mới" → 07.
- Cards: "Việc hôm nay" (5 rows with owner names); "Vườn đang trồng" (3 rows with progress); "Nhà mình hôm nay" (3 activity rows + dark banner "Đến hạn check-in ảnh: Húng quế sân thượng" / "Chụp trên điện thoại").

**Outside MVP set (not specified here):** 22 Xếp hạng (P2), 24 Timeline ảnh (P2), 25 Thời tiết & vắng nhà (P2), 27 Cây ảo (P3), 28 Thiết bị (P3), 30–31 Widget (P3).

---

## 4. Data model

Derived from req §8, FL, AI doc and plan §2. Column names are proposals. Enums are as the sources give them.

### 4.1 Enums

| Enum | Values | Labels / source |
|---|---|---|
| `space` | `indoor`, `balcony`, `yard`, `rooftop` | "Trong nhà", "Ban công", "Sân vườn" (rooftop unlabelled, §7) |
| `sun_level` | `1`–`4` (AI doc) | "Dưới 3 giờ", "3–6 giờ", "Trên 6 giờ" (mapping open) |
| `pot_type` | e.g. `plastic_20cm` (example) | "Chậu nhựa 20L, đất trộn" |
| `watering` | `manual`, `auto` | "Tưới tay"; FL PRJ-03 |
| `start_stage` | `seed`, `seedling`, `mature` (proposed) | "Hạt giống", "Cây con", "Trưởng thành" |
| `experience` | `new`, `mid`, `pro` (AI doc) | "Mới bắt đầu", "Trung bình", "Thành thạo" |
| `time_budget` | `<10p`, `10–30p`, `>30p` (AI doc) | no UI |
| `lang` | `vi`, `en` | "Tiếng Việt", "English" |
| `plant_group` | `rau_qua`, `cay_canh` | "Rau & quả", "Cây cảnh trong nhà" |
| `condition_tag` | `LEAF_YELLOW`, `WILT`, `PESTS`, `SPOTS` (proposed) | "Lá vàng", "Héo", "Có sâu", "Đốm" (FL) |
| `shot` | `whole_plant`, `close_leaf`, `leaf_underside` | "Toàn cây", "Cận lá", "Mặt dưới lá" |
| `task_window` | `morning`, `afternoon`, `all_day` | "Sáng sớm · 6–8h", "Chiều mát · 16–18h", "Cả ngày" |
| `frequency` | `once`, `every_n_days`, `daily`, `fixed_date` | "Một lần", "N ngày/lần", "hằng ngày", "Ngày 20" |
| `assignment_mode` | `once`, `series`, `rotation` | "Chỉ lần này", "Cả chuỗi lặp", "Xoay vòng" |
| `task_action` | `done`, `skip`, `snooze` | "Xong", "Bỏ qua", "Dời lại" |
| `role` | `owner`, `member` | "Owner", "Member" |
| `project_status` | `active`, `done`, `failed`, `archived` | "Đang trồng", "Đã xong", "Lưu trữ" |
| `change_kind` | `add`, `remove`, `shift`, freq change | "THÊM VIỆC", "ĐỔI TẦN SUẤT", "DỜI MỐC" |
| `health` | `good`, … | "Tốt" (other values open) |
| `confidence_band` | high / medium / low | "Tin cậy cao · 86%", "Tin cậy trung bình · 58%" |
| `plan_source` | `template`, `ai`, `fallback` (proposed) | AI doc; plan §2.1 |
| `reason_code` / `problem_code` / `task_code` | `R_HOT_SEASON`; `P_YELLOW_LEAF_OVERWATER`, `P_APHID`, `P_ROOT_ROT`; `T_WATER`, `T_FERT_ORGANIC`, `T_PRUNE` | AI doc examples only |
| `milestone_code` | `SPROUT`, `TRUE_LEAVES`, `HEIGHT_40`, `FLOWER`, `FRUIT_SET`, `HARVEST` (proposed) | "Nảy mầm", "Ra lá thật", "Cao 40cm", "Ra hoa", "Đậu quả", "Thu hoạch" |
| `notif_type` | `task_reminder`, `checkin_reminder`, `assignment`, `achievement`, `household_activity`, `overdue` (P1) | FL SET-01; plan §2.3 |
| `level` | 1…N | "Người mới" → "Nhà vườn" (GAM-05); "Người chăm chỉ" (Cấp 4), "Thợ vườn" (Cấp 5) |

### 4.2 Tables

**Identity and household**
- `users`: id, display_name, avatar_path, lang, timezone, province_code or zone_code (region only, ACC-03), experience, time_budget, prefer_organic, quiet_start, quiet_end, xp_total, level, created_at, deleted_at. Auth identity lives in Supabase Auth.
- `households`: id, name, owner_id, created_at.
- `household_members`: household_id, user_id (unique: one household per user), role, joined_at, away_until (P1).
- `invites`: id, household_id, code, channel, target, role, created_by, expires_at (+7 days), accepted_by, status.

**Plant knowledge base (CSDL cây)**
- `plants`: id, group, name_vi, name_en, scientific_name, difficulty, days_to_harvest, toxic_child, toxic_pet, data_status (`verified` / `ai_unverified`), sources, updated_at.
- `plant_stages`: plant_id, code, order, name_vi, name_en, day_min, day_max, milestone_code.
- `task_codes`: code, group, default_window, default_frequency, safety_flags.
- `text_templates`: kind (task / problem / reason / milestone / safety), code, lang, field (name / steps / why / safety), body, source_ref, status.
- `problem_codes`: code, symptoms, causes, safe_actions, severity (scale open).
- `plan_templates`: template_key, plant_id, zone, season, start_stage, space, sun_level, version, status, created_by, hit_count. Example key: `basil|VN_S|rainy|seedling|balcony|sun3`.

**Projects and plans**
- `projects`: id, household_id, owner_id, plant_id, name, start_date, start_stage, pot_count, space, sun_level, pot_type, watering, cover_path, status, template_key, end_reason, end_note, created_at.
- `plans`: id, project_id, version, source, confidence, status (`draft` / `approved` / `superseded`), approved_at.
- `stages`: id, plan_id, idx, code, name, day_from, day_to, milestone_code.
- `tasks`: id, project_id, stage_id, task_code, window, frequency, interval_days, reminder_time, assignee_id, assignment_mode, rotation_order, source (`template` / `ai` / `manual`), status, xp.
- `task_occurrences` (not named in sources; needed for the day view): task_id, due_date, window, state.
- `task_logs`: id, task_id, occurrence_date, user_id, action, skip_reason, snooze_until, note, photo_path, client_id (proposed, offline dedup), created_at.

**Check-in and AI**
- `checkins`: id, project_id, user_id, shots (type + storage path), tags[], note, status (`pending` / `analyzed` / `retake` / `approved` / `rejected`), ai_result (json), model, counts_toward_quota, created_at.
- `checkin_changes`: id, checkin_id, change_kind, payload, accepted. Applied only on user approval (CHK-05, AI-05).
- `milestones_reached`: id, project_id, milestone_code, reached_on, confirmed_by (`ai` / `user`), checkin_id.
- `project_lessons`: user_id, plant_id, zone, season, text, source_project_id. Written at project end (PRJ-07). Example: "basil 2026-08: thất bại, P_ROOT_ROT, tưới quá nhiều".
- `ai_usage`: user_id, day, kind (`plan` / `checkin`), count, model, tokens_in, tokens_out, cache_read, cost_usd.
- `ai_feedback`: id, ref_type, ref_id, helpful, created_at (AI-07).

**Gamification**
- `xp_events`: id, user_id, project_id, source (`task_done` / `checkin` / `milestone` / `project_done`), ref_id, amount, day, created_at. Written only by the server.
- `badges_catalog`: code, name_vi, criteria. `user_badges`: user_id, badge_code, earned_at.

**Other**
- `notification_prefs`: user_id, type, enabled, bundle_daily, quiet_start, quiet_end.
- `devices`: placeholder for IoT (id, user_id, kind, external_id, status, meta).
- `push_tokens`, `consents`: implied by FCM and NĐ 13/2023, not designed in sources.

**Storage and client:** check-in photos in a private bucket with signed links. Client resizes to 768 px long edge, JPEG 75% (AI doc §3.6), and blur-checks before upload. Client offline queue (drift/SQLite) holds Done, Skip and Snooze; the server recomputes XP from the action time (plan §2.2).

---

## 5. AI contracts

Three AI paths: plan creation, photo analysis with the plan delta in the same call, and retake. The question-and-answer feature is removed (FL). Field names are proposals based on AI doc examples.

### 5.1 Call A: plan generation (`ai-plan`)

Runs only on a template-key miss. A hit copies the template and personalizes it by rule (start date, window, frequency by sun level).

Input:
```json
{
  "plant_id": "tomato_cherry",
  "start_date": "2026-10-13",
  "start_stage": "seedling",
  "context": {"zone": "VN_S", "season": "rainy", "space": "balcony",
              "sun_level": 3, "pot": "plastic_20l", "watering": "manual"},
  "user": {"experience": "new", "time_budget": "10-30p", "prefer_organic": true},
  "household": {"has_children": false, "has_pets": false},
  "plant_card": {"stages": ["..."], "problems_top": ["P_..."]},
  "lessons": ["basil 2026-08: thất bại, P_ROOT_ROT, tưới quá nhiều"]
}
```

Output (codes and params only):
```json
{
  "template_key": "tomato_cherry|VN_S|rainy|seedling|balcony|sun3",
  "confidence": 0.86,
  "stages": [{"code": "S1", "day_from": 1, "day_to": 7, "milestone": "SPROUT"}],
  "tasks": [{"task": "T_WATER", "stage": "S2", "every_d": 2,
             "window": "morning", "why": "R_HOT_SEASON"}],
  "new_text": null
}
```

Rules:
- AI returns codes and parameters. The app builds VN/EN sentences from `text_templates` (AI doc §3.2; FL 14/10).
- `new_text` is non-null only if the plant is not in CSDL. It is stored with `status = ai_unverified` and shown with the AI label (AI-03).
- The result is cached as a template for later users with the same key.
- Model: Haiku 5.5 by default. Escalate to Sonnet 5.5 if the plant is new or confidence is below a threshold (value open).
- Target ≤ 20 s with progress UI (AI-08).
- Error or limit reached: fall back to the plant-type template, tagged `source = fallback`.

### 5.2 Call B: photo check-in with plan delta (`ai-checkin`)

One call returns diagnosis and a delta, not a full plan (AI doc §3.3).

Input:
```json
{
  "project_card": {"plant": "tomato_cherry", "stage": "S3", "day": 38,
    "zone": "VN_S", "season": "rainy", "space": "balcony", "sun": 3,
    "pot": "plastic_20l", "water": "manual", "adherence_14d": 0.92,
    "skipped": ["T_FERT_ORGANIC x2"], "checkins": [{"d": 23, "health": "good"}],
    "active_issues": [], "applied_changes": []},
  "tags": ["LEAF_YELLOW"],
  "note": "(max length not stated)",
  "images": [{"shot": "whole_plant", "px": 768, "jpeg_q": 75}],
  "prev_thumb": {"d": 23, "for": "P_YELLOW_LEAF_OVERWATER"}
}
```

- The project card (about 300–500 tokens) is updated by code after each event, not by the AI. Keep the last 3 check-ins; older ones go into a short `history_summary`. Send a previous thumbnail only while an issue is tracked (AI doc §1).

Output:
```json
{
  "status": "ok",
  "stage_est": {"code": "S3_late", "confidence": 0.82},
  "health": {"value": "good", "confidence": 0.80},
  "issues": [{"code": "P_CALCIUM_LOW", "confidence": 0.58, "severity": 1,
              "actions": [{"task": "T_EGGSHELL_ADD"}]}],
  "milestone_seen": {"code": "HEIGHT_40", "confidence": 0.90},
  "delta": [
    {"op": "add", "task": "T_EGGSHELL_ADD", "stage": "S3"},
    {"op": "change_freq", "task": "T_WATER", "every_d": 1, "why": "R_HEAT_33C"},
    {"op": "shift", "milestone": "FLOWER", "to": "2026-10-20"}
  ],
  "reason_codes": ["R_HOT_SEASON"]
}
```

Retake (CHK-06):
```json
{"status": "retake", "reason": "BLUR", "hint_code": "H_RETAKE_LIGHT"}
```

Rules:
- Ops are `add`, `remove`, `shift` (AI doc). The mockup shows add, frequency change and shift. No remove row is drawn (§7).
- Every delta item needs user approval (CHK-05, AI-05). Unselected items are discarded.
- Confidence shows as a percent with a band label: high "Tin cậy cao · {n}%", medium "Tin cậy trung bình · {n}%". Low confidence suggests asking a local agricultural store (CHK-08, P1). Thresholds open.
- Blurred or dark images are rejected on the device first (CHK-06). Retakes do not count toward the daily quota (ChupLai copy).
- No new call if the same project was analyzed < 24 h ago and there are no new tags (AI doc §3.7).
- Target ≤ 15 s (AI-08).
- On error: no delta is applied; the current plan stays (inferred; sources only specify fallback for plan creation).

### 5.3 Safety (both calls)

- No chemical doses or product amounts. Fertilizer and pesticide advice points to the product label (ChiTietTask copy; AI-06).
- Organic or safe options first (PLN-09).
- Every AI text carries "Gợi ý từ AI" and a confidence value (AI-02).
- Toxic-plant warnings come from rules, not AI (PLT-05; AI doc §2).
- When uncertain, say so and ask for more input (AI-04).
- Server validates output against the code list. Unknown codes are rejected and the app falls back to the template or asks for a retake.

### 5.4 Caps and cost

- `ai_usage` counts `plan` and `checkin` calls per user per day, enforced in the Edge Function (plan §2.1). Cap values not given (§7).
- Prompt-cache order: system + schema → plant card → project card → images (AI doc §3.5).
- Batch-generate templates for 30–50 common plants by region and season (AI doc §3.1). Cost numbers in AI doc §4 are estimates.

---

## 6. Business rules

### 6.1 Scheduling

- Windows: "Sáng sớm · 6–8h", "Chiều mát · 16–18h"; check-in is "Cả ngày". Each task has its own reminder time (mockup: "Nhắc lúc 16:30" inside 16–18). User can set a reminder time (req §5).
- Check-in every 3–7 days by stage (CHK-01); mockup uses 5 days for the "Cây con" stage.
- Plan and task edits are manual: add, edit, delete, change frequency or reminder (PLN-05).

### 6.2 Task actions

- **Done:** one tap on the Hôm nay checkbox, or "Xong · +10 XP" on detail. Target: ≤ 2 taps (TSK-02).
- **Skip:** "Bỏ qua" on detail, optional reason (TSK-02). Reason options not given.
- **Snooze:** "Dời lại". Duration not given.
- Done, Skip and Snooze work offline and sync later (plan §2.2). Overdue handling (TSK-05) is P1, fixed rules, no AI.

### 6.3 XP and levels

| Event | XP | Source |
|---|---|---|
| Task done on time | +10 | Hôm nay progress line; "Xong · +10 XP" |
| Check-in photo | +30 | Hôm nay banner; result chip; calendar row |
| Milestone (photo-confirmed) | +100 | Milestone screen |
| Project completed | not given | GAM-01 names it (§7) |

- Daily cap for ordinary XP: 150 ("Mỗi ngày tối đa 150 XP từ việc thường").
- Milestone XP only when a check-in photo confirms it (GAM-08).
- Sum check: 620 (on time) + 330 (check-in) + 300 (milestone) = 1,250 total, matching the hero.
- Level: Cấp 4 at 1,250 XP; Cấp 5 at 1,500 XP (inferred from "Còn 250 XP").

### 6.4 Badges and streak

- Header says "5/16" but only 8 badges are drawn. Criteria are given for almost none (§7). "Vươn cao" is awarded on the "Cao 40cm" milestone in the sample.
- Streak chip "12 ngày liên tục". Streak definition and freeze (GAM-02) are not given.

### 6.5 Anti-cheat (GAM-08)

- Big XP needs evidence: milestone XP needs a photo-confirmed check-in.
- Daily cap of 150 for ordinary activity.
- XP is computed on the server from the action time, not the device clock (plan §2.2).

### 6.6 Household permissions

| Action | Owner | Member | Source |
|---|---|---|---|
| Create household | yes (becomes Owner) | — | 03 |
| Join by code or link | — | yes (Member) | 03 |
| Invite (link, code, email, phone) | yes | not stated | HSH-01; §7 |
| Pick Owner role in invite | UI offers it | not stated | 18 (§7) |
| Share project to household | yes | not stated | HSH-03 |
| Assign task (once / series / rotation) | yes | no | 18, 19 copy |
| Done / Skip / Snooze own tasks | — | yes | HSH-02 |
| View shared projects and photos | members only | members only | req §7 |
| Activity feed | yes | yes | HSH-06 |
| Leave household | yes (Owner case open) | yes | HSH-09 |

- One household per user. No public friends or community (req §11).
- Rotation skips members who are away (HSH-07, P2).

### 6.7 Notifications

| Type | Channel | Toggle (mockup) | Notes |
|---|---|---|---|
| Task reminder | local | "Nhắc việc chăm cây" | works offline (plan §2.3) |
| Check-in reminder | local (decided in QA round 2; no `pg_cron`) | "Nhắc chụp check-in" | every 3–7 days; 09:00 on the due date, planned on the device like task reminders, so it works offline and needs no server job |
| Assignment | FCM (`send-push`) | "Được giao việc" | sent when `tasks.assignee_id` changes to someone else; accept/decline is P1 (HSH-05) |
| Achievement | FCM (`send-push`) | "Thành tích & huy hiệu" | sent on every `user_badges` insert |
| Household activity | FCM (`send-push`) | none in the UI (pref type `household_activity`, default on) | sent to the other members on every `household_activity` insert; §7 |
| Bundle | setting | "Gộp thông báo thành 1 lần/ngày" (off) | TSK-04 |
| Quiet hours | setting | "Giờ yên lặng 22:00–06:00" (P2) | SET-03 (P1). Server pushes inside the window are dropped, not queued (`docs/backend.md` §6) |

### 6.8 Formats

- Week starts Monday (T2 … CN). Dates `dd/mm/yyyy` in inputs, `13/10` in labels. Times `16:30`, `6–8h`, `22:00–06:00`. Units `300ml/chậu`, `31°C`. No currency shown.

### 6.9 Account and privacy

- Delete account and all data (ACC-05), entry on Cài đặt, label "Xóa tài khoản và toàn bộ dữ liệu".
- Location stored at region level only (ACC-03, req §7).
- Consent copy on login: "Điều khoản", "Chính sách dữ liệu", NĐ 13/2023.

---

## 7. Open gaps

The sources leave these unspecified, or they conflict. Nothing is invented above.

**Phase and naming**
1. Mockup "P2" = Phase 2 (req P1); "P3" = Phase 3 (req P2). Pick one scheme.
2. CHK-03 "Tình trạng nhanh" is badged P2, but the 14/10 decision moved CHK-03 into MVP.
3. "Chia sẻ ảnh kỷ niệm" (milestone) is unbadged, but FL puts sharing in Phase 3.
4. Web dashboard is P0 in the canvas, but plan §3 puts Web after Android.
5. "31°C nắng" on Hôm nay implies weather data in MVP, but weather is Phase 2. Data source not given.
6. ACC-04 experience is badged P2 on an MVP screen.

**Auth and onboarding**
7. No OTP code-entry screen. "Nhận mã đăng nhập" goes straight to profile.
8. No account chooser, login error, or failed-invite states.
9. Timezone (ACC-02) has no UI. Language pills are not linked to the Cài đặt "Ngôn ngữ" row.
10. "Tạo gia đình mới" goes to the invite screen. Intended flow unconfirmed.

**Plant search and enums**
11. No no-results, search-loading, or offline search state. Unaccented matching and ranking rules not given.
12. "Không phải" has no target. PLT-03 says AI creates data in the plan step, but no UI for that.
13. Location: AI doc has `rooftop`; mockup has three labels only.
14. Sunlight: AI doc uses 1–4; mockup has three buckets. Mapping not given.
15. Pot types: full list not given. Only one option visible.
16. Plant group label: "Rau thơm" appears in one kind line; FL uses "Rau-quả" and "Cây cảnh". Difficulty full range not given.
17. Stage codes (e.g. `S2_vegetative`) and start-stage codes not defined.

**Plan and tasks**
18. Duyệt plan counts do not match rows: stage 2 "5 việc" shows 3 rows, stage 3 "6 việc" shows 3, stage 4 "4 việc" shows 1. Hidden rows or wrong count.
19. Sample dates conflict: start "13/10/2026" with stage "Hạt giống", but the project shows "Ngày 38/85" on the same date.
20. Progress formula not given. 38/85 = 45% matches. Húng quế "ngày 21/60" shows 30% (21/60 = 35%).
21. Calendar bar colors: meaning not stated.
22. "Tạo lại" (PLN-06, P1): whether approved stages are kept is not stated.
23. "Bắt đầu trồng" activation rules (approval needed?) not given.
24. On-time window for "+10 XP mỗi việc đúng hạn" not defined. Late-done XP not stated.
25. Skip reason list, snooze duration and target not given.
26. Overdue (TSK-05, P1) behavior not drawn.
27. "Gợi ý từ AI" label is applied to DB-sourced steps (05). AI doc says text comes from CSDL. Labeling rule not decided.

**Check-in and AI**
28. Condition tags: FL lists "đốm"; mockup shows three.
29. Photo count: mockup says "Ảnh 1/2" and three shot types; req says "chụp hoặc tải ảnh". Required count and minimum not given.
30. Gallery upload path, permission-denied, and no-camera states not drawn.
31. Confidence band thresholds (high, medium, low) and Sonnet escalation threshold not given.
32. Blur threshold (Laplacian variance) not given.
33. Daily cap values not given. "Limit reached" UI not designed.
34. Whether a retake earns XP is not stated.
35. Change ops: AI doc has `remove`; mockup has no remove row. "ĐỔI TẦN SUẤT" op name not confirmed.
36. Problem severity scale (`sev`) not given.
37. Exact model IDs for Haiku 5.5 and Sonnet 5.5 are not confirmed in sources.
38. Check-in AI failure state and fallback not designed (plan fallback covers plan creation only).
39. "Áp dụng" always routes to the milestone screen in the mockup. Rule for when to show it not given.
40. Retention and deletion for check-in photos (beyond account deletion) not given.
41. Consent for using photos to improve the app (plan §6, NĐ 13) has no screen.
42. Note length for check-in not stated (only onboarding note is ≤ 200 characters).

**Gamification**
43. Level thresholds other than 1,250 and 1,500 not given. Level names beyond the mockup not given.
44. Badge criteria (16 total, 8 drawn) not given.
45. Project completion XP not given.
46. Whether check-in and milestone XP count toward the 150 cap is not stated.
47. Streak definition and freeze rules (GAM-02) not given.
48. "Hiện điểm & xếp hạng" has no FL id (closest GAM-09, which is P1 and about turning gamification off).

**Household**
49. Whether Members can invite is not stated. Whether an invite can grant Owner is not stated (radio offers it).
50. Owner leaving or transferring ownership not given. Removing a member not designed.
51. What happens to tasks and history when a member leaves ("giữ đúng quy định" unspecified).
52. Who can share or un-share projects not given.
53. Activity feed size and retention not given.
54. Accept, decline and "nhờ đổi" flow (HSH-05) not designed.
55. Invalid code, expired code, and "already in a household" states not designed.

**Notifications and settings**
56. Default reminder time when none is set not given.
57. Quiet hours editable? Mockup shows fixed text.
58. Household activity notification has no toggle.
59. Permission request timing screens not designed (req §7 "đúng lúc").
60. Units preference (SET-03) and timezone UI not shown.

**Quality, platform, data**
61. Minimum font size and contrast standard beyond "chữ lớn, tương phản tốt" not stated.
62. Dark mode not specified. Only two dark screens drawn.
63. Status bar and safe-area not drawn.
64. Milestone animation: plan names Rive or Lottie; mockup is static.
65. Images are placeholders with aspect ratios only.
66. Empty states not drawn: no projects, no tasks today, no household members, no activity, no search results.
67. Loading skeletons for Hôm nay (≤ 2 s on 4G, req §7) not drawn.
68. Offline and network error states not drawn (FL TSK-08 is P1).
69. Web: no login, no breakpoints below 1280 px.
70. English UI strings not drawn; schema has `name_en` and EN templates.
71. Template key composition (whether pot and watering are included) not stated.
72. `task_occurrences` and `template_stages` are proposed here, not named in sources.
73. `push_tokens`, `consents` and `devices` shapes are placeholders.
