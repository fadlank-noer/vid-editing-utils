<?php

require_once __DIR__ . '/../vendor/autoload.php';

Flight::route('/', function () {
    echo 'Hello, World!';
});

Flight::start();
