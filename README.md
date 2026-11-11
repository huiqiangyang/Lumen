# Lumen 0.1.1 — Release

本仓库只存放 Lumen 的发布产物：由源码仓库的 `./scripts/make-release.sh` 汇总 `build/`
生成后同步过来，源码与构建脚本不在这里。构建自当前源码：按作用域排序的补全、
项目级查找用法、标签栏边缘箭头、welcome composer，以及 mygo v0.8.3。

## 文件一览

| 文件 | 平台 | 说明 |
|---|---|---|
| `Lumen-darwin-arm64.tar.gz` | macOS 13+ / Apple Silicon | 内含 `Lumen.app`，ad-hoc 签名、未公证 |
| `lumen-0.1.1-linux-amd64.tar.gz` | Linux x86-64 | `lumen` + `libghostty-vt.so` + desktop/图标，通用 ELF |
| `lumen_0.1.1_amd64.deb` | Debian / Ubuntu | `dpkg -i` |
| `install.sh` | Linux | 配合上面的 tar.gz，免 root 装到 `~/.local` |
| `PKGBUILD` | Arch Linux | 与 tar.gz、图标同目录 `makepkg -si` |
| `Lumen-windows-amd64.zip` | Windows x86-64 | `Lumen.exe` + `ghostty-vt.dll` 需保持同目录 |
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

# 免安装直接运行（libghostty-vt.so 必须与 lumen 同目录）
tar xzf lumen-0.1.1-linux-amd64.tar.gz && ./lumen
```

运行时依赖 GTK 3 与 WebKit2GTK 4.1（见 `PKGBUILD` 的 `depends`）。
Linux 产物是通用 glibc 动态链接二进制，没有 Nix / NixOS 专用包或适配层。

### Windows

解压 `Lumen-windows-amd64.zip` 到任意目录，保持 `Lumen.exe` 与
`ghostty-vt.dll` 在同一目录，双击 `Lumen.exe` 即可。

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

## 重新生成

以下命令在**源码仓库**执行；产物生成后把 `release/` 的内容同步到本仓库并提交。
脚本只打包、不编译：

```bash
go tool mygo build -platform darwin/arm64
go tool mygo build -platform linux/amd64
go tool mygo build -platform windows/amd64 -skip-installer
# macOS 的 .app 打成分发包：
(cd build/darwin-arm64 && tar czf ../deploy/Lumen-darwin-arm64.tar.gz Lumen.app)
./scripts/make-release.sh
```

在 Linux / macOS 上交叉构建 Windows 时加 `-skip-installer`（NSIS 安装器只在
Windows 本机生成）。`resources/windows-amd64/Lumen.ico` 由构建自动放到产物旁，
不需要手工补。脚本从 `mygo.json` 读版本号，升级版本只需改那一处。

脚本会清空 `release/` 中除本 README 外的旧产物，重新复制、打包并写 `SHA256SUMS`；
随后把 `release/` 的内容同步到产物仓库发布。

## 发布仓库的约定

产物仓库（`github.com/huiqiangyang/Lumen`）只保留**一个 commit**。里面全是几十 MB
的二进制，累积历史会让仓库永久膨胀；每次发布都用当前产物造一个无父提交，然后
强制推送覆盖远端：

```bash
cd ../Lumen-release
find . -mindepth 1 -maxdepth 1 ! -name .git ! -name README.md -exec rm -rf {} +
cp -a ../lumen/release/. .
git add -A
single=$(git commit-tree "$(git write-tree)" -m "Release 0.1.1: macOS/Linux/Windows builds and plugin archives")
git reset --hard "$single"
git push --force origin main
```

强制推送会覆盖远端 `main`，推送前确认远端没有别人的改动。
