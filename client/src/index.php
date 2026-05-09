<?php

ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

require_once __DIR__ . '/../vendor/autoload.php';

// Debug: surface all errors
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
