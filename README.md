# Unpacka / 解包鸭

解包鸭是一款面向 macOS 的轻量压缩与解压工具，目标是提供简单、快速、适合中文用户的归档体验。

## 当前功能

- 解压：`.zip`、`.tar`、`.tar.gz`、`.tgz`、`.gz`、`.tar.bz2`、`.tbz2`、`.bz2`、`.tar.xz`、`.txz`、`.xz`
- 压缩：`.zip`、`.tar`、`.tar.gz`、`.tar.bz2`、`.tar.xz`
- 7Z：安装 `7zz` 或 `7z` 后支持 `.7z` 解压和压缩
- RAR：安装 `unrar` 或 `7zz/7z` 后支持 `.rar` 解压；安装 `rar` 后支持 `.rar` 压缩
- 拖拽解压
- 批量选择解压
- 选择文件或文件夹后压缩
- 自动创建输出文件夹
- 文件头识别格式，不只依赖扩展名
- SwiftUI 原生 macOS 界面
- Rust Core 目录已预留，用于后续接入高性能解压核心

## 使用方法

### 解压文件

1. 打开 `Unpacka.app`。
2. 把压缩包拖到主界面的投放区域。
3. 也可以点击右上角的“解压”按钮，选择一个或多个压缩包。
4. 解压结果默认输出到压缩包同级目录下的同名文件夹。

示例：

```text
~/Downloads/demo.zip
→ ~/Downloads/demo/
```

### 压缩文件或文件夹

1. 在窗口右上角选择压缩格式，例如 `ZIP`、`TAR`、`GZ`、`BZ2`、`XZ`。
2. 点击“压缩”按钮。
3. 选择要压缩的文件或文件夹。
4. 生成的压缩包会输出到第一个所选项目的同级目录。

示例：

```text
~/Desktop/photos/
→ ~/Desktop/photos.zip
```

### 7Z 和 RAR 支持

macOS 默认不内置 7Z/RAR 后端。需要额外安装命令行工具：

```bash
brew install sevenzip
brew install unrar
```

RAR 压缩通常需要单独的 `rar` 命令，取决于本机安装和授权情况。

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
dist/Unpacka-macOS-arm64.dmg
dist/Unpacka-macOS-x86_64.dmg
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

