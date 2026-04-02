# Supabase Setup Guide for Beam

This guide walks you through setting up Supabase for the Beam application.

## Prerequisites

- A Supabase account (https://supabase.com)
- Supabase CLI installed (`npm install -g supabase` or `brew install supabase/tap/supabase`)

## Step 1: Create a New Supabase Project

1. Go to https://supabase.com and sign in
2. Click "New Project"
3. Fill in:
   - **Name:** Beam
   - **Database Password:** (save this securely)
   - **Region:** Choose closest to your users
4. Click "Create new project" (takes ~2 minutes)

## Step 2: Run the Database Schema

1. In your Supabase dashboard, go to **SQL Editor**
2. Click "New query"
3. Copy the contents of `supabase_schema.sql` from this project
4. Paste and click "Run"
5. Verify all tables were created successfully

## Step 3: Configure Storage Buckets

The schema creates these buckets automatically:
- `documents` (private)
- `signatures` (private)
- `avatars` (public)

Verify in **Storage** → **Buckets** that they exist with correct policies.

## Step 4: Set Up Environment Variables

### In Supabase Dashboard

1. Go to **Project Settings** → **API**
2. Copy these values:
   - **Project URL** → `SUPABASE_URL`
   - **anon/public key** → `SUPABASE_ANON_KEY`
   - **service_role key** → (keep secret, for Edge Functions only)

### For Edge Functions

1. Go to **Project Settings** → **Edge Functions**
2. Click "Manage secrets"
3. Add these secrets:

```bash
GEMINI_API_KEY=your_google_ai_api_key
OPENAI_API_KEY=your_openai_api_key
CHINESE_AI_API_KEY=your_qwen_or_deepseek_api_key
CHINESE_AI_ENDPOINT=https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions
```

### Get API Keys

- **Google AI (Gemini):** https://makersuite.google.com/app/apikey
- **OpenAI:** https://platform.openai.com/api-keys
- **Alibaba Cloud (Qwen/DeepSeek):** https://dashscope.console.aliyun.com/apiKey

## Step 5: Deploy Edge Functions

```bash
# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref YOUR_PROJECT_REF

# Deploy the AI router function
supabase functions deploy ai-router --project-ref YOUR_PROJECT_REF
```

### Get Project Reference

Find your project reference in:
- **Project Settings** → **General** → **Reference**

## Step 6: Configure Email Authentication

1. Go to **Authentication** → **Providers**
2. Ensure **Email** is enabled
3. Configure email templates:
   - Go to **Authentication** → **Email Templates**
   - Customize "Confirm signup" and "Reset password" templates
   - Add your app logo and branding

### Custom SMTP (Optional for Production)

For production, configure custom SMTP:
1. Go to **Project Settings** → **Auth**
2. Scroll to "Custom SMTP"
3. Add your SMTP credentials (SendGrid, Postmark, etc.)

## Step 7: Set Up Realtime

The schema enables realtime for `documents` and `folders` tables.

Verify in **Database** → **Replication**:
- `documents` table should be published
- `folders` table should be published

## Step 8: Test the Setup

### Test Authentication

```bash
# In Supabase Dashboard → SQL Editor
INSERT INTO auth.users (email, encrypted_password, email_confirmed_at)
VALUES (
  'test@example.com',
  crypt('testpassword123', gen_salt('bf')),
  NOW()
);
```

### Test Edge Function

```bash
# Test the AI router function
curl -X POST 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/ai-router' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "action_type": "summarize",
    "user_id": "test-user-id",
    "file_content": "This is a test document."
  }'
```

## Step 9: Update Flutter App

Create a `.env` file in the project root (not committed to git):

```env
SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Or use `--dart-define` when running:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

## Security Checklist

- [ ] RLS (Row Level Security) enabled on all tables
- [ ] Storage bucket policies restrict access to user's own files
- [ ] Edge Function secrets configured (not in client code)
- [ ] Email confirmation enabled
- [ ] Strong password policy enabled
- [ ] Rate limiting configured (default: 60 requests/minute)

## Troubleshooting

### "Function not found" error
- Ensure Edge Function is deployed: `supabase functions deploy ai-router`
- Check function URL: `https://PROJECT_REF.supabase.co/functions/v1/ai-router`

### "Permission denied" error
- Verify RLS policies are correctly set up
- Check that user is authenticated before making requests

### "Credits not deducting" error
- Ensure RPC functions exist: Check `functions` schema in SQL Editor
- Verify `service_role` key is used in Edge Function

## Monthly Credit Reset (Premium Users)

Set up a scheduled function to reset credits monthly:

```sql
-- In SQL Editor, create a pg_cron job
SELECT cron.schedule(
  'reset-premium-credits',
  '0 0 1 * *', -- First day of each month at midnight
  $$
    UPDATE users 
    SET credits_remaining = 50 
    WHERE plan = 'premium'
  $$
);
```

Note: Requires pg_cron extension enabled in your Supabase project.

## Resources

- [Supabase Docs](https://supabase.com/docs)
- [Edge Functions Docs](https://supabase.com/docs/guides/functions)
- [Row Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)
- [Supabase Discord](https://discord.supabase.com)

---

**Next Step:** Run `flutter pub get` and start building Task 3 (Home Screen)
