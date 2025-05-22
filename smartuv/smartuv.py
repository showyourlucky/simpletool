#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
SmartUV - 智能Python包管理工具
用法: smartuv -r requirements.txt
"""

import argparse
import subprocess
import sys
import re
from packaging import version

def get_installed_packages():
    """获取当前已安装的所有包及其版本"""
    try:
        result = subprocess.run(['uv', 'pip', 'list'], capture_output=True, text=True, check=True)
        packages = {}
        
        # 跳过标题行
        for line in result.stdout.strip().split('\n')[2:]:
            parts = line.split()
            if len(parts) >= 2:
                package_name = parts[0].lower()
                package_version = parts[1]
                packages[package_name] = package_version
        
        return packages
    except subprocess.CalledProcessError as e:
        print(f"获取已安装包列表失败: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"执行命令时出错: {e}")
        sys.exit(1)

def parse_requirement(req_line):
    """解析requirements.txt中的单行依赖"""
    # 移除注释和空格
    req_line = req_line.split('#')[0].strip()
    if not req_line:
        return None, None
    
    # 解析包名和版本要求
    match = re.match(r'^([a-zA-Z0-9_\-\.]+)(?:\s*([<>=]=?)\s*([0-9a-zA-Z\.]+))?', req_line)
    if not match:
        return None, None
    
    package_name = match.group(1).lower()
    operator = match.group(2) if match.group(2) else None
    version_req = match.group(3) if match.group(3) else None
    
    return package_name, (operator, version_req)

def should_install(package_name, version_req, installed_packages):
    """判断是否需要安装或更新包"""
    # 如果没有版本要求，且未安装，则安装
    if not version_req[0] and package_name not in installed_packages:
        return package_name, True
    
    # 如果没有版本要求，但已安装，则跳过
    if not version_req[0] and package_name in installed_packages:
        return None, False
    
    # 如果有版本要求，但未安装，则安装指定版本
    if version_req[0] and package_name not in installed_packages:
        operator, req_version = version_req
        if operator == '==':
            return f"{package_name}=={req_version}", True
        elif operator == '>':
            return f"{package_name}>={req_version}", True
        elif operator == '<':
            return f"{package_name}<{req_version}", True
        elif operator == '>=':
            return f"{package_name}>={req_version}", True
        elif operator == '<=':
            return f"{package_name}<={req_version}", True
    
    # 如果有版本要求，且已安装，则比较版本
    if version_req[0] and package_name in installed_packages:
        operator, req_version = version_req
        installed_ver = version.parse(installed_packages[package_name])
        req_ver = version.parse(req_version)
        
        if operator == '==':
            if installed_ver != req_ver:
                return f"{package_name}=={req_version}", True
        elif operator == '>':
            if installed_ver <= req_ver:
                return f"{package_name}>={req_version}", True
        elif operator == '<':
            if installed_ver >= req_ver:
                return f"{package_name}<{req_version}", True
        elif operator == '>=':
            if installed_ver < req_ver:
                return f"{package_name}>={req_version}", True
        elif operator == '<=':
            if installed_ver > req_ver:
                return f"{package_name}<={req_version}", True
    
    return None, False

def install_requirements(requirements_file):
    """处理requirements.txt文件并安装依赖包"""
    try:
        # 获取已安装的包
        print("正在获取已安装包列表...")
        installed_packages = get_installed_packages()
        
        # 读取requirements.txt，尝试多种编码
        try:
            try:
                # 首先尝试UTF-8编码
                with open(requirements_file, 'r', encoding='utf-8') as f:
                    requirements = f.readlines()
            except UnicodeDecodeError:
                # 如果UTF-8解码失败，尝试使用Latin-1编码（它可以读取任何字节序列）
                print("UTF-8编码读取失败，尝试使用Latin-1编码...")
                with open(requirements_file, 'r', encoding='latin-1') as f:
                    requirements = f.readlines()
        except Exception as e:
            print(f"无法读取requirements文件: {e}")
            sys.exit(1)
        
        # 处理每一行要求
        to_install = []
        for req in requirements:
            package_name, version_req = parse_requirement(req)
            if not package_name:
                continue
                
            install_spec, should_inst = should_install(package_name, version_req, installed_packages)
            if should_inst and install_spec:
                to_install.append(install_spec)
                print(f"需要安装: {install_spec}")
            else:
                print(f"跳过 {package_name}: 已满足要求")
        
        # 如果有需要安装的包，执行安装命令
        if to_install:
            print("开始安装依赖...")
            packages_str = " ".join(to_install)
            install_cmd = f"uv pip install {packages_str} --link-mode symlink"
            print(f"执行命令: {install_cmd}")
            
            try:
                subprocess.run(install_cmd, shell=True, check=True)
                print("安装完成!")
            except subprocess.CalledProcessError as e:
                print(f"安装过程中出错: {e}")
                sys.exit(1)
        else:
            print("所有依赖已满足，无需安装。")
            
    except Exception as e:
        print(f"处理requirements过程中出错: {e}")
        sys.exit(1)

def main():
    """主函数"""
    parser = argparse.ArgumentParser(description='智能Python包管理工具')
    parser.add_argument('-r', '--requirements', help='指定requirements.txt文件路径')
    
    args = parser.parse_args()
    
    if args.requirements:
        install_requirements(args.requirements)
    else:
        parser.print_help()

if __name__ == "__main__":
    main() 