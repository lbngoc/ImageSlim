# ImageSlim 🖼️

[English](README.md) · **Tiếng Việt** · [繁體中文](README.zh-TW.md)

Nén ảnh ngay từ menu chuột phải của Finder trên macOS.

## Tính năng

- 🎯 **Ba định dạng** — PNG, JPG/JPEG, WebP
- ⚡ **Một cú chuột phải** — không mở app, không kéo thả
- 🛠️ **Tự cài dependency** — dùng Homebrew để cài công cụ cần thiết
- 🛡️ **Không bao giờ mất bản gốc** — file cũ được giữ thành `tên.orig.đuôi`
- 📦 **Chỉ thay khi thực sự nhỏ hơn** — kết quả không nhỏ hơn thì giữ nguyên file
- 🔁 **Chạy lại an toàn** — file đã có bản `.orig.` sẽ bị bỏ qua, không mất chất lượng lần hai
- 🔔 **Một notification tổng kết** cho mỗi lần chạy

## Định dạng hỗ trợ

| Định dạng | Công cụ | Thiết lập | Ghi chú |
|---|---|---|---|
| PNG | `pngquant` | chất lượng 70–90 | Lượng tử hoá màu. Bỏ qua nếu kết quả lớn hơn (exit 98) hoặc dưới ngưỡng chất lượng (exit 99). |
| JPG/JPEG | `jpegoptim` | tối đa 85, `--strip-all` | Xoá metadata (EXIF, gồm cả orientation, và ICC profile). |
| WebP | `cwebp` | chất lượng 80 | Encode qua file tạm, không ghi đè lên chính input. |

## Yêu cầu

- macOS
- Homebrew — `install.sh` tự cài nếu chưa có (script cài chính thức của Homebrew được tải
  từ GitHub và chạy; macOS có thể hỏi mật khẩu ở bước này)

## Cài đặt

Các URL dưới đây trỏ tới `lbngoc/ImageSlim` — fork đang chứa các thay đổi này; khi đã merge
lên upstream thì đổi `lbngoc` thành `sacahan`.

### Cài nhanh

```bash
curl -fsSL https://raw.githubusercontent.com/lbngoc/ImageSlim/main/install.sh -o /tmp/imageslim-install.sh
less /tmp/imageslim-install.sh   # xem qua nếu muốn
bash /tmp/imageslim-install.sh
```

Pipe thẳng vào shell cũng được, nhưng khi đó bạn không đọc nội dung sẽ chạy:

```bash
curl -fsSL https://raw.githubusercontent.com/lbngoc/ImageSlim/main/install.sh | bash
```

Dùng `bash`, **không** dùng `sh`: script cần cú pháp bash (`[[ ]]`, heredoc), nên `sh`
(trên nhiều hệ thống là `dash`) sẽ lỗi.

URL trỏ theo nhánh `main` nên luôn cài đúng bản mới nhất ở thời điểm chạy. Muốn ghim phiên
bản thì thay `main` bằng tag hoặc commit:

```bash
curl -fsSL https://raw.githubusercontent.com/lbngoc/ImageSlim/<tag-hoac-commit>/install.sh | bash
```

### Từ bản clone

```bash
git clone https://github.com/lbngoc/ImageSlim.git
cd ImageSlim
bash install.sh
```

Cả hai cách đều không cần gì thêm — script tự chứa mọi thứ.

Installer làm những việc sau:

1. Kiểm tra hệ điều hành macOS
2. Cài Homebrew nếu chưa có
3. `brew install pngquant jpegoptim webp`
4. Tạo `~/Library/Services/ImageSlim (PNG_JPG_WEBP).workflow`
5. Bật service trong `pbs` của macOS (service mới thêm mặc định bị tắt trên các bản macOS
   gần đây — chỉ `killall Finder` là không đủ)
6. Restart Finder

## Cách dùng

1. Chọn một hoặc nhiều ảnh trong Finder
2. Chuột phải → **Quick Actions** → **ImageSlim (PNG/JPG/WEBP)**
3. Đọc notification khi xong

Kết quả:

```
photo.png         644 KB  →  212 KB      (đã nén, giữ nguyên tên)
photo.orig.png    644 KB                 (bản gốc không đổi)
IMG_0002.JPG      657 KB  →   54 KB
IMG_0002.orig.JPG 657 KB
```

Quy tắc:

- Kết quả nén giữ **tên file gốc**; file cũ được đổi tên thành `tên.orig.đuôi`.
- Chỉ thay khi file mới **nhỏ hơn**, nếu không thì không đụng gì.
- Nếu `tên.orig.đuôi` đã tồn tại thì file đó **bị bỏ qua**, nên chạy hai lần không làm
  ảnh mất chất lượng hai lần.
- File không hỗ trợ bị bỏ qua; thiếu một công cụ chỉ skip định dạng đó, các file còn lại
  vẫn được xử lý.

Ví dụ notification:

| Tình huống | Notification |
|---|---|
| Có nén được | `3 compressed, saved 2.3 MB` |
| Hỗn hợp | `1 compressed, saved 281 KB, 1 skipped` |
| Không nhỏ hơn được | `Nothing to optimize, 3 skipped` |
| Chỉ chọn file không hỗ trợ | không hiện notification |

### Khôi phục bản gốc

```bash
mv photo.orig.png photo.png
```

## Gỡ cài đặt

```bash
rm -rf ~/Library/Services/"ImageSlim (PNG_JPG_WEBP).workflow"
killall Finder
```

Các công cụ có thể giữ lại (app khác có thể dùng) hoặc gỡ bằng
`brew uninstall pngquant jpegoptim webp`.

## Cách hoạt động

```
install.sh
  ├─ kiểm tra macOS
  ├─ kiểm tra / cài Homebrew
  ├─ brew install pngquant jpegoptim webp
  ├─ tạo ~/Library/Services/ImageSlim (PNG_JPG_WEBP).workflow
  │    ├─ Contents/Info.plist      entry NSServices (chỉ Finder, public.image)
  │    ├─ Contents/version.plist
  │    └─ Contents/document.wflow  action "Run Shell Script" của Automator
  ├─ bật service trong pbs
  └─ killall Finder
```

Chi tiết kỹ thuật:

- Action chạy bằng `/bin/zsh`, nhận danh sách file đã chọn qua tham số.
- Phần mở rộng quyết định công cụ: `png` → `pngquant`, `jpg|jpeg` → `jpegoptim`,
  `webp` → `cwebp`.
- Kết quả ghi ra `mktemp -t imageslim`, so sánh dung lượng bằng `stat -f%z`, chỉ khi nhỏ
  hơn mới `mv` đè vào file. `jpegoptim` dùng `--stdout` nên không bao giờ ghi đè input.
- Có `trap` dọn file tạm nếu action bị huỷ giữa chừng.

## Xử lý sự cố

| Vấn đề | Cách sửa |
|---|---|
| Không thấy Quick Action | Xem mục dưới |
| `Permission denied` | `chmod +x install.sh` rồi chạy lại |
| Thiếu công cụ | `brew install pngquant jpegoptim webp` |

### Quick Action không xuất hiện

Trên macOS gần đây, service mới bỏ vào `~/Library/Services/` vẫn ở trạng thái tắt cho tới
khi `pbs` có entry cho nó, nên `killall Finder` một mình không có tác dụng. `install.sh`
đã xử lý việc này; nếu cần sửa tay:

```bash
# 1. restart lại service registry để nó nạp lại preferences
killall pbs; sleep 1
# 2. cho pbs quét lại ~/Library/Services
/System/Library/CoreServices/pbs -update
# 3. restart Finder để dựng lại menu
killall Finder
```

Nếu vẫn không thấy, kiểm tra theo thứ tự:

1. **Chọn đúng file ảnh trước** — chuột phải vào vùng trống trong folder sẽ không hiện
   action cho ảnh.
2. System Settings → Keyboard → Keyboard Shortcuts → **Services** → **Finder** rồi tick
   `ImageSlim (PNG/JPG/WEBP)`.
3. Xác nhận service đã được đăng ký:

   ```bash
   /System/Library/CoreServices/pbs -dump_pboard | grep -A3 ImageSlim
   ```

   Không có output nghĩa là bundle chưa được đọc — chạy lại `bash install.sh`.
4. Kiểm tra bản thân workflow còn chạy được (loại trừ bundle hỏng):

   ```bash
   /usr/bin/automator -i ~/Desktop/test.png \
     ~/Library/Services/"ImageSlim (PNG_JPG_WEBP).workflow"
   ```
5. Hiếm khi cần logout rồi login lại thì Finder mới dựng lại menu.

### Bỏ "khoá" backup

File đã có `tên.orig.đuôi` sẽ bị bỏ qua (đúng thiết kế). Muốn nén lại với chất lượng khác
thì xoá bản backup trước:

```bash
rm photo.orig.png
```

## Lưu ý

- `jpegoptim --strip-all` xoá EXIF, nên ảnh dựa vào cờ orientation trong EXIF có thể bị
  xoay sai sau khi nén. Nếu quan trọng, đổi sang `--strip-none`.
- Notification sẽ im lặng nếu đang bật Focus / Do Not Disturb, hoặc nếu Automator bị tắt
  quyền thông báo trong System Settings → Notifications.

## Tác giả

Brian Han — [GitHub](https://github.com/sacahan)

## Giấy phép

MIT License
