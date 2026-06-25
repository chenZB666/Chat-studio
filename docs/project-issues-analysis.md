# LlamaChat 项目现存问题分析

> 分析日期：2026-06-25
> 最后更新：2026-06-25
> 项目版本：1.0.0

---

## ✅ 已修复（2026-06-25）

| 问题 | 修复内容 |
|------|---------|
| 设置持久化 | 引入 `shared_preferences`，`AppSettings` 启动时自动加载，变更时自动持久化 |
| 参数面板滑块功能 | 所有 5 个滑块接入 `StorageService.updateConversationParameters`，150ms 防抖写入 DB |
| 复制按钮 | 使用 `Clipboard.setData` 实现一键复制，附带短暂 SnackBar 反馈 |
| API Key 明文存储 | 引入 `flutter_secure_storage`，API Key 存入 Windows DPAPI / macOS Keychain，SQLite 列置空；自动迁移旧数据 |
| API Key 可见性切换 | 密码框旁的按钮现在可以切换文本显示/隐藏 |
| PDF 文本提取 | 引入 `syncfusion_flutter_pdf`，`PdfTextExtractor` 真实提取文本内容 |
| `file_picker` 版本约束 | 从精确版本 `10.0.0` 改为宽松约束 `^10.0.0` |
| 保存服务器删除按钮 | 修复空回调，接入 `deleteServerConfig` + `refreshSavedServers` |

---

## 🟡 中等级别

### 1. 无单元测试

项目中只有一个 Flutter 默认生成的 `test/widget_test.dart`，没有任何有意义的功能测试、provider 测试或 API 客户端测试。

### 2. 数据库无迁移机制

**文件：** `lib/database/database.dart:15`

```dart
@override
int get schemaVersion => 1;
```

没有实现 `MigrationStrategy`。一旦后续需要改表结构，现有用户的数据库会直接崩溃或报错。

### 3. `template_selector.dart` 已定义但未被引用

**文件：** `lib/widgets/template_selector.dart`

整个项目中搜索不到任何地方 import 或使用 `TemplateSelector` 组件，属于死代码。

### 4. 无法重命名对话

`StorageService` 提供了 `updateConversationTitle` 方法，但 UI 上没有入口让用户修改对话标题。侧边栏中所有对话标题都不可编辑。

### 5. 搜索对话后无视觉反馈

**文件：** `lib/screens/home_screen.dart`

搜索结果点击后仅仅关闭搜索面板并加载对话，用户无法直观地看到搜索高亮或搜索结果出现的上下文。

### 6. 模型选择器缺少搜索/排序功能

**文件：** `lib/widgets/chat_input.dart`

`DropdownButton` 在有大量模型时没有搜索或筛选功能，用户体验较差。

### 7. `testConnection` 和 `saveServer` 调用链有冗余

**文件：** `lib/screens/server_settings_screen.dart`

`_saveServer` 先调用 `_testConnection`，而 `_testConnection` 内部又调用了完整的连接流程（包括获取模型列表）。如果用户只是想保存配置稍后使用，不应该强制测试连接。

---

## 🔵 低级别 / 代码质量

### 8. 加载历史对话时不会自动滚动到底部

**文件：** `lib/screens/chat_screen.dart`

只在 `streaming` 状态时调用 `_scrollToBottom()`，加载已有对话历史时不会自动滚到底部。

### 9. API 客户端是共享可变单例

**文件：** `lib/services/llama_api_client.dart`

`LlamaApiClient` 通过 Provider 作为单例共享，`connect()` 修改内部可变状态（`_baseUrl`、`_apiKey`、`_cancelToken`），并发场景下可能有问题。

### 10. 思考标签解析硬编码

**文件：** `lib/providers/chat_provider.dart:174-210`

`_extractThinking` 方法硬编码了 `  ` / `  ` 标签。这只兼容 DeepSeek R1 风格模型，对其他模型不适用，且不可配置。

### 11. 文件类型命名不一致

**文件：** `lib/providers/document_provider.dart:44`

非图片文件时直接把扩展名作为 `fileType`，而在 `MessageBubble` 中期望的是 `'image'`、`'pdf'`、`'txt'`、`'md'` 等标准类型。上传 PDF 以外的非图片文件时图标映射可能不匹配。

### 12. 错误处理不完整

- `ConversationList` 的数据加载只处理了 `isLoading` 状态，没有处理 error 状态
- `ConversationListState` 中没有 `errorMessage` 字段
- 若干异步数据库操作未包裹 try-catch

### 13. `database.g.dart` 被 `.gitignore` 排除

`*.g.dart` 在 `.gitignore` 中，`build_runner` 生成的文件不会被提交。新开发者需要手动运行 `dart run build_runner build`，否则编译失败。没有文档说明这一步骤。

---

## 📋 剩余问题修复建议

| 优先级 | 问题 | 预估工作量 | 影响范围 |
|--------|------|-----------|---------|
| P1 | 数据库迁移策略 | ~1h | 后续迭代基础 |
| P2 | 单元测试 | ~4h+ | 质量保障 |
| P2 | 对话重命名功能 | ~1h | UX 完善 |
| P2 | 死代码清理 (`template_selector`) | ~0.5h | 代码维护 |
| P3 | 加载历史对话自动滚动 | ~0.5h | UX 细节 |
| P3 | 模型选择器搜索/排序 | ~1h | UX 完善 |
| P3 | 代码质量问题汇总（思考标签、文件类型、错误处理等） | 持续改进 | 长期质量 |