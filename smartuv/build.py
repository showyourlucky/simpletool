#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
构建脚本 - 将smartuv.py打包成独立的可执行文件
"""

import os
import subprocess
import sys

def main():
    """执行打包过程"""
    print("正在开始打包过程...")
    
    # 确保依赖已安装
    print("检查并安装依赖...")
    try:
        subprocess.run([sys.executable, "-m", "pip", "install", "-r", "requirements.txt"], check=True)
    except subprocess.CalledProcessError as e:
        print(f"安装依赖失败: {e}")
        sys.exit(1)
    
    # 使用PyInstaller打包
    print("使用PyInstaller打包smartuv.py...")
    try:
        subprocess.run([
            sys.executable, 
            "-m", 
            "PyInstaller", 
            "--onefile",  # 单文件模式
            "--name", "smartuv",  # 输出名称
            "smartuv.py"  # 要打包的脚本
        ], check=True)
    except subprocess.CalledProcessError as e:
        print(f"打包失败: {e}")
        sys.exit(1)
    
    # 检查打包结果
    exe_path = os.path.join("dist", "smartuv.exe")
    if os.path.exists(exe_path):
        print(f"打包成功! 可执行文件位于: {exe_path}")
    else:
        print("打包似乎成功了，但找不到生成的可执行文件。")
        sys.exit(1)

if __name__ == "__main__":
    main() 