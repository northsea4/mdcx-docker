#!/bin/sh

if [ -n "$DEBUG_CONTAINER" ]; then
  echo "=========================!!!!!!!!=============================="
  echo "            I'm sleeping. Make yourself at home!"
  echo "=========================!!!!!!!!=============================="

  while :
  do
    sleep 10
  done
fi

export LC_ALL=zh_CN.UTF-8

cd /app

# 调试Qt插件问题
echo "🔍 Qt Debug Information:"
echo "QT_QPA_PLATFORM: $QT_QPA_PLATFORM"
echo "QT_PLUGIN_PATH: $QT_PLUGIN_PATH"
echo "LD_LIBRARY_PATH: $LD_LIBRARY_PATH"

# 检查应用目录中的文件
echo "📁 Application directory contents:"
ls -la /app/

# 检查是否有PyInstaller的_internal目录
echo "🔍 Checking for PyInstaller _internal directory:"
if [ -d "/app/_internal" ]; then
  echo "✅ Found _internal directory"
  ls -la /app/_internal/
  echo "🔍 Looking for Qt plugins in _internal:"
  find /app/_internal -name "*platform*" -o -name "*xcb*" 2>/dev/null | head -10
  # 设置插件路径
  export QT_PLUGIN_PATH="/app/_internal:$QT_PLUGIN_PATH"
else
  echo "❌ No _internal directory found"
fi

# 检查系统Qt插件并复制到应用目录（运行时备用方案）
echo "🔧 Checking and setting up Qt plugins:"
if [ ! -f "/app/platforms/libqxcb.so" ] && [ -f "/usr/lib/x86_64-linux-gnu/qt5/plugins/platforms/libqxcb.so" ]; then
  echo "📋 Copying system xcb plugin to app directory..."
  mkdir -p /app/platforms
  cp /usr/lib/x86_64-linux-gnu/qt5/plugins/platforms/libqxcb.so /app/platforms/
  echo "✅ xcb plugin copied"
fi

# 列出所有可用的Qt插件
echo "🔍 Available Qt platform plugins:"
find /usr/lib/x86_64-linux-gnu/qt5/plugins/platforms -name "*.so" 2>/dev/null || echo "No system Qt plugins found"
find /app -name "*xcb*" -o -name "*platform*" 2>/dev/null || echo "No app Qt plugins found"

# 检查platforms目录内容
echo "🔍 Checking platforms directory:"
if [ -d "/app/platforms" ]; then
  echo "📁 Contents of /app/platforms:"
  ls -la /app/platforms/
  if [ -z "$(ls -A /app/platforms)" ]; then
    echo "❌ platforms directory is empty"
  else
    echo "✅ Found files in platforms directory"
  fi
else
  echo "❌ No platforms directory"
fi

# 设置DISPLAY环境变量 (确保X11正常工作)
export DISPLAY=:0

echo "🔍 Final environment:"
echo "DISPLAY: $DISPLAY"
echo "QT_PLUGIN_PATH: $QT_PLUGIN_PATH"


if [ -f "/cert-patch/ensure-cacert.sh" ]; then
  echo "🔘 执行cacert.pem缺失问题的临时修复脚本"
  nohup /cert-patch/ensure-cacert.sh &
fi

echo "⏳ 启动MDCx..."

exec /app/MDCx