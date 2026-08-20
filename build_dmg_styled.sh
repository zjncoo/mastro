#!/bin/bash
set -e

PROJECT_DIR="/Users/francescozanchetta/Desktop/mastro"
STAGE_DIR="$PROJECT_DIR/dmg_stage"
OUTPUT_DMG="/Users/francescozanchetta/Desktop/mastro_installer.dmg"
TEMP_DMG="$PROJECT_DIR/temp.dmg"

rm -rf "$STAGE_DIR" "$TEMP_DMG" "$OUTPUT_DMG"
mkdir -p "$STAGE_DIR/.background"

# 1. Copia l'applicazione compilata e rinominala mastro.app
if [ -d "$PROJECT_DIR/build/Build/Products/Release/mastro.app" ]; then
    cp -R "$PROJECT_DIR/build/Build/Products/Release/mastro.app" "$STAGE_DIR/mastro.app"
else
    cp -R "$PROJECT_DIR/build/Build/Products/Release/GestoreCantieri.app" "$STAGE_DIR/mastro.app"
fi

ln -s /Applications "$STAGE_DIR/Applications"
cp "$PROJECT_DIR/dmg_background.png" "$STAGE_DIR/.background/background.png"

# Copia esplicita delle risorse (font Manrope ed icone) nel bundle mastro.app
mkdir -p "$STAGE_DIR/mastro.app/Contents/Resources"
if [ -d "$PROJECT_DIR/mastro/Resources" ]; then
    cp -R "$PROJECT_DIR/mastro/Resources/"* "$STAGE_DIR/mastro.app/Contents/Resources/" 2>/dev/null || true
fi
if [ -f "$PROJECT_DIR/mastro/Assets.xcassets/AppIcon.appiconset/AppIcon.icns" ]; then
    cp "$PROJECT_DIR/mastro/Assets.xcassets/AppIcon.appiconset/AppIcon.icns" "$STAGE_DIR/mastro.app/Contents/Resources/AppIcon.icns"
fi

# Aggiorna il nome visualizzato ed il file icona in Info.plist (tutto in minuscolo: mastro)
plutil -replace CFBundleName -string "mastro" "$STAGE_DIR/mastro.app/Contents/Info.plist" 2>/dev/null || plutil -insert CFBundleName -string "mastro" "$STAGE_DIR/mastro.app/Contents/Info.plist"
plutil -replace CFBundleDisplayName -string "mastro" "$STAGE_DIR/mastro.app/Contents/Info.plist" 2>/dev/null || plutil -insert CFBundleDisplayName -string "mastro" "$STAGE_DIR/mastro.app/Contents/Info.plist"
plutil -replace CFBundleIconFile -string "AppIcon" "$STAGE_DIR/mastro.app/Contents/Info.plist" 2>/dev/null || plutil -insert CFBundleIconFile -string "AppIcon" "$STAGE_DIR/mastro.app/Contents/Info.plist"

# Rimuovi file o dati di test residui eventualmente presenti nel bundle
rm -rf "$STAGE_DIR/mastro.app/Contents/Resources/gestionale_db.json"
rm -rf "$STAGE_DIR/mastro.app/Contents/Resources/settings.json"
rm -rf "$STAGE_DIR/mastro.app/Contents/Resources/Asset_Azienda"

# Ricompila la firma di codice per evitare crash di sicurezza OSStatus -67030
echo "Rifirma del bundle dell'app mastro..."
codesign --force --deep --sign - "$STAGE_DIR/mastro.app"
codesign --verify --verbose "$STAGE_DIR/mastro.app"

# 2. Crea il disco temporaneo UDRW per applicare lo stile Finder
hdiutil create -srcfolder "$STAGE_DIR" -volname "mastro" -fs HFS+ -format UDRW "$TEMP_DMG"

# 3. Monta il disco temporaneo
DEVICE=$(hdiutil attach -readwrite -noverify "$TEMP_DMG" | egrep '^/dev/' | sed 1q | awk '{print $1}')
sleep 2

# 4. Applica il layout grafico Finder con AppleScript (Freccia, sfondo e posizioni)
echo "Configurazione del layout visivo del DMG mastro..."
osascript <<EOF
tell application "Finder"
    tell disk "mastro"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 150, 940, 530}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 110
        set background picture of viewOptions to file ".background:background.png"
        set position of item "mastro.app" of container window to {135, 195}
        set position of item "Applications" of container window to {405, 195}
        update without registering applications
        delay 2
        close
    end tell
end tell
EOF

sync
hdiutil detach "$DEVICE"
sleep 1

# 5. Converte nel DMG finale compresso
hdiutil convert "$TEMP_DMG" -format UDZO -imagekey zlib-level=9 -o "$OUTPUT_DMG"
rm -rf "$TEMP_DMG" "$STAGE_DIR"

# 6. Copia sul Desktop principale e nella cartella docs/ per il sito web
cp "$OUTPUT_DMG" "$PROJECT_DIR/mastro_installer.dmg"
cp "$OUTPUT_DMG" "$PROJECT_DIR/docs/mastro_installer.dmg"
open -R "$OUTPUT_DMG"
echo "DMG mastro generato con successo con mastro.app e font Manrope!"
