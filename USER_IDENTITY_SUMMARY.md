# User Identity Fields Summary

This document summarizes how `user_id`, `handle`, and `display_name` are used throughout the Meal Mate project.

## Overview

The project uses three key fields to identify and display users:

1. **`user_id`** - UUID from `auth.users` table (primary key, immutable)
2. **`handle`** - Unique identifier from `profiles` table (fixed, DB use only)
3. **`display_name`** - User-friendly name (editable, shown in UI)

---

## 1. `user_id` (UUID from auth.users)

### Database Usage (Primary Key & Foreign Keys)
- **Type**: UUID (from Supabase auth)
- **Purpose**: Primary identifier for database relationships and Row Level Security (RLS)
- **Immutable**: Cannot be changed (managed by Supabase Auth)

### Where It's Used:

#### Tables Using `user_id`:
- `profiles.user_id` - Links profile to auth user
- `stores.user_id` - Identifies store owner
- `home_inventory.user_id` - Identifies inventory owner
- `meal_plans.user_id` - Identifies meal plan owner
- `recipe_saves.user_id` - Identifies who saved a recipe
- `recipes.author_id` - Identifies recipe creator (also has legacy `user_id` field)

#### Code Usage:
- **Filtering data by user**: All providers filter by `user.id` from `currentUserProvider`
  - `storesStreamProvider`: `.eq('user_id', user.id)`
  - `homeInventoryStreamProvider`: `.eq('user_id', user.id)`
  - `mealPlanProvider`: `.eq('user_id', user.id)`
  - `myRecipesStreamProvider`: `.eq('author_id', user.id)`

- **Row Level Security (RLS)**: All RLS policies check `auth.uid() = user_id`

- **Ownership checks**: Used to determine if user owns resources
  - Recipe ownership: `currentUser?.id == recipe.authorId`
  - Store/item ownership: Verified in queries

---

## 2. `handle` (from profiles table)

### Database Usage
- **Type**: TEXT, UNIQUE constraint
- **Purpose**: Fixed database identifier, must be unique across all users
- **Format**: lowercase letters, numbers, underscores (3-20 characters)
- **Immutable after creation**: Should not be changed (fixed for DB use)

### Where It's Used:

#### Database:
- `profiles.handle` - Unique identifier for each user profile
- Used as fallback when `display_name` is null

#### Code Usage:

**Profile Setup**:
- Created during initial profile setup (`profile_setup_page.dart`)
- Must be unique (checked via `isHandleAvailable()`)
- Validated: 3-20 chars, lowercase, numbers, underscores only

**Display Logic**:
- **User Menu** (`home_page.dart`):
  - Shown as subtitle: `@${profile?.handle}` (e.g., "@user_b6cc7520")
  - Used as fallback for avatar initial if no `display_name`

- **Settings Page**:
  - Displayed as read-only "Handle (Fixed ID)"
  - Cannot be changed (by design)

**Recipe Authors** (`public_recipes_page.dart`):
- Used via `authorProfileProvider` to fetch author info
- Falls back to handle if `display_name` is not available
- Displayed in format: "By {display_name or handle}"

---

## 3. `display_name` (from profiles table)

### Database Usage
- **Type**: TEXT, nullable
- **Purpose**: User-friendly name shown in UI
- **Editable**: Can be updated via Settings page
- **Optional**: If null, `handle` is used as fallback

### Where It's Used:

#### UI Display (Primary Usage):

**User Menu** (`home_page.dart`):
- **Title**: `profile?.displayName ?? profile?.handle ?? 'User'`
- **Avatar Initial**: Uses first letter of `display_name` if available, otherwise `handle`
- Example: Shows "52877988" as title, "@user_b6cc7520" as subtitle

**Settings Page** (`settings_page.dart`):
- Editable field to update display name
- Allows user to change how their name appears
- Can be cleared (set to null) to use handle instead

**Recipe Authors** (`public_recipes_page.dart`):
- `_getAuthorDisplayName()` function prioritizes:
  1. `display_name` (if not empty)
  2. `handle` (if `display_name` is null/empty)
  3. Shortened UUID (if no profile info)
  4. "Community" (fallback)
- Displayed as: "By {display_name or handle}"

**Profile Setup** (`profile_setup_page.dart`):
- Optional field during initial profile creation
- Can be set to empty to use handle only

---

## Usage Patterns

### Priority Order for Display:
1. **`display_name`** (if not null/empty) - Preferred for user-friendly display
2. **`handle`** (fallback) - Used when `display_name` is null/empty
3. **Shortened UUID** - Used when no profile exists
4. **"Community" / "User"** - Final fallback

### Database Relationships:
```
auth.users (id: UUID)
    ↓
profiles (user_id: UUID → auth.users.id, handle: TEXT, display_name: TEXT)
    ↓
All other tables reference user_id/author_id for ownership
```

### Security:
- All queries filter by `user.id` to ensure data isolation
- RLS policies use `auth.uid() = user_id` pattern
- User can only access/modify their own data

---

## Key Files Reference

### Models:
- `lib/models/user_profile.dart` - UserProfile model definition

### Services:
- `lib/services/supabase_service.dart` - Database operations
  - `getCurrentUserProfile()` - Fetches profile
  - `updateUserProfile()` - Updates profile (including display_name)
  - `isHandleAvailable()` - Checks handle uniqueness

### Providers:
- `lib/providers/auth_providers.dart` - Auth state and profile providers
  - `userProfileProvider` - Stream of current user profile
  - `currentUserProvider` - Current auth user (has `user.id`)

### UI Pages:
- `lib/pages/home_page.dart` - User menu display
- `lib/pages/settings_page.dart` - Update display name
- `lib/pages/profile_setup_page.dart` - Initial profile creation
- `lib/pages/public_recipes_page.dart` - Recipe author display

---

## Summary Table

| Field | Type | Editable | Purpose | Display Priority |
|-------|------|----------|---------|------------------|
| `user_id` | UUID | ❌ No | Database relationships, RLS, ownership | Not displayed |
| `handle` | TEXT | ❌ No (after creation) | Fixed DB identifier, unique | 2nd (after display_name) |
| `display_name` | TEXT | ✅ Yes | User-friendly name | 1st (primary) |

---

## Best Practices

1. **Always use `user_id`** for database queries and relationships
2. **Never change `handle`** after profile creation (it's fixed)
3. **Use `display_name`** for all UI display, with `handle` as fallback
4. **Check ownership** using `user.id == resource.user_id/author_id`
5. **Filter queries** by `user_id` to ensure data isolation

