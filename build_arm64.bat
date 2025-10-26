@echo off
REM LZ4 ARM64 Cross-Compilation Script for Windows

echo ==========================================
echo LZ4 ARM64 Cross-Compilation with SVE2
echo ==========================================
echo.

REM 检查是否在 WSL 环境
where wsl.exe >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo Running in WSL environment...
    echo.
    
    REM 调用 WSL 版本的脚本
    wsl bash build_arm64.sh
    goto :end
)

REM 检查是否有交叉编译器
where aarch64-linux-gnu-gcc.exe >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Error: aarch64-linux-gnu-gcc not found
    echo.
    echo Please install cross-compiler tools:
    echo   1. Install WSL2 and run: sudo apt install gcc-aarch64-linux-gnu
    echo   2. Or use Docker: docker build -f Dockerfile.arm64 .
    echo.
    exit /b 1
)

REM 设置编译器
set CC=aarch64-linux-gnu-gcc.exe
set CXX=aarch64-linux-gnu-g++.exe

REM 设置编译选项
set CFLAGS=-march=armv9-a+sve2 -O3 -DHAVE_SVE2

echo Compiler: %CC%
echo CFLAGS: %CFLAGS%
echo.

REM 清理
echo Cleaning...
mingw32-make clean 2>nul

REM 编译
echo Building...
mingw32-make CC=%CC% CXX=%CXX% CFLAGS="%CFLAGS%"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ==========================================
    echo Build completed successfully!
    echo ==========================================
    echo.
    echo Binary: programs\lz4.exe
) else (
    echo.
    echo Build failed!
    exit /b 1
)

:end
pause
