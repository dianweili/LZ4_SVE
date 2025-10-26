# LZ4 ARM64 编译快速指南

## 🚀 三种编译方法

### 方法 1：使用提供的脚本（最简单）

#### Windows
```cmd
REM 使用 WSL
wsl bash build_arm64.sh

REM 或使用批处理
build_arm64.bat
```

#### Linux/macOS
```bash
chmod +x build_arm64.sh
./build_arm64.sh
```

---

### 方法 2：直接使用 Makefile（推荐）

#### 在 Windows (WSL) 中

```bash
# 1. 设置编译器
export CC=aarch64-linux-gnu-gcc
export CFLAGS="-march=armv9-a+sve2 -O3"

# 2. 编译
cd e:/Project1/lz4/lz4
make clean
make

# 3. 验证
file programs/lz4
# 输出: ARM aarch64
```

#### 在 Linux 中

```bash
# 安装交叉编译器（如果还没有）
sudo apt install gcc-aarch64-linux-gnu

# 编译
make CC=aarch64-linux-gnu-gcc CFLAGS="-march=armv9-a+sve2 -O3"

# 验证
file programs/lz4
```

---

### 方法 3：使用 Docker（无需安装工具链）

```bash
# 自动编译并测试
docker-compose up

# 或手动构建
docker build -f Dockerfile.arm64 -t lz4-arm64 .
```

---

## 📝 详细步骤

### 步骤 1：确认工具链

```bash
# 检查是否有交叉编译器
which aarch64-linux-gnu-gcc

# 如果没有，安装
sudo apt update
sudo apt install gcc-aarch64-linux-gnu g++-aarch64-linux-gnu
```

### 步骤 2：编译

```bash
# 进入项目目录
cd /path/to/lz4

# 方法 A：使用环境变量
export CC=aarch64-linux-gnu-gcc
export CFLAGS="-march=armv9-a+sve2 -O3"
make clean && make

# 方法 B：在 make 命令中指定
make clean
make CC=aarch64-linux-gnu-gcc CFLAGS="-march=armv9-a+sve2 -O3"

# 方法 C：同时指定多个工具
make CC=aarch64-linux-gnu-gcc \
     CXX=aarch64-linux-gnu-g++ \
     CFLAGS="-march=armv9-a+sve2 -O3" \
     CXXFLAGS="-march=armv9-a+sve2 -O3"
```

### 步骤 3：验证

```bash
# 检查二进制文件架构
file programs/lz4
# 应显示: ELF 64-bit LSB executable, ARM aarch64

# 使用 QEMU 运行测试（如果安装了 QEMU）
qemu-aarch64-static programs/lz4 -V
```

---

## 🎯 常见场景

### 场景 1：在 Windows 上编译（使用 WSL2）

```bash
# 打开 WSL2 终端
wsl

# 进入项目目录
cd /mnt/e/Project1/lz4/lz4

# 运行编译脚本
bash build_arm64.sh
```

### 场景 2：在 Linux 上编译

```bash
# 直接使用 Makefile
make CC=aarch64-linux-gnu-gcc CFLAGS="-march=armv9-a+sve2 -O3"
```

### 场景 3：使用 Docker（无需本地工具链）

```bash
# 构建镜像
docker build -f Dockerfile.arm64 -t lz4-arm64 .

# 运行测试
docker run --rm lz4-arm64 lz4 -V

# 或进入容器调试
docker run --rm -it lz4-arm64 bash
```

### 场景 4：在云 ARM 实例上编译

```bash
# 直接编译（无需交叉编译）
cd /path/to/lz4
make CFLAGS="-march=armv9-a+sve2 -O3" -j$(nproc)

# 运行测试
./programs/lz4 -V
./test_sve2.sh
```

---

## ⚙️ 编译选项说明

### 基本选项

| 选项 | 说明 |
|-----|------|
| `CC=gcc` | 指定 C 编译器 |
| `CXX=g++` | 指定 C++ 编译器 |
| `CFLAGS=...` | C 编译器标志 |
| `CXXFLAGS=...` | C++ 编译器标志 |
| `LDFLAGS=...` | 链接器标志 |

### SVE2 特定选项

| 选项 | 说明 |
|-----|------|
| `-march=armv9-a+sve2` | 启用 SVE2 指令集 |
| `-march=armv8.5-a+sve2` | ARMv8.5 版本的 SVE2 |
| `-DHAVE_SVE2` | 启用 SVE2 检测宏 |
| `-O3` | 最高优化级别 |

---

## 🔍 故障排除

### 问题 1：找不到交叉编译器

```bash
# Windows (WSL2)
sudo apt install gcc-aarch64-linux-gnu

# Linux
sudo apt install gcc-aarch64-linux-gnu g++-aarch64-linux-gnu

# macOS
brew install gcc-aarch64-linux-gnu
```

### 问题 2：编译错误 "unsupported -march"

```bash
# 检查 GCC 版本（需要 10+）
aarch64-linux-gnu-gcc --version

# 如果版本太低，更新 GCC
sudo apt install gcc-11-aarch64-linux-gnu
```

### 问题 3：Makefile 不识别变量

```bash
# 使用明确的变量名
make USERCFLAGS="-march=armv9-a+sve2 -O3" CC=aarch64-linux-gnu-gcc
```

### 问题 4：符号链接错误（Windows）

```bash
# 在 WSL 中运行
wsl bash build_arm64.sh

# 或使用 Docker
docker-compose up
```

---

## 📊 编译后的验证

### 1. 检查架构

```bash
file programs/lz4
# 应输出: ELF 64-bit LSB executable, ARM aarch64
```

### 2. 查看符号

```bash
aarch64-linux-gnu-nm programs/lz4 | grep lz4
```

### 3. 功能测试（使用 QEMU）

```bash
# 安装 QEMU
sudo apt install qemu-user-static

# 运行测试
qemu-aarch64-static programs/lz4 -V
echo "test" | qemu-aarch64-static programs/lz4 | qemu-aarch64-static programs/lz4 -d
```

---

## 📚 相关文档

- `BUILD_ARM64.md` - 详细编译指南
- `ARM_TESTING_GUIDE.md` - 测试指南  
- `SVE2_OPTIMIZATION.md` - 技术文档
- `QUICKSTART.md` - 快速开始
