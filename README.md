# Lumen 0.1.1 — Release

本仓库只存放 Lumen 的发布产物，由源码仓库生成后同步过来；源码与构建脚本不在这里。
构建自当前源码：按作用域排序的补全、项目级查找用法、标签栏边缘箭头与 welcome composer。

## 文件一览

| 文件 | 平台 | 说明 |
|---|---|---|
| `Lumen-darwin-arm64.tar.gz` | macOS 13+ / Apple Silicon | 内含 `Lumen.app`，ad-hoc 签名、未公证 |
| `lumen-0.1.1-linux-amd64.tar.gz` | Linux x86-64 | `lumen`、运行库与 desktop/图标，通用二进制 |
| `lumen_0.1.1_amd64.deb` | Debian / Ubuntu | `dpkg -i` |
| `install.sh` | Linux | 配合上面的 tar.gz，免 root 装到 `~/.local` |
| `PKGBUILD` | Arch Linux | 与 tar.gz、图标同目录 `makepkg -si` |
| `Lumen-windows-amd64.zip` | Windows x86-64 | 解压后保持包内全部文件同目录 |
| `Lumen-plugins-0.1.1.zip` | 全平台 | 9 个示例插件的批量包 |
| `plugins/<id>.zip` | 全平台 | 单个插件，供设置界面从 zip 安装 |
| `SHA256SUMS` | — | 上述产物的校验和（不含本 README） |

## 校验

```bash
cd release
sha256sum -c SHA256SUMS        # Linux
shasum -a 256 -c SHA256SUMS    # macOS
```

Windows（PowerShell）：`Get-FileHash -Algorithm SHA256 <文件>`，与 `SHA256SUMS` 对照。

## 安装

### macOS

```bash
tar xzf Lumen-darwin-arm64.tar.gz -C ~/Applications/
xattr -cr ~/Applications/Lumen.app      # 去掉隔离属性
open -a ~/Applications/Lumen.app
```

应用是 ad-hoc 签名、未经公证。若 Gatekeeper 提示「已损坏」或「无法验证开发者」，
执行上面的 `xattr -cr`，或到「系统设置 → 隐私与安全性」点「仍要打开」。
升级时先退出正在运行的 Lumen，再替换 `Lumen.app`；建议保留旧版备份。

### Linux

```bash
# 用户级安装（推荐）：install.sh 会自动使用同目录的 tar.gz
sh install.sh
sh install.sh --uninstall        # 卸载，保留设置与数据

# Debian / Ubuntu
sudo dpkg -i lumen_0.1.1_amd64.deb

# Arch：把 tar.gz、PKGBUILD、两个 png 放同一目录
makepkg -si

# 免安装直接运行（包内全部文件保持同目录）
tar xzf lumen-0.1.1-linux-amd64.tar.gz && ./lumen
```

Linux 产物是通用二进制；桌面运行库由各发行版的包管理器按常规方式提供
（Arch 由 `PKGBUILD` 自动处理）。

### Windows

解压 `Lumen-windows-amd64.zip` 到任意目录，保持包内全部文件在同一目录，
双击 `Lumen.exe` 即可。

## 插件

应用**不预装任何插件**：第三方主题 / 键位预设、语言包、按语言着色的文件图标、
公式与图表渲染、外部 Agent 的会话标题解析都由 `examples/` 下的插件提供。
契约与排错见 `docs/USING-PLUGINS.md`。

- 批量安装：把 `Lumen-plugins-0.1.1.zip` 解压到数据目录的 `plugins/`，
  每个顶层目录名即插件 `id`：
  ```bash
  unzip Lumen-plugins-0.1.1.zip -d ~/.config/Lumen/plugins/
  ```
- 单个安装：**设置 → Plugins → `+` → From Zip Archive…**，选择
  `plugins/<id>.zip`（支持「一个顶层文件夹包着 `plugin.json`」）。
  也可以把某个目录直接拷进 `plugins/<id>/`。
- 装完点 Plugins 面板右上角刷新。

数据目录：

| 系统 | 路径 |
|---|---|
| macOS | `~/Library/Application Support/Lumen` |
| Linux | `$XDG_CONFIG_HOME/Lumen`，未设则 `~/.config/Lumen` |
| Windows | `%AppData%\Lumen` |

可用 `LUMEN_DATA_DIR=~/lumen-dev` 指向独立目录做隔离测试。
