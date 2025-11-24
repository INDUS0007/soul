# Code Optimization Plan

## Overview
This document outlines the code optimization and cleanup plan for removing duplicate code, unused files, and improving code structure.

## ✅ Completed Optimizations

### 1. Shared Widgets Moved to Common Package
- ✅ `LoadingIndicator` - Moved to `packages/common/lib/widgets/loading_indicator.dart`
- ✅ `LoadingOverlay` - Moved to `packages/common/lib/widgets/loading_indicator.dart`
- ✅ `ErrorMessage` - Moved to `packages/common/lib/widgets/error_message.dart`
- ✅ `showErrorSnackBar()` - Moved to `packages/common/lib/widgets/error_message.dart`
- ✅ `showSuccessSnackBar()` - Moved to `packages/common/lib/widgets/error_message.dart`
- ✅ Duplicate files removed from both apps

### 2. Shared Utilities Created
- ✅ `LoadingStateMixin` - Helper mixin for loading/error state patterns
- ✅ `AsyncDataLoader` - Utility class for async data loading
- ✅ Exported in `packages/common/lib/common.dart`

## 🔄 In Progress

### 3. Replace Duplicate Loading/Error Patterns

**Pattern Found:** Multiple screens use duplicate code:
```dart
// BEFORE (Duplicate)
if (_loading) {
  return const Center(child: CircularProgressIndicator());
}
if (_error != null) {
  return Center(
    child: Column(
      children: [
        Text(_error!),
        FilledButton(onPressed: _loadData, child: Text('Retry')),
      ],
    ),
  );
}

// AFTER (Using Shared Widgets)
if (_loading) {
  return const LoadingIndicator();
}
if (_error != null) {
  return ErrorMessage(message: _error!, onRetry: _loadData);
}
```

**Screens to Update (User App):**
- [ ] `wallet_page.dart`
- [ ] `music_page.dart`
- [ ] `meditation_page.dart`
- [ ] `wellness_plan_page.dart`
- [ ] `wellness_journal_page.dart`
- [ ] `support_groups_page.dart`
- [ ] `professional_guidance_page.dart`
- [ ] `reports_analytics_page.dart`
- [ ] `history_center_page.dart`
- [ ] `upcoming_sessions_page.dart`
- [ ] `settings_page.dart`
- [ ] `mindcare_booster_page.dart` (partially done)

**Screens to Update (Counsellor App):**
- [ ] `counselor_dashboard.dart`
- [ ] `queued_chats_screen.dart`

### 4. Consolidate Duplicate Loading State Logic

**Pattern Found:** Same loading/error pattern repeated:
```dart
// BEFORE (Duplicate)
Future<void> _loadData() async {
  setState(() {
    _loading = true;
    _error = null;
  });
  try {
    final data = await _api.fetchData();
    if (!mounted) return;
    setState(() {
      _data = data;
      _loading = false;
    });
  } on ApiClientException catch (error) {
    if (!mounted) return;
    setState(() {
      _error = error.message;
      _loading = false;
    });
  } catch (error) {
    if (!mounted) return;
    setState(() {
      _error = 'Something went wrong: $error';
      _loading = false;
    });
  }
}

// AFTER (Using LoadingStateMixin)
class _MyPageState extends State<MyPage> with LoadingStateMixin {
  Future<void> _loadData() async {
    await executeWithLoading(
      action: () => _api.fetchData(),
      errorMessage: 'Unable to load data',
    );
  }
}
```

### 5. Remove Temporary Documentation Files

**Files to Remove:**
- ✅ `BILLING_DEBUG_GUIDE.md` (deleted)
- ✅ `BILLING_FIX_SUMMARY.md` (deleted)
- [ ] `MODEL_VERIFICATION_REPORT.md` (temporary)
- [ ] `CONNECTION_VERIFICATION_REPORT.md` (temporary)
- [ ] `CHAT_DATABASE_TABLES.md` (consolidate into main docs)
- [ ] `FIX_WINDOWS_BUILD.md` (consolidate into main docs)
- [ ] `OPTIMIZATION_SUMMARY.md` (consolidate into main docs)

**Files to Keep:**
- ✅ `README.md` - Main project README
- ✅ `PROJECT_DOCUMENTATION.md` - Comprehensive documentation
- ✅ `MULTI_APP_ARCHITECTURE.md` - Architecture documentation
- ✅ `BILLING_IMPLEMENTATION.md` - Billing feature documentation

### 6. Remove Unused Build Files

**Directories to Add to .gitignore:**
- `apps/*/build/` - Flutter build outputs
- `apps/*/.dart_tool/` - Dart tool cache
- `*.lock` files (except pubspec.lock)
- `backend/__pycache__/` - Python cache
- `backend/*.pyc` - Compiled Python files

## 📋 Detailed Optimization Tasks

### Task 1: Replace Loading Indicators

**Current:** 13 screens use `Center(child: CircularProgressIndicator())`
**Target:** All screens use `LoadingIndicator` from common package

**Steps:**
1. Add `import 'package:common/common.dart';` to each screen
2. Replace `Center(child: CircularProgressIndicator())` with `LoadingIndicator()`
3. Replace inline error displays with `ErrorMessage` widget

### Task 2: Consolidate Loading State Logic

**Current:** Every screen has duplicate try-catch-error handling
**Target:** Use `LoadingStateMixin` or `AsyncDataLoader` helper

**Screens with duplicate patterns:**
- All screens in `apps/app_user/lib/screens/`
- `counselor_dashboard.dart` in counsellor app

### Task 3: Remove Duplicate Error Display Code

**Current:** Multiple custom error widgets
**Target:** Use `ErrorMessage` from common package

**Examples:**
- `mindcare_booster_page.dart` - `_ErrorMessage` class (removed, needs import update)
- `wallet_page.dart` - Inline error display
- Multiple other screens

### Task 4: Optimize Import Statements

**Current:** Some screens import entire packages
**Target:** Import only what's needed

**Example:**
```dart
// BEFORE
import 'package:common/api/api_client.dart';

// AFTER (if only using widgets)
import 'package:common/common.dart';
```

### Task 5: Consolidate Session Timer Logic

**Current:** Session timer duplicated in multiple screens
**Target:** Use shared `SessionTimer` utility

**Files:**
- `chat_session_screen.dart`
- `session_screen.dart`
- `audio_call_screen.dart`

## 🎯 Optimization Priorities

### High Priority
1. ✅ Remove duplicate widget files
2. ✅ Create shared widgets in common package
3. 🔄 Replace `CircularProgressIndicator` with `LoadingIndicator`
4. 🔄 Replace inline error displays with `ErrorMessage`

### Medium Priority
5. 🔄 Implement `LoadingStateMixin` in key screens
6. 🔄 Consolidate session timer logic
7. 🔄 Remove temporary documentation files

### Low Priority
8. 🔄 Optimize import statements
9. 🔄 Add const constructors where possible
10. 🔄 Extract common patterns to utilities

## 📊 Code Duplication Analysis

### Duplicate Patterns Found:

1. **Loading State Pattern** (15+ files)
   - Pattern: `_loading`, `_error`, try-catch blocks
   - Solution: Use `LoadingStateMixin`

2. **Error Display Pattern** (10+ files)
   - Pattern: Center + Column + Text + Button
   - Solution: Use `ErrorMessage` widget

3. **Loading Indicator** (13+ files)
   - Pattern: `Center(child: CircularProgressIndicator())`
   - Solution: Use `LoadingIndicator` widget

4. **API Call Pattern** (20+ files)
   - Pattern: try-catch with `ApiClientException`
   - Solution: Use `LoadingStateMixin.executeWithLoading()`

## 🔧 Implementation Strategy

### Phase 1: Quick Wins (✅ Done)
- ✅ Move widgets to common package
- ✅ Delete duplicate files
- ✅ Create utility helpers

### Phase 2: Screen Updates (In Progress)
- Replace loading indicators
- Replace error displays
- Update imports

### Phase 3: Pattern Consolidation
- Implement LoadingStateMixin
- Refactor API call patterns
- Consolidate session timer

### Phase 4: Cleanup
- Remove temporary docs
- Optimize imports
- Add const constructors

## 📝 Next Steps

1. **Update wallet_page.dart** as example
2. **Update remaining screens** systematically
3. **Test all screens** after updates
4. **Remove temporary files**
5. **Update documentation**

