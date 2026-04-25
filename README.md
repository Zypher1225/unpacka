# Unpacka / 解包鸭

解包鸭是一款面向 macOS 的轻量压缩与解压工具，目标是提供简单、快速、适合中文用户的归档体验。

## 当前功能

- 解压：`.zip`、`.tar`、`.tar.gz`、`.tgz`、`.gz`、`.tar.bz2`、`.tbz2`、`.bz2`、`.tar.xz`、`.txz`、`.xz`
- 压缩：`.zip`、`.tar`、`.tar.gz`、`.tar.bz2`、`.tar.xz`
- 7Z：内置 7-Zip 后端，支持 `.7z` 解压和压缩
- RAR：内置 7-Zip 后端，支持常见 `.rar` 解压
- 双击或右键打开压缩包后，先浏览内容，再选择是否解压
- 拖拽解压
- 批量选择解压
- 选择文件或文件夹后压缩，可选择格式、路径和密码
- 自动创建输出文件夹
- 文件头识别格式，不只依赖扩展名
- SwiftUI 原生 macOS 界面
- Rust Core 目录已预留，用于后续接入高性能解压核心

## 使用方法

### 解压文件

1. 打开 `解包鸭.app`。
2. 把压缩包拖到主界面的投放区域。
3. 也可以点击右上角的“解压”按钮，选择一个或多个压缩包。
4. 解包鸭会先展示压缩包内容。
5. 选择输出路径，必要时输入密码。
6. 点击“解压全部”。

示例：

```text
~/Downloads/demo.zip
→ ~/Downloads/demo/
```

### 压缩文件或文件夹

1. 点击“压缩”按钮。
2. 选择要压缩的文件或文件夹。
3. 在压缩设置里选择格式，例如 `ZIP`、`7Z`、`TAR`、`GZ`、`BZ2`、`XZ`。
4. 选择保存路径。
5. 如需加密，可为 `ZIP` 或 `7Z` 输入密码。
6. 点击“开始压缩”。

示例：

```text
~/Desktop/photos/
→ ~/Desktop/photos.zip
```

### 7Z 和 RAR 支持

解包鸭的 DMG 已内置 7-Zip 后端，用户不需要额外安装 `7zz` 或 `7z`。

RAR 解压通过内置 7-Zip 后端支持。RAR 压缩暂不作为内置功能提供，因为官方 `rar` 压缩工具是专有授权，直接随 App 分发并不适合第一版。

如果你的 Mac 已额外安装 `rar` 命令，解包鸭会检测并启用 RAR 压缩。

### 双击和右键打开

安装 `解包鸭.app` 后，macOS 会识别它可以打开常见压缩包格式。你可以：

- 右键压缩包，选择“打开方式”中的“解包鸭”
- 在 Finder 里对某个压缩包选择“显示简介”，把“打开方式”改成“解包鸭”，再点击“全部更改”

macOS 不会强制新安装的 App 立刻抢占系统默认压缩包处理器，所以如果双击仍然进入“归档实用工具”，请按上面的方式手动设为默认。

### 密码支持

- 加密解压：支持 ZIP / 7Z / 常见 RAR
- 加密压缩：支持 ZIP / 7Z
- RAR 压缩：暂不内置

### 解压路径

打开压缩包后，可以在预览页点击“选择位置”指定输出目录。设置页中也保留了默认路径、冲突策略、编码策略和性能模式，后续会继续完善持久化保存。

## 本地开发

### 构建 SwiftUI App

```bash
cd /Users/yuhao/Projects/Unpacka/apps/macos
swift build
```

### 运行测试

```bash
cd /Users/yuhao/Projects/Unpacka/apps/macos
swift test

cd /Users/yuhao/Projects/Unpacka/core
cargo test
```

### 生成 DMG

```bash
cd /Users/yuhao/Projects/Unpacka
./scripts/package_dmg.sh
```

生成文件会放在：

```text
dist/Unpacka-版本号-macOS-arm64.dmg
dist/Unpacka-版本号-macOS-x86_64.dmg
```

## 项目结构

```text
Unpacka/
├── apps/macos/          SwiftUI macOS 应用
├── core/                Rust Core 骨架
├── scripts/             构建与打包脚本
├── vendor/              第三方后端预留目录
└── dist/                发布产物输出目录
```

## 发布流程

```bash
git tag v0.1.0
git push origin main
git push origin v0.1.0
```

DMG 可以通过 GitHub Release 上传。
