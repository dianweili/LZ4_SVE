#!/bin/bash
# LZ4 ARM64 + SVE2 编译脚本

set -e

echo "=========================================="
echo "LZ4 ARM64 Cross-Compilation with SVE2"
echo "=========================================="

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 检查交叉编译器
echo "Checking cross-compiler..."
if command -v aarch64-linux-gnu-gcc &> /dev/null; then
    CC=aarch64-linux-gnu-gcc
    CXX=aarch64-linux-gnu-g++
    AR=aarch64-linux-gnu-ar
    STRIP=aarch64-linux-gnu-strip
    RANLIB=aarch64-linux-gnu-ranlib
    echo -e "${GREEN}✓ Found aarch64-linux-gnu-gcc${NC}"
else
    echo -e "${RED}✗ aarch64-linux-gnu-gcc not found${NC}"
    echo "Please install: sudo apt install gcc-aarch64-linux-gnu"
    exit 1
fi

# 检查版本
echo "Compiler version:"
$CC --version | head -1

# 设置编译选项
CFLAGS="-march=armv9-a+sve2 -O3 -DHAVE_SVE2"
CXXFLAGS="-march=armv9-a+sve2 -O3"

echo ""
echo "Building for ARM64 with SVE2..."
echo "CFLAGS: $CFLAGS"
echo ""

# 清理
echo "Cleaning..."
make clean > /dev/null 2>&1 || true

# 编译
echo "Compiling..."
make CC="$CC" \
     CXX="$CXX" \
     AR="$AR" \
     STRIP="$STRIP" \
     RANLIB="$RANLIB" \
     CFLAGS="$CFLAGS" \
     CXXFLAGS="$CXXFLAGS"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Build successful${NC}"
else
    echo -e "${RED}✗ Build failed${NC}"
    exit 1
fi

# 验证
echo ""
echo "Verifying build..."
echo "-----------------------------------"

# 检查二进制文件
if [ -f programs/lz4 ]; then
    file programs/lz4
    echo ""
    
    # 检查架构
    if file programs/lz4 | grep -q "ARM aarch64"; then
        echo -e "${GREEN}✓ Correct ARM64 architecture${NC}"
    else
        echo -e "${YELLOW}⚠ Not ARM64 binary${NC}"
    fi
    
    # 检查 SVE2 指令
    echo "Checking for SVE2 instructions..."
    if $CC -o /dev/null -march=armv9-a+sve2 -O3 lib/lz4.c -c 2>/dev/null; then
        if objdump -d lib/lz4.o 2>/dev/null | grep -q "svld1\|svst1"; then
            echo -e "${GREEN}✓ SVE2 instructions found${NC}"
        else
            echo -e "${YELLOW}⚠ SVE2 instructions not detected in output${NC}"
        fi
    fi
else
    echo -e "${RED}✗ Binary not found${NC}"
    exit 1
fi

echo ""
echo "=========================================="
echo -e "${GREEN}Build completed successfully!${NC}"
echo "=========================================="
echo ""
echo "Binary location: programs/lz4"
echo "Target: ARM64 (aarch64) with SVE2"
echo ""
echo "To test with QEMU:"
echo "  qemu-aarch64-static programs/lz4 -V"
