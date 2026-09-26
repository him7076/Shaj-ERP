const fs = require('fs');
const path = require('path');

const file = path.join(__dirname, 'lib/core/theme/app_theme.dart');
let content = fs.readFileSync(file, 'utf8');

// Update Neumorphic Light Theme
const lightBorderRegex = /border:\s*OutlineInputBorder\(\s*borderRadius:\s*BorderRadius\.circular\(12\),\s*borderSide:\s*BorderSide\.none,\s*\),/g;
const lightEnabledRegex = /enabledBorder:\s*OutlineInputBorder\(\s*borderRadius:\s*BorderRadius\.circular\(12\),\s*borderSide:\s*BorderSide\.none,\s*\),/g;

// We need to replace the first occurrence (Light) with grey color
let matchCount = 0;
content = content.replace(lightBorderRegex, (match) => {
    matchCount++;
    if (matchCount === 1) {
        return `border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.4), width: 1),
        ),`;
    } else if (matchCount === 2) {
        return `border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
        ),`;
    }
    return match;
});

matchCount = 0;
content = content.replace(lightEnabledRegex, (match) => {
    matchCount++;
    if (matchCount === 1) {
        return `enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.4), width: 1),
        ),`;
    } else if (matchCount === 2) {
        return `enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
        ),`;
    }
    return match;
});

// Remove fillColor so it looks more standard outline, or keep it?
// The user said "sare transaction form me jo bhi fileds hai imputs dalne ke unme sab le tilte small me box ki otline par left side aaye".
// This requires `floatingLabelBehavior` and an OutlineInputBorder. 
// Standard outline text fields often look best without fillColor, but we can keep the subtle neumorphic inner shadow fillColor while still having an outline.

// Also make sure floatingLabelBehavior is always (optional, but good for form fields)
// Let's add floatingLabelBehavior: FloatingLabelBehavior.always to InputDecorationTheme if the user wants it small at the top always. But usually they just mean floating when filled. We don't need to force always.

fs.writeFileSync(file, content, 'utf8');
console.log('Fixed theme borders for inputs');
