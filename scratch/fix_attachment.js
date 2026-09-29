const fs = require('fs');
const path = require('path');

function walk(dir) {
  let results = [];
  const list = fs.readdirSync(dir);
  list.forEach(file => {
    const filePath = path.join(dir, file);
    const stat = fs.statSync(filePath);
    if (stat && stat.isDirectory()) {
      results = results.concat(walk(filePath));
    } else if (filePath.endsWith('.dart') && (filePath.includes('add_edit'))) {
      results.push(filePath);
    }
  });
  return results;
}

const files = walk('lib');

files.forEach(file => {
  let c = fs.readFileSync(file, 'utf8');
  let original = c;

  if (c.includes(`_attachedImage == null ? 'attached.jpg' : null`)) {
    if (!c.includes('package:image_picker/image_picker.dart')) {
      c = "import 'package:image_picker/image_picker.dart';\n" + c;
    }

    const regex = /setState\(\(\)\s*\{\s*_attachedImage\s*=\s*_attachedImage\s*==\s*null\s*\?\s*'attached\.jpg'\s*:\s*null;\s*\}\);/g;
    
    c = c.replace(regex, `final picker = ImagePicker();
                      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                      if (pickedFile != null) {
                        setState(() {
                          _attachedImage = pickedFile.path;
                        });
                      }`);
    
    // Note: The enclosing onTap is synchronous right now!
    // So we need to make it async.
    c = c.replace(/onTap:\s*\(\)\s*\{[\s\S]*?final picker = ImagePicker\(\)/g, `onTap: () async {
                      final picker = ImagePicker()`);
  }

  if (c !== original) {
    fs.writeFileSync(file, c, 'utf8');
    console.log('Modified ' + file);
  }
});
