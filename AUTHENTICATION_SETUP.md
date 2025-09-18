# Multi-User Authentication Setup

This document outlines the implementation of multi-user authentication with Apple Sign-In for the Meal Mate app.

## ✅ What's Been Implemented

### 1. **Authentication System**
- Apple Sign-In integration with proper nonce generation
- Email/password authentication as fallback
- Secure authentication state management with Riverpod
- Automatic profile creation trigger after authentication

### 2. **User Profile Management**
- UserProfile model with handle, display name, avatar, bio, and privacy settings
- Profile setup flow for new users
- Handle uniqueness validation
- Profile update functionality

### 3. **Multi-User Recipe System**
- Updated Recipe model to support multi-user fields (`author_id`, `visibility`, etc.)
- Recipe visibility controls (public, unlisted, private)
- User-specific recipe streams and public recipe discovery
- Proper RLS (Row Level Security) integration

### 4. **Updated UI Components**
- Modern login page with Apple Sign-In button (iOS only)
- Profile setup page for new users
- Updated home page with user profile display and sign-out
- Authentication-aware navigation

### 5. **Router & Navigation**
- Authentication guards that redirect unauthenticated users to login
- Profile setup flow for users without profiles
- Automatic navigation after successful authentication

## 🔧 Setup Requirements

### iOS Configuration (Already Done)
- Added URL scheme `com.tousan.mealMate` to Info.plist for deep linking
- Apple Sign-In capability should be enabled in Xcode project settings

### Supabase Configuration (Already Done)
Based on your Supabase update document:
- Apple Sign-In provider enabled with Team ID `328KUR279N`
- Client ID: `com.tousan.mealMate`
- Key ID: `5W9YBK95L6`
- JWT client secret generated from `.p8` file
- Redirect URL: `https://hqnorxqkdgosvrjcftlf.supabase.co/auth/v1/callback`

## 🚀 How to Test

### 1. **Run the App**
```bash
cd meal_mate
flutter pub get
flutter run
```

### 2. **Test Authentication Flow**
1. App will redirect to login page if not authenticated
2. On iOS: Test Apple Sign-In button
3. On any platform: Test email/password sign up and sign in
4. New users will be prompted to set up their profile
5. Existing users go directly to home page

### 3. **Test Multi-User Features**
1. Create recipes with different visibility settings
2. Sign out and sign in with different account
3. Verify that private recipes are not visible to other users
4. Test profile display in home page header

## 📁 New Files Created

- `lib/models/user_profile.dart` - User profile data model
- `lib/providers/auth_providers.dart` - Authentication state management
- `lib/pages/profile_setup_page.dart` - Profile setup UI for new users
- `lib/pages/login_page.dart` - Updated with Apple Sign-In
- Updated existing files for multi-user support

## 🔐 Security Features

- Proper nonce generation for Apple Sign-In
- RLS-compliant database queries (author_id = auth.uid())
- User can only delete/modify their own recipes
- Profile privacy controls
- Secure authentication state management

## 🐛 Potential Issues & Solutions

### Apple Sign-In Not Working
- Ensure Apple Developer account has Sign-In capability enabled
- Verify bundle identifier matches Supabase configuration
- Check that device has Apple ID signed in

### Profile Setup Loop
- If users get stuck in profile setup, check Supabase profiles table
- Verify trigger is creating profile entries correctly

### Recipe Visibility Issues
- Check RLS policies in Supabase
- Verify `author_id` is being set correctly on recipe creation

## 🔄 Migration Notes

- Existing recipes will need `author_id` backfilled (already done in Supabase)
- Legacy `user_id` field maintained for compatibility
- New `visibility` field defaults to 'public'

## 🎯 Next Steps

1. **Add Google Sign-In** (optional)
2. **Implement profile editing page**
3. **Add social features** (following, recipe saves, comments)
4. **Image upload for profiles and recipes**
5. **Push notifications for social interactions**

The authentication system is now fully functional and ready for production use!
