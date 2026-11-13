#!/bin/bash
set -e

echo "🔍 檢查作業系統..."
if [[ "$OSTYPE" != "darwin"* ]]; then
  echo "❌ 此腳本僅支援 macOS"
  exit 1
fi

echo "🍺 檢查 Homebrew..."
if ! command -v brew >/dev/null 2>&1; then
  echo "➡️  未偵測到 Homebrew，開始安裝..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -f /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
else
  echo "✅ Homebrew 已存在"
fi

echo "📦 安裝圖片壓縮工具..."
brew install pngquant jpegoptim webp

echo "⚙️ 建立 Automator 快速動作..."

WORKFLOW_NAME="圖片減肥（PNG_JPG_WEBP）.workflow"
TARGET="$HOME/Library/Services/$WORKFLOW_NAME"

rm -rf "$TARGET"
mkdir -p "$TARGET/Contents"

cat > "$TARGET/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>NSServices</key>
	<array>
		<dict>
			<key>NSBackgroundColorName</key>
			<string>background</string>
			<key>NSBackgroundSystemColorName</key>
			<string>systemOrangeColor</string>
			<key>NSIconName</key>
			<string>NSActionTemplate</string>
			<key>NSMenuItem</key>
			<dict>
				<key>default</key>
				<string>圖片減肥（PNG_JPG_WEBP）</string>
			</dict>
			<key>NSMessage</key>
			<string>runWorkflowAsService</string>
			<key>NSRequiredContext</key>
			<dict>
				<key>NSApplicationIdentifier</key>
				<string>com.apple.finder</string>
			</dict>
			<key>NSSendFileTypes</key>
			<array>
				<string>public.image</string>
			</array>
		</dict>
	</array>
</dict>
</plist>
EOF

cat > "$TARGET/Contents/version.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>workflow.automator.version</key>
  <string>2.10</string>
</dict>
</plist>
EOF

cat > "$TARGET/Contents/document.wflow" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>AMApplicationBuild</key>
  <string>528</string>
  <key>AMApplicationVersion</key>
  <string>2.10</string>
  <key>AMDocumentVersion</key>
  <string>2</string>
  <key>actions</key>
  <array>
    <dict>
      <key>action</key>
      <dict>
        <key>AMAccepts</key>
        <dict>
          <key>Container</key>
          <string>List</string>
          <key>Optional</key>
          <true/>
          <key>Types</key>
          <array>
            <string>com.apple.cocoa.string</string>
          </array>
        </dict>
        <key>AMActionVersion</key>
        <string>2.0.3</string>
        <key>AMApplication</key>
        <array>
          <string>Automator</string>
        </array>
        <key>AMParameterProperties</key>
        <dict>
          <key>COMMAND_STRING</key>
          <dict/>
          <key>CheckedForUserDefaultShell</key>
          <dict/>
          <key>inputMethod</key>
          <dict/>
          <key>shell</key>
          <dict/>
          <key>source</key>
          <dict/>
        </dict>
        <key>AMProvides</key>
        <dict>
          <key>Container</key>
          <string>List</string>
          <key>Types</key>
          <array>
            <string>com.apple.cocoa.string</string>
          </array>
        </dict>
        <key>ActionBundlePath</key>
        <string>/System/Library/Automator/Run Shell Script.action</string>
        <key>ActionName</key>
        <string>執行Shell工序指令</string>
        <key>ActionParameters</key>
        <dict>
          <key>COMMAND_STRING</key>
          <string>export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# Compressed result keeps the original name; the untouched original is kept
# beside it as "&lt;name&gt;.orig.&lt;ext&gt;". If that backup already exists the file
# is skipped, so running twice never degrades it twice.

compressed=0
skipped=0
saved=0

for file in "$@"; do
  [ -f "$file" ] || continue

  ext="${file##*.}"
  base="${file%.*}"
  backup="$base.orig.${file##*.}"

  case "${ext:l}" in
    png)      tool=pngquant  ;;
    jpg|jpeg) tool=jpegoptim ;;
    webp)     tool=cwebp     ;;
    *)        continue       ;;
  esac

  if ! command -v "$tool" &gt;/dev/null 2&gt;&amp;1; then
    echo "Missing $tool. Run install.sh again to install it." &gt;&amp;2
    skipped=$((skipped+1))
    continue
  fi

  if [ -e "$backup" ]; then
    echo "Skipped, original already saved as $backup: $file" &gt;&amp;2
    skipped=$((skipped+1))
    continue
  fi

  tmp="$(mktemp -t imageslim)" || continue
  trap 'rm -f "$tmp"' EXIT

  orig_size=$(stat -f%z "$file")

  case "${ext:l}" in
    png)
      pngquant --force --skip-if-larger --quality=70-90 --output "$tmp" "$file"
      ;;
    jpg|jpeg)
      # --strip-all drops EXIF (including orientation) and the ICC profile.
      jpegoptim --strip-all --max=85 --stdout "$file" &gt; "$tmp"
      ;;
    webp)
      cwebp -quiet -q 80 "$file" -o "$tmp"
      ;;
  esac
  rc=$?

  # Only swap in the result when it is smaller; otherwise leave the file alone.
  if [ -s "$tmp" ] &amp;&amp; [ "$(stat -f%z "$tmp")" -lt "$orig_size" ]; then
    new_size=$(stat -f%z "$tmp")
    if mv -f "$file" "$backup" &amp;&amp; mv -f "$tmp" "$file"; then
      compressed=$((compressed+1))
      saved=$((saved + orig_size - new_size))
      echo "Compressed: $file (original saved as $(basename "$backup"))"
    fi
  else
    rm -f "$tmp"
    skipped=$((skipped+1))
    case "$rc" in
      98) echo "Skipped, result would be larger: $file" ;;
      99) echo "Skipped, quality would drop below target: $file" ;;
      *)  echo "Skipped, no smaller result: $file" ;;
    esac
  fi
done

# One summary notification for the whole batch.
if [ $((compressed + skipped)) -gt 0 ]; then
  if [ "$saved" -ge 1048576 ]; then
    human="$(awk -v b="$saved" 'BEGIN { printf "%.1f MB", b / 1048576 }')"
  elif [ "$saved" -ge 1024 ]; then
    human="$(awk -v b="$saved" 'BEGIN { printf "%.0f KB", b / 1024 }')"
  else
    human="${saved} B"
  fi

  if [ "$compressed" -gt 0 ]; then
    msg="$compressed compressed, saved $human"
    [ "$skipped" -gt 0 ] &amp;&amp; msg="$msg, $skipped skipped"
  else
    msg="Nothing to optimize, $skipped skipped"
  fi

  osascript -e "display notification \"$msg\" with title \"ImageSlim\"" &gt;/dev/null 2&gt;&amp;1
fi</string>
          <key>CheckedForUserDefaultShell</key>
          <true/>
          <key>inputMethod</key>
          <integer>1</integer>
          <key>shell</key>
          <string>/bin/zsh</string>
          <key>source</key>
          <string></string>
        </dict>
        <key>BundleIdentifier</key>
        <string>com.apple.RunShellScript</string>
        <key>CFBundleVersion</key>
        <string>2.0.3</string>
        <key>CanShowSelectedItemsWhenRun</key>
        <false/>
        <key>CanShowWhenRun</key>
        <true/>
        <key>Category</key>
        <array>
          <string>AMCategoryUtilities</string>
        </array>
        <key>Class Name</key>
        <string>RunShellScriptAction</string>
        <key>InputUUID</key>
        <string>27B12EF0-63B8-4B57-ADE9-E1E65B47454A</string>
        <key>Keywords</key>
        <array>
          <string>Shell</string>
          <string>工序指令</string>
          <string>指令</string>
          <string>執行</string>
          <string>Unix</string>
        </array>
        <key>OutputUUID</key>
        <string>AF3B813A-1326-455E-ACC0-A28D79789A0F</string>
        <key>UUID</key>
        <string>E2D45912-671C-428C-85E2-C40C62966A0B</string>
        <key>UnlocalizedApplications</key>
        <array>
          <string>Automator</string>
        </array>
        <key>arguments</key>
        <dict>
          <key>0</key>
          <dict>
            <key>default value</key>
            <integer>0</integer>
            <key>name</key>
            <string>inputMethod</string>
            <key>required</key>
            <string>0</string>
            <key>type</key>
            <string>0</string>
            <key>uuid</key>
            <string>0</string>
          </dict>
          <key>1</key>
          <dict>
            <key>default value</key>
            <false/>
            <key>name</key>
            <string>CheckedForUserDefaultShell</string>
            <key>required</key>
            <string>0</string>
            <key>type</key>
            <string>0</string>
            <key>uuid</key>
            <string>1</string>
          </dict>
          <key>2</key>
          <dict>
            <key>default value</key>
            <string></string>
            <key>name</key>
            <string>source</string>
            <key>required</key>
            <string>0</string>
            <key>type</key>
            <string>0</string>
            <key>uuid</key>
            <string>2</string>
          </dict>
          <key>3</key>
          <dict>
            <key>default value</key>
            <string></string>
            <key>name</key>
            <string>COMMAND_STRING</string>
            <key>required</key>
            <string>0</string>
            <key>type</key>
            <string>0</string>
            <key>uuid</key>
            <string>3</string>
          </dict>
          <key>4</key>
          <dict>
            <key>default value</key>
            <string>/bin/sh</string>
            <key>name</key>
            <string>shell</string>
            <key>required</key>
            <string>0</string>
            <key>type</key>
            <string>0</string>
            <key>uuid</key>
            <string>4</string>
          </dict>
        </dict>
        <key>conversionLabel</key>
        <integer>0</integer>
        <key>isViewVisible</key>
        <integer>1</integer>
        <key>location</key>
        <string>309.000000:305.000000</string>
        <key>nibPath</key>
        <string>/System/Library/Automator/Run Shell Script.action/Contents/Resources/Base.lproj/main.nib</string>
      </dict>
      <key>isViewVisible</key>
      <integer>1</integer>
    </dict>
  </array>
  <key>connectors</key>
  <dict/>
  <key>workflowMetaData</key>
  <dict>
    <key>applicationBundleID</key>
    <string>com.apple.finder</string>
    <key>applicationBundleIDsByPath</key>
    <dict>
      <key>/System/Library/CoreServices/Finder.app</key>
      <string>com.apple.finder</string>
    </dict>
    <key>applicationPath</key>
    <string>/System/Library/CoreServices/Finder.app</string>
    <key>applicationPaths</key>
    <array>
      <string>/System/Library/CoreServices/Finder.app</string>
    </array>
    <key>backgroundColor</key>
    <data>
    YnBsaXN0MDDUAQIDBAUGBwpYJHZlcnNpb25ZJGFyY2hpdmVyVCR0b3BYJG9i
    amVjdHMSAAGGoF8QD05TS2V5ZWRBcmNoaXZlctEICVRyb290gAGpCwwXGBki
    KCkwVSRudWxs1Q0ODxAREhMUFRZWJGNsYXNzW05TQ29sb3JOYW1lXE5TQ29s
    b3JTcGFjZV1OU0NhdGFsb2dOYW1lV05TQ29sb3KACIADEAaAAoAEVlN5c3Rl
    bV8QEXN5c3RlbU9yYW5nZUNvbG9y1RobDxwNHR4fIBJcTlNDb21wb25lbnRz
    VU5TUkdCXxASTlNDdXN0b21Db2xvclNwYWNlSTEgMC41IDAgMU8QJjAuOTg5
    MjMyMjQyMSAwLjQxNTMzMDQxIDAuMDMxODEwODc1OTgAEAGABYAI0yMkDSUm
    J1ROU0lEVU5TSUNDEAeABoAHTxEMSAAADEhMaW5vAhAAAG1udHJSR0IgWFla
    IAfOAAIACQAGADEAAGFjc3BNU0ZUAAAAAElFQyBzUkdCAAAAAAAAAAAAAAAA
    AAD21gABAAAAANMtSFAgIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAEWNwcnQAAAFQAAAAM2Rlc2MAAAGEAAAAbHd0
    cHQAAAHwAAAAFGJrcHQAAAIEAAAAFHJYWVoAAAIYAAAAFGdYWVoAAAIsAAAA
    FGJYWVoAAAJAAAAAFGRtbmQAAAJUAAAAcGRtZGQAAALEAAAAiHZ1ZWQAAANM
    AAAAhnZpZXcAAAPUAAAAJGx1bWkAAAP4AAAAFG1lYXMAAAQMAAAAJHRlY2gA
    AAQwAAAADHJUUkMAAAQ8AAAIDGdUUkMAAAQ8AAAIDGJUUkMAAAQ8AAAIDHRl
    eHQAAAAAQ29weXJpZ2h0IChjKSAxOTk4IEhld2xldHQtUGFja2FyZCBDb21w
    YW55AABkZXNjAAAAAAAAABJzUkdCIElFQzYxOTY2LTIuMQAAAAAAAAAAAAAA
    EnNSR0IgSUVDNjE5NjYtMi4xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAABYWVogAAAAAAAA81EAAQAAAAEWzFhZ
    WiAAAAAAAAAAAAAAAAAAAAAAWFlaIAAAAAAAAG+iAAA49QAAA5BYWVogAAAA
    AAAAYpkAALeFAAAY2lhZWiAAAAAAAAAkoAAAD4QAALbPZGVzYwAAAAAAAAAW
    SUVDIGh0dHA6Ly93d3cuaWVjLmNoAAAAAAAAAAAAAAAWSUVDIGh0dHA6Ly93
    d3cuaWVjLmNoAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAGRlc2MAAAAAAAAALklFQyA2MTk2Ni0yLjEgRGVmYXVsdCBS
    R0IgY29sb3VyIHNwYWNlIC0gc1JHQgAAAAAAAAAAAAAALklFQyA2MTk2Ni0y
    LjEgRGVmYXVsdCBSR0IgY29sb3VyIHNwYWNlIC0gc1JHQgAAAAAAAAAAAAAA
    AAAAAAAAAAAAAABkZXNjAAAAAAAAACxSZWZlcmVuY2UgVmlld2luZyBDb25k
    aXRpb24gaW4gSUVDNjE5NjYtMi4xAAAAAAAAAAAAAAAsUmVmZXJlbmNlIFZp
    ZXdpbmcgQ29uZGl0aW9uIGluIElFQzYxOTY2LTIuMQAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAdmlldwAAAAAAE6T+ABRfLgAQzxQAA+3MAAQTCwADXJ4A
    AAABWFlaIAAAAAAATAlWAFAAAABXH+dtZWFzAAAAAAAAAAEAAAAAAAAAAAAA
    AAAAAAAAAAACjwAAAAJzaWcgAAAAAENSVCBjdXJ2AAAAAAAABAAAAAAFAAoA
    DwAUABkAHgAjACgALQAyADcAOwBAAEUASgBPAFQAWQBeAGMAaABtAHIAdwB8
    AIEAhgCLAJAAlQCaAJ8ApACpAK4AsgC3ALwAwQDGAMsA0ADVANsA4ADlAOsA
    8AD2APsBAQEHAQ0BEwEZAR8BJQErATIBOAE+AUUBTAFSAVkBYAFnAW4BdQF8
    AYMBiwGSAZoBoQGpAbEBuQHBAckB0QHZAeEB6QHyAfoCAwIMAhQCHQImAi8C
    OAJBAksCVAJdAmcCcQJ6AoQCjgKYAqICrAK2AsECywLVAuAC6wL1AwADCwMW
    AyEDLQM4A0MDTwNaA2YDcgN+A4oDlgOiA64DugPHA9MD4APsA/kEBgQTBCAE
    LQQ7BEgEVQRjBHEEfgSMBJoEqAS2BMQE0wThBPAE/gUNBRwFKwU6BUkFWAVn
    BXcFhgWWBaYFtQXFBdUF5QX2BgYGFgYnBjcGSAZZBmoGewaMBp0GrwbABtEG
    4wb1BwcHGQcrBz0HTwdhB3QHhgeZB6wHvwfSB+UH+AgLCB8IMghGCFoIbgiC
    CJYIqgi+CNII5wj7CRAJJQk6CU8JZAl5CY8JpAm6Cc8J5Qn7ChEKJwo9ClQK
    agqBCpgKrgrFCtwK8wsLCyILOQtRC2kLgAuYC7ALyAvhC/kMEgwqDEMMXAx1
    DI4MpwzADNkM8w0NDSYNQA1aDXQNjg2pDcMN3g34DhMOLg5JDmQOfw6bDrYO
    0g7uDwkPJQ9BD14Peg+WD7MPzw/sEAkQJhBDEGEQfhCbELkQ1xD1ERMRMRFP
    EW0RjBGqEckR6BIHEiYSRRJkEoQSoxLDEuMTAxMjE0MTYxODE6QTxRPlFAYU
    JxRJFGoUixStFM4U8BUSFTQVVhV4FZsVvRXgFgMWJhZJFmwWjxayFtYW+hcd
    F0EXZReJF64X0hf3GBsYQBhlGIoYrxjVGPoZIBlFGWsZkRm3Gd0aBBoqGlEa
    dxqeGsUa7BsUGzsbYxuKG7Ib2hwCHCocUhx7HKMczBz1HR4dRx1wHZkdwx3s
    HhYeQB5qHpQevh7pHxMfPh9pH5Qfvx/qIBUgQSBsIJggxCDwIRwhSCF1IaEh
    ziH7IiciVSKCIq8i3SMKIzgjZiOUI8Ij8CQfJE0kfCSrJNolCSU4JWgllyXH
    JfcmJyZXJocmtyboJxgnSSd6J6sn3CgNKD8ocSiiKNQpBik4KWspnSnQKgIq
    NSpoKpsqzysCKzYraSudK9EsBSw5LG4soizXLQwtQS12Last4S4WLkwugi63
    Lu4vJC9aL5Evxy/+MDUwbDCkMNsxEjFKMYIxujHyMioyYzKbMtQzDTNGM38z
    uDPxNCs0ZTSeNNg1EzVNNYc1wjX9Njc2cjauNuk3JDdgN5w31zgUOFA4jDjI
    OQU5Qjl/Obw5+To2OnQ6sjrvOy07azuqO+g8JzxlPKQ84z0iPWE9oT3gPiA+
    YD6gPuA/IT9hP6I/4kAjQGRApkDnQSlBakGsQe5CMEJyQrVC90M6Q31DwEQD
    REdEikTORRJFVUWaRd5GIkZnRqtG8Ec1R3tHwEgFSEtIkUjXSR1JY0mpSfBK
    N0p9SsRLDEtTS5pL4kwqTHJMuk0CTUpNk03cTiVObk63TwBPSU+TT91QJ1Bx
    ULtRBlFQUZtR5lIxUnxSx1MTU19TqlP2VEJUj1TbVShVdVXCVg9WXFapVvdX
    RFeSV+BYL1h9WMtZGllpWbhaB1pWWqZa9VtFW5Vb5Vw1XIZc1l0nXXhdyV4a
    XmxevV8PX2Ffs2AFYFdgqmD8YU9homH1YklinGLwY0Njl2PrZEBklGTpZT1l
    kmXnZj1mkmboZz1nk2fpaD9olmjsaUNpmmnxakhqn2r3a09rp2v/bFdsr20I
    bWBtuW4SbmtuxG8eb3hv0XArcIZw4HE6cZVx8HJLcqZzAXNdc7h0FHRwdMx1
    KHWFdeF2Pnabdvh3VnezeBF4bnjMeSp5iXnnekZ6pXsEe2N7wnwhfIF84X1B
    faF+AX5ifsJ/I3+Ef+WAR4CogQqBa4HNgjCCkoL0g1eDuoQdhICE44VHhauG
    DoZyhteHO4efiASIaYjOiTOJmYn+imSKyoswi5aL/IxjjMqNMY2Yjf+OZo7O
    jzaPnpAGkG6Q1pE/kaiSEZJ6kuOTTZO2lCCUipT0lV+VyZY0lp+XCpd1l+CY
    TJi4mSSZkJn8mmia1ZtCm6+cHJyJnPedZJ3SnkCerp8dn4uf+qBpoNihR6G2
    oiailqMGo3aj5qRWpMelOKWpphqmi6b9p26n4KhSqMSpN6mpqhyqj6sCq3Wr
    6axcrNCtRK24ri2uoa8Wr4uwALB1sOqxYLHWskuywrM4s660JbSctRO1irYB
    tnm28Ldot+C4WbjRuUq5wro7urW7LrunvCG8m70VvY++Cr6Evv+/er/1wHDA
    7MFnwePCX8Lbw1jD1MRRxM7FS8XIxkbGw8dBx7/IPci8yTrJuco4yrfLNsu2
    zDXMtc01zbXONs62zzfPuNA50LrRPNG+0j/SwdNE08bUSdTL1U7V0dZV1tjX
    XNfg2GTY6Nls2fHadtr724DcBdyK3RDdlt4c3qLfKd+v4DbgveFE4cziU+Lb
    42Pj6+Rz5PzlhOYN5pbnH+ep6DLovOlG6dDqW+rl63Dr++yG7RHtnO4o7rTv
    QO/M8Fjw5fFy8f/yjPMZ86f0NPTC9VD13vZt9vv3ivgZ+Kj5OPnH+lf65/t3
    /Af8mP0p/br+S/7c/23//9IqKywtWiRjbGFzc25hbWVYJGNsYXNzZXNcTlND
    b2xvclNwYWNloi4vXE5TQ29sb3JTcGFjZVhOU09iamVjdNIqKzEyV05TQ29s
    b3KiMS8ACAARABoAJAApADIANwBJAEwAUQBTAF0AYwBuAHUAgQCOAJwApACm
    AKgAqgCsAK4AtQDJANQA4QDnAPwBBgEvATEBMwE1ATwBQQFHAUkBSwFNDZkN
    ng2pDbINvw3CDc8N2A3dDeUAAAAAAAACAQAAAAAAAAAzAAAAAAAAAAAAAAAA
    AAAN6A==
    </data>
    <key>backgroundColorName</key>
    <string>systemOrangeColor</string>
    <key>inputTypeIdentifier</key>
    <string>com.apple.Automator.fileSystemObject.image</string>
    <key>outputTypeIdentifier</key>
    <string>com.apple.Automator.nothing</string>
    <key>presentationMode</key>
    <integer>15</integer>
    <key>processesInput</key>
    <false/>
    <key>serviceApplicationBundleID</key>
    <string>com.apple.finder</string>
    <key>serviceApplicationPath</key>
    <string>/System/Library/CoreServices/Finder.app</string>
    <key>serviceInputTypeIdentifier</key>
    <string>com.apple.Automator.fileSystemObject.image</string>
    <key>serviceOutputTypeIdentifier</key>
    <string>com.apple.Automator.nothing</string>
    <key>serviceProcessesInput</key>
    <false/>
    <key>systemImageName</key>
    <string>NSActionTemplate</string>
    <key>useAutomaticInputType</key>
    <false/>
    <key>workflowTypeIdentifier</key>
    <string>com.apple.Automator.servicesMenu</string>
  </dict>
</dict>
</plist>
EOF

echo "🔄 重新載入 Finder..."
if killall Finder 2>/dev/null; then
  sleep 1
  echo "✅ Finder 已重新啟動，快速動作已激活"
else
  echo "⚠️  未能自動重啟 Finder，請手動重啟："
  echo "   按住 Option，右鍵點擊 Dock 中的 Finder，選擇「重新啟動」"
fi

echo ""
echo "🎉 安裝完成！"
echo "使用方式："
echo "Finder 選圖片 → 右鍵 → 快速動作 → 圖片減肥（PNG/JPG/WEBP）"
