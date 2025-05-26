# 🚀 Setup Instructions

## 1. **Get Your Gemma API Key**

1. Visit [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Sign in with your Google account
3. Click "Create API Key"
4. Copy the generated API key

## 2. **Configure API Key**

**Option A: Direct Configuration (Quick Setup)**
1. Open `lib/config/api_config.dart`
2. Replace `'YOUR_GEMMA_API_KEY_HERE'` with your actual API key:
   ```dart
   static const String gemmaApiKey = 'AIzaSy...your-key-here';
   ```

**Option B: Environment Variables (Recommended for Development)**
1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```
2. Edit `.env` and add your API key:
   ```
   GEMMA_API_KEY=AIzaSy...your-key-here
   ```

## 3. **Install Dependencies**

```bash
flutter pub get
```

## 4. **Run the App**

**For Web:**
```bash
flutter run -d chrome
```

**For Mobile (Android/iOS):**
```bash
flutter run
```

**For Desktop:**
```bash
flutter run -d macos  # or windows/linux
```

## 🔧 **Model Configuration**

You can change the Gemma model in `lib/config/api_config.dart`:

- `gemma-3-1b-it` - Fastest, text-only
- `gemma-3-4b-it` - **Default** - Balanced performance  
- `gemma-3-12b-it` - Higher quality
- `gemma-3-27b-it` - Best quality (requires more resources)

## 📱 **Platform Support**

- ✅ **Web** - Mobile responsive
- ✅ **Android** - Native mobile app
- ✅ **iOS** - Native mobile app  
- ✅ **macOS** - Desktop app
- ✅ **Windows** - Desktop app
- ✅ **Linux** - Desktop app

## 🔒 **Security Notes**

- **Never commit API keys** to version control
- Use environment variables for production
- The `.env` file is ignored by git for security
- Replace placeholder keys before deployment

## ⚡ **Quick Test**

1. Enter sample text in the app
2. Click "Summarize"
3. Check that the Gemma API responds with a summary

## 🆘 **Troubleshooting**

**API Key Issues:**
- Ensure key is valid and active
- Check API quotas in Google AI Studio
- Verify internet connection

**Build Issues:**
```bash
flutter clean
flutter pub get
flutter run
```

**Network Issues:**
- Check firewall settings
- Verify API endpoint accessibility
- Test with a simple HTTP request
