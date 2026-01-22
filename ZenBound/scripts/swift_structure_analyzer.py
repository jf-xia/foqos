#!/usr/bin/env python3
"""
Swift 项目结构分析器
使用 sourcekitten 分析 Swift 源代码并生成 Markdown 文档, 功能如下:
- 获取当前项目的 Swift 源代码文件列表, 文件名称包含相对路径,举例: ZenBound/Utils/RequestAuthorizer.swift 并输出到 md 文件
- 循环执行sourcekitten获取 json, 举例: sourcekitten structure --file ZenBound/Utils/RequestAuthorizer.swift
- 解析 JSON，提取出关键的类、属性和方法信息,内容尽可能简洁紧凑。
- 根据提取的信息，生成一个结构清晰、简洁紧凑的 Markdown 文档。
- 将生成的 Markdown 内容保存到一个新的 .md 文件中。
"""

import os
import subprocess
import json
from pathlib import Path
from datetime import datetime

# 配置
PROJECT_ROOT = Path(__file__).parent.parent
EXCLUDE_DIRS = {'.build', 'build', 'DerivedData', '.git', 'Pods', 'Carthage'}
OUTPUT_DIR = PROJECT_ROOT / "docs"
SKIP_COMMENTS = True  # 默认跳过注释节点


def get_swift_files():
    """获取项目中所有 Swift 源文件的相对路径"""
    swift_files = []
    for root, dirs, files in os.walk(PROJECT_ROOT):
        # 排除不需要的目录
        dirs[:] = [d for d in dirs if d not in EXCLUDE_DIRS and not d.endswith('.xcodeproj') and not d.endswith('.xcworkspace')]

        # 跳过 ZenBound/DemoUI 目录（默认配置）
        try:
            rel_root = Path(root).relative_to(PROJECT_ROOT)
        except Exception:
            rel_root = None

        if rel_root == Path('ZenBound'):
            dirs[:] = [d for d in dirs if d != 'DemoUI']
        
        for file in files:
            if file.endswith('.swift'):
                full_path = Path(root) / file
                rel_path = full_path.relative_to(PROJECT_ROOT)
                swift_files.append(str(rel_path))
    
    return sorted(swift_files)


def run_sourcekitten(file_path):
    """运行 sourcekitten 获取文件结构"""
    try:
        result = subprocess.run(
            ['sourcekitten', 'structure', '--file', file_path],
            capture_output=True,
            text=True,
            cwd=PROJECT_ROOT,
            timeout=30
        )
        if result.returncode == 0:
            return json.loads(result.stdout)
        else:
            print(f"  ⚠️ 错误: {result.stderr.strip()}")
            return None
    except subprocess.TimeoutExpired:
        print(f"  ⚠️ 超时: {file_path}")
        return None
    except json.JSONDecodeError as e:
        print(f"  ⚠️ JSON 解析错误: {e}")
        return None


def extract_structure(data, depth=0):
    """递归提取代码结构信息"""
    structures = []
    
    if not isinstance(data, dict):
        return structures
    
    substructures = data.get('key.substructure', [])
    
    for item in substructures:
        kind = item.get('key.kind', '')
        name = item.get('key.name', '')
        
        # 跳过注释节点（如果配置为True）
        if SKIP_COMMENTS and kind == 'source.lang.swift.syntaxtype.comment':
            continue
        
        if not name:
            # 递归处理无名结构
            structures.extend(extract_structure(item, depth))
            continue
        
        entry = {
            'kind': kind,
            'name': name,
            'depth': depth,
            'accessibility': item.get('key.accessibility', ''),
            'typename': item.get('key.typename', ''),
            'children': []
        }
        
        # 提取继承信息
        inherited = item.get('key.inheritedtypes', [])
        if inherited:
            entry['inherited'] = [i.get('key.name', '') for i in inherited]
        
        # 递归处理子结构
        entry['children'] = extract_structure(item, depth + 1)
        
        structures.append(entry)
    
    return structures


def kind_to_symbol(kind):
    """将 SourceKit kind 转换为简短符号"""
    kind_map = {
        'source.lang.swift.decl.class': '🔷 class',
        'source.lang.swift.decl.struct': '🔶 struct',
        'source.lang.swift.decl.enum': '🔸 enum',
        'source.lang.swift.decl.enumelement': 'case',
        'source.lang.swift.decl.protocol': '📋 protocol',
        'source.lang.swift.decl.extension': '🔗 extension',
        'source.lang.swift.decl.function.method.instance': 'func',
        'source.lang.swift.decl.function.method.static': 'static func',
        'source.lang.swift.decl.function.method.class': 'class func',
        'source.lang.swift.decl.function.free': 'func',
        'source.lang.swift.decl.var.instance': 'var',
        'source.lang.swift.decl.var.static': 'static var',
        'source.lang.swift.decl.var.class': 'class var',
        'source.lang.swift.decl.var.global': 'var',
        'source.lang.swift.decl.var.local': 'let',
        'source.lang.swift.decl.typealias': 'typealias',
        'source.lang.swift.decl.associatedtype': 'associatedtype',
        'source.lang.swift.decl.generic_type_param': 'T',
        'source.lang.swift.decl.function.constructor': 'init',
        'source.lang.swift.decl.function.destructor': 'deinit',
        'source.lang.swift.decl.function.subscript': 'subscript',
        'source.lang.swift.decl.function.operator': 'operator',
        'source.lang.swift.decl.function.accessor.getter': 'get',
        'source.lang.swift.decl.function.accessor.setter': 'set',
    }
    return kind_map.get(kind, kind.split('.')[-1] if kind else '?')


def access_to_symbol(access):
    """将访问级别转换为简短符号"""
    access_map = {
        'source.lang.swift.accessibility.private': '-',
        'source.lang.swift.accessibility.fileprivate': '~',
        'source.lang.swift.accessibility.internal': '',
        'source.lang.swift.accessibility.public': '+',
        'source.lang.swift.accessibility.open': '++',
    }
    return access_map.get(access, '')


def format_structure_compact(structures, indent=0):
    """格式化结构为紧凑的 Markdown"""
    lines = []
    prefix = '  ' * indent
    
    for item in structures:
        kind = item['kind']
        name = item['name']
        typename = item.get('typename', '')
        access = access_to_symbol(item.get('accessibility', ''))
        inherited = item.get('inherited', [])
        
        # 跳过 getter/setter 等内部实现
        if 'accessor' in kind:
            continue
        
        kind_str = kind_to_symbol(kind)
        
        # 构建行内容
        if 'class' in kind or 'struct' in kind or 'enum' in kind or 'protocol' in kind:
            # 类型定义
            inherit_str = f": {', '.join(inherited)}" if inherited else ""
            lines.append(f"{prefix}**{kind_str} {name}**{inherit_str}")
            
            # 处理子元素
            if item['children']:
                child_lines = format_structure_compact(item['children'], indent + 1)
                lines.extend(child_lines)
                
        elif 'extension' in kind:
            inherit_str = f": {', '.join(inherited)}" if inherited else ""
            lines.append(f"{prefix}**{kind_str} {name}**{inherit_str}")
            if item['children']:
                child_lines = format_structure_compact(item['children'], indent + 1)
                lines.extend(child_lines)
                
        elif 'func' in kind_str or 'init' in kind_str:
            # 方法
            type_str = f" → {typename}" if typename else ""
            lines.append(f"{prefix}- {access}`{kind_str} {name}`{type_str}")
            
        elif 'var' in kind_str or kind_str == 'let':
            # 属性
            type_str = f": {typename}" if typename else ""
            lines.append(f"{prefix}- {access}`{kind_str} {name}`{type_str}")
            
        elif 'case' in kind_str:
            # 枚举值
            lines.append(f"{prefix}- `{name}`")
            
        elif 'typealias' in kind_str:
            type_str = f" = {typename}" if typename else ""
            lines.append(f"{prefix}- `{kind_str} {name}`{type_str}")
        
        else:
            # 其他
            lines.append(f"{prefix}- `{name}` ({kind_str})")
    
    return lines


def generate_markdown(file_structures):
    """生成完整的 Markdown 文档"""
    lines = [
        "# ZenBound Swift Frameworks and structures",
        "",
        f"> Created At: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        "",
        "## File List",
        "",
    ]
    
    # 按目录分组
    grouped = {}
    for file_path, structures in file_structures.items():
        parts = file_path.split('/')
        if len(parts) > 1:
            group = parts[0]
        else:
            group = "Root"
        
        if group not in grouped:
            grouped[group] = []
        grouped[group].append((file_path, structures))
    
    # 生成目录
    for group in sorted(grouped.keys()):
        lines.append(f"- **{group}/**")
        for file_path, _ in sorted(grouped[group]):
            anchor = file_path.replace('/', '-').replace('.', '-').lower()
            lines.append(f"  - [{file_path}](#{anchor})")
    
    lines.append("")
    lines.append("---")
    lines.append("")
    lines.append("## Detailed Structure")
    lines.append("")
    
    # 生成每个文件的结构
    for group in sorted(grouped.keys()):
        lines.append(f"### 📁 {group}")
        lines.append("")
        
        for file_path, structures in sorted(grouped[group]):
            anchor = file_path.replace('/', '-').replace('.', '-').lower()
            file_name = file_path.split('/')[-1]
            lines.append(f"#### {file_name}")
            lines.append(f"<a id=\"{anchor}\"></a>")
            lines.append(f"`{file_path}`")
            lines.append("")
            
            if structures:
                formatted = format_structure_compact(structures)
                lines.extend(formatted)
            
            lines.append("")
    
    return '\n'.join(lines)


def main():
    print("🔍 Swift 项目结构分析器")
    print("=" * 50)
    
    # 创建输出目录
    OUTPUT_DIR.mkdir(exist_ok=True)
    
    # 获取 Swift 文件
    print("\n📂 获取 Swift 文件列表...")
    swift_files = get_swift_files()
    print(f"   找到 {len(swift_files)} 个 Swift 文件")
    
    # 保存文件列表
    # file_list_path = OUTPUT_DIR / "swift_files.md"
    # with open(file_list_path, 'w') as f:
    #     f.write("# Swift 源文件列表\n\n")
    #     f.write(f"> 生成时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
    #     for file in swift_files:
    #         f.write(f"- {file}\n")
    # print(f"   ✅ 文件列表已保存: {file_list_path}")
    
    # 分析每个文件
    print("\n🔬 分析代码结构...")
    file_structures = {}
    
    for i, file_path in enumerate(swift_files, 1):
        print(f"   [{i}/{len(swift_files)}] {file_path}")
        
        json_data = run_sourcekitten(file_path)
        if json_data:
            structures = extract_structure(json_data)
            file_structures[file_path] = structures
        else:
            file_structures[file_path] = []
    
    # 生成 Markdown
    print("\n📝 生成 Markdown 文档...")
    markdown_content = generate_markdown(file_structures)
    
    # 保存文档
    output_path = OUTPUT_DIR / "swift_structure.md"
    with open(output_path, 'w') as f:
        f.write(markdown_content)
    
    print(f"   ✅ 结构文档已保存: {output_path}")
    print("\n✨ 完成!")


if __name__ == '__main__':
    main()
