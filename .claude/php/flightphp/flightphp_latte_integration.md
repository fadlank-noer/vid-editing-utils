# FlightPHP + Latte — Integration Pattern

## Entry Point Setup (index.php)

```php
<?php

ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

require_once __DIR__ . '/../vendor/autoload.php';

// Surface Flight errors to browser (remove in production)
Flight::map('error', function (Throwable $e) {
    echo '<pre>' . $e . '</pre>';
    exit;
});
Flight::map('notFound', function () {
    echo '<pre>404 Not Found</pre>';
    exit;
});

// Register Latte as the template engine
Flight::map('render', function (string $template, array $data = [], ?string $block = null): void {
    $latte = new Latte\Engine;
    $latte->setTempDirectory(__DIR__ . '/../cache/');
    $viewsPath = __DIR__ . '/app/views';
    $finalPath = $viewsPath . '/' . $template;
    $latte->render($finalPath, $data, $block);
});

// Load routes
require_once __DIR__ . '/app/routes/web.php';

Flight::start();
```

## Key Points

- Views path is set as a **local variable** inside the render closure, not via `Flight::set('flight.views.path', ...)`. This avoids ordering issues where the setting might not be available when render is called.
- The `cache/` directory must exist and be writable. Latte auto-creates subdirectories inside it.
- `Flight::map('error', ...)` catches all exceptions and dumps them. Essential for debugging — remove or replace with logging in production.
- Routes are in a separate file (`app/routes/web.php`) and loaded via `require_once`.

## Route File (app/routes/web.php)

```php
Flight::route('/', function () {
    Flight::render('pages/home.latte', ['title' => 'Home']);
});
```

## Debugging 500 Errors

If you get a 500 with no output:
1. Add `Flight::map('error', ...)` to dump exceptions
2. Check `docker logs <container>` — the PHP built-in server logs to stderr
3. Verify the cache directory exists and is writable inside the container
4. Verify template paths — Latte resolves `{extends}` and `{import}` relative to the current file (see `latte_path_resolution.md`)
