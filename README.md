

# 🦙 Chat Studio

**一款精致、跨平台的本地大语言模型桌面客户端**

*在桌面上与本地 LLM 对话 — Flutter 驱动，原生体验。*



---

## 🌟 概述

Chat Studio 是一个**跨平台桌面应用**，为你提供与本地大语言模型对话的原生体验。完全离线运行，所有数据存储在本地，无需云服务，不发送遥测数据。

兼容任何提供 **OpenAI 兼容 API** 的推理引擎：

- [Ollama](https://ollama.ai)
- [LM Studio](https://lmstudio.ai)
- [LocalAI](https://localai.io)
- [llama.cpp](https://github.com/ggerganov/llama.cpp) 及其衍生版本
- 任何实现 `/v1/chat/completions` 接口的服务

---

## ✨ 功能特性

### 💬 智能对话
- **流式输出** — 实时显示模型生成内容，逐 token 呈现
- **Markdown 渲染** — 标题、列表、表格、LaTeX 数学公式完整支持
- **代码高亮** — 数十种编程语言语法高亮，代码块一键复制
- **DeepSeek R1 兼容** — `  ...  ` 推理过程自动折叠/展开

### 🎨 精致界面
- **Material 3 (Material You)** — 现代设计语言，动态配色，圆润过渡
- **10 种色系** — 蓝、绿、紫、橙、红、青、粉、灰、棕、靛蓝，随时切换
- **亮色 / 暗色 / 跟随系统** — 三种主题模式，一键切换
- **自定义标题栏** — 原生窗口按钮（最小化、最大化、关闭）+ 鼠标拖拽移动

### 🔧 模型控制
- **完整参数面板** — Temperature、Top-P、Top-K、Max Tokens、Repeat Penalty
- **每会话独立参数** — 每个对话记住自己的参数配置
- **可搜索的模型选择器** — 底部弹窗 + 实时筛选，模型再多也不怕

### 🗂️ 对话管理
- **本地持久化** — SQLite 存储，重启不丢失
- **智能分组** — 今天 / 昨天 / 本周 / 更早 自动归类
- **全文搜索** — 按标题快速查找历史对话
- **重命名 & 删除** — 长按重命名，一键删除
- **导入 / 导出** — 批量导出为 JSON，随时重新导入

### 📎 文件附件
- **文本与 Markdown** — 上传 `.txt`、`.md` 文件作为上下文
- **PDF 文本提取** — 自动提取 PDF 文本内容（Syncfusion 引擎）
- **图片预览** — 支持的图片格式自动识别
- **多附件支持** — 一条消息可携带多个文件

### 🔐 安全与隐私
- **API Key 加密存储** — 密钥存入系统原生密钥链（Windows DPAPI / macOS Keychain）
- **100% 本地运行** — 数据永不离开你的电脑
- **错误信息脱敏** — 异常日志自动过滤敏感令牌

### 🖥️ 桌面专属体验
- **系统托盘** — 关闭窗口时最小化到托盘，后台常驻
- **窗口管理** — 窗口大小和位置自动记忆
- **跨平台一致** — Windows、macOS、Linux 统一操作体验

---

## 🚀 快速开始

### 前置条件

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ^3.4.0
- 一台运行 LLM 的本地服务（如 Ollama、LM Studio）

### 安装

```bash
# 克隆仓库
git clone https://github.com/CchenZB666/chat-studio.git
cd chat-studio

# 安装依赖
flutter pub get

# 生成数据库代码
flutter pub run build_runner build --delete-conflicting-outputs

# 启动
flutter run
```

### 连接服务器

1. 启动你的 LLM 后端（例如 `ollama serve`）
2. 打开 Chat Studio → 点击侧边栏 **Servers**
3. 填写服务器地址（例如 `http://localhost:11434`）
4. 如有需要，填写 API Key
5. 点击 **Test Connection** 验证连接
6. 保存配置，开始对话！

---

## 🧩 技术栈

| 技术 | 用途 |
|------|------|
| **Flutter 3.4+** | 跨平台 UI 框架 |
| **Riverpod** | 状态管理（StateNotifier + Provider） |
| **Drift** | 本地 SQLite 数据库 ORM |
| **Dio** | HTTP 客户端，支持流式响应 |
| **SharedPreferences** | 设置持久化 |
| **FlutterSecureStorage** | API Key 安全存储 |
| **FlexColorScheme** | Material 3 主题系统 |
| **FlutterMarkdown** | Markdown 渲染引擎 |
| **Syncfusion PDF** | PDF 文本提取 |
| **WindowManager** | 自定义窗口标题栏 |
| **SystemTray** | 系统托盘 |

---

## 项目结构

```
lib/
├── core/
│   ├── constants/        # 应用常量与默认值
│   └── theme/            # Material 3 主题配置
├── database/             # Drift 数据库定义与迁移
├── models/               # 数据模型
├── providers/            # Riverpod 状态管理
│   ├── settings          # 应用设置
│   ├── server            # 服务器与模型列表
│   ├── chat              # 对话与流式输出
│   ├── conversation_list # 对话列表
│   ├── document          # 文件附件
│   └── template          # 提示词模板
├── screens/              # 页面
│   ├── home              # 主界面（自适应布局）
│   ├── chat              # 对话页面
│   ├── settings          # 设置页面
│   ├── server_settings   # 服务器配置
│   └── prompt_library    # 提示词库
├── services/             # 业务逻辑
│   ├── llama_api_client  # LLM API 客户端
│   ├── storage_service   # 数据持久化
│   ├── file_service      # 文件处理
│   ├── api_key_store     # 密钥安全存储
│   └── desktop_tray      # 系统托盘
├── widgets/              # 可复用组件
│   ├── title_bar         # 自定义窗口标题栏
│   ├── message_bubble    # 消息气泡
│   ├── chat_input        # 输入区域 + 附件
│   ├── conversation_list # 对话列表（侧边栏）
│   ├── parameter_panel   # 模型参数面板
│   └── connection_status # 连接状态指示器
├── main.dart             # 入口
└── app.dart              # 根组件
```

---

## 🎨 主题自定义

在设置中可从 **10 种 Material 3 色系** 中选择：

```
blue  ·  green  ·  purple  ·  orange  ·  red
teal  ·  pink   ·  grey    ·  brown   ·  indigo
```

支持 **亮色 / 暗色 / 跟随系统** 三种主题模式，随时切换。

---

## 🔌 API 兼容性

Chat Studio 遵循 **OpenAI Chat Completions API** 格式，兼容以下后端：

| 后端 | 默认地址 | API Key |
|------|---------|---------|
| Ollama | `http://localhost:11434` | 可选 |
| LM Studio | `http://localhost:1234` | 可选 |
| LocalAI | `http://localhost:8080` | 可选 |
| llama.cpp | `http://localhost:8080` | 可选 |
| vLLM | `http://localhost:8000` | 必需 |
| OpenAI 代理 | 自定义 | 必需 |

---

## 🤝 参与贡献

欢迎提交 Issue 和 Pull Request！

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/amazing`)
3. 提交改动 (`git commit -m 'Add amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing`)
5. 开启 Pull Request

---

## 📄 许可证

本项目基于 MIT 许可证开源。详见 [LICENSE](LICENSE) 文件。

---

<div align="center">
  <sub>用 ❤️ 为开源 AI 社区打造</sub>
</div>