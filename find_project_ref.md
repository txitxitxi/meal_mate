# Find Your Supabase Project Reference

## 🔍 **How to Get Your Project Reference:**

### **Option 1: From Supabase Dashboard**
1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project
3. Look at the URL: `https://supabase.com/dashboard/project/[PROJECT_REF]`
4. The `[PROJECT_REF]` is what we need

### **Option 2: From Your Flutter App**
Look in your Flutter app's Supabase configuration:
```dart
// Usually in lib/services/supabase_service.dart or main.dart
final supabaseUrl = 'https://[PROJECT_REF].supabase.co';
```

### **Option 3: From Your Database Connection**
If you have the database connection string:
```
postgresql://postgres:[PASSWORD]@db.[PROJECT_REF].supabase.co:5432/postgres
```

## 📋 **Next Steps:**

Once you have your project reference:
1. **Copy the project reference** (it's a long string of letters/numbers)
2. **Run the link command** (I'll help you with this)
3. **Deploy the Edge Function**

## 💡 **What the Project Reference Looks Like:**
- Usually 20+ characters long
- Mix of letters and numbers
- Example: `abcdefghijklmnopqrst`

**Can you find your project reference and share it?** Then I can help you link the project and deploy the Edge Function!
