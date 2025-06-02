#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Chrome书签解析工具
解析Chrome书签并以树形结构输出，显示所有目录和书签
"""

import json
import os
import sys
from pathlib import Path
from typing import Dict, List, Any


class ChromeBookmarkParser:
    def __init__(self):
        self.bookmarks_data = None
        self.output_lines = []
    
    def find_bookmarks_file(self) -> str:
        """查找Chrome书签文件路径"""
        # Windows Chrome书签文件路径
        chrome_paths = [
            os.path.expanduser("~\\AppData\\Local\\Google\\Chrome\\User Data\\Default\\Bookmarks"),
            os.path.expanduser("~\\AppData\\Local\\Google\\Chrome\\User Data\\Profile 1\\Bookmarks"),
            # 可以添加更多可能的路径
        ]
        
        # macOS路径
        if sys.platform == "darwin":
            chrome_paths.extend([
                os.path.expanduser("~/Library/Application Support/Google/Chrome/Default/Bookmarks"),
                os.path.expanduser("~/Library/Application Support/Google/Chrome/Profile 1/Bookmarks"),
            ])
        
        # Linux路径
        elif sys.platform.startswith("linux"):
            chrome_paths.extend([
                os.path.expanduser("~/.config/google-chrome/Default/Bookmarks"),
                os.path.expanduser("~/.config/google-chrome/Profile 1/Bookmarks"),
            ])
        
        for path in chrome_paths:
            if os.path.exists(path):
                return path
        
        raise FileNotFoundError("未找到Chrome书签文件，请确保Chrome已安装并有书签数据")
    
    def load_bookmarks(self, bookmarks_file: str = None) -> Dict:
        """加载Chrome书签文件"""
        if bookmarks_file is None:
            bookmarks_file = self.find_bookmarks_file()
        
        try:
            with open(bookmarks_file, 'r', encoding='utf-8') as f:
                self.bookmarks_data = json.load(f)
            print(f"成功加载书签文件: {bookmarks_file}")
            return self.bookmarks_data
        except Exception as e:
            raise Exception(f"加载书签文件失败: {e}")
    

    def parse_bookmark_node(self, node: Dict, level: int = 0) -> None:
        """递归解析书签节点"""
        if not isinstance(node, dict):
            return
        
        node_type = node.get('type', '')
        name = node.get('name', '')
        
        # 显示所有文件夹和书签，不进行排除
        
        # 生成缩进
        indent = "│   " * level
        
        if node_type == 'folder':
            # 文件夹节点
            if level == 0:
                self.output_lines.append(f"{name}/")
            else:
                self.output_lines.append(f"{indent}├── {name}/")
            
            # 递归处理子节点
            children = node.get('children', [])
            for child in children:
                self.parse_bookmark_node(child, level + 1)
        
        elif node_type == 'url':
            # 书签节点
            url = node.get('url', '')
            self.output_lines.append(f"{indent}├── {name}")
            self.output_lines.append(f"{indent}│   └── {url}")
    
    def parse_bookmarks(self) -> List[str]:
        """解析所有书签"""
        if not self.bookmarks_data:
            raise Exception("请先加载书签数据")
        
        self.output_lines = []
        self.output_lines.append("Chrome书签目录结构")
        self.output_lines.append("=" * 50)
        self.output_lines.append("")
        
        # 获取根节点
        roots = self.bookmarks_data.get('roots', {})
        
        # 处理书签栏
        if 'bookmark_bar' in roots:
            bookmark_bar = roots['bookmark_bar']
            #if not self.should_exclude_folder(bookmark_bar.get('name', '')):
            self.output_lines.append("书签栏/")
            children = bookmark_bar.get('children', [])
            for child in children:
                self.parse_bookmark_node(child, 1)
            self.output_lines.append("")
        
        # 处理其他书签
        if 'other' in roots:
            other_bookmarks = roots['other']
            self.output_lines.append("其他书签/")
            children = other_bookmarks.get('children', [])
            for child in children:
                self.parse_bookmark_node(child, 1)
            self.output_lines.append("")
        
        # 处理移动设备书签
        if 'synced' in roots:
            synced_bookmarks = roots['synced']
            self.output_lines.append("移动设备书签/")
            children = synced_bookmarks.get('children', [])
            for child in children:
                self.parse_bookmark_node(child, 1)
        
        return self.output_lines
    
    def save_to_file(self, output_file: str = "temp.text") -> None:
        """保存解析结果到文件"""
        try:
            with open(output_file, 'w', encoding='utf-8') as f:
                f.write('\n'.join(self.output_lines))
            print(f"书签树形结构已保存到: {output_file}")
        except Exception as e:
            print(f"保存文件失败: {e}")


def main():
    """主函数"""
    parser = ChromeBookmarkParser()
    
    try:
        # 加载书签
        book_file = 'L:/browser/Vivaldi/User Data/Default/Bookmarks'
        parser.load_bookmarks(book_file)
        
        # 解析书签
        result = parser.parse_bookmarks()
        
        # 保存到文件
        parser.save_to_file("temp.text")
        
        # 打印前几行预览
        print("\n预览前10行:")
        print("-" * 30)
        for line in result[:10]:
            print(line)
        if len(result) > 10:
            print("...")
            print(f"总共 {len(result)} 行")
    
    except Exception as e:
        print(f"错误: {e}")
        return 1
    
    return 0


if __name__ == "__main__":
    sys.exit(main())
