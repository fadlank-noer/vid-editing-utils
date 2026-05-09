# Latte — UI Component Pattern

## Folder Structure

```
views/
  ui/                   ← reusable mini components (buttons, cards, badges)
    button.latte
    card.latte
  pages/                ← page templates that extend layout
    home.latte
  layout.latte          ← master layout
```

## Two Ways to Create Components

### Approach A: `{define}` blocks (for small components in one file)

Define in `ui/button.latte`:
```latte
{define button-primary, string $text, string $url}
    <a href="{$url}" class="btn btn-primary">{$text}</a>
{/define}

{define button-secondary, string $text, string $url}
    <a href="{$url}" class="btn btn-secondary">{$text}</a>
{/define}
```

Use in a page:
```latte
{import '../ui/button.latte'}
{include button-primary, text: 'Click Me', url: '/go'}
```

### Approach B: Standalone template file (for larger components)

Create `ui/card.latte`:
```latte
<div class="card">
    <h2>{$title}</h2>
    <p>{$body}</p>
</div>
```

Use in a page:
```latte
{include '../ui/card.latte', title: 'Hello', body: 'World'}
```

## Difference

- `{define}` + `{import}` + `{include}`: many components in one file, imported once, called by block name
- `{include 'file.latte'}`: one component per file, no import needed, passes variables directly
