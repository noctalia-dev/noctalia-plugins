// ============================================================
// Robust Hyprland Keybind Parser for QML
// ============================================================
// 
// Features:
// - Auto-discovers all .conf files under ~/.config/hypr/
// - Handles $mod, $mainMod, or any custom modifier variable
// - Parses bindd (native description) AND bind with #comments
// - Recognizes multiple category header styles
// - Merges binds from multiple files
//
// Usage in QML:
//   1. Run file discovery command
//   2. Cat all found files together  
//   3. Pass content to parseKeybindConfig()
//
// ============================================================

.pragma library

// File discovery command (run via Process)
const DISCOVERY_CMD = "find ~/.config/hypr -type f -name '*.conf' -exec grep -l -E '^[[:space:]]*bindd?[[:space:]]*=' {} \\; 2>/dev/null | xargs cat 2>/dev/null";

// Alternative: simpler approach, just cat common patterns
const SIMPLE_CMD = "cat ~/.config/hypr/*.conf ~/.config/hypr/**/*.conf 2>/dev/null";


// ============================================================
// QML-Compatible Functions (no ES6+ features)
// ============================================================

function resolveModifiers(fullText) {
    var modDefs = {};
    var lines = fullText.split('\n');
    
    for (var i = 0; i < lines.length; i++) {
        var line = lines[i].trim();
        // Match: $mod = SUPER or $mainMod = SUPER SHIFT
        var match = line.match(/^\$(\w+)\s*=\s*([\w\s]+?)(?:\s*#.*)?$/);
        if (match) {
            var varName = match[1].toLowerCase();
            var value = match[2].trim();
            modDefs[varName] = value;
        }
    }
    
    // Cross-reference common aliases
    if (modDefs['mainmod'] && !modDefs['mod']) {
        modDefs['mod'] = modDefs['mainmod'];
    }
    if (modDefs['mod'] && !modDefs['mainmod']) {
        modDefs['mainmod'] = modDefs['mod'];
    }
    
    return modDefs;
}


function expandModifiers(modString, modDefs) {
    var result = modString;
    // Replace $varName patterns
    var match;
    var regex = /\$(\w+)/g;
    
    while ((match = regex.exec(modString)) !== null) {
        var varName = match[1].toLowerCase();
        if (modDefs[varName]) {
            result = result.replace(match[0], modDefs[varName]);
        }
    }
    
    return result;
}


function formatKeyCombo(mods, key) {
    var parts = [];
    var modUpper = mods.toUpperCase();
    
    // Consistent order: Super, Ctrl, Alt, Shift
    if (modUpper.indexOf('SUPER') !== -1) parts.push('Super');
    if (modUpper.indexOf('CTRL') !== -1) parts.push('Ctrl');
    if (modUpper.indexOf('ALT') !== -1) parts.push('Alt');
    if (modUpper.indexOf('SHIFT') !== -1) parts.push('Shift');
    
    var keyClean = key.toUpperCase().trim();
    if (keyClean) parts.push(keyClean);
    
    return parts.join(' + ');
}


function parseBindLine(line, modDefs) {
    var trimmed = line.trim();
    
    // Skip comments and empty lines
    if (!trimmed || trimmed.charAt(0) === '#') return null;
    
    // Match bind variants: bind, bindd, binde, bindl, bindel, bindm
    var bindMatch = trimmed.match(/^(bind[delm]*)\s*=\s*(.+)$/i);
    if (!bindMatch) return null;
    
    var bindType = bindMatch[1].toLowerCase();
    var rest = bindMatch[2];
    
    // Split by comma
    var parts = rest.split(',');
    for (var i = 0; i < parts.length; i++) {
        parts[i] = parts[i].trim();
    }
    
    if (parts.length < 3) return null;
    
    var mods = expandModifiers(parts[0], modDefs);
    var key = parts[1];
    var description = null;
    var dispatcher = null;
    
    // FORMAT 1: bindd = mods, key, DESCRIPTION, dispatcher, args
    if (bindType === 'bindd') {
        description = parts[2];
        dispatcher = parts[3] || '';
    } 
    // FORMAT 2: bind = mods, key, dispatcher, args #"description"
    else {
        dispatcher = parts[2];
        
        // Check for #"quoted description"
        var quotedMatch = rest.match(/#"([^"]+)"\s*$/);
        if (quotedMatch) {
            description = quotedMatch[1];
        } else {
            // Check for # unquoted description
            var unquotedMatch = rest.match(/#\s*([^#]+?)\s*$/);
            if (unquotedMatch) {
                var possibleDesc = unquotedMatch[1];
                // Avoid matching URLs or paths
                if (possibleDesc.indexOf('://') === -1 && 
                    possibleDesc.indexOf('/') === -1 &&
                    possibleDesc.charAt(0) !== '"') {
                    description = possibleDesc;
                }
            }
        }
    }
    
    // Skip binds without descriptions (cheatsheet needs descriptions)
    if (!description) return null;
    
    return {
        keys: formatKeyCombo(mods, key),
        desc: description
    };
}


function parseCategoryHeader(line) {
    var trimmed = line.trim();
    
    // Skip pure decoration: ########## or # ========
    if (trimmed.match(/^#{3,}$/) || trimmed.match(/^#\s*[=\-]{3,}\s*$/)) {
        return null;
    }
    
    // # 1. Category Name (numbered)
    var numbered = trimmed.match(/^#\s*\d+\.\s*(.+)$/);
    if (numbered) return numbered[1].trim();
    
    // ### CATEGORY ### (banner with text between hashes)
    var banner = trimmed.match(/^#{2,}\s+([^#]+?)\s+#{2,}$/);
    if (banner && banner[1].trim().length > 0) {
        return banner[1].trim();
    }
    
    // # === Category === or # --- Category ---
    var separator = trimmed.match(/^#\s*[=\-]{2,}\s+(.+?)\s+[=\-]{2,}\s*$/);
    if (separator) return separator[1].trim();
    
    // # [Category] or # {Category}
    var bracket = trimmed.match(/^#\s*[\[{]\s*(.+?)\s*[\]}]\s*$/);
    if (bracket) return bracket[1].trim();
    
    return null;
}


function parseKeybindConfig(fullText) {
    var modDefs = resolveModifiers(fullText);
    var lines = fullText.split('\n');
    var categories = [];
    var currentCategory = { title: 'General', binds: [] };
    
    for (var i = 0; i < lines.length; i++) {
        var line = lines[i];
        
        // Check for category header
        var categoryTitle = parseCategoryHeader(line);
        if (categoryTitle) {
            if (currentCategory.binds.length > 0) {
                categories.push(currentCategory);
            }
            currentCategory = { title: categoryTitle, binds: [] };
            continue;
        }
        
        // Try to parse as bind
        var bind = parseBindLine(line, modDefs);
        if (bind) {
            currentCategory.binds.push(bind);
        }
    }
    
    // Don't forget last category
    if (currentCategory.binds.length > 0) {
        categories.push(currentCategory);
    }
    
    return categories;
}


// Optional: merge categories with same name from multiple files
function mergeCategories(categories) {
    var merged = {};
    
    for (var i = 0; i < categories.length; i++) {
        var cat = categories[i];
        var title = cat.title;
        
        if (merged[title]) {
            // Append binds
            for (var j = 0; j < cat.binds.length; j++) {
                merged[title].binds.push(cat.binds[j]);
            }
        } else {
            merged[title] = {
                title: title,
                binds: cat.binds.slice() // copy array
            };
        }
    }
    
    // Convert to array
    var result = [];
    for (var key in merged) {
        if (merged[key].binds.length > 0) {
            result.push(merged[key]);
        }
    }
    
    return result;
}


// ============================================================
// Test
// ============================================================

var testWithMainMod = [
    '$mainMod = SUPER',
    '',
    '### Applications ###',
    'bindd = $mainMod, T, Launch terminal, exec, kitty',
    'bindd = $mainMod SHIFT, Q, Kill window, killactive,',
    '',
    '# 1. Window Focus',
    'bind = $mainMod, H, movefocus, l #"Focus left"',
    'bind = $mainMod, L, movefocus, r # Focus right',
].join('\n');

console.log("=== Test with $mainMod ===");
var result = parseKeybindConfig(testWithMainMod);
console.log(JSON.stringify(result, null, 2));


// Export for Node testing
if (typeof module !== 'undefined') {
    module.exports = {
        parseKeybindConfig: parseKeybindConfig,
        mergeCategories: mergeCategories,
        DISCOVERY_CMD: DISCOVERY_CMD,
        SIMPLE_CMD: SIMPLE_CMD
    };
}
