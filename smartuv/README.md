# SmartUV - 智能Python包管理工具

SmartUV是一个智能的Python包管理工具，它能够智能地分析requirements.txt文件中的依赖关系，并使用uv安装所需的包。

## 功能特点

- 自动检测已安装的包及其版本
- 智能分析requirements.txt中的依赖关系
- 支持多种版本指定方式（==, >, <, >=, <=）
- 避免不必要的包更新
- 使用uv作为底层包管理器，性能更好

## 安装

1. 确保您的系统中已安装Python 3.6+
2. 克隆此仓库
3. 运行打包脚本构建可执行文件：

```bash
python build.py
```

4. 构建完成后，可执行文件位于`dist`目录下

## 使用方法

使用SmartUV安装requirements.txt文件中的依赖：

```bash
smartuv -r requirements.txt
```

## 工作原理

1. 执行`uv pip list`获取当前已安装的所有包及其版本
2. 逐行读取requirements.txt文件中的依赖
3. 根据以下规则判断是否需要安装或更新包：
   - 对于无版本要求的包（如`requests`），如果未安装则安装
   - 对于精确版本要求（如`requests==1.1`），检查已安装版本是否匹配
   - 对于大于版本要求（如`requests>1.1`），检查已安装版本是否满足条件
   - 对于小于版本要求（如`requests<1.1`），检查已安装版本是否满足条件
4. 使用`uv pip install --link-mode symlink`命令安装所需的包

## 系统要求

- Windows操作系统
- Python 3.6+
- uv包管理器已安装

## 许可证

MIT 