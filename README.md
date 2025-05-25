# Flutter Gemma Text Summarizer

A Flutter mobile application that uses the Gemma AI model to summarize text content. This app provides a clean, user-friendly interface for text summarization on mobile devices.

## Features

- **Text Input**: Large text area for entering content to summarize
- **AI-Powered Summarization**: Uses Gemma model for intelligent text summarization
- **Real-time Feedback**: Loading indicators and error handling
- **Copy to Clipboard**: Easy copying of generated summaries
- **Character Count**: Real-time character counting for input text
- **Responsive Design**: Optimized for mobile devices

## Screenshots

The app includes:
- Clean Material Design 3 interface
- Card-based layout for better organization
- Loading states and error handling
- Copy functionality for summaries

## Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK
- Android Studio / VS Code
- Android device or emulator for testing

### Installation

1. Clone this repository:
```bash
git clone <repository-url>
cd flutter_gemma_summarizer
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure API (if using real Gemma API):
   - Open `lib/services/gemma_service.dart`
   - Replace `YOUR_API_KEY_HERE` with your actual API key
   - Update the base URL to point to your Gemma API endpoint

4. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── screens/
│   └── home_screen.dart     # Main screen with text input and summary
├── providers/
│   └── summarization_provider.dart  # State management for summarization
├── services/
│   └── gemma_service.dart   # API service for Gemma model integration
└── widgets/
    ├── text_input_card.dart # Text input widget
    └── summary_card.dart    # Summary display widget
```

## API Integration

### Current Implementation

The app currently uses a mock implementation for demonstration purposes. The `GemmaService` class simulates API calls and provides basic text summarization.

### Real API Integration

To integrate with a real Gemma API:

1. **Google AI Studio**: Use Google's AI Studio API
2. **Hugging Face**: Use Hugging Face's inference API
3. **Custom Endpoint**: Deploy Gemma model on your own server
4. **Local Model**: Use TensorFlow Lite for on-device inference

Example API integration:
```dart
final response = await _dio.post(
  '/chat/completions',
  data: {
    'model': 'gemma-7b',
    'messages': [
      {
        'role': 'system',
        'content': 'You are a helpful assistant that summarizes text concisely.'
      },
      {
        'role': 'user',
        'content': 'Please summarize the following text: $text'
      }
    ],
    'max_tokens': 150,
    'temperature': 0.7,
  },
);
```

## Dependencies

- `flutter`: Flutter framework
- `provider`: State management
- `dio`: HTTP client for API calls
- `flutter_markdown`: Markdown rendering (if needed)
- `path_provider`: File system access
- `cupertino_icons`: iOS-style icons

## Testing

Run tests with:
```bash
flutter test
```

## Building for Release

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## Configuration

### Android Permissions

The app requires internet permissions for API calls:
- `android.permission.INTERNET`
- `android.permission.ACCESS_NETWORK_STATE`

### iOS Permissions

Add network permissions to `ios/Runner/Info.plist` if needed.

## Troubleshooting

### Common Issues

1. **API Key Issues**: Ensure your API key is correctly configured
2. **Network Errors**: Check internet connection and API endpoint
3. **Build Errors**: Run `flutter clean` and `flutter pub get`

### Error Handling

The app includes comprehensive error handling for:
- Network timeouts
- API rate limits
- Invalid responses
- Connection issues

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Google Gemma team for the AI model
- Flutter team for the framework
- Material Design for UI guidelines
