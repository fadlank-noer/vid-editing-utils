# Latte — Template Engine for PHP

## Overview

Latte is the recommended template engine for FlightPHP. It provides a secure, fast, and comfortable templating system with features like auto-escaping, macros, layout inheritance, and translation support.

## Installation

```bash
composer require latte/latte
```

## Basic Configuration with FlightPHP

Overwrite the `render` method to use Latte instead of the default PHP renderer:

```php
Flight::map('render', function(string $template, array $data, ?string $block): void {
    $latte = new Latte\Engine;

    // Where Latte stores its cache
    $latte->setTempDirectory(__DIR__ . '/../cache/');

    $finalPath = Flight::get('flight.views.path') . $template;

    $latte->render($finalPath, $data, $block);
});
```

## Usage in FlightPHP

Route example:

```php
Flight::route('/@name', function ($name) {
    Flight::render('home.latte', [
        'title' => 'Home Page',
        'name' => $name
    ]);
});
```

Template (`app/views/home.latte`):

```latte
<html>
  <head>
    <title>{$title ? $title . ' - '}My App</title>
    <link rel="stylesheet" href="style.css">
  </head>
  <body>
    <h1>Hello, {$name}!</h1>
  </body>
</html>
```

Output when visiting `/Bob`:

```html
<html>
  <head>
    <title>Home Page - My App</title>
    <link rel="stylesheet" href="style.css">
  </head>
  <body>
    <h1>Hello, Bob!</h1>
  </body>
</html>
```

## Key Latte Syntax

- **Variable output:** `{$variable}` — auto-escaped by default
- **Ternary:** `{$title ? $title . ' - '}` — inline conditional
- **Blocks/layout inheritance:** Latte supports `{block}`, `{extends}`, `{layout}` for template inheritance
- **Macros:** Latte uses `{n:...}` attributes and `{...}` tags for control structures

## Further Reading

- Official Latte documentation: https://latte.nette.org/en/
- Complex layout examples with Latte are in the FlightPHP awesome plugins section
- Latte supports translation and internationalization natively
