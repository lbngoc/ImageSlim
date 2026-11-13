# ImageSlim 🖼️

一鍵為圖片「減肥」的 macOS 快速動作工具。

## 功能特性

- 🎯 **支援多種格式**：PNG、JPG/JPEG、WebP
- ⚡ **快速便捷**：Finder 右鍵即可使用
- 🛠️ **自動配置**：一鍵安裝所有依賴
- 📦 **無損最優化**：智能壓縮演算法

## 支援的圖片格式

| 格式  | 工具 | 品質設定 | 說明 |
|-------|------|--------|------|
| PNG   | pngquant | 70-90 | 顏色量子化，跳過較大的文件 |
| JPG/JPEG | jpegoptim | 85 | 移除元數據，最大品質 85 |
| WebP | cwebp | 80 | 現代高效格式 |

## 安裝方式

```bash
bash install.sh
```

**需求：**
- macOS 系統
- 具有 Homebrew 的寫入權限

## 重啟 Finder

安裝完成後，需要重啟 Finder 以使快速動作生效：

```bash
killall Finder
```

或者通過 UI：按住 `Option` 鍵，右鍵點擊 Dock 中的 Finder 圖標，選擇「重新啟動」。

## 使用方法

1. 在 Finder 中選取一或多張圖片
2. 右鍵點擊
3. 選擇「快速動作」
4. 點擊「ImageSlim (PNG/JPG/WEBP)」

✅ 壓縮結果保留原檔名，原始檔自動備份為 `檔名.orig.原副檔名`（例：`photo.png` → `photo.orig.png`）

- 只有當結果**更小**時才會替換，否則原檔不動
- 備份已存在時會跳過該檔，避免重複壓縮造成二次失真
- 想還原就刪掉壓縮檔，把 `.orig.` 那份改回原名

## 腳本流程

```
① 檢查 macOS 系統
   ↓
② 檢查/安裝 Homebrew
   ↓
③ 安裝壓縮工具
   ├─ pngquant
   ├─ jpegoptim
   └─ webp
   ↓
④ 建立 Automator 快速動作
   ↓
⑤ 重新載入 Finder
   ↓
✨ 完成！
```

## 技術細節

### Shell Script 版本
- Shell: `/bin/zsh`
- 使用 case 語句根據副檔名選擇對應的壓縮工具

### Automator 工作流程
- 類型：Finder 快速動作
- 接受：圖片文件列表
- 執行：Run Shell Script 行動

## 故障排除

| 問題 | 解決方案 |
|-----|--------|
| 找不到快速動作 | 見下方「快速動作沒有出現」 |
| 權限被拒 | 執行 `chmod +x install.sh` 後重試 |
| 工具未安裝 | 執行 `brew install pngquant jpegoptim webp` |

### 快速動作沒有出現

macOS 上，新加入 `~/Library/Services/` 的服務預設是「未啟用」的，只重啟 Finder 不夠。
`install.sh` 已自動處理，若要手動修復：

```bash
# 1. 讓 pbs 重新掃描 Services，並重啟它
/System/Library/CoreServices/pbs -update
killall pbs
# 2. 重啟 Finder
killall Finder
```

仍看不到時，依序確認：

1. **先選中圖片檔案**再右鍵 —— 空的資料夾背景不會顯示圖片類動作
2. System Settings → Keyboard → Keyboard Shortcuts → **Services** → **Finder**，
   勾選 `ImageSlim (PNG/JPG/WEBP)`
3. 檢查服務是否已註冊：
   ```bash
   /System/Library/CoreServices/pbs -dump_pboard | grep -A3 ImageSlim
   ```
   沒有輸出代表 bundle 沒被讀到，重新執行 `bash install.sh`
4. 直接驗證工作流本身可否執行（可排除 bundle 損壞）：
   ```bash
   /usr/bin/automator -i ~/Desktop/test.png \
     ~/Library/Services/"ImageSlim (PNG_JPG_WEBP).workflow"
   ```
5. 極少數情況需要登出再登入，Finder 才會重建選單

## 作者

Brian Han - [GitHub](https://github.com/sacahan)

## 授權

MIT License
