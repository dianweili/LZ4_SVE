# LZ4 ARM64 编译指南 - Windows 版本

## 🎯 Windows 上的三种编译方法

### 方法 1：使用 WSL2（推荐）

#### 步骤 1：打开 WSL2 终端

```powershell
# 在 PowerShell 中
wsl

# 或在命令提示符中
cmd
wsl
```

#### 步骤 2：进入项目目录

```bash
# 项目在 e:/Project1/lz4/lz4
cd /mnt/e/Project1/lz4/lz4

# 或使用 E 盘挂载点
cd /e/Project1/lz4/lz4
```

#### 步骤 3：安装交叉编译器（首次需要）

```bash
sudo apt update
sudo apt install -y gcc-aarch64-linux-gnu g++-aarch64-linux-gnu

# 验证
aarch64-linux-gnu-gcc --version
```

#### 步骤 4：编译

```bash
# 使用提供的脚本
bash build_arm64.sh

# 或手动编译
export CC=aarch64-linux-gnu-gcc
export CFLAGS="-march=armv9-a+sve2 -O3"
make clean && make
```

---

### 方法 2：直接在 WSL2 中使用 Make

```bash
# 进入项目目录
cd /mnt/e/Project1/lz4/lz4

# 一键编译
make CC=aarch64-linux-gnu-gcc CFLAGS="-march=armv9-a+sve2 -O3"
```

---

### 方法 3：使用 Docker（最简单，无需安装任何工具）

```powershell
# 在 PowerShell 中运行
docker-compose up

# 或手动构建
docker build -f Dockerfile.arm64 -t lz4-arm64 .
```

---

## 📝 详细步骤

### 完整流程（WSL2）

```bash
# 1. 打开 WSL2
wsl

# 2. 进入项目
cd /mnt/e/Project1/lz4/lz4

# 3. 安装工具（首次需要）
sudo apt install -y build-essential gcc-aarch64-linux-gnu

# 4. 编译
make clean
make CC=aarch64-linux-gnu-gcc CFLAGS="-march=armv9-a+sve2 -O3" -j$(nproc)

# 5. 验证
file programs/lz4

# 6. 测试（使用 QEMU）
sudo apt install -y qemu-user-static
qemu-aarch64-static programs/lz4 -V
```

---

## 🔧 Makefile 编译选项参考

LZ4 项目使用标准的 GNU Makefile，支持以下变量：

### 编译器设置

```bash
# 设置交叉编译器
export CC=aarch64-linux-gnu-gcc
export CXX=aarch64-linux-gnu-g++
export AR=aarch64-linux-gnu-ar
export STRIP=aarch64-linux-gnu-strip
```

### 编译标志设置

```bash
# 方式 1：通过 CFLAGS 环境变量
export CFLAGS="-march=armv9-a+sve2 -O3"
make

# 方式 2：通过 make 命令行
make CFLAGS="-march=armv9-a+sve2 -O3"

# 方式 3：通过 USERCFLAGS（Makefile 内部使用）
make USERCFLAGS="-march=armv9-a+sve2 -O3"
```

### 完整编译命令示例

```bash
make clean
make \
  CC=aarch64-linux-gnu-gcc \
  CXX=aarch64-linux-gnu-g++ \
  AR=aarch64-linux-gnu-ar \
  STRIP=aarch64-linux-gnu-strip \
  CFLAGS="-march=armv9-a+sve2 -O3 -DHAVE_SVE2" \
  CXXFLAGS="-march=armv9-a+sve2 -O3"
```

---

## 📋 Makefile 工作方式

查看 `programs/Makefile` 的关键行：

```makefile
# 第 52-53 行
USERCFLAGS:= -O3 $(CFLAGS)  # 用户提供的 CFLAGS
CFLAGS    = $(DEBUGFLAGS) $(USERCFLAGS)  # 最终 CFLAGS

# 第 49-53 行
DEBUGFLAGS= -Wall -Wextra -Wundef...
CFLAGS    = $(DEBUGFLAGS) $(USERCFLAGS)
```

### 变量优先级

1. `CFLAGS`（命令行）- 最高优先级
2. `USERCFLAGS`（命令行）
3. `CFLAGS`（环境变量）
4. 内置的 `DEBUGFLAGS`

---

## 🚀 快速编译命令

### 最简单的方式

```bash
# 在 WSL2 中
cd /mnt/e/Project1/lz4/lz4
make CC=aarch64-linux-gnu-gcc CFLAGS="-march=armv9-a+sve2 -O3"
```

### 使用脚本

```bash
# 在 WSL2 中运行
bash build_arm64.sh

# 或从 PowerShell 运行
wsl bash build_arm64.sh
```

### 使用 Docker

```powershell
# 在 PowerShell 中
docker-compose up
```

---

## ⚠️ Windows 特定注意事项

### 1. 不要在 Windows 路径中使用空格

```bash
# ❌ 错误
cd /mnt/c/Program Files/lz4

# ✅ 正确
cd "E:\Project1\lz4\lz4"  # 在 WSL 中用
cd /mnt/e/Project1/lz4/lz4
```

### 2. 使用 WSL2 而不是 WSL1

```powershell
# 检查 WSL 版本
wsl -l -v

# 如果是 VERSION 1，升级到 WSL2
wsl --set-version <distro> 2
```

### 3. 符号链接问题

如果在 Windows 文件系统中编译失败：

```bash
# 使用 WSL 的文件系统
cd ~/projects/lz4  # WSL 内部路径
# 而不是 /mnt/e/...（Windows 挂载路径）
```

---

## ✅ 验证编译结果

```bash
# 检查架构
file programs/lz4

# 检查 SVE2 符号（如果有）
aarch64-linux-gnu-nm programs/lz4 | grep sve2

# 简单测试（需要 QEMU）
qemu-aarch64-static programs/lz4 -V
```

---

## 📚 快速参考

| 操作 | 命令 |
|-----|------|
| 打开 WSL2 | `wsl` |
| 进入项目 | `cd /mnt/e/Project1/lz4/lz4` |
| 编译 | `make CC=aarch64-linux-gnu-gcc CFLAGS="-march=armv9-a+sve2 -O3"` |
| 清理 | `make clean` |
| 验证 | `file programs/lz4` |

---

## 💡 提示

1. **使用 WSL2** 获得完整的 Linux 环境
2. **在 WSL 的文件系统**中工作，避免跨文件系统问题
3. **使用提供的脚本** `build_arm64.sh` 自动化编译过程
4. **使用 Docker** 最简单，无需安装任何本地工具
