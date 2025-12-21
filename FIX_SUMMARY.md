# 🐛 Fix for "Plugin does not found the Main function" Error

## Problem
The MA3 PDF Exporter plugin was created on grandMA3 v2.0 but fails to load on grandMA3 v2.3 with the error:
> "Plugin does not found the Main function"

## Root Cause  
**grandMA3 v2.3 requires the `Main` function to explicitly return a value.**

In v2.0, Lua functions could return implicitly (returning `nil` by default), but v2.3 enforces explicit return statements for plugin entry points.

## The Fix (One Line!)

Add `return true` at the end of your Main function:

```lua
function Main(displayHandle, argument)
    -- All your existing code
    -- ...
    
    return true  -- ← ADD THIS LINE
end
```

## Quick Start

### If You Have the Source Code:
1. Open your Lua source file
2. Find the `Main` function  
3. Add `return true` before the final `end`
4. Recompile in grandMA3 v2.3
5. Done! ✅

### If You Don't Have the Source Code:
The plugin will need to be recreated. See `HOW_TO_FIX.md` for guidance.

## Why This Happens

| Version | Main Return | Status |
|---------|-------------|--------|
| grandMA3 v2.0 | Optional | Functions can implicitly return `nil` |
| grandMA3 v2.3 | **Required** | Functions MUST explicitly return a value |

## Files in This Fix

- **`HOW_TO_FIX.md`** - Detailed step-by-step instructions
- **`COMPATIBILITY_FIX.md`** - Technical analysis and bytecode investigation
- **This file** - Quick reference

## Verification

After the fix, your plugin should:
- ✅ Load without errors in grandMA3 v2.3
- ✅ Show up in the plugin list
- ✅ Execute normally when called

## Technical Details

The bytecode analysis confirmed:
- Main function exists with correct name (case-sensitive)
- Parameters are correctly defined: `displayHandle`, `argument`
- The only missing piece is the explicit return statement

## Support

For more details, see:
- [HOW_TO_FIX.md](HOW_TO_FIX.md) - Comprehensive fix guide
- [COMPATIBILITY_FIX.md](COMPATIBILITY_FIX.md) - Technical analysis
- [README.md](README.md) - Plugin documentation
