# Counsellor Bio Save Bug Fix

## Problem Found ❌
In the **Counsellor Profile Setup Screen**, when a user updated their **bio** and clicked **Save**, the data was **NOT being sent to the backend**. The app just showed a success message without actually making any API call.

### Root Cause
The `_saveProfile()` method in `apps/app_counsellor/lib/screens/profile_setup_screen.dart` was incomplete:

```dart
void _saveProfile() {
  if (_formKey.currentState?.validate() ?? false) {
    // ❌ NO API CALL - just shows message and navigates back
    showSuccessSnackBar(context, 'Profile updated successfully');
    Navigator.pop(context);
  }
}
```

## Solution Implemented ✅

### Changes Made

#### 1. **Added Missing Imports**
```dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
```

#### 2. **Updated `_saveProfile()` to Make Actual API Call**
```dart
void _saveProfile() async {
  if (_formKey.currentState?.validate() ?? false) {
    try {
      // Prepare payload
      final updateData = {
        'bio': _bioController.text,
        'specialization': _specializationController.text,
      };

      // Get auth token from secure storage
      const storage = FlutterSecureStorage();
      final access = await storage.read(key: 'access');
      
      if (access == null) {
        showErrorSnackBar(context, 'Authentication required. Please login first.');
        return;
      }

      // ✅ Make HTTP PATCH request to backend
      final response = await http.patch(
        Uri.parse('${ApiClient.base}/counselor/profile/'),
        headers: {
          'Authorization': 'Bearer $access',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(updateData),
      );

      if (response.statusCode == 200) {
        showSuccessSnackBar(context, 'Profile updated successfully! ✅');
        Navigator.pop(context, true);
      } else {
        final errorMsg = _extractErrorMessage(response);
        showErrorSnackBar(context, 'Failed to update profile: $errorMsg');
      }
    } catch (e) {
      showErrorSnackBar(context, 'Error updating profile: $e');
    }
  }
}
```

#### 3. **Added Error Message Extraction Helper**
```dart
String _extractErrorMessage(http.Response response) {
  if (response.body.isEmpty) {
    return 'Request failed with status ${response.statusCode}';
  }
  try {
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      if (decoded['detail'] != null) {
        return decoded['detail'].toString();
      }
      if (decoded.values.isNotEmpty) {
        return decoded.values.first.toString();
      }
    }
  } catch (_) {}
  return response.body;
}
```

## Backend Verification ✅

### API Endpoint
- **Endpoint:** `PATCH /api/counselor/profile/`
- **View:** `CounsellorProfileView` (RetrieveUpdateAPIView)
- **Serializer:** `CounsellorProfileSerializer`

### Serializer Fields
The `CounsellorProfileSerializer` includes `bio` in its fields and it's **writable** (not in `read_only_fields`):

```python
class CounsellorProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = CounsellorProfile
        fields = (
            "id",
            "username",
            "email",
            "full_name",
            "specialization",
            "experience_years",
            "languages",
            "rating",
            "is_available",
            "bio",  # ✅ BIO IS HERE
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "rating", "created_at", "updated_at")  # ✅ BIO NOT IN READ_ONLY
```

## How It Works Now

### Flow Diagram
```
User enters bio text
         ↓
User clicks "Save"
         ↓
✅ Validation runs
         ↓
✅ Get auth token from secure storage
         ↓
✅ Make PATCH request: /api/counselor/profile/
         ↓
✅ Backend receives data and updates CounsellorProfile.bio
         ↓
✅ Response returns updated profile (status 200)
         ↓
✅ Show success snackbar "Profile updated successfully! ✅"
         ↓
✅ Navigate back to previous screen
```

## Testing Steps

1. **Login** to the counsellor app with your credentials
2. **Navigate** to Profile Setup screen
3. **Edit** the Bio field (e.g., add "Experienced counselor specializing in anxiety and stress management")
4. **Click Save**
5. **Expected Result:** 
   - ✅ Success message appears: "Profile updated successfully! ✅"
   - ✅ Changes are saved to the database
   - ✅ Screen navigates back
6. **Verify in Database:**
   ```sql
   SELECT * FROM api_counsellorprofile WHERE user_id = <your_user_id>;
   ```
   You should see the updated `bio` value.

## File Modified
- `apps/app_counsellor/lib/screens/profile_setup_screen.dart`

## Impact
- ✅ Bio updates now properly saved to database
- ✅ Error messages displayed if save fails
- ✅ Auth token validation before making request
- ✅ Proper HTTP status code handling
- ✅ User feedback (success/error snackbars)

---

**Status:** ✅ FIXED AND READY TO TEST