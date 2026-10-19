# Vườn Nhà – MVP spec (Phase 1)

Derived reference for programmers. Generated 2026-10-19.

**Sources**
- `/mnt/project-files/User Requirement – App Quản lý Trồng & Chăm sóc Cây.md` (v0.1, "req")
- `/mnt/project-files/garden-app/feature-list.md` (MVP = Phase 1 section, "FL")
- `/mnt/project-files/garden-app/ai-memory-va-tiet-kiem-token.md` ("AI doc")
- `/mnt/project-files/garden-app/ke-hoach-lam-app-android.md` (build plan, milestones M0–M8, "plan")
- Mockup: Design artifact `https://claude.ai/artifact/Kn8ZdLjjXvfo3iTnaD17dK` (version 1791952697-163e, 29 screens in `project/canvas.json`, "mockup")

**Conventions**
- Vietnamese UI strings are quoted verbatim.
- Feature IDs (ACC, PRJ, PLT, PLN, CHK, TSK, GAM, HSH, SET) come from FL.
- Mockup badge "P2" means Phase 2 (req P1). Mockup badge "P3" means Phase 3 (req P2). No badge means MVP. See §7 for this naming clash.
- Sample data in the mockup (Minh, Lan, Hùng, "Cà chua bi ban công") is dummy content.
- Anything not stated in the sources is listed in §7 and not invented here.
- Suggested token and route names are proposals. They are not in the sources.

---

## 1. Design tokens

### 1.1 Color

Hex values are as they appear in the mockup. Suggested token names are proposals.

| Suggested token | Value | Used for |
|---|---|---|
| `--ink` | `#16211A` | primary text, dark pill, dark CTA ("Vào", "Gửi lời mời"), dark hero card |
| `--ink-2` | `#55625A` | secondary text, captions, inactive tab label |
| `--ink-3` | `#3B463E` | tertiary text, neutral chip text |
| `--ink-muted` | `#7D8C81` | inactive stage number dot |
| `--ink-on-dark-2` | `#B8C4BB` | secondary text on dark screens |
| `--ink-on-dark-3` | `#D2E6D8` | body text on milestone screen |
| `--green` | `#1E6B43` | brand: logo tile, avatar "M", progress fill, done check circles in plan, active tab label, link color, active stage number, "Đã xong" hint dot, "P2"-free status tags |
| `--green-hover` | `#14502F` | link hover, milestone screen background |
| `--green-tint` | `#E3EFE6` | green chips, banners, selected role/status, household illustration panel |
| `--green-tint-ink` | `#14502F` | text on green tint |
| `--green-light` | `#7FB08F` | partially complete progress segment |
| `--green-accent-dark` | `#9FD3AE` | accent on dark screens (dashed guide, "ĐẠT MỐC MỚI") |
| `--green-photo` | `#BBD8C1` | photo placeholder tiles |
| `--orange-1/2/3` | `#FF9A52` / `#F26A1B` / `#D9510A` | primary CTA gradient (see §1.2) |
| `--orange-accent` | `#F2600F` | tab underline, radio ring, selected-role ring |
| `--orange-solid-dark` | `#FF8A3D` | solid CTA and progress on dark screens, medal fill, level text |
| `--orange-tint` | `#FCEBDD` | streak chip, XP chip, leaderboard banner |
| `--orange-tint-ink` | `#9A4508` | text on orange tint |
| `--orange-chip` | `#FFE6D6` | gradient end of selected option chip |
| `--orange-text` | `#A63A00` | text of selected option chip |
| `--blue-tint` | `#E6EEFA` | "Gợi ý từ AI" chip, hint banners, "P2" tag bg |
| `--blue-ink` | `#1D4785` | text on blue tint |
| `--blue` | `#2457A6` | "P2" tag text, avatar "H", Google "G" glyph, "Vươn cao" badge |
| `--blue-tag-dark` | `#A9C4F0` | "P2" tag text on dark |
| `--warn-bg` | `#FFF4D6` | safety banner, problem card, "Tình trạng" warnings |
| `--warn-ink` | `#6B4200` / `#4D3000` | text on warn bg |
| `--warn-badge` | `#FFE7A3` | "Tin cậy trung bình" badge |
| `--danger` | `#B42318` | "Xóa tài khoản…" text, "Ảnh bị mờ, thiếu sáng" label |
| `--danger-line` | `#F1C4BF` | danger button border |
| `--line` | `#DCE3DA` | progress track, light divider |
| `--line-soft` | `#EEF1EC` | row dividers inside cards |
| `--line-dashed` | `#9AA89D` | empty checkbox ring, dashed add-photo border |
| `--toggle-off` | `#B6C1B8` | toggle off track |
| `--timeline-rail` | `#CFD8CD` | stage rail |
| `--neutral-chip` | `#F0F2EE` | neutral chip, stepper button |
| `--input-bg` | `#F8FAF7` | code-entry input |
| `--placeholder` | `#C9D3CB` | blurred photo placeholder |
| `--avatar-L` | `#C2570C` | avatar for Lan |
| `--avatar-H` | `#2457A6` | avatar for Hùng |
| `--badge-purple` | `#7A4FA0` | badge "Thợ chụp ảnh" |
| `--badge-green-2` | `#3D7A3A` | badge "Nảy mầm" |
| `--cam-bg` | `#0F1712` | check-in camera screen background |
| `--cam-preview` | `#26332A` | viewfinder, inactive shot pill |
| `--cam-chip-border` | `#3B4A40` | quick-tag chip border (camera) |
| `--hero-track` | `#2E3B32` | XP progress track on hero card |
| `--milestone-btn-line` | `#4E8A66` | "Xem thành tích" outline |
| `--pv-purple` | `#F1E8F7` / `#6A3F8F` | "P3" tag |

### 1.2 Gradients, glass, shadows, glow

- **Canvas background** (all light screens, web included):
  `radial-gradient(circle at 8% 4%, rgba(255,175,125,.55) 0, rgba(255,175,125,0) 40%)`,
  `radial-gradient(circle at 96% 30%, rgba(255,165,135,.5) 0, rgba(255,165,135,0) 42%)`,
  `radial-gradient(circle at 18% 92%, rgba(150,220,175,.55) 0, rgba(150,220,175,0) 46%)`,
  over `linear-gradient(170deg, #FBF8EF 0%, #EAF4EA 100%)`.
- **Glass ("kính mờ")**, used on cards, inputs, chips, nav bar and bottom action bars:
  - `background: rgba(255,255,255,0.62)`
  - `backdrop-filter: blur(18px) saturate(150%)` (plus `-webkit-` prefix)
  - `box-shadow: 0 8px 24px rgba(40,70,50,0.10), inset 0 1px 0 rgba(255,255,255,0.9)`
  - `border: 1px solid rgba(255,255,255,0.8)`
  - Bars use the same recipe with `border-top` only.
  - Segmented-control track: `rgba(255,255,255,0.45)`, with a glass thumb.
- **Primary orange CTA** (white text, 16px/600, height 52, radius 14):
  - `background: linear-gradient(180deg,#FF9A52 0%,#F26A1B 50%,#D9510A 100%)`
  - `box-shadow: 0 8px 22px rgba(242,96,15,0.45), 0 0 0 1px rgba(255,255,255,0.55), inset 0 1px 0 rgba(255,255,255,0.75)`
- **Selected option chip** (light, orange text, not white):
  - `background: linear-gradient(180deg,#FFFFFF 0%,#FFE6D6 100%)`
  - `border: 1px solid rgba(255,255,255,0.95)`
  - `box-shadow: 0 0 0 3px rgba(255,127,50,0.45), 0 6px 18px rgba(242,96,15,0.3), inset 0 1px 0 #FFFFFF`
  - text `#A63A00`, weight 600
- **Input focus ring** (search): `0 0 0 3px rgba(255,127,50,0.45)` with the same glow as the selected chip.
- **Blur radius:** 18px everywhere. **Saturate:** 150%.

### 1.3 Radius

| Radius | Used for |
|---|---|
| 28 | logo tile (88×88) |
| 50% | avatars, check circles, shutter, medal (150), badges (60) |
| 20 | camera viewfinder, login/consent cards, "Mã mời" card |
| 16–18 | section cards, project cards, hero card |
| 14 | primary CTA, list rows, banners, day cells |
| 12 | form inputs, secondary buttons, photo tiles |
| 10 | small buttons, icon tiles, stepper |
| 8 | checkbox (26 square), tag chips |
| 17–20 | pill chips (height 34–36), FAB pill (56 high, radius 28) |

### 1.4 Typography

- **Family:** `'Be Vietnam Pro', system-ui, sans-serif`. Loaded from Google Fonts with weights 400, 500, 600, 700.
- **Sizes used (px):** 11, 12, 13, 14, 15, 16, 17, 20, 22, 24, 26, 30, 32, 34.
  - 11: tab labels, tiny tags, badge names
  - 12: meta, captions, chip text
  - 13: secondary line, eyebrow ("Trồng cây mới · Bước 1/3"), banners
  - 14: small body, secondary buttons, field labels (500)
  - 15: list titles, section labels
  - 16: primary CTA, input text, option labels
  - 17 / 20: stat numbers
  - 22: sub-screen titles
  - 24: onboarding and task headings
  - 26: tab screen titles ("Hôm nay", "Vườn của tôi", "Cài đặt")
  - 30: login brand, web H1, milestone H1
  - 32: XP total (hero)
  - 34: invite code
- **Weights:** 700 for headings and big numbers, 600 for buttons, titles and active labels, 500 for labels and secondary text, 400 default body.
- **Letter-spacing:** brand −0.5px; uppercase section labels 0.4px; eyebrow "ĐẠT MỐC MỚI" 1px; invite code 4px; code input 1px.

### 1.5 Spacing and layout

- Mobile frame **390×844**. Web frame **1280×900** (`WebDashboard`).
- Screen side padding: **20px** on most screens. **24px** on login, onboarding profile, household setup, generating-plan, milestone.
- Vertical gaps used: 6, 8, 10, 12, 14, 16, 20, 24, 28.
- Bottom tab bar: height 76, padding `6px 4px 14px`, item min-width 64, icon 24px (stroke 2, round caps and joins), label 11px.
- Bottom action bar: padding `12px 20px 24px`, buttons 52 high.
- Input height 46–52. Chip height 34–36. Stepper button 38.
- Card padding 12–20. Nested tile padding 10–12.
- Touch targets: icon buttons 44×44.
- FAB ("+ Trồng cây mới"): right 20, bottom 96 (sits above the 76px tab bar).
- Web: left nav min-width 220 (flex-wrap), main padding 32, card grid `repeat(auto-fit, minmax(300px,1fr))`, gap 20.
- Phone-width rule: 16px side gutter is not in the mockup; mockup uses 20px. Open, see §7.

### 1.6 Icons

Inline SVG line icons, stroke 2, round caps and joins, sized 16–28px. The mockup names no icon library. Icons used: leaf (logo, Vườn tab), sun (Hôm nay), two people (Gia đình), trophy (Thành tích), gear (Cài đặt), back chevron, close X, search, plus, check, camera, gallery, help "?", GPS crosshair, flame (streak), sparkle (AI label), warning triangle, award (milestone medal), calendar chevrons, "G" glyph (Google).

### 1.7 Where each color treatment goes

- **Orange gradient + white text (primary CTA):** "Tiếp tục" (HoSo), "Nhận mã đăng nhập" (Login), "Tạo kế hoạch chăm sóc" (BoiCanh), "Bắt đầu trồng" (DuyetPlan), "Xong · +10 XP" (ChiTietTask), "Check-in ảnh" (ChiTietProject), "Chụp lại" (ChupLai), "Áp dụng N thay đổi" (CheckinKetQua), "Trồng cây mới" (FAB), "Mời" (GiaDinh), "Gửi link mời", "Giao việc" (GiaoViec).
- **Orange gradient on tiles:** completed task checkbox (Hôm nay), selected day cell (LichPlan), toggle ON track, "Check-in" banner card (Hôm nay).
- **Light orange selected chip (orange text, not white):** selected choice in onboarding, context and assignment screens, selected role, selected change-row checkbox (solid orange).
- **Green `#1E6B43`:** logo, active tab label, progress bars, avatar "M", done circles in plan steps, stage number of the expanded stage, links. Green is not used for primary CTAs (those are orange).
- **Dark screens:** camera (`CheckinChup`, bg `#0F1712`) and milestone (`Milestone`, bg `#14502F`). Dark blocks on light screens: hero card (`ThanhTich`, `#16211A`), active filter pill ("Đang trồng · 3", `#16211A`), dark "Vào" and "Gửi lời mời" buttons, web reminder banner.

---

## 2. Navigation

### 2.1 Bottom tab bar (mobile, 5 tabs)

| # | Label (verbatim) | Icon | Target screen | Active on |
|---|---|---|---|---|
| 1 | "Hôm nay" | sun (circle + rays) | Hôm nay | HomNay |
| 2 | "Vườn" | leaf | Danh sách project | DanhSachProject |
| 3 | "Gia đình" | two people | Gia đình | GiaDinh |
| 4 | "Thành tích" | trophy | Thành tích | ThanhTich |
| 5 | "Cài đặt" | gear | Cài đặt | CaiDat |

- Active: `#1E6B43`, weight 600. Inactive: `#55625A`, weight 500.
- Shown only on the five tab screens. Flow screens use a back chevron instead.

**Web left nav** (`WebDashboard`): "Hôm nay", "Vườn của tôi", "Lịch chăm sóc", "Gia đình", "Thành tích", "Cài đặt". Active item uses `#E3EFE6` bg and `#14502F` text.

### 2.2 Main flows

- **Onboarding:** Đăng nhập → Thiết lập hồ sơ ("Bước 1/2") → Thiết lập gia đình ("Bước 2/2") → Hôm nay. There is no OTP entry screen in the mockup (see §7).
- **Create project:** Vườn → "+ Trồng cây mới" → Tìm cây ("Bước 1/3") → Thông tin & bối cảnh trồng ("Bước 2/3") → AI đang tạo plan ("Bước 3/3") → Duyệt plan → "Bắt đầu trồng" → Chi tiết project.
- **Daily task:** Hôm nay → (row checkbox, or title → Chi tiết task → "Xong · +10 XP").
- **Check-in:** Chi tiết project or Hôm nay banner → Check-in chụp ảnh → Ảnh chưa đủ rõ (if rejected) → Kết quả check-in → "Áp dụng" → Chúc mừng milestone → Chi tiết project.
- **Household:** Gia đình → "Mời" → Mời thành viên; Chi tiết project or Chi tiết task → "Giao việc" → Giao việc.

### 2.3 Route names (suggested)

| Screen | Suggested route |
|---|---|
| Đăng nhập | `/login` |
| Thiết lập hồ sơ | `/onboarding/profile` |
| Thiết lập gia đình | `/onboarding/household` |
| Hôm nay | `/today` |
| Chi tiết task | `/task/:taskId` |
| Giao việc | `/task/:taskId/assign` |
| Danh sách project | `/projects` |
| Tìm cây | `/projects/new/search` |
| Thông tin & bối cảnh | `/projects/new/context?plant=:plantId` |
| AI đang tạo plan | `/projects/:projectId/generating` |
| Duyệt plan | `/projects/:projectId/plan` |
| Lịch plan | `/projects/:projectId/calendar` |
| Chi tiết project | `/projects/:projectId` |
| Check-in chụp ảnh | `/projects/:projectId/checkin` |
| Kết quả check-in | `/projects/:projectId/checkin/:checkinId` |
| Ảnh chưa đủ rõ | `/projects/:projectId/checkin/retake` |
| Chúc mừng milestone | `/projects/:projectId/milestone/:milestoneCode` |
| Gia đình | `/household` |
| Mời thành viên | `/household/invite` |
| Thành tích | `/achievements` |
| Cài đặt | `/settings` |
| Web dashboard | `/web` |

---

## 3. MVP screens

Canvas numbers match `project/canvas.json`. Each screen lists elements top to bottom. "→" marks navigation.

### 01 Đăng nhập (`/login`, `Main.dc.html`) — ACC-01

1. Background gradient; top padding 72.
2. Logo tile 88×88, radius 28, green, white leaf icon 48px.
3. H1 "Vườn Nhà" (30/700, letter-spacing −0.5).
4. Tagline "Kế hoạch chăm cây do AI lập riêng cho bạn, việc mỗi ngày rõ ràng, cả nhà cùng chăm." (16/24, `#55625A`, centered, max-width 290).
5. Glass button: blue "G" glyph + "Tiếp tục với Google" → HoSo.
6. Divider with "hoặc".
7. Label "Email", input placeholder "ban@email.com".
8. Orange CTA "Nhận mã đăng nhập" → HoSo.
9. Footer 12/18: "Tiếp tục nghĩa là bạn đồng ý với Điều khoản và Chính sách dữ liệu (theo Nghị định 13/2023/NĐ-CP)." Links "Điều khoản", "Chính sách dữ liệu".

Notes: no Apple button (decision 13/10 in FL). States: none drawn (no error, no loading, no OTP entry).

### 02 Thiết lập hồ sơ (`/onboarding/profile`, `HoSo.dc.html`) — ACC-02, ACC-03, ACC-04 (ACC-04 has the P2 badge)

1. Top row: back chevron (→ Đăng nhập), "Bước 1/2", spacer.
2. Progress: two 4px segments (green, then `#DCE3DA`).
3. H1 "Giới thiệu một chút về bạn" (24/700).
4. Sub 15/22: "Vị trí giúp AI tính khí hậu và mùa vụ. App chỉ lưu ở mức tỉnh/thành."
5. Avatar 64px circle `#E3EFE6` with initial "M" + glass button "Đổi ảnh đại diện".
6. Label "Tên hiển thị", input value "Minh".
7. Label "Bạn trồng cây ở đâu?", input "TP. Hồ Chí Minh" + 48×48 GPS button (aria "Dùng vị trí hiện tại").
8. Helper 13: "Khí hậu nhiệt đới, mùa mưa tháng 5–11".
9. Label "Kinh nghiệm trồng cây" + blue tag "Phase 2". Three options: "Mới bắt đầu" (selected by default), "Trung bình", "Thành thạo".
10. Label "Ngôn ngữ": pill "Tiếng Việt" (selected, `#16211A` bg, white text) and pill "English" (glass). Pill height 40, radius 20.
11. Orange CTA "Tiếp tục" → Thiết lập gia đình (margin-top auto).

States: none drawn. No unrecognized-location state.

### 03 Thiết lập gia đình (`/onboarding/household`, `GiaDinhSetup.dc.html`) — HSH-01, HSH-02

1. Top row: back (→ HoSo), "Bước 2/2", "Bỏ qua" (→ Hôm nay).
2. Progress: two green segments.
3. H1 "Chăm cây cùng người nhà?" (24/700).
4. Sub 15/22: "Tạo gia đình để giao việc tưới, bón cho từng người và xem ai đã làm gì. Bạn có thể làm việc này sau."
5. Illustration panel 180 high, `#E3EFE6`, three overlapping 64px avatars: "M" (green), "L" (`#C2570C`), "H" (`#2457A6`), each with 3px `#E3EFE6` border.
6. Glass option card: icon tile 44 + "Tạo gia đình mới" / "Bạn là chủ nhà (Owner)" → Mời thành viên.
7. Glass card: label "Tham gia bằng mã mời" (16/600), note "Bạn sẽ là thành viên (Member)", input placeholder "VD: VUON-4821" (`#F8FAF7` bg, letter-spacing 1px), dark button "Vào" (→ Hôm nay).
8. Footer 13/19: "Mỗi người chỉ ở trong một gia đình. App không có kết bạn công khai."

States: none drawn (no invalid-code state).

### 04 Hôm nay (`/today`, `HomNay.dc.html`) — TSK-01, TSK-02, CHK-01 (tab 1)

1. Header row: eyebrow "Thứ Ba, 13/10 · 31°C nắng" (13/500 `#55625A`); H1 "Hôm nay" (26/700).
2. Right chips: streak chip with flame icon "12 ngày" (`#FCEBDD`, `#9A4508`); XP chip "{xp} XP" (`#E3EFE6`, `#14502F`). Sample XP = 1240 + 10 × done.
3. Progress row: "Đã xong {done}/{total} việc" (left), "+10 XP mỗi việc đúng hạn" (right). Bar 8px `#DCE3DA` with green fill.
4. Check-in banner (orange CTA card, radius 16, padding 14): camera tile, "Đến hạn chụp ảnh check-in" (15/600), "Cà chua bi ban công · +30 XP" (13, white 92%), chevron → Check-in chụp ảnh.
5. Segmented control: "Theo khung giờ" (selected) | "Theo project".
6. Group header (13/600 uppercase `#55625A`): "Sáng sớm · 6–8h", then "Chiều mát · 16–18h".
7. Task row (glass, radius 14, padding 10/12):
   - Checkbox 32px: unchecked = 2px ring `#9AA89D`. Checked = orange gradient disc with white check. Labels: "Đánh dấu xong" / "Bỏ đánh dấu xong".
   - Title (15/600) → Chi tiết task. Meta line (13): project name and tag, e.g. "Cà chua bi ban công · Hữu cơ".
   - Right: 28px assignee avatar with initial (color by person).
8. Tab bar (Hôm nay active).

Sample tasks: "Tưới nước 300ml/chậu" (Minh), "Xoay chậu về phía sáng" (Minh), "Bón phân trùn quế" (Lan), "Kiểm tra mặt dưới lá" (Hùng), "Tưới phun sương" (Hùng).

States: none drawn (no empty day, no loading, no offline indicator). Row shows only the checkbox; Skip and Snooze appear only on the detail screen.

### 05 Chi tiết task (`/task/:taskId`, `ChiTietTask.dc.html`) — TSK-02, PLN-03, PLN-05, PLN-09 (TSK-03 "Thêm ảnh" has P2 badge)

1. Top row: back (→ Hôm nay), glass button "Sửa task".
2. Eyebrow "Cà chua bi ban công · Giai đoạn Sinh trưởng"; H1 "Bón phân trùn quế" (24/700).
3. Three info tiles (label 12 `#55625A`, value 14/600): "Khung giờ" → "Chiều mát"; "Lặp lại" → "14 ngày/lần"; "Nhắc lúc" → "16:30".
4. Assignee row: avatar "L" (`#C2570C`), "Giao cho **Lan**", link "Đổi" (→ Giao việc).
5. Card "Cách làm" with badge "Gợi ý từ AI · tin cậy cao" (blue, sparkle icon). Numbered steps:
   1. "Rải 1 nắm tay phân trùn quế quanh gốc, cách thân 5cm."
   2. "Xới nhẹ lớp đất mặt cho phân trộn đều."
   3. "Tưới đẫm nước sau khi bón."
   Then "**Vì sao?** Cây đang ra nhiều lá, cần đạm và vi sinh để chuẩn bị ra hoa." Then source line (12): "Nguồn: CSDL cây Vườn Nhà (312 đợt trồng thực tế)".
6. Safety banner (`#FFF4D6`, 13/19): "Nếu dùng phân bón đóng gói, làm theo liều trên nhãn sản phẩm. App không đưa liều hóa chất cụ thể."
7. Glass button "Thêm ảnh" with P2 badge.
8. Bottom bar: "Bỏ qua" (width 72), "Dời lại" (width 72), orange "Xong · +10 XP" with check icon (flex-grow).

States: none drawn. No skip-reason sheet, no snooze picker.

### 06 Danh sách project — "Vườn của tôi" (`/projects`, `DanhSachProject.dc.html`) — PRJ-01, PRJ-04 (PRJ-05 hint has P2) (tab 2)

1. Header: H1 "Vườn của tôi" (26/700); search button 44 (aria "Tìm project").
2. Chips: "Đang trồng · 3" (dark `#16211A`, white text), "Đã xong · 1" (glass), "Lưu trữ" (glass).
3. Project card (glass, radius 18, padding 12, gap 12):
   - Cover tile 88×104, radius 12, tinted by project, with leaf icon and caption "Ảnh mới nhất".
   - Name (16/600). Kind line (13 `#55625A`): "Rau quả · 4 chậu · ngày 38".
   - Stage line (13) with 8px dot: "Sinh trưởng · sắp ra hoa" (dot green) or "Cây con · cần check-in" (dot `#C2570C`).
   - Progress bar 6px: 45%, 30%, 70%.
   - Footer (12): "3 việc hôm nay" (left), "Ảnh: 2 ngày trước" (right).
4. Blue hint banner: "Vuốt sang trái để lưu trữ, nhân bản hoặc xóa project (Phase 2)."
5. FAB pill "+ Trồng cây mới" → Tìm cây.
6. Tab bar (Vườn active).

Sample projects: "Cà chua bi ban công", "Húng quế sân thượng" (Rau thơm · 6 chậu · ngày 21), "Trầu bà phòng khách" (Cây cảnh trong nhà · 1 chậu).

States: none drawn (no empty list, no "Đã xong" or "Lưu trữ" content).

### 07 Tìm cây (`/projects/new/search`, `TimCay.dc.html`) — PLT-01, PLT-02, PLT-03 (warning card has P2 label; PLT-05)

1. Top row: close X (→ Danh sách project), eyebrow "Trồng cây mới · Bước 1/3", H1 "Bạn muốn trồng cây gì?" (22/700).
2. Search field, height 52, radius 14, focus glow. Magnifier icon, input value "ca chua" (aria "Tên cây").
3. Filter chips: "Tất cả" (dark, active), "Rau & quả", "Cây cảnh trong nhà".
4. Count 13: "3 kết quả cho “cà chua”".
5. Result cards (glass, radius 16, padding 10). Each: 64px image tile ("Ảnh"), name (15/600), scientific name (12 italic), chips "Dễ" / "Trung bình" (green tint) and "Thu hoạch ~75 ngày" (neutral). → Thông tin & bối cảnh.
   - "Cà chua bi" · *Solanum lycopersicum var. cerasiforme* · Dễ · ~75 ngày
   - "Cà chua thường" · *Solanum lycopersicum* · Trung bình · ~90 ngày
   - "Cà chua cherry vàng" · *Solanum lycopersicum* · Dễ · ~70 ngày
6. Blue card: "Không thấy cây bạn cần?" then "Bạn gõ “ca chua tim”. Có phải bạn muốn nói **Cà chua tím (Indigo Rose)**?" Buttons "Đúng rồi" (blue solid → Thông tin & bối cảnh) and "Không phải" (outline, no target shown).
7. Warn card (`#FFF4D6`) with P2 label: "**Phase 2:** lá và thân cà chua có độc nhẹ với chó mèo. Cảnh báo này hiện khi bạn khai báo có thú cưng."

States: none drawn. No no-results state, no loading, no free-text AI creation state (PLT-03 says AI creates data in the plan step).

### 08 Thông tin & bối cảnh trồng (`/projects/new/context`, `BoiCanh.dc.html`) — PRJ-02, PRJ-03

1. Top row: back (→ Tìm cây), eyebrow "Trồng cây mới · Bước 2/3", H1 "Cà chua bi trồng ở đâu?" (22/700).
2. Label "Tên project", input "Cà chua bi ban công – 10/2026".
3. Two columns: "Ngày bắt đầu" (input "13/10/2026") | "Số chậu" stepper (− 4 +).
4. "Bắt đầu từ": "Hạt giống" (selected) | "Cây con" | "Trưởng thành".
5. "Nơi trồng": "Trong nhà" | "Ban công" (selected) | "Sân vườn".
6. "Nắng mỗi ngày": "Dưới 3 giờ" | "3–6 giờ" (selected) | "Trên 6 giờ".
7. Two columns: "Chậu / đất" select → "Chậu nhựa 20L, đất trộn" | "Cách tưới" select → "Tưới tay".
8. Dashed row: 44 icon tile + "Thêm ảnh bìa (không bắt buộc)".
9. Bottom glass bar: orange CTA with sparkle icon "Tạo kế hoạch chăm sóc" → AI đang tạo plan.

States: none. No validation message.

### 09 AI đang tạo plan (`/projects/:projectId/generating`, `TaoPlan.dc.html`) — PLN-01

1. Eyebrow centered "Trồng cây mới · Bước 3/3".
2. Spinner: 140 circle `#E3EFE6`, inner 112 ring (6px white, two green arcs), sparkle icon.
3. H1 centered "Đang lập kế hoạch cho" + line break + "Cà chua bi ban công" (24/700).
4. "Thường mất dưới 20 giây" (14 `#55625A`).
5. Step card (glass, padding 18, gap 14). Each step: check disc 26 (green, white check) or dashed 2px ring (pending); title 15/600; subtitle 13:
   - ✓ "Đọc dữ liệu chuẩn cà chua bi" / "Từ cơ sở dữ liệu cây Vườn Nhà"
   - ✓ "Tính khí hậu TP. Hồ Chí Minh" / "Tháng 10, cuối mùa mưa, 26–33°C"
   - ✓ "Chia giai đoạn và mốc" / "6 giai đoạn, khoảng 85 ngày"
   - ○ "Tạo việc chăm sóc hằng ngày" / "Theo khung giờ sáng sớm / chiều mát"
6. Note 13 centered: "Nếu AI gặp sự cố, app dùng plan mẫu cho cà chua bi để bạn bắt đầu ngay."
7. Orange CTA "Xem kế hoạch" → Duyệt plan.

States: loading (this screen is the loading state). Error path is described in copy only. The CTA is shown during loading in the mockup (see §7).

### 10 Duyệt plan (`/projects/:projectId/plan`, `DuyetPlan.dc.html`) — PLN-02, PLN-03, PLN-05, PLN-07, PLN-09; PLN-06 "Tạo lại" has P2 badge

1. Top row: back (→ Thông tin & bối cảnh), H1 "Kế hoạch 85 ngày" (22/700).
2. Chips: "Gợi ý từ AI" (blue, sparkle), "Tin cậy cao · 86%" (green tint), "Nguồn: CSDL cây + 2 tài liệu" (glass).
3. Segmented: "Giai đoạn" (selected) | "Lịch" (→ Lịch plan).
4. Stage timeline (rail 2px `#CFD8CD`). Each stage row:
   - Number disc 28: green when expanded, `#7D8C81` otherwise.
   - Name (15/600), subline (12): "Ngày 1–7 · Mốc: Nảy mầm", right "3 việc".
   - Tap toggles expansion. Expanded: glass card with task rows (name 13 left, frequency 13 `#55625A` right), then "+ Thêm việc" (green, 13/600).
5. Bottom glass bar: "Tạo lại" with P2 badge (glass, flex 1) and orange "Bắt đầu trồng" (flex 2 → Chi tiết project).

Stages (sample tomato plan):
- 1 "Ươm hạt", Ngày 1–7, mốc "Nảy mầm", 3 việc: "Ngâm hạt nước ấm 4 giờ" (Một lần), "Gieo hạt vào khay ươm" (Một lần), "Phun ẩm khay ươm" (Sáng sớm, hằng ngày).
- 2 "Cây con", Ngày 8–25, mốc "Ra lá thật", 5 việc: "Tưới gốc" (Sáng sớm, 2 ngày/lần), "Chuyển sang chậu 20L" (Ngày 20), "Check-in ảnh" (5 ngày/lần).
- 3 "Sinh trưởng", Ngày 26–45, mốc "Cao 40cm", 6 việc: "Cắm cọc, buộc dây" (Một lần), "Bón phân trùn quế" (14 ngày/lần), "Tỉa chồi nách" (7 ngày/lần).
- 4 "Ra hoa", Ngày 46–60, mốc "Ra hoa", 4 việc: "Lắc nhẹ cây hỗ trợ thụ phấn" (Sáng, hằng ngày).
- 5 "Đậu quả", Ngày 61–75, mốc "Đậu quả", 4 việc: "Bổ sung vỏ trứng nghiền" (Một lần).
- 6 "Thu hoạch", Ngày 76–85, mốc "Thu hoạch", 2 việc: "Hái quả chín đỏ" (2 ngày/lần).

States: none drawn. The mockup code expands stage 1 by default; only one stage is expanded at a time.

### 11 Lịch plan (`/projects/:projectId/calendar`, `LichPlan.dc.html`) — PLN-04, PLN-05

1. Top row: back (→ Chi tiết project), eyebrow with project name "Cà chua bi ban công", H1 "Lịch chăm sóc" (22/700).
2. Segmented: "Giai đoạn" (→ Duyệt plan) | "Lịch" (selected).
3. Week row: "Tuần 12–18/10" (16/600), glass buttons 40 with aria "Tuần trước" / "Tuần sau".
4. Seven day cells (height 64, radius 14, gap 4): weekday (11), date (17/700), count "N việc" (10). Selected: orange gradient, white text. Others: glass.
5. Stage banner (`#E3EFE6`, height 30, 12/600): "Giai đoạn 3 · Sinh trưởng (ngày 26–45) · còn 7 ngày".
6. Day label (15/600), e.g. "Thứ Ba, 13/10".
7. Task rows (glass, radius 14): time label (64 wide, 12/600): "Sáng sớm", "Chiều mát", "Cả ngày"; 3px color bar (meaning not stated); title (15/600); meta (12): "300ml/chậu · Minh", "14 ngày/lần · Lan", "5 ngày/lần · +30 XP". → Chi tiết task.
8. Dashed orange button "+ Thêm việc thủ công".

Sample task counts by day: 12 → 1, 13 → 3, 14 → 2, 15 → 1, 16 → 2, 17 → 1, 18 → 2.

States: no empty-day state drawn.

### 12 Chi tiết project (`/projects/:projectId`, `ChiTietProject.dc.html`) — PRJ-06, TSK-06, HSH-03 (menu items PRJ-05/PRJ-07 are P2)

1. Cover area 180 high, `#F6DED3`, placeholder "[Ảnh bìa project]". Round glass back button (top-left, 44) and round glass "more" button (top-right, 44; aria "Thêm tùy chọn: lưu trữ, nhân bản, kết thúc project").
2. H1 "Cà chua bi ban công" (22/700). Meta (13): "Rau quả · 4 chậu · Ban công 3–6 giờ nắng · Chia sẻ với gia đình".
3. Tabs (14px, underline 3px `#F2600F` on active): "Tổng quan" (active), "Plan" (→ Duyệt plan), "Lịch" (→ Lịch plan), "Ảnh" (→ Timeline ảnh, P2), "Thành viên" (→ Gia đình).
4. Stage card (glass): "Giai đoạn 3/6 · Sinh trưởng" (left), "Ngày 38/85" (right). Six-segment bar (2 green, 1 `#7FB08F`, 3 `#DCE3DA`). "Mốc tiếp theo: **Ra hoa**, dự kiến khoảng 22/10".
5. Three stat tiles: "92%" / "việc đúng hạn"; "7" / "lần check-in"; "2/6" / "mốc đã đạt".
6. "Ảnh tăng trưởng" (15/600) with "Xem tất cả" (→ Timeline, P2). Four photo tiles (square, radius 10), labels "Ngày 5", "Ngày 15", "Ngày 26", "Ngày 36".
7. "Lịch sử gần đây" (15/600). Rows with 26px avatar, text and time:
   - "**Lan** tỉa chồi nách" · "Hôm qua, 17:10"
   - "**Minh** check-in ảnh" · "11/10, 07:02"
8. Bottom glass bar: "Giao việc" (outline, flex 1 → Giao việc) and orange "Check-in ảnh" with camera icon (flex 2 → Check-in chụp ảnh).

States: none drawn. Task history is shown as the last two events only (the "TSK-06" log is not visible as a full list).

### 13 Check-in: chụp ảnh (`/projects/:projectId/checkin`, `CheckinChup.dc.html`) — CHK-02, CHK-03, CHK-01 (quick-tag row has P2 badge in mockup)

Dark screen, background `#0F1712`.

1. Top bar: close X (→ Chi tiết project, aria "Đóng"); center "Check-in · Cà chua bi" (15/600) with "Ảnh 1/2 · Toàn cây" (12 `#B8C4BB`); flash button (aria "Bật đèn flash").
2. Viewfinder: 470 high, radius 20, `#26332A`, margin 8/16. Dashed guide oval 230×360 (2px dashed `#9FD3AE`, radius 120 120 24 24) with caption "Đặt cả cây trong khung". Corner label "[Khung camera]" (placeholder for live preview). Bottom pill "Ánh sáng tốt · Đủ nét" (`#1E6B43`, 12/600).
3. Shot pills (height 34, radius 17): "1 · Toàn cây" (glass, active), "2 · Cận lá", "Mặt dưới lá" (`#26332A`).
4. Quick-tag row (12 `#B8C4BB`): "Tình trạng nhanh" + P2 badge, then chips (border `#3B4A40`, white text): "Lá vàng", "Héo", "Có sâu". The requirement also lists "đốm" (see §7).
5. Shutter row (padding `0 36px 40px`): gallery button 52 (aria "Chọn từ thư viện ảnh"), shutter ring 78 (4px white border, 60px white disc → Kết quả check-in), help button 52 circle "?" (aria "Xem mẹo chụp" → Ảnh chưa đủ rõ).

States: none drawn. No permission-denied state, no retake of a shot in progress.

### 14 Kết quả check-in (`/projects/:projectId/checkin/:checkinId`, `CheckinKetQua.dc.html`) — CHK-04, CHK-05, AI-02, AI-07 (GAM-08 wording "+30 XP")

1. Header: back (→ Check-in), H1 "Kết quả check-in" (22/700, flex-grow), chip "+30 XP" (`#FCEBDD`, `#9A4508`).
2. Summary card (glass): 84px thumbnail "Ảnh ngày 38"; blue chip "Gợi ý từ AI"; "**Giai đoạn:** cuối Sinh trưởng, sắp ra hoa *(82%)*"; "**Sức khỏe:** Tốt" (green, 600).
3. Problem card (`#FFF4D6`): title "Nghi thiếu canxi nhẹ" (14/600) with badge "Tin cậy trung bình · 58%" (`#FFE7A3`). Body 13/19: "Mép lá non hơi vàng. Có thể do tưới không đều trong đợt nắng gần đây."
4. Green note (`#E3EFE6`): check icon + "Ảnh xác nhận đạt mốc **Cao 40cm**".
5. "Đề xuất điều chỉnh plan" (15/600). Change rows (glass, radius 14): checkbox 26 square (orange when selected, 2px ring when not), kind label (11/700 uppercase `#55625A`), title (14/600), reason (12 `#55625A`):
   - "THÊM VIỆC" · "Rải vỏ trứng nghiền quanh gốc" · "Bổ sung canxi tự nhiên, an toàn"
   - "ĐỔI TẦN SUẤT" · "Tưới: 2 ngày/lần → hằng ngày" · "Giữ ẩm đều trong đợt nắng 33°C"
   - "DỜI MỐC" · "Ra hoa: 22/10 → 20/10" · "Cây phát triển nhanh hơn dự kiến"
6. Feedback row: "Kết quả này có hữu ích?" with buttons "Có", "Không" (AI-07).
7. Bottom glass bar: "Để sau" (outline, flex 1 → Chi tiết project), orange "Áp dụng {count} thay đổi" (flex 2, count = selected rows → Chúc mừng milestone).

States: none drawn. Note: the mockup routes "Áp dụng" to the milestone screen unconditionally (see §7).

### 15 Ảnh chưa đủ rõ (`/projects/:projectId/checkin/retake`, `ChupLai.dc.html`) — CHK-06

1. Top row: back (→ Check-in), H1 "Cần chụp lại" (22/700).
2. Photo preview 260 high, radius 20, `#C9D3CB`, blurred oval placeholder, label chip (glass, `#B42318`): "Ảnh bị mờ, thiếu sáng".
3. "AI chưa đủ thông tin để đánh giá" (16/600). Body (14/21): "Để tránh đoán sai, bạn chụp lại giúp mình nhé. Lần chụp này chưa tính vào lượt phân tích trong ngày."
4. Tips card: "Mẹo chụp rõ" (15/600) and three rows with green icon tiles (32):
   - "Chụp ban ngày, tránh ngược sáng"
   - "Giữ máy cách cây 40–60cm, chạm để lấy nét"
   - "Thêm 1 ảnh cận lá có dấu hiệu lạ"
5. Orange CTA "Chụp lại" with camera icon → Check-in chụp ảnh.

States: this screen is the retake error state.

### 16 Chúc mừng milestone (`/projects/:projectId/milestone/:milestoneCode`, `Milestone.dc.html`) — GAM-03, GAM-04, GAM-01

Dark screen, background `#14502F`.

1. Decorative shapes (orange `#FF8A3D`, light green `#9FD3AE`, glass squares), absolutely positioned.
2. Close X (→ Chi tiết project).
3. Eyebrow "ĐẠT MỐC MỚI" (14/600, `#9FD3AE`, letter-spacing 1).
4. Medal 150px circle `#FF8A3D`, white award icon, 12px ring `rgba(255,138,61,0.25)`.
5. H1 "Cao 40cm rồi!" (30/700, centered).
6. Body (15/22 `#D2E6D8`): "Cà chua bi ban công đã qua mốc thứ 3. Ảnh check-in hôm nay đã xác nhận."
7. Reward tiles (`#1E6B43`): "+100 XP" (20/700, `#FF8A3D`) with "Milestone" (12); "Huy hiệu" (20/700) with "“Vươn cao”" (12).
8. Keepsake card (glass): 64px thumbnail "Ảnh kỷ niệm"; "Thẻ kỷ niệm ngày 38" (14/600); "Ảnh trước–sau, có thể chia sẻ" (12).
9. Buttons: "Chia sẻ ảnh kỷ niệm" (solid `#FF8A3D`, white 16/700, height 52); "Xem thành tích" (outline `#4E8A66`, → Thành tích).

States: none.

### 17 Gia đình (`/household`, `GiaDinh.dc.html`) — HSH-02, HSH-03, HSH-06 (leaderboard banner and "đang vắng nhà" are P2) (tab 3)

1. Header: eyebrow "Gia đình · 3 người", H1 "Nhà mình" (26/700), orange pill "Mời" with plus icon (height 44 → Mời thành viên).
2. Member card (glass): rows with 40px avatar (initial, color), name (15/600) and sub (12), role chip (Owner: `#E3EFE6` / `#14502F`; Member: `#F0F2EE` / `#3B463E`):
   - "Minh (bạn)" · "5 việc tuần này" · Owner
   - "Lan" · "8 việc tuần này" · Member
   - "Hùng" · "3 việc tuần này · đang vắng nhà" · Member
3. "Project chia sẻ" (15/600), chips (height 34, glass): "Cà chua bi ban công", "Húng quế sân thượng", dashed "+ Chia sẻ thêm".
4. Leaderboard banner (`#FCEBDD`, `#4D2304`): "**Lan** đang dẫn đầu tuần này · 340 XP" with P2 badge (→ Xếp hạng).
5. "Hoạt động" (15/600) feed rows (26px avatar, "**who** what", time 12):
   - "Lan đã tỉa chồi nách · Cà chua bi" · 17:10
   - "Hùng đã tưới phun sương · Húng quế" · 16:45
   - "Minh giao “Bón phân trùn quế” cho Lan" · 09:02
   - "Minh đạt mốc Cao 40cm · Cà chua bi" · 07:05
6. Tab bar (Gia đình active).

States: none drawn.

### 18 Mời thành viên (`/household/invite`, `MoiThanhVien.dc.html`) — HSH-01, HSH-02

1. Top row: back (→ Gia đình), H1 "Mời người nhà" (22/700).
2. Code card (glass, radius 20, centered): "Mã mời của Nhà mình" (13), "VUON-4821" (34/700, letter-spacing 4), "Hết hạn sau 7 ngày" (12). Buttons: "Sao chép mã" (glass), "Gửi link mời" (orange).
3. Divider "hoặc mời trực tiếp".
4. Label "Số điện thoại hoặc email", input placeholder "09xx xxx xxx".
5. "Vai trò" (14/500). Radio cards:
   - "Member" (selected; orange ring and light orange gradient) · "Làm việc được giao, xem project được chia sẻ"
   - "Owner" · "Quản lý thành viên, project và giao việc"
6. Dark CTA "Gửi lời mời" (→ Gia đình).

States: none (no sent confirmation, no invalid-contact state).

### 19 Giao việc (`/task/:taskId/assign`, `GiaoViec.dc.html`) — HSH-04; HSH-05 note P2; HSH-07 "vắng nhà" P2

1. Top row: back (→ Chi tiết task), H1 "Giao việc" (22/700).
2. Summary card: 40 tile (`#E6EEFA`, icon), "Tưới gốc 300ml/chậu" (15/600), "Cà chua bi ban công · Sáng sớm · 2 ngày/lần" (12).
3. "Cách giao" (14/600), three options (height 64): "Chỉ lần này", "Cả chuỗi lặp", "Xoay vòng" (default, selected).
4. Label: "Thứ tự xoay vòng" in rotation mode, "Giao cho" in single modes.
5. People rows (glass buttons): 36px avatar, name (15/600), sub (12):
   - "Minh (bạn)" · "5 việc tuần này"
   - "Lan" · "8 việc tuần này"
   - "Hùng" · "Vắng nhà đến 20/10"
   Right marker: green disc 26 with order number (rotation) or "✓" (single); empty 2px ring when not selected.
6. Hint banner (blue, 13/19), depends on mode:
   - Rotation: "Xoay vòng: {names joined with →} → lặp lại. Người vắng nhà được bỏ qua tự động."
   - Series: "Mọi lần tưới tiếp theo sẽ giao cho {name}."
   - Once: "Chỉ lần tưới sáng 14/10 giao cho {name}."
7. Note row: P2 badge + "Người được giao có thể nhận, từ chối hoặc nhờ đổi."
8. Orange CTA "Giao việc" (→ Gia đình).

States: none.

### 20 Thành tích (`/achievements`, `ThanhTich.dc.html`) — GAM-01, GAM-04, GAM-08; level naming P2 (tab 4)

1. H1 "Thành tích" (26/700).
2. Hero card (`#16211A`, radius 18, padding 16):
   - "Tổng điểm" (13 `#B8C4BB`), "1.250 XP" (32/700).
   - Right: "Level · P2" tag (`#2E3B32` bg, `#A9C4F0` text), "Cấp 4 · Người chăm chỉ" (15/600, `#FF8A3D`).
   - Progress 8px track `#2E3B32`, fill `#FF8A3D` 62%.
   - "Còn 250 XP để lên Cấp 5 · Thợ vườn" (12 `#B8C4BB`).
3. Stat tiles 2×2 (glass, radius 14): "Việc đúng hạn" / "+620 XP"; "Check-in ảnh" / "+330 XP"; "Đạt milestone" / "+300 XP"; "Hôm nay" / "60/150 XP".
4. Blue banner: "Mỗi ngày tối đa 150 XP từ việc thường. Điểm milestone chỉ cộng khi có ảnh check-in xác nhận."
5. Row: "Huy hiệu · 5/16" (15/600) and link "Xếp hạng nhà" (→ Xếp hạng, P2).
6. Badge grid, four columns, eight shown (60px disc + name 11):
   - Earned (colored disc): "Hạt giống đầu tiên" (`#1E6B43`), "Nảy mầm" (`#3D7A3A`), "7 ngày liên tục" (`#C2570C`), "Vươn cao" (`#2457A6`), "Thợ chụp ảnh" (`#7A4FA0`).
   - Locked (dashed `#B6C1B8` ring, grey icon): "Ra hoa", "Thu hoạch đầu tiên", "30 ngày liên tục".
7. Tab bar (Thành tích active).

States: locked badges are the empty state for achievements.

### 21 Cài đặt (`/settings`, `CaiDat.dc.html`) — SET-01, SET-02, ACC-05, HSH-09, TSK-04 (tab 5)

1. H1 "Cài đặt" (26/700).
2. Profile card (glass): 44 avatar "M", "Minh" (15/600), "TP. Hồ Chí Minh · Tiếng Việt" (12), link "Sửa" (→ Thiết lập hồ sơ).
3. Section label "THÔNG BÁO" (12/600 uppercase). Toggle rows (48 high, 14px label, divider). Toggle 46×28:
   - "Nhắc việc chăm cây": ON
   - "Nhắc chụp check-in": ON
   - "Được giao việc": ON
   - "Thành tích & huy hiệu": ON
   - "Gộp thông báo thành 1 lần/ngày": OFF
   - "Hiện điểm & xếp hạng": ON (P2 badge)
   - "Giờ yên lặng" · "22:00–06:00" (P2 badge; not a toggle in the mockup)
4. Section label "KHÁC". Rows:
   - "Ngôn ngữ" · "Tiếng Việt" (value only)
   - "Chế độ vắng nhà" (P2 badge → Thời tiết & vắng nhà)
   - "Thiết bị & cảm biến" (P3 badge, `#F1E8F7` / `#6A3F8F` → Thiết bị)
   - "Rời gia đình “Nhà mình”"
5. Outline danger button (border `#F1C4BF`, text `#B42318`, 14/600): "Xóa tài khoản và toàn bộ dữ liệu".
6. Tab bar (Cài đặt active).

States: none.

### 29 Web – Bảng điều khiển (`/web`, `WebDashboard.dc.html`, 1280×900) — P0 per canvas; FL §10 real-time sync

1. Left nav (glass): logo tile 36 green with leaf icon + "Vườn Nhà" (18/700); six items (height 42, radius 10): "Hôm nay" (active), "Vườn của tôi", "Lịch chăm sóc", "Gia đình", "Thành tích", "Cài đặt".
2. Header: eyebrow "Thứ Ba, 13/10 · TP. Hồ Chí Minh 31°C"; H1 "Chào Minh, hôm nay có 5 việc" (30/700); chips "12 ngày liên tục" (orange tint), "1.250 XP" (green tint); orange CTA "+ Trồng cây mới" (→ Tìm cây).
3. Three cards in an auto-fit grid (min 300):
   - "Việc hôm nay" (17/600): five rows with status disc (green check or 2px ring), title (14/600), meta (12), owner name (12). Samples: "Tưới nước 300ml/chậu" (Minh, done), "Xoay chậu về phía sáng" (Minh), "Bón phân trùn quế" (Lan), "Kiểm tra mặt dưới lá" (Hùng), "Tưới phun sương" (Hùng, done).
   - "Vườn đang trồng": three rows with a 56px tinted tile, name, stage, progress bar.
   - "Nhà mình hôm nay": three activity rows (26px avatar, text, time) and a dark banner: "Đến hạn check-in ảnh: Húng quế sân thượng" with "Chụp trên điện thoại".

States: none drawn.

**Not in the MVP set (out of scope here):** 22 Xếp hạng & streak (P2), 24 Timeline ảnh (P2), 25 Thời tiết & vắng nhà (P2), 27 Cây ảo (P3), 28 Thiết bị & cảm biến (P3), 30 Thêm widget (P3), 31 Widget trên màn hình chính (P3).

---

## 4. Data model

Tables and enums are derived from req §8, FL, AI doc and plan §2. Where the sources only give examples, the field is marked "example". Column names are proposals.

### 4.1 Enums

| Enum | Values (code) | Labels in sources | Source |
|---|---|---|---|
| `space` (location) | `indoor`, `balcony`, `yard`, `rooftop` | "Trong nhà", "Ban công", "Sân vườn" | AI doc; mockup (rooftop has no label, see §7) |
| `sun_level` | `1`–`4` | "Dưới 3 giờ", "3–6 giờ", "Trên 6 giờ" (3 options in mockup) | AI doc (scale), mockup (labels); mapping not given |
| `pot_type` | example `plastic_20cm` | "Chậu nhựa 20L, đất trộn" | AI doc example; mockup label |
| `watering` | `manual`, `auto` | "Tưới tay" (mockup) | FL PRJ-03 ("tay/tự động"); AI doc example `manual` |
| `start_stage` | `seed`, `seedling`, `mature` (proposed) | "Hạt giống", "Cây con", "Trưởng thành" | FL PRJ-02; mockup |
| `experience` | `new`, `mid`, `pro` | "Mới bắt đầu", "Trung bình", "Thành thạo" | AI doc; mockup |
| `time_budget` | `<10p`, `10–30p`, `>30p` | not shown in mockup | AI doc |
| `lang` | `vi`, `en` | "Tiếng Việt", "English" | FL SET-02; mockup |
| `plant_group` | `rau_qua`, `cay_canh` | "Rau & quả", "Cây cảnh trong nhà" | req §11; mockup filters |
| `difficulty` | e.g. `easy`, `medium` | "Dễ", "Trung bình" | mockup (full range not given) |
| `condition_tag` (CHK-03) | `LEAF_YELLOW`, `WILT`, `PESTS`, `SPOTS` (proposed codes) | "Lá vàng", "Héo", "Có sâu", "Đốm" in FL; mockup shows first three | FL CHK-03 |
| `shot` | `whole_plant`, `close_leaf`, `leaf_underside` | "Toàn cây", "Cận lá", "Mặt dưới lá" | mockup |
| `task_window` | `morning`, `afternoon`, `all_day` | "Sáng sớm · 6–8h", "Chiều mát · 16–18h", "Cả ngày" | AI doc (`morning`); mockup |
| `frequency` | `once`, `every_n_days`, `daily`, `fixed_date` | "Một lần", "N ngày/lần", "hằng ngày", "Ngày 20" | mockup |
| `assignment_mode` | `once`, `series`, `rotation` | "Chỉ lần này", "Cả chuỗi lặp", "Xoay vòng" | mockup; FL HSH-04 |
| `task_action` | `done`, `skip`, `snooze` | "Xong", "Bỏ qua", "Dời lại" | FL TSK-02 |
| `role` | `owner`, `member` | "Owner", "Member" | FL HSH-02 |
| `project_status` | `active`, `done`, `failed`, `archived` | "Đang trồng", "Đã xong", "Lưu trữ" | mockup; FL PRJ-07 (done/failed are P1) |
| `change_kind` | `add`, `remove`, `shift` (+ frequency change) | "THÊM VIỆC", "ĐỔI TẦN SUẤT", "DỜI MỐC" | AI doc (add/remove/shift); mockup labels |
| `health` | `good`, … | "Tốt" | AI doc (`good`); other values not given |
| `trend` | `better`, … | not shown | AI doc |
| `confidence_band` | high / medium / low (thresholds open) | "Tin cậy cao · 86%", "Tin cậy trung bình · 58%" | mockup |
| `plan_source` | `template`, `ai`, `fallback` (proposed) | "Gợi ý từ AI" label | AI doc; plan §2.1 |
| `reason_code` | `R_HOT_SEASON`, … | not shown | AI doc example |
| `problem_code` | `P_YELLOW_LEAF_OVERWATER`, `P_APHID`, `P_ROOT_ROT`, … | "Nghi thiếu canxi nhẹ" (no code shown) | AI doc examples |
| `task_code` | `T_WATER`, `T_FERT_ORGANIC`, `T_PRUNE`, … | task names in mockup (no codes shown) | AI doc examples |
| `milestone_code` | proposed: `SPROUT`, `TRUE_LEAVES`, `HEIGHT_40`, `FLOWER`, `FRUIT_SET`, `HARVEST` | "Nảy mầm", "Ra lá thật", "Cao 40cm", "Ra hoa", "Đậu quả", "Thu hoạch" | mockup |
| `notif_type` | `task_reminder`, `checkin_reminder`, `assignment`, `achievement`, `household_activity`, `overdue` (P1) | "Nhắc việc chăm cây", "Nhắc chụp check-in", "Được giao việc", "Thành tích & huy hiệu" | FL SET-01, plan §2.3 |
| `invite_channel` | `link`, `code`, `email`, `phone` | "Gửi link mời", "Số điện thoại hoặc email" | FL HSH-01 |
| `level` | 1…N, with names "Người mới" … "Nhà vườn" | "Cấp 4 · Người chăm chỉ", "Cấp 5 · Thợ vườn" | FL GAM-05; mockup |

### 4.2 Tables

**Identity and household**
- `users`: `id`, `display_name` (ACC-02), `avatar_path`, `lang`, `timezone` (ACC-02), `province_code` or `zone_code` (region only, ACC-03), `experience`, `time_budget`, `prefer_organic` (PLN-09 / AI doc), `quiet_start`, `quiet_end` (SET-03, P1), `xp_total`, `level`, `created_at`, `deleted_at`. Email and Google identity are in Supabase Auth.
- `households`: `id`, `name` (example "Nhà mình"), `owner_id`, `created_at`.
- `household_members`: `household_id`, `user_id` (unique: one household per user, per mockup), `role`, `joined_at`, `away_until` (HSH-07, P1).
- `invites`: `id`, `household_id`, `code` (format "VUON-" + 4 digits in mockup), `channel`, `target` (email/phone), `role`, `created_by`, `expires_at` (+7 days), `accepted_by`, `status`.

**Content (CSDL cây)**
- `plants`: `id`, `group`, `name_vi`, `name_en`, `scientific_name`, `difficulty`, `days_to_harvest` (or maturity), `toxic_child`, `toxic_pet` (PLT-05 flags), `data_status` (`verified` / `ai_unverified`), `sources` (list), `updated_at`.
- `plant_stages`: `plant_id`, `code`, `order`, `name_vi`, `name_en`, `day_min`, `day_max`, `milestone_code`. The seed plan has six stages.
- `task_codes`: `code`, `group`, `default_window`, `default_frequency`, `safety_flags`. Example codes from AI doc: `T_WATER`, `T_FERT_ORGANIC`, `T_PRUNE`.
- `text_templates`: `kind` (task / problem / reason / milestone / safety), `code`, `lang` (`vi` / `en`), `field` (`name`, `steps`, `why`, `safety`), `body`, `source_ref`, `status` (`verified` / `ai_unverified`). Example steps are in §3 screen 05.
- `problem_codes`: `code`, `symptoms`, `causes`, `safe_actions`, `severity`. AI doc example shows numeric `sev: 2`; scale not given.
- `plan_templates`: `template_key`, `plant_id`, `zone`, `season`, `start_stage`, `space`, `sun_level`, `version`, `status`, `created_by` (`ai` / `manual`), `hit_count`. Example key from AI doc: `basil|VN_S|rainy|seedling|balcony|sun3`. Whether `pot_type` and `watering` belong in the key is not stated.
- `template_stages`, `template_tasks`: the stored plan body (stage code, day range, task code, params). Shape is implied by AI output (§5.1), not named in the sources.

**Projects and plans**
- `projects`: `id`, `household_id`, `owner_id`, `plant_id`, `name`, `start_date`, `start_stage`, `pot_count`, `space`, `sun_level`, `pot_type`, `watering`, `cover_path`, `status`, `template_key`, `end_reason`, `end_note`, `created_at`.
- `plans`: `id`, `project_id`, `version`, `source`, `confidence`, `status` (`draft` / `approved` / `superseded`), `approved_at`.
- `stages`: `id`, `plan_id`, `idx`, `code`, `name`, `day_from`, `day_to`, `milestone_code`.
- `tasks`: `id`, `project_id`, `stage_id`, `task_code`, `window`, `frequency`, `interval_days`, `reminder_time`, `assignee_id`, `assignment_mode`, `rotation_order`, `source` (`template` / `ai` / `manual`), `status`, `xp`.
- `task_occurrences`: `task_id`, `due_date`, `window`, `state`. Not named in the sources. Needed to render "Hôm nay" by day (see §7).
- `task_logs`: `id`, `task_id`, `occurrence_date`, `user_id`, `action` (`done` / `skip` / `snooze`), `skip_reason`, `snooze_until`, `note`, `photo_path`, `client_id` (offline dedup, proposed), `created_at`. Req TSK-06: log is kept as data for evaluation.

**Check-in and AI**
- `checkins`: `id`, `project_id`, `user_id`, `shots` (type + storage path, see §4.3), `tags[]`, `note` (AI doc: note max 200 characters for onboarding; check-in note limit not stated), `status` (`pending` / `analyzed` / `retake` / `approved` / `rejected`), `ai_result` (json), `model`, `counts_toward_quota`, `created_at`.
- `checkin_changes`: `id`, `checkin_id`, `change_kind`, `payload`, `accepted` (boolean). Applied only after user approval (CHK-05, AI-05).
- `milestones_reached`: `id`, `project_id`, `milestone_code`, `reached_on`, `confirmed_by` (`ai` / `user`), `checkin_id`.
- `project_lessons`: `user_id`, `plant_id`, `zone`, `season`, `text` (example "basil 2026-08: thất bại, P_ROOT_ROT, tưới quá nhiều"), `source_project_id`. Written at project end (PRJ-07).
- `ai_usage`: `user_id`, `day`, `kind` (`plan` / `checkin`), `count`, `model`, `tokens_in`, `tokens_out`, `cache_read`, `cost_usd` (AI doc §5 measurement list).
- `ai_feedback`: `id`, `ref_type`, `ref_id`, `helpful` (boolean), `created_at` (AI-07).

**Gamification**
- `xp_events`: `id`, `user_id`, `project_id`, `source` (`task_done` / `checkin` / `milestone` / `project_done`), `ref_id`, `amount`, `day`, `created_at`. Written by server (`award-xp`).
- `badges_catalog`: `code`, `name_vi`, `criteria` (criteria not given for most badges, see §7).
- `user_badges`: `user_id`, `badge_code`, `earned_at`.

**Other**
- `notification_prefs`: `user_id`, `type` (§4.1), `enabled`, `bundle_daily`, `quiet_start`, `quiet_end`.
- `devices`: placeholder for IoT (plan §2, FL Phase 3): `id`, `user_id`, `kind`, `external_id`, `status`, `meta`.
- `push_tokens`: implied by FCM (plan §2.3). Not named in the sources.
- `consents`: implied by NĐ 13/2023 (req §7) and the photo-use consent in AI doc §6. Not designed (§7).

### 4.3 Storage and client

- Check-in photos: private bucket, served by signed link (plan §2 Storage). Members only (req §7 security).
- Client compresses to long edge 768px, JPEG quality 75% (AI doc §3.6). Blur check on device before upload (req CHK-06).
- Client-side offline queue (drift/SQLite): pending Done, Skip, Snooze actions. Synced when online (plan §2.2). Server recomputes XP at the real action time.

---

## 5. AI contracts

Only three AI calls exist: plan creation, photo analysis with plan delta, and (in the same call) the delta. Question-and-answer on tasks is removed (FL). Field names below are proposals derived from the AI doc examples. Unless marked "example", the content comes from the sources.

### 5.1 Call A: plan generation (`ai-plan`)

Called only when the template key misses `plan_templates`. Hit = no AI call, template is copied and personalized by rule (start date, time window, frequency by sun level).

Input (proposed):

```json
{
  "plant_id": "tomato_cherry",
  "start_date": "2026-10-13",
  "start_stage": "seedling",
  "context": { "zone": "VN_S", "season": "rainy", "space": "balcony",
               "sun_level": 3, "pot": "plastic_20l", "watering": "manual" },
  "user": { "experience": "new", "time_budget": "10-30p", "prefer_organic": true },
  "household": { "has_children": false, "has_pets": false },
  "plant_card": { "stages": ["..."], "problems_top": ["P_..."] },
  "lessons": ["basil 2026-08: thất bại, P_ROOT_ROT, tưới quá nhiều"]
}
```

Output (proposed; codes and params only):

```json
{
  "template_key": "tomato_cherry|VN_S|rainy|seedling|balcony|sun3",
  "confidence": 0.86,
  "stages": [ { "code": "S1", "day_from": 1, "day_to": 7, "milestone": "SPROUT" } ],
  "tasks": [ { "task": "T_WATER", "stage": "S2", "every_d": 2, "window": "morning", "why": "R_HOT_SEASON" } ],
  "new_text": null
}
```

Rules:
- AI outputs codes and parameters only. The app builds VN/EN sentences from `text_templates` (AI doc §3.2, FL 14/10).
- `new_text` is non-null only when the plant is not in CSDL. It is saved to `text_templates` with `status = ai_unverified`, and shown with the AI label (req AI-03).
- The result is stored as a template. Later users with the same key pay no AI cost.
- AI must not invent a dose. Pesticide and chemical fertilizer content is limited to label reading and organic preference (req AI-06, PLN-09).
- Model: default Haiku 5.5. Escalate to Sonnet 5.5 when the plant is new, or confidence is below a threshold (threshold value open, §7). Exact model IDs to confirm (§7).
- Latency target: ≤ 20 s, with progress UI (req AI-08).
- Fallback on error or limit: plan mẫu for the plant type (FL §10, TaoPlan screen copy). Tagged `source = fallback`.

### 5.2 Call B: photo check-in with plan delta (`ai-checkin`)

One call returns diagnosis and delta together (AI doc §3.3). Output is a delta, not a full plan.

Input (proposed):

```json
{
  "project_card": {
    "plant": "tomato_cherry", "stage": "S3", "day": 38,
    "zone": "VN_S", "season": "rainy", "space": "balcony", "sun": 3,
    "pot": "plastic_20l", "water": "manual",
    "adherence_14d": 0.92, "skipped": ["T_FERT_ORGANIC x2"],
    "checkins": [ { "d": 23, "health": "good" } ],
    "active_issues": [], "applied_changes": []
  },
  "tags": ["LEAF_YELLOW"],
  "note": "(max 200 chars, assumed; not stated for check-in)",
  "images": [ { "shot": "whole_plant", "px": 768, "jpeg_q": 75 } ],
  "prev_thumb": { "d": 23, "for": "P_YELLOW_LEAF_OVERWATER" }
}
```

The project card is about 300–500 tokens. It is updated by code after each event, not by AI (AI doc §1, lớp 2). Only the last 3 check-ins are kept in full. Older ones are summarized in `history_summary`. A previous thumbnail is sent only while an issue is being tracked.

Output (proposed):

```json
{
  "status": "ok",
  "stage_est": { "code": "S3_late", "confidence": 0.82 },
  "health": { "value": "good", "confidence": 0.8 },
  "issues": [ { "code": "P_CALCIUM_LOW", "confidence": 0.58, "severity": 1,
                "actions": [ { "task": "T_EGGSHELL_ADD" } ] } ],
  "milestone_seen": { "code": "HEIGHT_40", "confidence": 0.9 },
  "delta": [
    { "op": "add", "task": "T_EGGSHELL_ADD", "stage": "S3" },
    { "op": "change_freq", "task": "T_WATER", "every_d": 1, "why": "R_HEAT_33C" },
    { "op": "shift", "milestone": "FLOWER", "to": "2026-10-20" }
  ],
  "reason_codes": ["R_HOT_SEASON"]
}
```

Retake response (CHK-06):

```json
{ "status": "retake", "reason": "BLUR", "hint_code": "H_RETAKE_LIGHT" }
```

Rules:
- Ops are `add`, `remove`, `shift` (AI doc). Mockup shows add, frequency change and milestone shift. A `remove` row is not shown (§7).
- Each `delta` item needs user approval before it is applied (CHK-05, AI-05). Unselected items are discarded.
- Confidence displays as a percent with a band label. High: "Tin cậy cao · {n}%". Medium: "Tin cậy trung bình · {n}%". Low: suggest a local agricultural store (CHK-08, P1). Band thresholds are open (§7).
- Blurred or dark photos are rejected on device first (CHK-06). The retake does not count toward quota (ChupLai copy).
- Skip rule: no new AI call if the same project was analyzed within 24 h and there is no new tag (AI doc §3.7).
- Images are sent at 768 px long edge (≈800 tokens per image; AI doc §3.6).
- Latency target ≤ 15 s (req AI-08).
- Fallback on error: no delta is applied. The user keeps the current plan (inferred; the sources only say plan template fallback applies to plan creation).

### 5.3 Safety rules (both calls)

- No chemical dose or product amount. Fertilizer or pesticide advice must point to the label (ChiTietTask copy; req AI-06).
- Prefer organic or safe actions first (req PLN-09).
- Every AI-originated text carries the "Gợi ý từ AI" label and confidence (req AI-02).
- Toxic-plant warnings come from rules, not AI (req PLT-05, AI doc §2 "luật lọc cây độc").
- When uncertain, the AI says so and asks for more input (req AI-04).
- Server validates the AI JSON against the code list. Unknown codes are rejected and the app falls back to the template or retake.

### 5.4 Caps and cost controls

- `ai_usage` counts per user per day for `plan` and `checkin`. Enforced in the Edge Function (plan §2.1).
- Daily cap values are not given (§7). The UI for "limit reached" is not designed (§7).
- Cost target numbers from AI doc §4 are estimates. Re-measure per AI doc §5.
- Prompt-cache order (AI doc §3.5): system + schema → plant card → project card → images.
- Batch pre-generation of templates for 30–50 common plants, per region and season (AI doc §3.1).

---

## 6. Business rules

### 6.1 Task scheduling

- Windows: "Sáng sớm · 6–8h", "Chiều mát · 16–18h". Check-in uses "Cả ngày". Suggested windows, not exact times (req §3 item 1).
- Each task has its own reminder time. Mockup example: "Nhắc lúc 16:30" inside the 16–18 window. Default reminder time rule not given (§7).
- Frequency examples: once, every N days (2, 5, 7, 14), daily ("hằng ngày").
- Check-in cadence: every 3–7 days depending on stage (req CHK-01). Mockup uses 5 days for the "Cây con" stage.
- Plan and task edits are manual (PLN-05): add, edit, delete, change frequency or reminder.

### 6.2 Task actions

- **Done:** one tap on the Hôm nay checkbox. Or "Xong · +10 XP" on the detail screen (req target: Done ≤ 2 taps).
- **Skip:** from the detail screen, "Bỏ qua". Optional reason (FL TSK-02). Reason list not given (§7).
- **Snooze:** "Dời lại". Duration not given (§7).
- Offline: Done, Skip and Snooze queue locally and sync later (plan §2.2, FL TSK-08 is P1 for full offline).
- Overdue handling (TSK-05, P1): fixed rules, no AI. Not in MVP screens.

### 6.3 XP and levels (values from mockup and FL)

| Event | XP | Source |
|---|---|---|
| Task done on time | +10 | Hôm nay progress line, detail "Xong · +10 XP" |
| Check-in photo | +30 | Hôm nay banner, Kết quả chip, Lịch row |
| Milestone reached (photo-confirmed) | +100 | Milestone screen "+100 XP" |
| Project completed | not given | FL GAM-01 mentions it (§7) |

- Daily cap for ordinary XP: 150. Mockup copy: "Mỗi ngày tối đa 150 XP từ việc thường." Whether check-in XP is inside the cap is not stated (§7).
- Milestone XP counts only when a check-in photo confirms the milestone (mockup copy; FL GAM-08).
- Totals in mockup: "Việc đúng hạn +620", "Check-in ảnh +330", "Đạt milestone +300" = 1,250, matches the hero total.
- Levels shown: Cấp 4 "Người chăm chỉ" at 1,250 XP. Cấp 5 "Thợ vườn" at 1,500 XP (inferred from "Còn 250 XP"). Full table not given (§7). FL GAM-05 range: "Người mới" → "Nhà vườn".

### 6.4 Badges and streak

- Badge catalog size shown as 16 ("Huy hiệu · 5/16"), but only 8 badges are drawn.
- Names given: "Hạt giống đầu tiên", "Nảy mầm", "7 ngày liên tục", "Vươn cao", "Thợ chụp ảnh", "Ra hoa", "Thu hoạch đầu tiên", "30 ngày liên tục". The "Vươn cao" badge is shown on the milestone "Cao 40cm". Criteria for the others are not given (§7).
- Streak: chip "12 ngày liên tục" on Hôm nay and web. What counts as a streak day is not given. Freeze is P1 (GAM-02).

### 6.5 Anti-cheat (GAM-08)

- Large XP needs evidence. Milestone XP needs a photo-confirmed check-in (mockup copy, Thành tích info banner).
- Daily cap of 150 XP for ordinary activity.
- XP is computed on the server (`award-xp`) from the action timestamp, not the device clock (plan §2.2).
- Leaderboard (P1) raises the stakes (req §11 item 4).

### 6.6 Household permissions

| Action | Owner | Member | Source |
|---|---|---|---|
| Create household | yes (creator becomes Owner) | — | mockup GiaDinhSetup |
| Join by code or link | — | yes (joins as Member) | mockup GiaDinhSetup |
| Invite by link, code, email, phone | yes | not stated | FL HSH-01; roles text (§7) |
| Choose Owner role when inviting | shown in UI | not stated | mockup MoiThanhVien (§7) |
| Share project to household | yes | not stated | FL HSH-03; roles text |
| Assign task (once, series, rotation) | yes | no | mockup Owner/Member text |
| Done, Skip, Snooze on own tasks | — | yes | FL HSH-02 |
| View shared projects, photos | yes | yes (members only) | req §7 security |
| See activity feed | yes | yes | FL HSH-06 |
| Leave household | yes (Owner case not specified) | yes | FL HSH-09; mockup Cài đặt |

- One household per user (mockup copy: "Mỗi người chỉ ở trong một gia đình.").
- No public friends or community (req §11 item 3).
- Rotation assignment skips away members automatically (P2, HSH-07).

### 6.7 Notifications

| Type | Channel | Toggle label (mockup) | Notes |
|---|---|---|---|
| Task reminder (own tasks) | local notification on device | "Nhắc việc chăm cây" | works offline (plan §2.3) |
| Check-in reminder | scheduled (`pg_cron`) | "Nhắc chụp check-in" | every 3–7 days (plan §2) |
| Assignment | FCM push | "Được giao việc" | accept or decline is P1 (HSH-05) |
| Achievement | local or FCM (not stated) | "Thành tích & huy hiệu" | milestone and badge |
| Household activity | FCM | none in mockup | §7 |
| Bundling | setting | "Gộp thông báo thành 1 lần/ngày" (off by default) | req TSK-04 |
| Quiet hours | setting | "Giờ yên lặng 22:00–06:00" (P2 badge) | SET-03 (P1) |

- Permission prompts "đúng lúc" (req §7). No screens designed for this (§7).

### 6.8 Dates, units and formats

- Week starts Monday ("T2"…"CN").
- Dates "dd/mm/yyyy" in inputs; "13/10" in labels.
- Time formats "6–8h", "16:30", "22:00–06:00".
- Volume "300ml/chậu". Temperature "31°C".
- Currency: none shown.

### 6.9 Account and privacy

- Delete account and all data (ACC-05). Entry point is Cài đặt. The red button label is verbatim: "Xóa tài khoản và toàn bộ dữ liệu".
- Location stored at region level only (ACC-03, req §7).
- Consent texts: "Điều khoản", "Chính sách dữ liệu", "Nghị định 13/2023/NĐ-CP" (Đăng nhập footer).

---

## 7. Open gaps

Items the sources leave unspecified or that conflict. Not invented here.

**Naming and phase conflicts**
1. Mockup badge "P2" means Phase 2 (req P1) and "P3" means Phase 3 (req P2). This clashes with req priority P1/P2 wording. Pick one scheme for the team.
2. "Tình trạng nhanh" (CHK-03) is badged P2 in the mockup. The 14/10 decision moved CHK-03 into MVP. Fix one of them.
3. "Chia sẻ ảnh kỷ niệm" on the milestone screen has no badge. FL places "Chia sẻ thành tích ra ngoài" in Phase 3. Confirm MVP scope.
4. Web dashboard is P0 in the canvas, but the plan says Web comes after Android (plan §3). Confirm.
5. Weather header "31°C nắng" appears on Hôm nay in MVP, while weather features are Phase 2 (PLN-08, Thời tiết screen). Source of temperature data is not given.
6. "Lưu trữ" tab on the projects list has no badge, but the swipe hint for archive/duplicate/delete is badged Phase 2 (PRJ-05).
7. "Kinh nghiệm" (ACC-04) is badged P2 in the mockup, but the onboarding screen is MVP.

**Auth and onboarding**
8. No OTP code-entry screen. "Nhận mã đăng nhập" navigates straight to profile setup.
9. No Google account chooser or error state. No failed-login state.
10. Timezone (ACC-02) has no UI in the mockup.
11. Language switch in onboarding pills is not connected to the Cài đặt "Ngôn ngữ" row (static value).
12. Household setup "Tạo gia đình mới" leads to the invite screen (MoiThanhVien). Intended flow not confirmed.
13. Invalid invite code, expired invite, and "đã ở gia đình khác" states are not designed.

**Plant search and creation**
14. No "no results" state. No loading state for search. No offline search behavior.
15. "Không phải" (did-you-mean) has no target.
16. PLT-03 says AI creates data for a new plant in the plan step. No UI for "AI đang tạo dữ liệu cây".
17. Search matching rules for unaccented input and ranking are not specified.

**Project context enums**
18. Location list: AI doc has `rooftop`; mockup has "Trong nhà", "Ban công", "Sân vườn" only. The project "Húng quế sân thượng" exists.
19. Sunlight: AI doc uses scale 1–4. Mockup has three buckets ("Dưới 3 giờ", "3–6 giờ", "Trên 6 giờ"). Mapping not given.
20. Pot type: AI doc example `plastic_20cm`. Mockup "Chậu nhựa 20L, đất trộn". Only one option is visible. Full list not given.
21. Experience and time-budget values exist in AI doc only. Time budget has no UI.
22. Plant group label: mockup uses "Rau thơm" in one project kind line. FL uses "Rau-quả" and "Cây cảnh". Final labels not given.
23. Difficulty full range not given.
24. Starting stage codes are not defined (AI doc uses names like `S2_vegetative`).
25. Stage count and milestone names are sample data. Mapping from plant to stages is in CSDL, not defined here.

**Plan and tasks**
26. Stage task counts on Duyệt plan ("5 việc", "6 việc") differ from the number of rows shown when expanded (Stage 2 shows 3 rows, Stage 3 shows 3, Stage 4 shows 1). Hidden rows or wrong count, unclear.
27. Sample dates conflict. BoiCanh sets start date "13/10/2026" and stage "Hạt giống", but ChiTietProject shows "Ngày 38/85" on the same date, and the card on Hôm nay shows 13/10 as today. Sample state only; confirm.
28. Progress percent formula is not given. 38/85 gives 45% (matches). Húng quế shows "ngày 21/60" with 30% (21/60 = 35%, 21/70 = 30%). Inconsistent.
29. Task row bar color on Lịch plan: meaning not given.
30. Plan "Tạo lại" (PLN-06) is P1. Behavior (keep or replace approved stages) not given.
31. Button "Bắt đầu trồng" target is Chi tiết project. Activation rules (plan must be approved?) not given.
32. Overdue tasks (TSK-05), and how "Dời lại" interacts with overdue (duration and target time), not given.
33. "Xong" XP when done late: "+10 XP mỗi việc đúng hạn" implies no XP when late. On-time window is not defined.
34. Skip reason options, snooze duration and snooze target are not given.
35. Task detail "Thêm ảnh" and Hôm nay tags (TSK-03) are P1. Photo or note storage rules not given.
36. "Gợi ý từ AI" badge is shown on a task text that comes from CSDL (ChiTietTask). AI doc says text comes from CSDL. Labeling rule for DB-sourced text not decided.

**Check-in and AI**
37. Condition tags: FL lists "đốm" with the others. Mockup shows three (Lá vàng, Héo, Có sâu). Add the fourth or confirm.
38. Photos per check-in: mockup shows "Ảnh 1/2" with three shot types. Req says "chụp hoặc tải ảnh". Required count and minimum not given.
39. Gallery upload path (req CHK-02) has no state. Photo permission-denied state not designed.
40. Confidence bands: high and medium thresholds not given. Low band threshold not given. Escalation threshold for Sonnet not given.
41. Blur detection threshold (Laplacian variance) not given.
42. Daily caps for plan and check-in calls not given. "Limit reached" UI not designed.
43. Retake: whether a retake earns check-in XP is not stated.
44. Change kinds: AI doc has `remove`. Mockup shows no remove row. Frequency change kind label is ĐỔI TẦN SUẤT, not "shift". Confirm op names.
45. Problem severity scale (`sev`) not given.
46. Which exact Claude model IDs are used, and whether Haiku 5.5 / Sonnet 5.5 names are final, is not confirmed in the sources.
47. Error UI for AI failure on check-in (not only plan) not designed. Fallback for check-in is not specified.
48. "Áp dụng" on the result screen routes to the milestone screen regardless of whether a milestone is reached. Routing rule not given.
49. Photo retention and deletion for check-in images (not stated beyond account deletion).
50. Image consent for AI improvement (plan §6 long-term, NĐ 13) has no screen.

**Gamification**
51. Level thresholds other than Cấp 4 (1,250) and Cấp 5 (1,500, inferred) are not given. Names beyond "Người mới", "Người chăm chỉ", "Thợ vườn", "Nhà vườn" are not given.
52. Badge criteria are given for only a few badges (see §6.4). Catalog size 16 vs 8 shown.
53. Project completion XP amount is not given.
54. Whether check-in and milestone XP count toward the 150 daily cap is not stated.
55. Streak definition and "freeze" rules (P1) not given.
56. "Hiện điểm & xếp hạng" toggle has no matching FL id (closest is GAM-09, "tắt gamification", P1).

**Household**
57. Who can invite, and whether Members can invite (not stated).
58. Whether the invite flow can grant Owner (mockup offers Owner radio).
59. Owner leaving the household, or transferring ownership. Not given.
60. Removing a member as Owner. Not designed.
61. What happens to tasks and history when a member leaves (HSH-09 says "giữ đúng quy định" without detail).
62. Whether Members can share or un-share projects (HSH-03 owner not specified).
63. Activity feed size and retention.
64. Assignment accept, decline, and "nhờ đổi" flow are P1 (HSH-05). Not designed.

**Notifications and settings**
65. Default reminder time for a task when not set.
66. Quiet hours: editable? Mockup shows fixed "22:00–06:00" text.
67. Household activity notification has no toggle in mockup.
68. Permission request timing screens are not designed (req §7 "đúng lúc").
69. Units preference (SET-03, P1) and timezone UI not shown.

**Accessibility, performance, platform**
70. Minimum font size and contrast standard beyond "chữ lớn, tương phản tốt" (req §7). Not stated.
71. One-hand reach target rules beyond 44px touch target. Not stated.
72. Dark mode: not specified. Only two dark screens are drawn (camera, milestone), plus dark blocks.
73. Status bar and safe-area handling not drawn.
74. Milestone celebration animation: FL says Rive or Lottie (plan §1.3), mockup shows static layout only.
75. Images: placeholders only ("[Ảnh bìa project]", "[Khung camera]"). No image assets or sizes are given beyond aspect ratios.
76. Empty states: none drawn for no projects, no tasks today, no household members, no activity, no achievements (except locked badges), no search results.
77. Loading: only AI plan creation is drawn. No skeletons for Hôm nay (req: ≤ 2 s on 4G).
78. Error and offline states: none drawn. Offline indicator for Hôm nay not designed (FL TSK-08 is P1).
79. Web (`WebDashboard`): no login or responsive breakpoints shown below 1280 px. Web timeline for check-in is "Chụp trên điện thoại" only.
80. English strings: mockup has only Vietnamese UI. Plant `name_en` and template EN text exist in schema but no EN screens are drawn.
81. Font weights 400 used by default only. No explicit body weight token.

**Data**
82. `task_occurrences` and `template_stages` are not named in the sources. Proposed here for rendering the day view.
83. Consents table and push token storage are implied but not designed.
84. Sun levels and pot types need final enums before the template key can be built.
85. The template key composition (whether pot and watering are included) is not stated.
