#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Chrome HTML书签解析工具
解析Chrome导出的HTML书签文件并以树形结构输出，显示所有目录和书签
"""

import os
import sys
import re
from pathlib import Path
from typing import List, Dict, Any
from html.parser import HTMLParser
from urllib.parse import unquote


class BookmarkHTMLParser(HTMLParser):
    """HTML书签解析器"""
    
    def __init__(self):
        super().__init__()
        self.bookmarks = []
        self.current_folder = []
        self.folder_stack = []
        self.in_dt = False
        self.in_h3 = False
        self.in_a = False
        self.current_link = {}
        self.current_folder_name = ""
        
    def handle_starttag(self, tag, attrs):
        """处理开始标签"""
        if tag.lower() == 'dt':
            self.in_dt = True
        elif tag.lower() == 'h3':
            self.in_h3 = True
            self.current_folder_name = ""
        elif tag.lower() == 'a':
            self.in_a = True
            self.current_link = {}
            # 提取链接属性
            for attr_name, attr_value in attrs:
                if attr_name.lower() == 'href':
                    self.current_link['url'] = attr_value
                elif attr_name.lower() == 'add_date':
                    self.current_link['add_date'] = attr_value
                elif attr_name.lower() == 'icon':
                    self.current_link['icon'] = attr_value
        elif tag.lower() == 'dl':
            # 进入新的文件夹层级
            if self.current_folder_name:
                self.folder_stack.append(self.current_folder_name)
                self.current_folder_name = ""
    
    def handle_endtag(self, tag):
        """处理结束标签"""
        if tag.lower() == 'dt':
            self.in_dt = False
        elif tag.lower() == 'h3':
            self.in_h3 = False
        elif tag.lower() == 'a':
            self.in_a = False
            if self.current_link:
                # 添加当前文件夹路径
                self.current_link['folder_path'] = self.folder_stack.copy()
                self.bookmarks.append(self.current_link)
                self.current_link = {}
        elif tag.lower() == 'dl':
            # 退出当前文件夹层级
            if self.folder_stack:
                self.folder_stack.pop()
    
    def handle_data(self, data):
        """处理文本数据"""
        data = data.strip()
        if data:
            if self.in_h3:
                self.current_folder_name = data
            elif self.in_a:
                self.current_link['title'] = data


class ChromeHTMLBookmarkParser:
    """Chrome HTML书签解析器主类"""
    
    def __init__(self):
        self.bookmarks = []
        self.folder_structure = {}
        self.output_lines = []
    
    def load_html_bookmarks(self, html_file: str) -> List[Dict]:
        """加载HTML书签文件"""
        if not os.path.exists(html_file):
            raise FileNotFoundError(f"HTML书签文件不存在: {html_file}")
        
        try:
            with open(html_file, 'r', encoding='utf-8') as f:
                html_content = f.read()
            
            # 使用HTML解析器解析
            parser = BookmarkHTMLParser()
            parser.feed(html_content)
            
            self.bookmarks = parser.bookmarks
            print(f"成功解析HTML书签文件: {html_file}")
            print(f"共找到 {len(self.bookmarks)} 个书签")
            
            return self.bookmarks
            
        except Exception as e:
            raise Exception(f"解析HTML书签文件失败: {e}")
    
    def build_folder_structure(self) -> Dict:
        """构建文件夹结构"""
        self.folder_structure = {}
        
        for bookmark in self.bookmarks:
            folder_path = bookmark.get('folder_path', [])
            current_level = self.folder_structure
            
            # 构建文件夹层级结构
            for folder_name in folder_path:
                if folder_name not in current_level:
                    current_level[folder_name] = {'folders': {}, 'bookmarks': []}
                current_level = current_level[folder_name]['folders']
            
            # 添加书签到对应文件夹
            if folder_path:
                target_folder = self.folder_structure
                for folder_name in folder_path[:-1]:
                    target_folder = target_folder[folder_name]['folders']
                if folder_path[-1] in target_folder:
                    target_folder[folder_path[-1]]['bookmarks'].append(bookmark)
            else:
                # 根级别书签
                if 'root_bookmarks' not in self.folder_structure:
                    self.folder_structure['root_bookmarks'] = []
                self.folder_structure['root_bookmarks'].append(bookmark)
        
        return self.folder_structure
    
    def print_folder_structure(self, structure: Dict, level: int = 0, parent_name: str = "") -> None:
        """递归打印文件夹结构"""
        indent = "│   " * level
        
        for folder_name, folder_data in structure.items():
            if folder_name == 'root_bookmarks':
                continue
                
            # 打印文件夹名
            if level == 0:
                self.output_lines.append(f"{folder_name}/")
            else:
                self.output_lines.append(f"{indent}├── {folder_name}/")
            
            # 打印文件夹中的书签
            bookmarks = folder_data.get('bookmarks', [])
            for bookmark in bookmarks:
                title = bookmark.get('title', '无标题')
                url = bookmark.get('url', '')
                self.output_lines.append(f"{indent}│   ├── {title}")
                self.output_lines.append(f"{indent}│   │   └── {url}")
            
            # 递归处理子文件夹
            sub_folders = folder_data.get('folders', {})
            if sub_folders:
                self.print_folder_structure(sub_folders, level + 1, folder_name)
    
    def parse_bookmarks(self) -> List[str]:
        """解析并格式化书签"""
        if not self.bookmarks:
            raise Exception("请先加载HTML书签数据")
        
        self.output_lines = []
        self.output_lines.append("Chrome HTML书签目录结构")
        self.output_lines.append("=" * 50)
        self.output_lines.append("")
        
        # 构建文件夹结构
        structure = self.build_folder_structure()
        
        # 打印根级别书签
        root_bookmarks = structure.get('root_bookmarks', [])
        if root_bookmarks:
            self.output_lines.append("根目录书签/")
            for bookmark in root_bookmarks:
                title = bookmark.get('title', '无标题')
                url = bookmark.get('url', '')
                self.output_lines.append(f"├── {title}")
                self.output_lines.append(f"│   └── {url}")
            self.output_lines.append("")
        
        # 打印文件夹结构
        folder_structure = {k: v for k, v in structure.items() if k != 'root_bookmarks'}
        self.print_folder_structure(folder_structure)
        
        return self.output_lines
    
    def save_to_file(self, output_file: str = "html_bookmarks_tree.txt") -> None:
        """保存解析结果到文件"""
        try:
            with open(output_file, 'w', encoding='utf-8') as f:
                f.write('\n'.join(self.output_lines))
            print(f"HTML书签树形结构已保存到: {output_file}")
        except Exception as e:
            print(f"保存文件失败: {e}")
    
    def export_to_json(self, output_file: str = "html_bookmarks.json") -> None:
        """导出书签数据为JSON格式"""
        import json
        try:
            with open(output_file, 'w', encoding='utf-8') as f:
                json.dump(self.bookmarks, f, ensure_ascii=False, indent=2)
            print(f"书签数据已导出为JSON: {output_file}")
        except Exception as e:
            print(f"导出JSON失败: {e}")
    
    def search_bookmarks(self, keyword: str) -> List[Dict]:
        """搜索书签"""
        results = []
        keyword_lower = keyword.lower()
        
        for bookmark in self.bookmarks:
            title = bookmark.get('title', '').lower()
            url = bookmark.get('url', '').lower()
            
            if keyword_lower in title or keyword_lower in url:
                results.append(bookmark)
        
        return results


def main():
    """主函数"""
    parser = ChromeHTMLBookmarkParser()
    
    # 可以通过命令行参数指定HTML文件路径
    if len(sys.argv) > 1:
        html_file = sys.argv[1]
    else:
        # 默认查找常见的HTML书签文件名
        html_file = "L:/Downloads/bookmarks_2025_6_1.html"
    try:
        # 加载HTML书签
        parser.load_html_bookmarks(html_file)
        
        # 解析书签
        result = parser.parse_bookmarks()
        
        # 保存到文件
        parser.save_to_file("html_bookmarks_tree.txt")
        
        # 导出为JSON
        parser.export_to_json("html_bookmarks.json")
        
        # 打印前几行预览
        print("\n预览前15行:")
        print("-" * 30)
        for line in result[:15]:
            print(line)
        if len(result) > 15:
            print("...")
            print(f"总共 {len(result)} 行")
        
        # 演示搜索功能
        print(f"\n搜索示例 (包含'github'的书签):")
        search_results = parser.search_bookmarks('github')
        for i, bookmark in enumerate(search_results[:5]):
            print(f"{i+1}. {bookmark.get('title', '无标题')} - {bookmark.get('url', '')}")
        if len(search_results) > 5:
            print(f"... 还有 {len(search_results) - 5} 个结果")
    
    except Exception as e:
        print(f"错误: {e}")
        return 1
    
    return 0


if __name__ == "__main__":
    sys.exit(main())
