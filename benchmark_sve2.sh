#!/bin/bash
# LZ4 SVE2 优化性能对比脚本

set -e

echo "=========================================="
echo "LZ4 SVE2 Optimization Benchmark"
echo "=========================================="

# 生成测试数据
echo "Generating test data..."
TEST_SIZES=(1M 10M 100M)
TEST_DIR="/tmp/lz4_bench_$$"
mkdir -p "$TEST_DIR"

for size in ${TEST_SIZES[@]}; do
    echo "Creating ${size}B test file..."
    dd if=/dev/urandom of="$TEST_DIR/data_${size}.dat" bs=$size count=1 2>/dev/null
done

# 创建结果目录
RESULTS="benchmark_results_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$RESULTS"

# 编译两个版本
echo ""
echo "=========================================="
echo "Building baseline version (no SVE2)..."
echo "=========================================="
make clean
make CFLAGS="-O3" -j$(nproc)

mv programs/lz4 programs/lz4_baseline

echo ""
echo "=========================================="
echo "Building SVE2 optimized version..."
echo "=========================================="
make clean
make CFLAGS="-march=armv9-a+sve2 -O3" -j$(nproc)

mv programs/lz4 programs/lz4_sve2

# 恢复 lz4
make clean
make CFLAGS="-march=armv9-a+sve2 -O3" -j$(nproc)

# 基准测试函数
run_benchmark() {
    local name=$1
    local binary=$2
    local test_file=$3
    
    echo "Testing $name with $test_file..."
    
    # 压缩测试
    echo "  Compression:"
    local compress_time=$( (time $binary -9 -f "$test_file" "$test_file.lz4") 2>&1 | grep real | awk '{print $2}')
    
    # 压缩率
    local orig_size=$(stat -f%z "$test_file" 2>/dev/null || stat -c%s "$test_file")
    local comp_size=$(stat -f%z "$test_file.lz4" 2>/dev/null || stat -c%s "$test_file.lz4")
    local ratio=$(echo "scale=2; $comp_size * 100 / $orig_size" | bc)
    
    # 解压测试
    echo "  Decompression:"
    local decompress_time=$( (time $binary -d -f "$test_file.lz4" "$test_file.out") 2>&1 | grep real | awk '{print $2}')
    
    # 验证
    if ! diff "$test_file" "$test_file.out" > /dev/null; then
        echo "  ERROR: Data corruption!"
        return 1
    fi
    
    echo "  Results:"
    echo "    Compress: $compress_time"
    echo "    Decompress: $decompress_time"
    echo "    Ratio: ${ratio}%"
    
    # 保存结果
    echo "$name,$test_file,$compress_time,$decompress_time,$ratio" >> "$RESULTS/results.csv"
    
    # 清理
    rm -f "$test_file.lz4" "$test_file.out"
}

# 运行对比测试
echo ""
echo "=========================================="
echo "Running benchmarks..."
echo "=========================================="

echo "Test,Build,Compress_Time,Decompress_Time,Compression_Ratio" > "$RESULTS/results.csv"

for size in ${TEST_SIZES[@]}; do
    test_file="$TEST_DIR/data_${size}.dat"
    
    echo ""
    echo "--- Testing ${size}B file ---"
    
    run_benchmark "baseline" "./programs/lz4_baseline" "$test_file"
    run_benchmark "sve2" "./programs/lz4_sve2" "$test_file"
done

# 生成报告
echo ""
echo "=========================================="
echo "Benchmark Results"
echo "=========================================="
cat "$RESULTS/results.csv" | column -t -s ','

# 清理
rm -rf "$TEST_DIR"

echo ""
echo "Results saved to: $RESULTS/results.csv"
echo "=========================================="
