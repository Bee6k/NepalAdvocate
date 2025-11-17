# WebView Integration Guide

## Overview

WebView has been integrated into the NepalAdvocate Flutter app to display web content, legal templates, and external resources.

## Features

### 1. AppWebView Widget
A reusable WebView widget for displaying URLs with:
- Loading states and progress indicators
- Error handling with retry functionality
- Navigation controls (back/forward/refresh)
- JavaScript support
- Custom headers support (for authenticated content)

**Location**: `lib/widgets/common/app_webview.dart`

**Usage**:
```dart
AppWebView(
  url: 'https://example.com',
  title: 'Page Title',
  enableJavaScript: true,
  headers: {'Authorization': 'Bearer token'},
)
```

### 2. HtmlWebView Widget
A WebView widget for displaying HTML content directly (not from URL):
- Styled HTML content with dark theme
- JavaScript support (optional)
- Custom CSS for consistent appearance

**Location**: `lib/widgets/common/html_webview.dart`

**Usage**:
```dart
HtmlWebView(
  htmlContent: '<h1>Hello World</h1>',
  title: 'Document Title',
  enableJavaScript: false,
)
```

## Integration Points

### 1. Legal Templates Viewer
- **Screen**: `lib/views/webview/template_viewer_screen.dart`
- **Purpose**: Display legal template content in HTML format
- **Usage**: Accessed from templates list screen

### 2. Terms & Privacy Policy
- **Screen**: `lib/views/webview/terms_privacy_screen.dart`
- **Purpose**: Display Terms of Service and Privacy Policy from web URLs
- **Usage**: Accessed from Settings screen

### 3. Templates List Screen
- **Screen**: `lib/views/templates/templates_list_screen.dart`
- **Features**:
  - Search templates
  - Filter by category
  - View template in WebView
  - Pull to refresh

## Configuration

### Android Setup
The Android configuration is already set up:
- `INTERNET` permission is included in AndroidManifest.xml
- WebView is available on Android API 21+ (minSdkVersion)

### Package
- **Package**: `webview_flutter: ^4.4.2`
- **Location**: `pubspec.yaml`

## Usage Examples

### Displaying a URL
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => AppWebView(
      url: 'https://nepaladvocate.app/terms',
      title: 'Terms of Service',
    ),
  ),
);
```

### Displaying HTML Content
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => HtmlWebView(
      htmlContent: template.content,
      title: template.title,
    ),
  ),
);
```

### With Custom Headers (Authenticated Content)
```dart
AppWebView(
  url: 'https://api.example.com/protected',
  title: 'Protected Content',
  headers: {
    'Authorization': 'Bearer $token',
  },
)
```

## Features

### Navigation Controls
- Back button: Navigate to previous page
- Forward button: Navigate to next page
- Refresh button: Reload current page
- Progress indicator: Shows loading progress

### Error Handling
- Displays error message when page fails to load
- Retry button to reload the page
- User-friendly error UI

### Loading States
- Loading indicator during page load
- Progress bar showing load progress
- Smooth transitions between states

## Customization

### Styling HTML Content
The `HtmlWebView` widget includes custom CSS for dark theme:
- Dark background (#0E0E11)
- Light text (#F2F2F2)
- Accent colors for headings (#22E3E8)
- Responsive design
- Code block styling

### JavaScript Support
- Enabled by default for `AppWebView`
- Can be disabled for security
- Required for interactive web pages

## Security Considerations

1. **URL Validation**: Always validate URLs before loading
2. **HTTPS**: Prefer HTTPS URLs for secure content
3. **JavaScript**: Disable JavaScript for untrusted content
4. **Headers**: Use secure storage for authentication tokens in headers

## Future Enhancements

Potential improvements:
- Cookie management
- Download support
- Print functionality
- Offline caching
- Custom user agent
- URL whitelist/blacklist

## Troubleshooting

### WebView not loading
- Check internet permission in AndroidManifest.xml
- Verify URL is valid and accessible
- Check network connectivity

### JavaScript not working
- Ensure `enableJavaScript: true` is set
- Check if JavaScript is required for the page

### Styling issues
- Verify HTML content structure
- Check CSS compatibility
- Test on different screen sizes

