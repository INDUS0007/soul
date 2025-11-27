# Password Field Overflow Fix

## Problem
The "Password" and "Confirm password" labels are overflowing in the registration screen's security step.

## Root Cause
The `InputDecoration` in `_fieldDecoration()` method doesn't have proper padding and density settings, causing the label text to overflow when the field is narrow.

## Solution

### Step 1: Update `_fieldDecoration` method in `register_screen.dart`

**Location:** Around line 299

**Current code:**
```dart
InputDecoration _fieldDecoration({
  required String label,
  IconData? prefix,
  Widget? suffix,
}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: prefix != null ? Icon(prefix) : null,
    suffixIcon: suffix,
    border: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(25)),
    ),
  );
}
```

**Replace with:**
```dart
InputDecoration _fieldDecoration({
  required String label,
  IconData? prefix,
  Widget? suffix,
}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: prefix != null ? Icon(prefix) : null,
    suffixIcon: suffix,
    isDense: true,  // ✅ ADD THIS
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),  // ✅ ADD THIS
    border: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(25)),
    ),
  );
}
```

## What These Properties Do

- **`isDense: true`** - Reduces the default padding inside the text field, making it more compact
- **`contentPadding`** - Explicitly sets the padding inside the text field (left/right 16, top/bottom 12)

## Result

After this change:
✅ Labels won't overflow
✅ Text fields will be more compact and organized
✅ Better spacing around icons and text
✅ Consistent padding across all form fields

## Testing

After making this change:
1. Open the register screen
2. Navigate to "Security & consent" step
3. Check that "Password" and "Confirm password" labels are no longer overflowing
4. Verify the visibility toggle icons still appear correctly
