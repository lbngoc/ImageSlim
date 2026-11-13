# ImageSlim 🖼️

[English](README.md) · [Tiếng Việt](README.vi.md) · **繁體中文**

在 macOS 上從 Finder 右鍵選單直接為圖片「減肥」。

## 功能特色

- 🎯 **支援三種格式** — PNG、JPG/JPEG、WebP
- ⚡ **一次右鍵** — 不必開 App、不必拖放
- 🛠️ **自動安裝相依工具** — 透過 Homebrew 安裝所需壓縮工具
- 🛡️ **絕不弄丟原檔** — 原始檔保留為 `檔名.orig.副檔名`
- 📦 **只在真的變小時才替換** — 結果沒有比較小就原檔不動
- 🔁 **可重複執行** — 已有 `.orig.` 備份的檔案會跳過，不會二次失真
- 🔔 **每批次一則通知** — 不逐檔洗版

## 支援的圖片格式

| 格式 | 工具 | 設定 | 說明 |
|---|---|---|---|
| PNG | `pngquant` | 品質 70–90 | 顏色量子化。結果更大（exit 98）或低於品質下限（exit 99）時跳過。 |
| JPG/JPEG | `jpegoptim` | 最高 85、`--strip-all` | 移除中繼資料（EXIF，含 orientation，以及 ICC profile）。 |
| WebP | `cwebp` | 品質 80 | 透過暫存檔重新編碼，不會覆蓋自己的輸入檔。 |

## 系統需求

- macOS
- Homebrew — 未安裝時 `install.sh` 會自動安裝（會從 GitHub 下載並執行 Homebrew 官方
  安裝腳本，macOS 可能在該步驟要求輸入密碼）

## 安裝方式

```bash
git clone https://github.com/sacahan/ImageSlim.git
cd ImageSlim
bash install.sh
```

安裝腳本依序執行：

1. 檢查是否為 macOS
2. 未安裝時安裝 Homebrew
3. `brew install pngquant jpegoptim webp`
4. 建立 `~/Library/Services/ImageSlim (PNG_JPG_WEBP).workflow`
5. 在 macOS 的 `pbs` 中啟用此服務（新版 macOS 對新加入的服務預設為停用，只重啟
   Finder 並不足夠）
6. 重新啟動 Finder

## 使用方法

1. 在 Finder 中選取一或多張圖片
2. 右鍵 → **快速動作** → **ImageSlim (PNG/JPG/WEBP)**
3. 完成後看通知

執行結果：

```
photo.png         644 KB  →  212 KB      （已壓縮，保留原檔名）
photo.orig.png    644 KB                 （原始檔，未變動）
IMG_0002.JPG      657 KB  →   54 KB
IMG_0002.orig.JPG 657 KB
```

規則：

- 壓縮結果保留**原檔名**，舊檔改名為 `檔名.orig.副檔名`。
- 只有新檔**更小**時才替換，否則完全不動。
- 若 `檔名.orig.副檔名` 已存在則**跳過**該檔，因此重複執行不會讓同一張圖失真兩次。
- 不支援的檔案直接忽略；缺少某個工具只會跳過該格式，其餘檔案照常處理。

通知範例：

| 情況 | 通知內容 |
|---|---|
| 有壓縮成功 | `3 compressed, saved 2.3 MB` |
| 混合情況 | `1 compressed, saved 281 KB, 1 skipped` |
| 沒有變小的空間 | `Nothing to optimize, 3 skipped` |
| 只選到不支援的檔案 | 不顯示通知 |

### 還原原始檔

```bash
mv photo.orig.png photo.png
```

## 卸載流程

```bash
rm -rf ~/Library/Services/"ImageSlim (PNG_JPG_WEBP).workflow"
killall Finder
```

壓縮工具可保留（其他 App 可能在用），或執行
`brew uninstall pngquant jpegoptim webp` 移除。

## 運作原理

```
install.sh
  ├─ 檢查 macOS
  ├─ 檢查／安裝 Homebrew
  ├─ brew install pngquant jpegoptim webp
  ├─ 建立 ~/Library/Services/ImageSlim (PNG_JPG_WEBP).workflow
  │    ├─ Contents/Info.plist      NSServices 項目（僅 Finder、public.image）
  │    ├─ Contents/version.plist
  │    └─ Contents/document.wflow  Automator「執行 Shell 工序指令」動作
  ├─ 在 pbs 中啟用服務
  └─ killall Finder
```

技術細節：

- 動作以 `/bin/zsh` 執行，透過參數接收選取的檔案清單。
- 依副檔名選擇工具：`png` → `pngquant`、`jpg|jpeg` → `jpegoptim`、`webp` → `cwebp`。
- 輸出先寫到 `mktemp -t imageslim`，用 `stat -f%z` 比較大小，確認更小才 `mv` 覆蓋。
  `jpegoptim` 使用 `--stdout`，因此永遠不會寫到自己的輸入檔。
- 以 `trap` 在中斷時清除暫存檔。

## 故障排除

| 問題 | 解決方式 |
|---|---|
| 選單找不到快速動作 | 見下方說明 |
| `Permission denied` | 執行 `chmod +x install.sh` 後重試 |
| 工具未安裝 | `brew install pngquant jpegoptim webp` |

### 快速動作沒有出現

新版 macOS 上，放進 `~/Library/Services/` 的新服務預設是停用的，必須等 `pbs` 有它的
項目才會出現，因此只執行 `killall Finder` 沒有作用。`install.sh` 已自動處理；若要手動
修復：

```bash
# 1. 重啟服務註冊程序，讓它重新載入偏好設定
killall pbs; sleep 1
# 2. 讓 pbs 重新掃描 ~/Library/Services
/System/Library/CoreServices/pbs -update
# 3. 重啟 Finder 讓它重建選單
killall Finder
```

仍看不到時，依序確認：

1. **先選中圖片檔案**再右鍵 —— 在資料夾空白處右鍵不會顯示圖片類動作。
2. System Settings → Keyboard → Keyboard Shortcuts → **Services** → **Finder**，
   勾選 `ImageSlim (PNG/JPG/WEBP)`。
3. 確認服務是否已註冊：

   ```bash
   /System/Library/CoreServices/pbs -dump_pboard | grep -A3 ImageSlim
   ```

   沒有輸出代表 bundle 沒被讀到，重新執行 `bash install.sh`。
4. 直接驗證工作流本身能否執行（排除 bundle 損壞）：

   ```bash
   /usr/bin/automator -i ~/Desktop/test.png \
     ~/Library/Services/"ImageSlim (PNG_JPG_WEBP).workflow"
   ```
5. 極少數情況需要登出再登入，Finder 才會重建選單。

### 解除備份鎖定

已有 `檔名.orig.副檔名` 的檔案會依設計被跳過。想用不同品質重新壓縮，先刪掉備份：

```bash
rm photo.orig.png
```

## 注意事項

- `jpegoptim --strip-all` 會移除 EXIF，依賴 EXIF orientation 的相片可能因此轉向。
  若在意可改用 `--strip-none`。
- 若開啟專注模式／勿擾模式，或 Automator 的通知權限被關閉
  （System Settings → Notifications），通知不會顯示。

## 作者

Brian Han — [GitHub](https://github.com/sacahan)

## 授權

MIT License
