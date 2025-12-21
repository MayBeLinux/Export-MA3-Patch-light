# How to Fix the grandMA3 v2.3 Main Function Issue

## Quick Fix (If you have the source code)

Add this line at the very end of your `Main` function, just before the `end`:

```lua
function Main(displayHandle, argument)
    -- Your existing plugin code
    -- ...
    -- All your current code stays here
    -- ...
    
    return true  -- ADD THIS LINE
end
```

## Why This Fixes the Issue

grandMA3 v2.3 requires all plugin Main functions to explicitly return a value. Version 2.0 allowed functions to return implicitly (Lua's default `nil` return), but v2.3 enforces explicit returns.

## Step-by-Step Fix

1. **Locate your original Lua source file** (the one you used to create the plugin before it was compiled)

2. **Open the file** in a text editor

3. **Find the Main function** - it should look like:
   ```lua
   function Main(displayHandle, argument)
       -- your code
   end
   ```

4. **Add `return true` before the final `end`**:
   ```lua
   function Main(displayHandle, argument)
       -- your code
       return true  -- <-- ADD THIS
   end
   ```

5. **Save the file**

6. **Recompile the plugin** in grandMA3 v2.3:
   - Open grandMA3 v2.3
   - Go to the plugin editor
   - Load your modified Lua file
   - Save/Export the plugin
   - This will generate new bytecode compatible with v2.3

7. **Replace the files** in this repository with the newly compiled versions

## If You Don't Have the Source Code

The plugin needs to be recreated from scratch. The current files are compiled bytecode which cannot be easily modified. You would need to:

1. Review what the plugin does (based on the PDF export functionality described in the README)
2. Rewrite the Lua code from scratch
3. Ensure the new Main function returns a value
4. Compile it in grandMA3 v2.3

## Testing

After making the fix:
1. Load the plugin in grandMA3 v2.3
2. The error "Plugin does not found the Main function" should be gone
3. The plugin should load and run normally

## Additional Notes

- The function signature `function Main(displayHandle, argument)` is correct and doesn't need to be changed
- You can return `true`, `false`, or any other value - the important part is that you return SOMETHING
- Conventionally, plugins return `true` on success
