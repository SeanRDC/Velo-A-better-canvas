#!/bin/bash

# 1. Securely inject your Groq key and leave Canvas URL blank for Method 2
echo "GROQ_API_KEY=$GROQ_API_KEY" > .env
echo "CANVAS_BASE_URL=" >> .env

# 2. Download the Flutter SDK
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# 3. Build the optimized web application
flutter clean
flutter pub get
flutter build web --release