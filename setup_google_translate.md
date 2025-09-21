# Google Translate API Setup Guide

## 🔑 **Step 1: Get Google Translate API Key**

### **Option A: Free Tier (Recommended)**
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable the **Cloud Translation API**
4. Go to **Credentials** → **Create Credentials** → **API Key**
5. Copy your API key

### **Option B: Free Alternative (No API Key Needed)**
If you prefer not to use Google Translate, I can modify the Edge Function to use a free translation service.

## ⚙️ **Step 2: Set Up Supabase Edge Function**

### **Install Supabase CLI (if not already installed):**
```bash
# Install via npm
npm install -g supabase

# Or via Homebrew (macOS)
brew install supabase/tap/supabase
```

### **Login to Supabase:**
```bash
supabase login
```

### **Link to your project:**
```bash
supabase link --project-ref YOUR_PROJECT_REF
```

### **Deploy the Edge Function:**
```bash
supabase functions deploy translate-ingredient
```

## 🔧 **Step 3: Set Environment Variables**

### **In Supabase Dashboard:**
1. Go to **Settings** → **Edge Functions**
2. Add environment variable:
   - **Name**: `GOOGLE_TRANSLATE_API_KEY`
   - **Value**: `your_actual_api_key_here`

### **Or via CLI:**
```bash
supabase secrets set GOOGLE_TRANSLATE_API_KEY=your_actual_api_key_here
```

## 🧪 **Step 4: Test the Edge Function**

### **Test locally first:**
```bash
supabase functions serve translate-ingredient
```

### **Test with curl:**
```bash
curl -X POST 'http://localhost:54321/functions/v1/translate-ingredient' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{"ingredient_name": "Noodle", "target_language": "zh"}'
```

## 🚀 **Step 5: Run the Smart Translation System**

Run this in your Supabase SQL Editor:
```sql
-- File: smart_translation_system.sql
```

## 🎯 **Expected Results:**

After setup, when you add "Noodle" in your Flutter app:
1. **Trigger adds placeholder**: `[Auto-translate: Noodle]`
2. **Edge Function translates**: `Noodle` → `面条`
3. **Database updates**: Replaces placeholder with `面条`
4. **Future "Noodle" ingredients**: Use cached `面条`

## 💰 **Cost Considerations:**

- **Google Translate Free Tier**: 500,000 characters/month
- **Typical ingredient**: ~10 characters
- **Free tier capacity**: ~50,000 ingredient translations/month
- **Should be more than enough** for your app!

## 🔄 **Alternative: Free Translation Service**

If you prefer not to use Google Translate, I can modify the Edge Function to use:
- **LibreTranslate** (free, self-hosted)
- **MyMemory API** (free tier available)
- **Azure Translator** (free tier)

**Which option would you prefer?**
