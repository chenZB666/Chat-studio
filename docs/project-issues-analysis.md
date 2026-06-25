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
| 窗口控制按钮消失 | 恢复自定义 `TitleBar`，修复因误改标准 `AppBar` 导致的最小化/最大化/关闭按钮丢失 |
| `template_selector.dart` 死代码 | 删除未引用的文件 |
| 数据库迁移机制 | 添加 `MigrationStrategy`，预留 schema 升级入口 |
| 对话重命名功能 | 长按对话列表项弹出重命名对话框，调用 `StorageService.updateConversationTitle` |
| 模型选择器搜索功能 | 将 `DropdownButton` 替换为搜索式 `ModalBottomSheet`，支持按名称筛选模型 |
| 冗余的 test/save 调用链 | 将"保存并连接"拆分为独立"保存"和"保存并连接"两个按钮，用户可选择仅保存 |

---

## 🟡 中等级别

### 1. 无单元测试

项目中只有一个 Flutter 默认生成的 `test/widget_test.dart`，没有任何有意义的功能测试、provider 测试或 API 客户端测试。

### 2. 搜索对话后无视觉反馈

**文件：** `lib/screens/home_screen.dart`

搜索结果点击后仅仅关闭搜索面板并加载对话，用户无法直观地看到搜索高亮或搜索结果出现的上下文。

---

## 🔵 低级别 / 代码质量

### 3. 加载历史对话时不会自动滚动到底部

**文件：** `lib/screens/chat_screen.dart`

只在 `streaming` 状态时调用 `_scrollToBottom()`，加载已有对话历史时不会自动滚到底部。

### 4. API 客户端是共享可变单例

**文件：** `lib/services/llama_api_client.dart`

`LlamaApiClient` 通过 Provider 作为单例共享，`connect()` 修改内部可变状态（`_baseUrl`、`_apiKey`、`_cancelToken`），并发场景下可能有问题。

### 5. 思考标签解析硬编码

**文件：** `lib/providers/chat_provider.dart:174-210`

`_extractThinking` 方法硬编码了 `  ` / `  ` 标签。这只兼容 DeepSeek R1 风格模型，对其他模型不适用，且不可配置。

### 6. 文件类型命名不一致

**文件：** `lib/providers/document_provider.dart:44`

非图片文件时直接把扩展名作为 `fileType`，而在 `MessageBubble` 中期望的是 `'image'`、`'pdf'`、`'txt'`、`'md'` 等标准类型。上传 PDF 以外的非图片文件时图标映射可能不匹配。

### 7. 错误处理不完整

- `ConversationList` 的数据加载只处理了 `isLoading` 状态，没有处理 error 状态
- `ConversationListState` 中没有 `errorMessage` 字段
- 若干异步数据库操作未包裹 try-catch

### 8. `database.g.dart` 被 `.gitignore` 排除

`*.g.dart` 在 `.gitignore` 中，`build_runner` 生成的文件不会被提交。新开发者需要手动运行 `dart run build_runner build`，否则编译失败。没有文档说明这一步骤。

---

## 📋 剩余问题修复建议

| 优先级 | 问题 | 预估工作量 | 影响范围 |
|--------|------|-----------|---------|
| P2 | 单元测试 | ~4h+ | 质量保障 |
| P3 | 加载历史对话自动滚动 | ~0.5h | UX 细节 |
| P3 | 思考标签可配置化 | ~1h | 模型兼容性 |
| P3 | 代码质量问题汇总（文件类型、错误处理等） | 持续改进 | 长期质量 |