<?php

Flight::route('/', function () {
    Flight::render('pages/home.latte', ['title' => 'Home']);
});
