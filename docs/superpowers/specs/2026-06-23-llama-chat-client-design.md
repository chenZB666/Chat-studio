# LlamaChat — 基于 llama.cpp 的跨平台聊天客户端

## 概述

基于 Flutter 的跨平台聊天客户端，用户自行提供 llama.cpp server 地址，在 Windows 和 Android 上获得原生聊天体验。

---

## 技术栈

| 层级 | 技术 | 理由 |
|------|------|------|
| UI 框架 | Flutter + Material 3 | 跨平台一套代码，MD3 原生支持 |
| 状态管理 | Riverpod | 轻量、类型安全、测试友好 |
| 本地存储 | Drift (SQLite) | 结构化聊天数据，支持复杂查询和搜索 |
| HTTP/SSE | dio + flutter_sse | 流式请求 + Server-Sent Events |
| 文件处理 | file_picker + super_editor | 文档上传与富文本渲染 |
| 路由 | go_router | 声明式路由，支持 deep link |
| 主题 | flex_color_scheme | Material 3 动态主题生成 |

---

## 核心架构

```
┌──────────────────────────────────────────────────────────┐
│                    Flutter App                           │
│  ┌──────────────┐  ┌────────────────────────────────┐   │
│  │  Presentation │  │         State Layer            │   │
│  │  (Material 3) │  │     (Riverpod Providers)       │   │
│  │  Screens      │◄─┤     ChatProvider               │   │
│  │  Widgets      │  │     ConversationProvider       │   │
│  │  Themes       │  │     ServerProvider             │   │
│  └──────────────┘  │     SettingsProvider           │   │
│                     │     DocumentProvider           │   │
│                     │     TemplateProvider           │   │
│                     └───────────┬────────────────────┘   │
│                                 │                        │
│  ┌──────────────────────────────▼─────────────────────┐  │
│  │                   Service Layer                     │  │
│  │  ┌───────────────┐ ┌──────────┐ ┌───────────────┐  │  │
│  │  │  Llama API    │ │ Storage  │ │  File Proc    │  │  │
│  │  │  Client       │ │ (Drift)  │ │  Service      │  │  │
│  │  │  (HTTP + SSE) │ │          │ │               │  │  │
│  │  └───────────────┘ └──────────┘ └───────────────┘  │  │
│  └─────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────┘
```

### 项目结构

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   ├── theme/
│   └── utils/
├── models/
│   ├── chat_message.dart
│   ├── conversation.dart
│   ├── server_config.dart
│   ├── model_info.dart
│   ├── prompt_template.dart
│   └── settings.dart
├── providers/
│   ├── chat_provider.dart
│   ├── conversation_list_provider.dart
│   ├── server_provider.dart
│   ├── settings_provider.dart
│   ├── template_provider.dart
│   └── document_provider.dart
├── services/
│   ├── llama_api_client.dart
│   ├── storage_service.dart
│   └── file_service.dart
├── screens/
│   ├── home_screen.dart
│   ├── chat_screen.dart
│   ├── server_settings_screen.dart
│   ├── settings_screen.dart
│   └── prompt_library_screen.dart
└── widgets/
    ├── message_bubble.dart
    ├── chat_input.dart
    ├── model_selector.dart
    ├── parameter_panel.dart
    ├── document_uploader.dart
    ├── conversation_list.dart
    └── template_selector.dart
```

---

## 功能规格

### 1. 服务器连接

- 用户手动输入 llama.cpp server URL（HTTP/HTTPS）
- 可选 API Key
- 自动获取可用模型列表（`GET /v1/models`）
- 连接状态指示（已连接/未连接/错误）
- 延迟显示
- 可保存多个服务器配置并切换

**API 调用方式：**
```
POST /v1/chat/completions  (stream: true)
  → SSE stream of delta chunks
  → 实时解析并渲染
```

### 2. 多轮对话

- 新建/切换/删除对话
- 流式输出（SSE），逐 token 渲染
- 对话按日期分组（今天/昨天/更早）
- 对话自动保存，重启不丢失
- 对话命名（自动取首条消息摘要或用户重命名）
- 发送消息时支持 Shift+Enter 换行

### 3. Markdown / 代码渲染

- CommonMark 兼容 Markdown 渲染
- 代码语法高亮（支持常见语言）
- 数学公式（KaTeX 或 flutter_math）
- 表格渲染
- 行内代码
- 代码块添加"复制"按钮

### 4. 模型参数调节

可折叠面板，提供以下参数滑块/输入：

| 参数 | 范围 | 默认值 |
|------|------|--------|
| Temperature | 0.0 - 2.0 | 0.7 |
| Top-P | 0.0 - 1.0 | 0.9 |
| Top-K | 0 - 100 | 40 |
| Max Tokens | 256 - 32768 | 4096 |
| Repeat Penalty | 1.0 - 2.0 | 1.1 |

- System Prompt 编辑区
- 参数自动保存到当前会话

### 5. 多模型切换

- 从服务器可用模型列表中切换
- 当前模型显示在输入栏上方
- 切换模型不影响对话历史

### 6. 对话导出/导入

- 导出为 Markdown 格式（含对话元数据）
- 导出为 JSON 格式（含完整结构，可重新导入）
- 导入 JSON 对话
- 导出整个对话或选中对话

### 7. 对话搜索

- 搜索所有对话内容（消息文本）
- 搜索结果显示上下文片段
- 点击结果跳转到对应对话

### 8. 文档上传

- 支持格式：PDF、TXT、Markdown
- 文件内容提取为纯文本
- 以引用块形式附加在用户消息上方
- 显示文件名和大小
- 移除/替换已上传文档

> **设计决策：** 不做本地向量数据库/embedding。文档内容直接作为上下文发送给 llama server。如果未来需要真正的 RAG（超长文档、语义检索），可以后续增加本地 embedding 引擎。

### 9. 多模态

- 图片上传（📷 按钮）
- 将图片以 base64 或 URL 形式发送给 llama server
- 适用于支持视觉模型的 server（如 LLaVA、Qwen-VL）
- 图片以缩略图预览显示在消息中

### 10. Prompt 模板库

- 预设模板列表（系统内置 + 用户自定义）
- 内置模板：代码审查、翻译助手、论文总结、头脑风暴等
- 新建/编辑/删除模板
- 模板包含：标题、System Prompt、用户消息模板、标签/分组
- 使用：聊天时从 📋 按钮选择模板 → 自动填入 → 可编辑后发送
- 搜索模板
- 最近使用排序

### 11. 深色模式 / 主题切换

- 模式：跟随系统 / 强制浅色 / 强制深色
- 10 种预设配色 seed（蓝、绿、紫、橙、红、青、粉、灰、棕、靛蓝）
- 自定义 seed 色值输入
- Material 3 自动生成完整调色板
- 所有 UI 组件自适应主题切换

---

## 页面布局

### HomeScreen（主页面）

```
┌──────────────────────────────────────────────────┐
│  ☰  LlamaChat                  🔍  ⚙️  ● ● ●  │
├──────────────┬───────────────────────────────────┤
│  对话列表     │                                   │
│              │                                   │
│  ◆ 今天       │   [对话内容区域]                   │
│  ├ 量子计算    │                                   │
│  ├ Python优化  │   选择或开始一个新对话             │
│  │            │                                   │
│  ◆ 昨天       │                                   │
│  ├ 项目规划    │                                   │
│  │            │                                   │
│  ◆ 更早       │                                   │
│  ├ Flutter学习 │                                   │
│  │            │                                   │
│  ───────────  │                                   │
│  + 新建对话   │                                   │
│              │                                   │
├──────────────┴───────────────────────────────────┤
│  ● llama 已连接  │  llama.example.com:8080       │
└──────────────────────────────────────────────────┘
```

**自适应布局：**
- 宽屏（Windows ≥800px）：左栏 + 右栏
- 窄屏（<800px / Android 默认）：抽屉式侧栏

### ChatScreen（对话界面）

```
┌──────────────────────────────────────────────────┐
│  ←  量子计算讨论                     ⋮ 对话菜单  │
├──────────────────────────────────────────────────┤
│                                                  │
│  [消息列表 — 自动滚动到底部]                      │
│                                                  │
│  ┌──────────────────────────────────────────┐    │
│  │  用户      这是一个关于量子计算的问题...   │    │
│  │  12:34                                    │    │
│  └──────────────────────────────────────────┘    │
│                                                  │
│  ┌──────────────────────────────────────────┐    │
│  │  🤖      这是一个很好的问题！            │    │
│  │          量子计算的核心是...              │    │
│  │          ```python                       │    │
│  │          print("hello")                  │    │
│  │          ```                            │    │
│  │  ── 12:35 ──                             │    │
│  └──────────────────────────────────────────┘    │
│                                                  │
│  [流式输出状态: ▊▊▊▊▊▊▊▊▊▊▊▊▊▊░░░░ 65%  ■停止] │
│                                                  │
├──────────────────────────────────────────────────┤
│  📎 📷 💬 ┌──────────────────────┐ 🚀           │
│           │ 输入消息...           │              │
│           └──────────────────────┘              │
│  ▸ Temperature 0.7  Max Tokens 4096  [展开参数]  │
└──────────────────────────────────────────────────┘
```

### ServerSettingsScreen（服务器配置）

- URL 输入框（带 http:// 前缀校验）
- API Key 输入（可选，密码模式）
- 可用模型列表（多选，刷新按钮）
- 连接测试按钮
- 连接状态显示
- 保存/取消

### SettingsScreen（全局设置）

- 外观：主题模式、配色 seed、字体大小
- 对话：默认 System Prompt、默认参数值
- 数据管理：导出/导入对话、清除历史
- 关于：版本号、开源许可

### PromptLibraryScreen（模板库）

- 搜索栏
- 模板卡片列表（标题、预览、最近使用时间）
- 新建/编辑/删除
- 模板编辑器：标题 + System Prompt + 用户消息模板

---

## 主题系统（Material 3）

```
🎨 主题架构:

1. ThemeMode（模式）
   ├ system  → 跟随系统
   ├ light   → 强制浅色
   └ dark    → 强制深色

2. ColorSeed（配色种子）
   ├ 10 种预设
   └ 自定义 HEX 色值

3. Material 3 自动生成
   ├ Primary / OnPrimary
   ├ Secondary / OnSecondary
   ├ Tertiary / OnTertiary
   ├ Error / OnError
   ├ Surface / OnSurface
   └ → 所有组件自适应（FilledButton、Card、Dialog...）
```

---

## 数据模型

### Conversation（对话）

```dart
@drift
class Conversations extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  TextColumn get modelId => text().nullable()();
  RealColumn get temperature => real().withDefault(const Constant(0.7))();
  IntColumn get maxTokens => integer().withDefault(const Constant(4096))();
  TextColumn get systemPrompt => text().nullable()();
}
```

### ChatMessage（消息）

```dart
@drift
class ChatMessages extends Table {
  TextColumn get id => text()();
  TextColumn get conversationId => text()();
  TextColumn get role => text()();  // 'user' | 'assistant'
  TextColumn get content => text()();
  IntColumn get createdAt => integer()();
  IntColumn get tokenCount => integer().nullable()();
  BlobColumn get attachments => blob().nullable()();  // JSON
}
```

### ServerConfig（服务器配置）

```dart
@drift
class ServerConfigs extends Table {
  TextColumn get id => text()();
  TextColumn get url => text()();
  TextColumn get apiKey => text().nullable()();
  TextColumn get label => text()();
  IntColumn get createdAt => integer()();
  IntColumn get lastUsedAt => integer().nullable()();
}
```

### PromptTemplate（Prompt 模板）

```dart
@drift
class PromptTemplates extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get systemPrompt => text()();
  TextColumn get userMessageTemplate => text()();
  TextColumn get category => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get lastUsedAt => integer().nullable()();
  BoolColumn get isBuiltIn => boolean().withDefault(const Constant(false))();
}
```

---

## 状态管理（Riverpod Provider 概览）

| Provider | 用途 | 关键方法 |
|----------|------|---------|
| `serverProvider` | 当前服务器配置和状态 | `connect(url, key)`, `fetchModels()` |
| `conversationListProvider` | 对话列表和分组 | `create()`, `delete(id)`, `search(q)` |
| `chatProvider` | 当前对话的消息流 | `sendMessage(text)`, `stopStream()` |
| `settingsProvider` | 全局设置和主题 | `toggleTheme()`, `setColorSeed()` |
| `templateProvider` | Prompt 模板管理 | `list()`, `apply(template)` |
| `documentProvider` | 文档上传状态 | `upload(file)`, `remove()` |

---

## 错误处理

- **服务器连接失败** — 显示具体错误信息（连接超时/拒绝连接/DNS 解析失败）
- **流式请求中断** — 自动重试提示，保留已收到的文本
- **无效 URL** — 输入校验（格式、前缀）
- **文件解析失败** — 提示格式不支持或文件损坏
- **本地存储异常** — 数据库操作 try-catch，显示友好提示

---

## 后续扩展（不做在 MVP 中，但架构预留）

- 本地 embedding + 语义搜索（真正 RAG）
- 对话同步（通过 WebDAV 或 iCloud 等）
- 语音输入
- 插件系统
- 对话 Branching（分支对话）

---

## 许可

MIT License
