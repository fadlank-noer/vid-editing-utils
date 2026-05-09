# FlightPHP — HTML Views and Templates

## Overview

Flight provides basic HTML templating functionality by default. Templating disconnects application logic from presentation. PHP by itself is a templating language, but wrapping business logic (DB calls, API calls, etc.) into HTML makes testing and decoupling difficult. Pushing data into a template and letting the template render itself makes it easier to decouple and unit test.

Flight allows swapping out the default view engine by registering your own view class.

## Built-in View Engine (Deprecated)

Display a view template by calling `render` with the template file name and optional data:

```php
Flight::render('hello.php', ['name' => 'Bob']);
```

Template data is automatically injected and referenced like local variables:

```php
Hello, <?= $name ?>!
```

Manually set view variables:

```php
Flight::view()->set('name', 'Bob');
```

Then render without passing data:

```php
Flight::render('hello');
```

When specifying the template name in `render`, you can leave out the `.php` extension.

Set an alternate path for templates:

```php
Flight::set('flight.views.path', '/path/to/views');
```

### Layouts

Render content to be used in a layout by passing an optional third parameter to `render`:

```php
Flight::render('header', ['heading' => 'Hello'], 'headerContent');
Flight::render('body', ['body' => 'World'], 'bodyContent');
Flight::render('layout', ['title' => 'Home Page']);
```

Example template files:

**header.php:**
```php
<h1><?= $heading ?></h1>
```

**body.php:**
```php
<div><?= $body ?></div>
```

**layout.php:**
```php
<html>
  <head>
    <title><?= $title ?></title>
  </head>
  <body>
    <?= $headerContent ?>
    <?= $bodyContent ?>
  </body>
</html>
```

## Smarty Integration

```php
require './Smarty/libs/Smarty.class.php';

Flight::register('view', Smarty::class, [], function (Smarty $smarty) {
  $smarty->setTemplateDir('./templates/');
  $smarty->setCompileDir('./templates_c/');
  $smarty->setConfigDir('./config/');
  $smarty->setCacheDir('./cache/');
});

Flight::view()->assign('name', 'Bob');
Flight::view()->display('hello.tpl');

// Override default render method
Flight::map('render', function(string $template, array $data): void {
  Flight::view()->assign($data);
  Flight::view()->display($template);
});
```

## Blade Integration

Install:

```bash
composer require eftec/bladeone
```

Configure:

```php
use eftec\bladeone\BladeOne;

Flight::register('view', BladeOne::class, [], function (BladeOne $blade) {
  $views = __DIR__ . '/../views';
  $cache = __DIR__ . '/../cache';
  $blade->setPath($views);
  $blade->setCompiledPath($cache);
});

Flight::view()->share('name', 'Bob');
echo Flight::view()->run('hello', []);

// Override default render method
Flight::map('render', function(string $template, array $data): void {
  echo Flight::view()->run($template, $data);
});
```

Template (`hello.blade.php`):

```blade
Hello, {{ $name }}!
```

## Troubleshooting

If a redirect in middleware doesn't seem to work, add `exit;` in the middleware.
