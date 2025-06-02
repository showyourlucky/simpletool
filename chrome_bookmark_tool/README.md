# Chrome书签解析工具

这是一个用于解析Chrome书签的Python工具集，支持解析Chrome的JSON格式书签文件和HTML导出书签文件。

## 工具说明

### parse_bookmarks.py (JSON格式书签解析)
解析Chrome内部使用的JSON格式书签文件，自动查找Chrome书签文件位置。

### parse_html_bookmarks.py (HTML格式书签解析)
解析Chrome导出的HTML书签文件，支持完整的文件夹层级结构和书签搜索功能。

## 功能特点

### JSON格式解析器 (parse_bookmarks.py)
1. 自动查找Chrome书签文件位置
2. 解析书签数据并生成树形结构
3. 显示所有目录和书签（包括所有文件夹）
4. 支持Windows、macOS和Linux系统
5. 输出结果保存到temp.text文件

### HTML格式解析器 (parse_html_bookmarks.py)
1. 解析Chrome导出的HTML书签文件
2. 支持完整的文件夹层级结构
3. 以树形结构显示所有书签和文件夹
4. 导出为JSON格式便于进一步处理
5. 内置书签搜索功能
6. 支持多种HTML书签文件格式

## 使用方法

### JSON格式书签解析 (Chrome内部格式)

```bash
python parse_bookmarks.py
```

脚本会自动查找Chrome书签文件并解析显示。

### HTML格式书签解析 (Chrome导出格式)

```bash
# 方法1: 指定HTML文件路径
python parse_html_bookmarks.py bookmarks.html

# 方法2: 将HTML文件命名为bookmarks.html放在当前目录
python parse_html_bookmarks.py
```

## 如何导出Chrome HTML书签

1. 打开Chrome浏览器
2. 点击右上角三点菜单 → 书签 → 书签管理器
3. 点击右上角三点菜单 → 导出书签
4. 保存为HTML文件

## 输出格式

```
Chrome书签目录结构
==================================================

书签栏/
│   ├── 开发工具/
│   │   ├── GitHub
│   │   │   └── https://github.com
│   │   ├── Stack Overflow
│   │   │   └── https://stackoverflow.com
│   ├── 新闻/
│   │   ├── BBC News
│   │   │   └── https://www.bbc.com/news

其他书签/
│   ├── 学习资源/
│   │   ├── Python文档
│   │   │   └── https://docs.python.org
```

## 输出文件

### JSON格式解析器输出
- `temp.text` - 树形结构文本文件

### HTML格式解析器输出
- `html_bookmarks_tree.txt` - 树形结构文本文件
- `html_bookmarks.json` - JSON格式书签数据

## 支持的系统

### JSON格式解析器
- Windows: `%LOCALAPPDATA%\Google\Chrome\User Data\Default\Bookmarks`
- macOS: `~/Library/Application Support/Google/Chrome/Default/Bookmarks`
- Linux: `~/.config/google-chrome/Default/Bookmarks`

### HTML格式解析器
- 支持所有操作系统
- 只需要Chrome导出的HTML文件

## 系统要求

- Python 3.6+
- Chrome浏览器已安装并有书签数据 (仅JSON格式解析需要)

## 注意事项

### JSON格式解析器
1. 确保Chrome浏览器已安装并有书签数据
2. 脚本会自动查找默认配置文件的书签
3. 如果有多个Chrome配置文件，可能需要手动指定路径
4. 脚本会显示所有书签目录和书签，不会排除任何内容

### HTML格式解析器
1. 需要先从Chrome导出HTML书签文件
2. 支持标准的Chrome HTML书签格式
3. 自动处理文件夹层级结构
4. 提供书签搜索功能

## 错误处理

### 常见错误
- `未找到Chrome书签文件`: 检查Chrome是否已安装 (JSON格式)
- `HTML书签文件不存在`: 检查文件路径是否正确 (HTML格式)
- `加载书签文件失败`: 检查文件权限或Chrome是否正在运行
- `保存文件失败`: 检查当前目录的写入权限
