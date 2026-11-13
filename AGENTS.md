# AGENTS.md

此文件用於記錄與 ImageSlim 項目相關的自動化代理配置。

## 項目概述

**ImageSlim** 是一個 macOS 自動化工具，為圖片壓縮提供 Finder 快速動作集成。

### 核心功能
- 自動檢測圖片格式（PNG、JPG、WebP）
- 使用特定工具進行最優化壓縮
- 通過 Automator 與 Finder 集成
- 一鍵安裝和配置

## 工作流程拓撲

```
用戶操作（Finder 右鍵選單）
    ↓
Automator 快速動作觸發
    ↓
Run Shell Script 行動
    ↓
Shell 腳本處理
    ├─ PNG → pngquant
    ├─ JPG → jpegoptim
    └─ WebP → cwebp
    ↓
圖片壓縮完成
```

## 自動化元素

| 元素 | 類型 | 位置 | 說明 |
| --- | --- | --- | --- |
| 安裝腳本 | Bash | `install.sh` | 初始設置和依賴安裝 |
| Automator 工作流 | XML/Plist | `~/Library/Services/` | Finder 快速動作定義 |
| 壓縮邏輯 | Shell | 嵌入式 | 依副檔名選工具；結果寫回原檔名，原始檔保留為 `檔名.orig.副檔名` |

### 壓縮輸出規則
1. 壓縮結果以**原檔名**寫入（必須比原檔小才替換，否則原檔不動）
2. 原始檔改名為 `檔名.orig.副檔名`（例：`photo.png` → `photo.orig.png`）
3. 若 `.orig.` 備份已存在則跳過該檔，避免重複壓縮二次失真
4. 工具輸出失敗或跳過（pngquant exit 98/99）時，原檔與目錄不變

## 環境配置

### 依賴工具
- **pngquant**：PNG 壓縮（70-90% 品質）
- **jpegoptim**：JPEG 壓縮（品質 85）
- **cwebp**：WebP 轉換和壓縮（品質 80）

### 系統要求
- macOS 作業系統
- Homebrew 包管理器
- Finder 應用

## 代理擴展可能性

未來可考慮的自動化增強：

1. **批量處理代理**
   - 監視特定文件夾的新圖片
   - 自動觸發壓縮工作流程

2. **智能品質代理**
   - 分析圖片內容自動調整品質參數
   - 基於文件大小目標優化

3. **同步代理**
   - 在雲存儲服務（iCloud、Dropbox）中自動壓縮
   - 保持原件和壓縮版本的版本控制

4. **監控和日誌代理**
   - 記錄壓縮操作統計
   - 生成壓縮效率報告

## 配置管理

### 安裝流程
```bash
bash install.sh
```

### 卸載流程
```bash
rm -rf ~/Library/Services/圖片減肥（PNG_JPG_WEBP）.workflow
```

## 測試場景

- [x] PNG 文件壓縮（實測 832KB → 270KB，備份 `*.orig.png` 位元組一致）
- [x] JPEG 文件壓縮（實測 657KB → 54KB，備份 `*.orig.JPG` 位元組一致）
- [x] WebP 文件壓縮（實測 105KB → 20.7KB，可正常解碼）
- [x] 混合格式批量處理（含檔名空白、大寫副檔名）
- [x] 已壓縮文件重複處理（.orig 備份已存在時跳過，二次執行零變更）
- [x] 非圖片文件忽略（notes.txt 不受影響）
- [x] pngquant 跳過情境（exit 98 結果更大 / exit 99 品質不足，原檔不動）

## 版本控制

- **v1.0**：初始版本，支持 PNG、JPG、WebP
- 未來改進待定

---

*最後更新：2026-01-19*
