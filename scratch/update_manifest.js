const fs = require('fs');
let c = fs.readFileSync('android/app/src/main/AndroidManifest.xml', 'utf8');
if (!c.includes('READ_MEDIA_VISUAL_USER_SELECTED')) {
  c = c.replace(
    '<uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />',
    '<uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />\n    <uses-permission android:name="android.permission.READ_MEDIA_VISUAL_USER_SELECTED" />'
  );
  fs.writeFileSync('android/app/src/main/AndroidManifest.xml', c);
  console.log('Added permission');
}
