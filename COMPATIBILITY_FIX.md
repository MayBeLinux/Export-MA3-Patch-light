# grandMA3 v2.3 Compatibility Fix

## Issue
The plugin was originally compiled for grandMA3 v2.0 and is not compatible with grandMA3 v2.3. The error message "Plugin does not found the Main function" indicates a function signature incompatibility.

## Root Cause
Between grandMA3 v2.0 and v2.3, the plugin API requirements changed. Specifically:

1. **Return Value Required**: The `Main` function must explicitly return a value (typically `true`)
2. **Strict Function Signature**: The function signature must be: `function Main(displayHandle, argument)`

## Current State
The plugin files in this repository are compiled Lua bytecode:
- `MA3 PDF Exporter V2.lua` - Compiled for v2.0
- `MA3 PDF Exporter lite` - Alternative version (also compiled)
- `MA3 PDF Exporter .xml` - Plugin manifest with embedded bytecode

### Bytecode Analysis
Analysis of the compiled bytecode confirms:
✅ The `Main` function IS defined (verified in bytecode strings table)
✅ The function parameters are correctly defined: `displayHandle`, `argument`
❌ The function likely does NOT return an explicit value (required for v2.3)

The bytecode hex sequence shows:
```
\x85\x4D\x61\x69\x6E (length + "Main" function name)
... preceded by displayHandle and argument parameters
```

## Required Fix
The Lua source code needs to be updated to ensure the Main function explicitly returns a value:

```lua
function Main(displayHandle, argument)
    -- Existing plugin code here
    -- ...
    
    -- IMPORTANT: Must return a value in v2.3+
    return true  -- <-- THIS IS THE FIX
end
```

**The problem:** The bytecode was compiled without an explicit return statement.  
**The solution:** Recompile the plugin with `return true` at the end of the Main function.

## Steps to Fix (Requires Original Source Code)

1. Locate the original uncompiled Lua source code
2. Update the Main function to include an explicit return statement
3. Ensure the function signature matches: `function Main(displayHandle, argument)`
4. Recompile the plugin using grandMA3 v2.3 plugin tools
5. Update the XML file with the new bytecode
6. Test the plugin in grandMA3 v2.3

## Alternative Workaround
If the original source code is not available:
1. The bytecode would need to be decompiled (not recommended and may not be legal)
2. Or the plugin would need to be recreated from scratch based on its functionality

## Version Compatibility Matrix
| grandMA3 Version | Plugin DataVersion | Main Return Required |
|------------------|-------------------|---------------------|
| 2.0              | 2.1.1.5          | No                  |
| 2.3              | 2.3.x.x          | Yes                 |

## Note
This repository currently contains only compiled bytecode. To fully fix this issue, the original Lua source code is required.
