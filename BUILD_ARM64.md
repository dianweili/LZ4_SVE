# LZ4 ARM64 编译指南

使用 LZ4 项目自带的 Makefile 进行 ARM64 交叉编译。

## 方法 1：使用交叉编译工具链

### 1. 安装 ARM64 交叉编译工具

#### Windows (WSL2/Cygwin)
```bash
# 在 WSL2 中
sudo apt update
sudo apt install -y gcc-aarch64-linux-gnu g++-aarch64-linux-gnu

# 验证安装
aarch64-linux-gnu-gcc --version
```

#### Linux (Ubuntu/Debian)
```bash
sudo apt update
sudo apt install -y gcc-aarch64-linux-gnu g++-aarch64-linux-gnu binutils-aarch64-linux-gnu
```

#### macOS
```bash
brew install gcc-aarch64-linux-gnu
```

### 2. 配置交叉编译环境

```bash
# 设置编译器
export CC=aarch64-linux-gnu-gcc
export CXX=aarch64-linux-gnu-g++
export AR=aarch64-linux-gnu-ar
export STRIP=aarch64-linux-gnu-strip

# 设置编译选项（启用 SVE2）
export CFLAGS="-march=armv9-a+sve2 -O3 -DHAVE_SVE2"
```

### 3. 编译项目

```bash
# 清理之前的构建
make clean

# 编译库
make -C lib CFLAGS="$CFLAGS" CC="$CC"

# 编译程序
make -C programs CFLAGS="$CFLAGS" CC="$CC"

# 或使用顶层 Makefile（自动传递变量）
make CFLAGS="$CFLAGS" CC="$CC" CXX="$CXX"
```

---

## 方法 2：使用 LZ4 Makefile 的 CFLAGS 参数

LZ4 Makefile 支持通过环境变量或命令行参数传递编译选项：

```bash
# 方式 1：使用环境变量
export CFLAGS="-march=armv9-a+sve2 -O3"
make

# 方式 2：直接在 make 命令中指定
make CFLAGS="-march=armv9-a+sve2 -O3"

# 方式 3：同时指定编译器和选项
make CC=aarch64-linux-gnu-gcc CFLAGS="-march=armv9-a+sve2 -O3"
```

### 完整编译命令

```bash
# 编译带 SVE2 优化的版本
make clean
make CC=aarch64-linux-gnu-gcc \
     CXX=aarch64-linux-gnu-g++ \
     CFLAGS="-march=armv9-a+sve2 -O3 -DHAVE_SVE2" \
     CXXFLAGS="-march=armv9-a+sve2 -O3"
```

---

## 方法 3：使用 make 变量覆盖

查看 Makefile 中使用 `USERCFLAGS` 的位置：

```52:53:programs/Makefile
USERCFLAGS:= -O3 $(CFLAGS) # -O3 can be overruled by user-provided -Ox level
CFLAGS    = $(DEBUGFLAGS) $(USERCFLAGS)
```

可以覆盖 `USERCFLAGS`：

```bash
make USERCFLAGS="-march=armv9-a+sve2 -O3 -DHAVE_SVE2"
```

---

## 方法 4：修改 Makefile（不推荐，但可行）

如果上述方法都不工作，可以临时修改 Makefile：

### 在 `lib/Makefile` 中：

```makefile
# 添加或修改
CFLAGS += -march=armv9-a+sve2 -O3 -DHAVE_SVE2
CC = aarch64-linux-gnu-gcc
```

### 在 `programs/Makefile` 中：

```makefile
# 修改
USERCFLAGS := -march=armv9-a+sve2 -O3 -DHAVE_SVE2
CC = aarch64-linux-gnu-gcc
```

---

## 完整编译示例

### 示例 1：基础 ARM64 编译

```bash
# 设置环境
export CC=aarch64-linux-gnu-gcc
export CFLAGS="-march=armv9-a+sve2 -O3"

# 编译
cd e:/Project1/lz4/lz4
make clean
make

# 验证
file programs/lz4
# 应输出：programs/lz4: ELF 64-bit LSB executable, ARM aarch64
```

### 示例 2：完整编译测试流程

```bash
#!/bin/bash
# build_arm64.sh

# 设置交叉编译环境
export CC=aarch64-linux-gnu-gcc
export CXX=aarch64-linux-gnu-g++
export AR=aarch64-linux-gnu-ar
export STRIP=aarch64-linux-gnu-strip
export RANLIB=aarch64-linux-gnu-ranlib

# 设置编译选项（启用 SVE2）
export CFLAGS="-march=armv9-a+sve2 -O3"
export CXXFLAGS="-march=armv9-a+sve2 -O3"

# 清理
make clean

# 编译
echo "Building for ARM64 with SVE2..."
make

# 验证编译结果
echo "Verifying build..."
file programs/lz4

# 检查 SVE2 符号
echo "Checking for SVE2 support..."
aarch64-linux-gnu-readelf -h lib/lz4.o | grep Machine
```

### 示例 3：Docker 中编译（推荐）

```bash
# 使用 Docker 环境
docker run --rm -it \
  -v "$(pwd):/work" \
  -w /work \
  arm64v8/ubuntu:22.04 bash -c \
  "apt-get update -qq && \
   apt-get install -y -qq build-essential && \
   make CFLAGS='-march=armv9-a+sve2 -O3'"
```

---

## 验证编译结果

### 1. 检查目标平台

```bash
# 查看二进制文件架构
file programs/lz4
# 输出: ELF 64-bit LSB executable, ARM aarch64

# 或使用 objdump
aarch64-linux-gnu-objdump -f programs/lz4 | grep architecture
# 输出: architecture: aarch64
```

### 2. 检查 SVE2 指令

```bash
# 反汇编查看 SVE2 指令
aarch64-linux-gnu-objdump -d lib/lz4.o | grep -i "svld1\|svst1\|svcntb"

# 检查是否包含 SVE2 函数
aarch64-linux-gnu-nm lib/lz4.o | grep -i sve2
```

### 3. 功能测试（使用 QEMU）

```bash
# 在 Linux 上安装 QEMU
sudo apt install qemu-user-static

# 运行 ARM64 二进制（自动使用 QEMU 模拟）
qemu-aarch64-static programs/lz4 -V

# 简单功能测试
echo "test" | qemu-aarch64-static programs/lz4 | qemu-aarch64-static programs/lz4 -d
```

---

## 常见问题

### Q: 如何指定特定的 ARM CPU？

```bash
# 针对特定 ARM CPU 优化
make CFLAGS="-mcpu=cortex-a78 -O3"
make CFLAGS="-mcpu=cortex-x1 -O3"
make CFLAGS="-mcpu=neoverse-n2 -O3"
```

### Q: Makefile 报错找不到交叉编译器？

```bash
# 确保工具链在 PATH 中
which aarch64-linux-gnu-gcc

# 或者在 Makefile 中明确指定
make CC=/usr/bin/aarch64-linux-gnu-gcc
```

### Q: 如何禁用 DEBUG 标志？

```bash
# Makefile 默认包含 DEBUG 标志
# 可以通过设置覆盖
make CFLAGS="-march=armv9-a+sve2 -O3 -UDEBUG"
```

### Q: 如何静态链接？

```bash
# 编译静态链接版本
make LDFLAGS="-static"
```

---

## 推荐编译命令

### 对于快速测试（启用 SVE2）

```bash
make clean
make CC=aarch64-linux-gnu-gcc CFLAGS="-march=armv9-a+sve2 -O3 -DHAVE_SVE2"
```

### 对于发布版本（Release）

```bash
make clean
make CC=aarch64-linux-gnu-gcc \
     CFLAGS="-march=armv9-a+sve2 -O3 -DHAVE_SVE2 -DNDEBUG" \
     DEBUGFLAGS=""
```

### 对于调试版本（Debug）

```bash
make clean
make CC=aarch64-linux-gnu-gcc \
     CFLAGS="-march=armv9-a+sve2 -g -O0 -DHAVE_SVE2" \
     DEBUGFLAGS="-g -O0"
```
