#!/bin/bash

# 函数：检查整行是否已存在
check_line_exists() {
    local file="$1"
    local line="$2"
    # 使用 awk 精确匹配整行
    awk -v search="$line" '$0 == search {found=1; exit} END{exit !found}' "$file" 2>/dev/null
    return $?
}

# 函数：检测配置是否存在（支持灵活的 javaagent 路径匹配）
check_javaagent_exists() {
    local file="$1"
    # 检测是否已存在任何 -javaagent:xxx/ja-netfilter.jar=jetbrains 格式的配置
    grep -q '^-javaagent:.*/ja-netfilter\.jar=jetbrains$' "$file" 2>/dev/null
    return $?
}

# 函数：检测单个配置是否存在
check_single_config() {
    local file="$1"
    local line="$2"
    grep -qFx "$line" "$file" 2>/dev/null
    return $?
}

# 设置默认路径
DEFAULT_AGENT_DIR="$HOME/DevTools/jetbra"

echo "=========================================="
echo "     JetBrains IDE 配置工具"
echo "=========================================="
echo ""

# 询问用户输入 ja-netfilter.jar 目录
read -p "请输入 ja-netfilter.jar 所在目录 [默认: $DEFAULT_AGENT_DIR]: " INPUT_DIR

# 如果用户未输入，使用默认目录
if [ -z "$INPUT_DIR" ]; then
    AGENT_DIR="$DEFAULT_AGENT_DIR"
else
    AGENT_DIR="$INPUT_DIR"
fi

# 构建完整的 ja-netfilter.jar 路径
AGENT_JAR="$AGENT_DIR/ja-netfilter.jar"

# 检查 ja-netfilter.jar 是否存在
if [ ! -f "$AGENT_JAR" ]; then
    echo "❌ 错误: 未找到 ja-netfilter.jar 文件"
    echo "   请检查路径: $AGENT_JAR"
    exit 1
fi

echo "✅ 找到代理文件: $AGENT_JAR"
echo ""

# 定义基础目录
BASE="$HOME/.local/share/JetBrains/Toolbox/apps"

# 定义要添加的配置行数组
CONFIG_LINES=(
    "-javaagent:$AGENT_JAR=jetbrains"
    "--add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED"
    "--add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED"
)

# IDE 配置信息数组（名称, 目录名, 配置文件名）
IDES=(
    "IntelliJ IDEA,intellij-idea,idea64.vmoptions"
    "WebStorm,webstorm,webstorm64.vmoptions"
    "PHPStorm,phpstorm,phpstorm64.vmoptions"
    "CLion,clion,clion64.vmoptions"
    "PyCharm,pycharm,pycharm64.vmoptions"
)

echo "🚀 开始配置 JetBrains IDE..."
echo ""

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
        echo ""
        continue
    fi

    # 检查文件是否可写
    if [ ! -w "$config_path" ]; then
        echo "   ⚠️  文件不可写: $config_path"
        echo "   💡 请检查文件权限"
        echo ""
        continue
    fi

    # 标记是否有新增配置
    added=false

    # 检查并添加所有配置到文件末尾
    for config_line in "${CONFIG_LINES[@]}"; do
        if [[ "$config_line" == *"javaagent"* ]]; then
            if ! check_javaagent_exists "$config_path"; then
                echo "   ➕ 添加 javaagent 配置..."
                echo "$config_line" >> "$config_path"
                added=true
            else
                echo "   ✓ javaagent 配置已存在"
            fi
        else
            if ! check_single_config "$config_path" "$config_line"; then
                echo "   ➕ 添加配置: $(echo $config_line | cut -c1-50)..."
                echo "$config_line" >> "$config_path"
                added=true
            else
                echo "   ✓ $(echo $config_line | cut -c1-50)... 已存在"
            fi
        fi
    done

    # 输出结果
    if [ "$added" = true ]; then
        echo "   ✅ $ide_name 配置已完成（已添加到文件末尾）"
    else
        echo "   ⏭️  $ide_name 所有配置已存在，无需修改"
    fi
    echo ""
done

echo "=========================================="
echo "✨ 所有 IDE 配置完成！"
echo ""
echo "📝 配置详情："
echo "   代理文件: $AGENT_JAR"
echo "   配置目录: $BASE"
echo "   影响 IDE: IntelliJ IDEA, WebStorm, PHPStorm, CLion, PyCharm"
echo ""
echo "💡 提示："
echo "   1. 请确保 ja-netfilter.jar 的配置正确"
echo "   2. 修改配置后需要重启 IDE 才能生效"
echo "   3. 如需查看配置，可检查对应 .vmoptions 文件"
echo "=========================================="