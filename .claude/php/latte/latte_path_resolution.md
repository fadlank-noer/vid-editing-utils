# Latte — Path Resolution

## Template Paths Are Relative

Latte resolves all template paths (`{extends}`, `{import}`, `{include}`) relative to the **current template file**, not the views root.

### Example

Given this structure:
```
views/
  layout.latte
  ui/
    button.latte
  pages/
    home.latte
```

Inside `pages/home.latte`:

```latte
{extends '../layout.latte'}         ✅ goes up to views/, then layout.latte
{extends 'layout.latte'}            ❌ looks for pages/layout.latte (does not exist)

{import '../ui/button.latte'}       ✅ goes up to views/, then into ui/
{import 'ui/button.latte'}          ❌ looks for pages/ui/button.latte (does not exist)
```

### Rule of Thumb

- From `views/pages/*.latte` → use `../` prefix to reference `views/` level files
- From `views/*.latte` → no prefix needed (already at views root)
- `{include}` with an inline block reference (no path) does not apply — only file-based includes need relative paths
