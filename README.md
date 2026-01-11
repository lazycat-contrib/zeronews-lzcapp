# ZeroNews - 零讯内网穿透平台

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform: LazyCat Cloud](https://img.shields.io/badge/Platform-LazyCat%20Cloud-blue)](https://lazycat.cloud)

## 简介

ZeroNews（零讯）是一个创新的边缘云内网穿透平台，通过自研高性能 zeronews tunnel 协议，帮助用户快速解决内网与外网之间的安全、快速访问需求。无需更改内网网络环境或安装 VPN，即可便捷地访问内网应用及资源。

## 核心特性

- 🚀 **免安装 Agent** - 下载即可快速运行，无需系统依赖
- 🔒 **安全可靠** - 采用先进的加密技术，确保数据传输安全
- ⚡ **高性能协议** - 自研 zeronews tunnel 协议，提供超快的传输速度
- 🌐 **无需 VPN** - 不需要复杂的 VPN 配置，简单快捷
- 💻 **跨平台支持** - 支持 Windows、macOS、Linux、Openwrt、树莓派等
- 📱 **多架构兼容** - 同时支持 x86 和 ARM 架构的系统及设备

## 支持平台

- Windows (x86/x64)
- macOS (Intel/Apple Silicon)
- Linux (x86/x64)
- Linux (ARM/ARM64)
- Openwrt
- 树莓派

## 应用场景

- **远程办公** - 在家也能访问公司内网资源
- **开发调试** - 快速将本地服务暴露到公网
- **物联网设备** - 轻松访问内网的智能家居设备
- **数据同步** - 安全地在不同网络间同步和传输数据

## 安装说明

### 前置要求

1. 注册 ZeroNews 账户并获取 Token
   - 访问 https://user.zeronews.cc/login
   - 登录您的账户
   - 在 Token 页面复制您的认证令牌

2. 准备应用图标
   - 需要提供一个 512x512 像素的 PNG 格式图标
   - 将图标命名为 `icon.png` 并放置在应用根目录

### 在懒猫云平台安装

1. 使用构建脚本构建应用：
   ```bash
   ./build.sh
   # 选择 1 - 构建应用
   ```

2. 安装到本地懒猫云：
   ```bash
   lzc-cli app install cloud.lazycat.app.zeronews-1.0.0.lpk
   ```

3. 在设置向导中输入您的 ZeroNews Token

### 发布到应用商店

如果您想将应用发布到懒猫应用商店：

1. 登录懒猫应用商店：
   ```bash
   lzc-cli appstore login
   ```

2. 使用一键发布功能：
   ```bash
   ./build.sh
   # 选择 4 - 一键构建+镜像复制+发布
   ```

   或者分步执行：
   ```bash
   # 步骤 1: 构建应用
   ./build.sh --build

   # 步骤 2: 复制镜像到懒猫仓库
   ./build.sh --copy-image

   # 步骤 3: 重新构建（使用新镜像）
   ./build.sh --build

   # 步骤 4: 发布到应用商店
   ./build.sh --publish
   ```

## 配置说明

### 设置向导参数

- **zeronews_token** (必填)
  - ZeroNews 认证令牌
  - 从 https://user.zeronews.cc/login 获取
  - 格式：字母、数字、下划线、短横线

### 存储路径

- `/lzcapp/var/config` - ZeroNews 配置目录（持久化存储）

### 网络配置

- **网络模式**: host（主机网络模式）
  - ZeroNews 需要直接访问主机网络以实现内网穿透功能

### 介绍页面

应用包含一个完整的 HTML 介绍页面（`content/index.html`），展示了 ZeroNews 的功能特性、使用说明和应用场景。

## 文件结构

```
zeronews-lzcapp/
├── lzc-manifest.yml          # 应用配置清单
├── lzc-deploy-params.yml     # 设置向导配置
├── lzc-build.yml             # 构建配置
├── build.sh                  # 自动化构建脚本
├── icon.png                  # 应用图标 (512x512 PNG)
├── content/                  # 内容目录
│   └── index.html           # 介绍页面
└── README.md                 # 本文档
```

## 构建脚本使用

`build.sh` 提供了完整的构建和发布功能：

### 菜单选项

1. **构建应用** - 构建 LPK 安装包
2. **镜像复制** - 复制 Docker 镜像到懒猫仓库
3. **发布到应用商店** - 发布应用到懒猫应用商店
4. **一键发布** - 自动完成构建、镜像复制、发布全流程
5. **查看应用信息** - 显示应用配置信息
6. **检查文件** - 验证所有必要文件是否存在
7. **验证配置** - 检查配置文件格式
8. **退出**

### 命令行参数

```bash
# 直接构建
./build.sh --build

# 复制镜像
./build.sh --copy-image

# 发布应用
./build.sh --publish

# 一键发布
./build.sh --one-click

# 查看信息
./build.sh --info
```

## 技术特性

### 应用配置

- **后台任务**: 启用（`background_task: true`）
  - ZeroNews 作为后台服务持续运行，不会因不活跃而被系统停止
- **资源限制**:
  - CPU: 512 shares
  - 内存: 512M
- **重启策略**: always（始终重启）

### Docker 镜像

- **原始镜像**: `zeronews/zeronews:latest`
- **懒猫仓库镜像**: 使用 `lzc-cli appstore copy-image` 复制后自动更新

## 常见问题

### Q: 如何获取 ZeroNews Token？

A: 访问 https://user.zeronews.cc/login，登录后在 Token 页面复制您的认证令牌。

### Q: 为什么需要 host 网络模式？

A: ZeroNews 作为内网穿透工具，需要直接访问主机网络以建立穿透隧道。

### Q: 应用图标在哪里获取？

A: 您需要自行提供一个 512x512 像素的 PNG 格式图标，可以从 ZeroNews 官网或设计一个。

### Q: 构建失败怎么办？

A: 首先运行 `./build.sh` 选择"检查文件"和"验证配置"，确保所有必要文件都存在且格式正确。

## 资源链接

- **ZeroNews 官网**: https://zeronews.cc
- **用户登录**: https://user.zeronews.cc/login
- **懒猫云开发者文档**: https://developer.lazycat.cloud

## 版本历史

### v1.0.0 (2024-01)
- 初始版本
- 支持基础内网穿透功能
- 集成懒猫云平台设置向导
- 包含完整介绍页面

## 许可证

MIT License

## 作者

ZeroNews Team

## 贡献

欢迎提交问题和改进建议！

---

**注意**: 使用本应用前，请确保您已经注册 ZeroNews 账户并获取了有效的 Token。
# zeronews-lzcapp
