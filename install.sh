#!/bin/bash

# 定义常量
AGENT="$HOME/DevTools/jetbra/ja-netfilter.jar"
BASE="$HOME/.local/share/JetBrains/Toolbox/apps"

# 定义要添加的配置行数组
CONFIG_LINES=(
    "-javaagent:$AGENT=jetbrains"
    "--add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED"
    "--add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED"
)

# IDE 配置信息数组（名称, 目录名, 配置文件名）
IDES=(
    "IntelliJ IDEA,intellij-idea-ultimate,idea64.vmoptions"
    "WebStorm,webstorm,webstorm64.vmoptions"
    "PHPStorm,phpstorm,phpstorm64.vmoptions"
    "CLion,clion,clion64.vmoptions"
    "PyCharm,pycharm,pycharm64.vmoptions"
)

# 函数：使用 awk 检查整行是否已存在
check_line_exists() {
    local file="$1"
    local line="$2"
    # 使用 awk 精确匹配整行
    awk -v search="$line" '$0 == search {found=1; exit} END{exit !found}' "$file" 2>/dev/null
    return $?
}

echo "🚀 开始配置 JetBrains IDE..."

# 遍历所有 IDE
for ide_info in "${IDES[@]}"; do
    # 解析 IDE 信息
    IFS=',' read -r ide_name dir_name config_file <<< "$ide_info"

    # 构建完整文件路径
    config_path="$BASE/$dir_name/bin/$config_file"

    echo "🔧 配置 $ide_name..."

    # 检查配置文件是否存在
    if [ ! -f "$config_path" ]; then
        echo "   ⚠️  配置文件不存在: $config_path"
        echo "   💡 请确认 $ide_name 已通过 JetBrains Toolbox 安装"
        continue
    fi

    # 检查并添加每行配置
    added=false
    for config_line in "${CONFIG_LINES[@]}"; do
        if ! check_line_exists "$config_path" "$config_line"; then
            echo "$config_line" >> "$config_path"
            added=true
        fi
    done

    # 输出结果
    if [ "$added" = true ]; then
        echo "   ✅ 配置已添加/更新"
    else
        echo "   ⏭️  所有配置已存在"
    fi
done

echo "✨ 所有 IDE 配置完成！"
echo ""
echo "📝 配置详情："
echo "   代理文件: $AGENT"
echo "   配置目录: $BASE"
echo "   影响 IDE: IntelliJ IDEA, WebStorm, PHPStorm, CLion, PyCharm"