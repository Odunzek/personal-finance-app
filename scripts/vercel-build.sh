#!/bin/sh
set -e

printf 'SUPABASE_URL=%s\nSUPABASE_ANON_KEY=%s\n' "$SUPABASE_URL" "$SUPABASE_ANON_KEY" > .env

git clone https://github.com/flutter/flutter.git -b stable --depth 1 _flutter
export PATH="$PATH:$PWD/_flutter/bin"

flutter config --enable-web --no-analytics
flutter pub get
flutter build web --release
