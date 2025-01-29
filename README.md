# owl_tech_pdf_scaner

// Для генерации рутов, локализации
flutter pub run build_runner build

// Для генерации иконки
flutter pub run flutter_launcher_icons

// для генерации парсера
flutter pub run easy_localization:generate -S "assets/translations" -O "lib/generated"

// для генерации ключей
flutter pub run easy_localization:generate -f keys -o locale_keys.g.dart -S "assets/translations" -O "lib/generated"

Windows
keytool -genkey -v -keystore c:\Users\zfann\Downloads\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload

macOs
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

flutter build apk --release

flutter build aab --release
