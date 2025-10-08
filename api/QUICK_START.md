# 🚀 Quick Start - View API Documentation

## ⚠️ File System Error Fix

If you're seeing the error:
```
Can't read from file file:///Users/.../openapi.yaml
```

This happens because browsers can't load local files directly for security reasons. Here are **3 easy solutions**:

---

## ✅ Solution 1: Use Python Server (Recommended - Easiest)

### **One Command:**
```bash
cd api
python3 serve.py
```

**That's it!** The script will:
- ✅ Start a local server
- ✅ Open your browser automatically
- ✅ Show full Swagger UI documentation

**Alternative Python commands:**
```bash
# Python 3
cd api
python3 -m http.server 8000

# Python 2
cd api
python -m SimpleHTTPServer 8000

# Then open: http://localhost:8000
```

---

## ✅ Solution 2: View Standalone Version

**No server needed!** Just open this file in your browser:
```bash
open api/standalone.html
```

This shows a simplified version of the API documentation that works without a server.

**Features:**
- ✅ All endpoints listed
- ✅ Request/response examples
- ✅ Download links for OpenAPI spec and Postman collection
- ✅ Works offline

---

## ✅ Solution 3: Deploy Online (100% FREE)

### **GitHub Pages (Recommended)**

1. **Push to GitHub:**
   ```bash
   git add api/
   git commit -m "Add API documentation"
   git push origin main
   ```

2. **Enable GitHub Pages:**
   - Go to your repository on GitHub
   - Click **Settings** → **Pages**
   - Source: `main` branch → `/api` folder
   - Click **Save**

3. **Your docs will be live at:**
   ```
   https://YOUR_USERNAME.github.io/YOUR_REPO_NAME/
   ```

### **Netlify (Drag & Drop)**

1. Go to https://netlify.com
2. Sign up (free)
3. Drag and drop the `api` folder
4. Done! Live at: `https://YOUR_SITE.netlify.app`

### **Vercel**

```bash
npm install -g vercel
cd api
vercel --prod
```

---

## 📖 What Each File Does

| File | Purpose | How to Use |
|------|---------|------------|
| `index.html` | Full Swagger UI (needs server) | Run `python3 serve.py` |
| `standalone.html` | Simplified docs (no server) | Just open in browser |
| `openapi.yaml` | OpenAPI specification | Import to Swagger Editor |
| `postman_collection.json` | Postman collection | Import to Postman |
| `serve.py` | Python server script | Run `python3 serve.py` |

---

## 🎯 Recommended Workflow

### **For Local Development:**
```bash
# Start server
cd api
python3 serve.py

# Opens browser automatically at http://localhost:8000
```

### **For Quick Preview:**
```bash
# No server needed
open api/standalone.html
```

### **For Production/Sharing:**
```bash
# Deploy to GitHub Pages, Netlify, or Vercel
# See deployment instructions above
```

---

## 🧪 Test the API

### **Using Postman:**

1. **Import collection:**
   - Open Postman
   - Click **Import**
   - Select `api/postman_collection.json`

2. **Set base URL:**
   - Click on the collection
   - Variables tab
   - Set `base_url` to your API endpoint

3. **Test login:**
   - Open "Authentication" → "Login"
   - Click **Send**
   - Token auto-saves for other requests

### **Using cURL:**

```bash
# Login
curl -X POST http://localhost:3000/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@hr.com",
    "password": "admin123",
    "role": "admin"
  }'

# Get employees (replace TOKEN)
curl -X GET http://localhost:3000/v1/employees \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

## 🔧 Troubleshooting

### **Problem: Can't read openapi.yaml**
**Solution:** Use one of the 3 solutions above (Python server, standalone.html, or deploy online)

### **Problem: Python not found**
**Solution:** 
- Install Python: https://www.python.org/downloads/
- Or use Node.js: `npx http-server api -p 8000`
- Or just open `standalone.html`

### **Problem: Port 8000 already in use**
**Solution:** Use a different port:
```bash
python3 -m http.server 8001
```

### **Problem: Browser doesn't open automatically**
**Solution:** Manually open: http://localhost:8000

---

## 📚 Next Steps

1. **View Documentation:**
   - Run `python3 serve.py` in the `api` folder
   - Or open `standalone.html`

2. **Test with Postman:**
   - Import `postman_collection.json`
   - Test all endpoints

3. **Implement Backend:**
   - Follow `IMPLEMENTATION_GUIDE.md`
   - Set up PostgreSQL database
   - Create API endpoints

4. **Deploy Online:**
   - Push to GitHub Pages
   - Or deploy to Netlify/Vercel
   - Share with your team

---

## 💡 Pro Tips

### **Fastest Way to View Docs:**
```bash
cd api && python3 serve.py
```

### **No Python? Use Node.js:**
```bash
npx http-server api -p 8000
```

### **No Server at All?**
```bash
open api/standalone.html
```

### **Share with Team:**
Deploy to GitHub Pages (free, permanent URL)

---

## 📞 Summary

**To fix the error and view documentation:**

1. **Easiest:** `cd api && python3 serve.py`
2. **No server:** `open api/standalone.html`
3. **Production:** Deploy to GitHub Pages/Netlify/Vercel

**All methods are FREE and take less than 1 minute!** 🎉

---

## 🎊 You're All Set!

Choose any method above and you'll have your API documentation running in seconds.

**Happy coding!** 🚀

