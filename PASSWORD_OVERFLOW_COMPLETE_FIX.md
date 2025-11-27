# Password Field Overflow - Complete Fix

## Problem
The "Password" label is still overflowing in the Security & consent step, even with `isDense: true` and `contentPadding`.

## Root Cause
The `Stepper` widget constrains the content width, and the label text "Password" with the prefix icon and suffix button (visibility toggle) is taking up too much horizontal space.

## Solution 1: Use Hint Text Instead of Label (Recommended)

This is the cleanest solution. Change the `_fieldDecoration` method to use `hintText` instead of `labelText`:

### Current Code (Line 299):
```dart
InputDecoration _fieldDecoration({
  required String label,
  IconData? prefix,
  Widget? suffix,
}) {
  return InputDecoration(
    labelText: label,  // ❌ This causes overflow
    prefixIcon: prefix != null ? Icon(prefix) : null,
    suffixIcon: suffix,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    border: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(25)),
    ),
  );
}
```

### Fixed Code:
```dart
InputDecoration _fieldDecoration({
  required String label,
  IconData? prefix,
  Widget? suffix,
}) {
  return InputDecoration(
    hintText: label,  // ✅ Use hintText instead of labelText
    prefixIcon: prefix != null ? Icon(prefix) : null,
    suffixIcon: suffix,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    border: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(25)),
    ),
  );
}
```

**Difference:**
- `labelText` → Creates a floating label that moves above the field when focused (takes space)
- `hintText` → Creates placeholder text inside the field that disappears when you type (doesn't overflow)

## Solution 2: Wrap Form in SingleChildScrollView

If you want to keep the floating labels, wrap the Form in `SingleChildScrollView`:

### In `_securityStep()` method (Line 571):

**Current:**
```dart
Step _securityStep() {
  return Step(
    title: const Text('Security & consent'),
    isActive: _currentStep >= 2,
    state: StepState.indexed,
    content: Form(  // ❌ Form content directly
      key: _passwordFormKey,
      child: Column(
```

**Fixed:**
```dart
Step _securityStep() {
  return Step(
    title: const Text('Security & consent'),
    isActive: _currentStep >= 2,
    state: StepState.indexed,
    content: SingleChildScrollView(  // ✅ Wrap in scroll view
      child: Form(
        key: _passwordFormKey,
        child: Column(
```

Then close the `SingleChildScrollView` at the end of the Column.

## Solution 3: Make Labels Shorter

If you prefer keeping labels, just shorten them:

Change in `_securityStep()`:
```dart
decoration: _fieldDecoration(
-  label: 'Password',
+  label: 'Password',  // Already short
   prefix: Icons.lock_outline,
```

## Recommended Fix: Use Solution 1 (hintText)

This is the **best solution** because:
✅ Fixes overflow immediately
✅ No layout changes needed
✅ Consistent with modern Material Design
✅ Works perfectly with icons and visibility toggles
✅ Minimal code change

### Steps:
1. Open `apps/app_user/lib/screens/register_screen.dart`
2. Go to line 307 (in `_fieldDecoration` method)
3. Change: `labelText: label,`
4. To: `hintText: label,`
5. Save and test

That's it! The password field won't overflow anymore.

## Visual Difference

### Before (with labelText - OVERFLOW):
```
Password ────────────────────────────  [eye icon]
│
Label overflows outside the box
```

### After (with hintText - FIXED):
```
[lock] Password         [eye icon]
When you type, the hint disappears
```

## Testing After Fix

1. Open register screen
2. Go to "Security & consent" step
3. Check that "Password" text no longer overflows ✅
4. Click on password field
5. Start typing
6. Verify hint disappears and text is hidden ✅
7. Toggle visibility icon to show/hide password ✅
