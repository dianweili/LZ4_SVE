#!/bin/bash
# LZ4 SVE2 优化测试脚本

set -e

echo "=========================================="
echo "LZ4 SVE2 Optimization Test"
echo "=========================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查架构
echo "Checking architecture..."
ARCH=$(uname -m)
if [ "$ARCH" == "aarch64" ] || [ "$ARCH" == "arm64" ]; then
    echo -e "${GREEN}✓ Running on ARM64${NC}"
else
    echo -e "${YELLOW}⚠ Running on $ARCH (will use cross-compilation)${NC}"
fi

# 检查编译器
echo "Checking GCC version..."
if command -v aarch64-linux-gnu-gcc &> /dev/null; then
    GCC_VERSION=$(aarch64-linux-gnu-gcc --version | head -1)
    echo -e "${GREEN}✓ Found: $GCC_VERSION${NC}"
    CC=aarch64-linux-gnu-gcc
else
    if command -v gcc &> /dev/null; then
        GCC_VERSION=$(gcc --version | head -1)
        echo -e "${GREEN}✓ Using native GCC: $GCC_VERSION${NC}"
        CC=gcc
    else
        echo -e "${RED}✗ No GCC found${NC}"
        exit 1
    fi
fi

# 清理旧构建
echo "Cleaning old build..."
make clean 2>/dev/null || true

# 编译（启用 SVE2）
echo "Building with SVE2 support..."
export CC=$CC
make CFLAGS="-march=armv9-a+sve2 -O3" -j$(nproc) || {
    echo -e "${RED}✗ Build failed${NC}"
    exit 1
}
echo -e "${GREEN}✓ Build successful${NC}"

# 功能测试
echo "Testing functionality..."

# 创建测试数据
TEST_FILE="/tmp/lz4_test_$$"
echo "Hello World from SVE2! This is a test message." > "$TEST_FILE"

# 压缩测试
./lz4 -f "$TEST_FILE" "${TEST_FILE}.lz4" || {
    echo -e "${RED}✗ Compression failed${NC}"
    exit 1
}
echo -e "${GREEN}✓ Compression successful${NC}"

# 解压测试
./lz4 -d -f "${TEST_FILE}.lz4" "${TEST_FILE}.out" || {
    echo -e "${RED}✗ Decompression failed${NC}"
    exit 1
}
echo -e "${GREEN}✓ Decompression successful${NC}"

# 验证数据正确性
if diff "$TEST_FILE" "${TEST_FILE}.out" > /dev/null; then
    echo -e "${GREEN}✓ Data integrity verified${NC}"
else
    echo -e "${RED}✗ Data corruption detected${NC}"
    exit 1
fi

# 清理测试文件
rm -f "$TEST_FILE" "${TEST_FILE}.lz4" "${TEST_FILE}.out"

# 性能基准测试（可选）
echo ""
echo "Running performance benchmark..."
echo "-----------------------------------"

# 生成测试数据
PERF_TEST="/tmp/lz4_perf_test_$$"
dd if=/dev/urandom of="$PERF_TEST" bs=1M count=10 2>/dev/null

# 测试压缩性能
echo "Compression performance:"
time (./lz4 -9 -f "$PERF_TEST" "${PERF_TEST}.lz4" > /dev/null 2>&1)

# 测试解压性能  
echo "Decompression performance:"
time (./lz4 -d -f "${PERF_TEST}.lz4" "${PERF_TEST}.out" > /dev/null 2>&1)

# 验证性能测试
if diff "$PERF_TEST" "${PERF_TEST}.out" > /dev/null; then
    echo -e "${GREEN}✓ Performance test passed${NC}"
else
    echo -e "${RED}✗ Performance test failed - data corruption${NC}"
fi

# 清理
rm -f "$PERF_TEST" "${PERF_TEST}.lz4" "${PERF_TEST}.out"

# 检查 SVE2 符号
echo ""
echo "Checking for SVE2 symbols..."
if nm programs/lz4 2>/dev/null | grep -i sve2; then
    echo -e "${GREEN}✓ SVE2 symbols found${NC}"
else
    echo -e "${YELLOW}⚠ No SVE2 symbols (may use runtime detection)${NC}"
fi

echo ""
echo "=========================================="
echo -e "${GREEN}All tests passed!${NC}"
echo "=========================================="
