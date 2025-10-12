# ⚡ Quick Start - Backblaze Backend Testing

## 🚀 3-Step Setup (10 minutes total)

### 1️⃣ Install & Test Locally (5 min)

```bash
cd /media/saif/brain/Projects/02-Pivot/functions

# Install dependencies
pip3 install -r requirements.txt

# Set credentials for local testing
export BACKBLAZE_KEY_ID="a81351b57fa1"
export BACKBLAZE_APPLICATION_KEY="003603dea751e56adcf1564c322a5a2f8ef093fcfe"

# Run tests
python3 test_backblaze.py
```

✅ **Expected result:** "🎉 All tests passed! Backend is ready."
✅ **STATUS:** ✅ **TESTS PASSED!** See `TESTS_PASSED.md` for full results.

---

### 2️⃣ Deploy to Firebase (3 min)

```bash
# Configure secrets (one-time setup)
firebase functions:secrets:set B2_KEY_ID
# When prompted, paste: a81351b57fa1

firebase functions:secrets:set B2_APPLICATION_KEY
# When prompted, paste: 003603dea751e56adcf1564c322a5a2f8ef093fcfe

# Deploy
cd /media/saif/brain/Projects/02-Pivot
firebase deploy --only functions
```

✅ **Expected result:** 4 new functions deployed

---

### 3️⃣ Test Deployed Endpoints (2 min)

```bash
# View deployed functions
firebase functions:list

# Watch logs
firebase functions:log --only generate_upload_url
```

Or import `Backblaze_API_Tests.postman_collection.json` into Postman.

---

## 📁 Files Created

```
functions/
├── config.py                                   # Configuration
├── backblaze_service.py                       # B2 operations
├── main.py                                    # API endpoints (extended)
├── test_backblaze.py                          # Test script
├── requirements.txt                           # Dependencies (updated)
├── BACKBLAZE_SETUP.md                        # Full documentation
├── BACKEND_COMPLETE_SUMMARY.md               # Implementation summary
├── QUICK_START.md                            # This file
└── Backblaze_API_Tests.postman_collection.json # Postman tests
```

---

## 🔍 Troubleshooting

**❌ "B2_KEY_ID not found"**

```bash
export BACKBLAZE_KEY_ID="a81351b57fa1"
export BACKBLAZE_APPLICATION_KEY="003603dea751e56adcf1564c322a5a2f8ef093fcfe"
```

**❌ "Module not found: b2sdk"**

```bash
pip3 install -r requirements.txt
```

**❌ "Bucket not found"**

- Check bucket name in Backblaze console: `pivot-materials`
- Verify credentials are correct

---

## 📊 What's Next?

After successful deployment:

1. ✅ **Backend is ready** (no more work needed here)
2. 🔄 **Next: Flutter integration** (create upload UI)
3. 🎯 **Phase 2 will be separate** (won't touch existing links feature)

---

## 💡 Quick Reference

**Bucket:** `pivot-materials`  
**Max file size:** 20 MB  
**Allowed types:** PDF, DOCX, PPTX, JPG, PNG  
**URL expiry:** 24 hours

**Endpoints:**

- `generate_upload_url` - Get upload URL
- `confirm_material_upload` - Save metadata
- `refresh_download_url` - Regenerate URL
- `delete_material_file` - Delete file

---

## 📞 Need Help?

Check these files:

- **Full setup:** `BACKBLAZE_SETUP.md`
- **Architecture:** `BACKEND_COMPLETE_SUMMARY.md`
- **Postman tests:** Import the JSON collection

---

**That's it! Backend is ready to go.** 🚀
