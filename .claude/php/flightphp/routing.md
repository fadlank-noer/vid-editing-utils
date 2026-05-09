# FlightPHP — Routing

## Overview

Routing maps URL patterns to callback functions or class methods. Routes are matched in the order they are defined; the first match is invoked.

## Basic Routing

### Simple Route

```php
Flight::route('/', function(){
    echo 'hello world!';
});
```

### Function as Callback

```php
function hello() {
    echo 'hello world!';
}
Flight::route('/', 'hello');
```

### Class Method as Controller

```php
class GreetingController {
    public function hello() {
        echo 'hello world!';
    }
}

Flight::route('/', [ GreetingController::class, 'hello' ]); // preferred
Flight::route('/', [ 'GreetingController', 'hello' ]);
Flight::route('/', [ 'GreetingController::hello' ]);
Flight::route('/', [ 'GreetingController->hello' ]);
```

With constructor injection:

```php
class GreetingController {
    protected Engine $app;
    public function __construct(Engine $app) {
        $this->app = $app;
    }
    public function hello() {
        echo "Hello!";
    }
}

$app = Flight::app();
$greeting = new GreetingController($app);
Flight::route('/', [ $greeting, 'hello' ]);
```

Note: By default, `flight\Engine` is always injected into controllers unless a DI container is used.

## Method-Specific Routing

```php
Flight::route('GET /', function () { echo 'GET request.'; });
Flight::route('POST /', function () { echo 'POST request.'; });

// Flight::get() gets variables, not routes! Use Flight::route('GET /...') instead.
Flight::post('/', function() { /* code */ });
Flight::patch('/', function() { /* code */ });
Flight::put('/', function() { /* code */ });
Flight::delete('/', function() { /* code */ });
```

Multiple methods with `|` delimiter:

```php
Flight::route('GET|POST /', function () {
  echo 'GET or POST request.';
});
```

### HEAD and OPTIONS

- HEAD requests are treated like GET but response body is removed automatically.
- OPTIONS requests return `204 No Content` with `Allow` header listing supported methods. No separate route needed.

## Router Object

```php
$router = Flight::router();
$router->map('/', function() { echo 'hello world!'; });
$router->get('/users', function() { echo 'users'; });
$router->post('/users', function() { /* code */});
$router->put('/users/update/@id', function() { /* code */});
$router->delete('/users/@id', function() { /* code */});
$router->patch('/users/@id', function() { /* code */});
```

## Named Parameters

```php
Flight::route('/@name/@id', function (string $name, string $id) {
  echo "hello, $name ($id)!";
});
```

With regex constraint using `:` delimiter:

```php
Flight::route('/@name/@id:[0-9]{3}', function (string $name, string $id) {
  // Matches /bob/123 but not /bob/12345
});
```

**Important:** Parameters are matched by position in the callback, NOT by name. `Flight::route('/@name/@id', function (string $id, string $name)` will swap the values.

### Optional Parameters

```php
Flight::route(
  '/blog(/@year(/@month(/@day)))',
  function(?string $year, ?string $month, ?string $day) {
    // Matches /blog, /blog/2012, /blog/2012/12, /blog/2012/12/10
  }
);
```

Unmatched optional parameters are passed as `NULL`.

## Wildcard Routing

```php
Flight::route('/blog/*', function () {
  // Matches /blog/2000/02/01
});

Flight::route('*', function () {
  // Matches all requests
});
```

## Regex Routes

```php
Flight::route('/user/[0-9]+', function () {
  // Matches /user/1234
});
```

Named parameters with regex are preferred over raw regex for readability.

## 404 Not Found Handler

```php
Flight::map('notFound', function() {
    $url = Flight::request()->url;
    $this->response()
        ->clearBody()
        ->status(404)
        ->write("<h1>404 Not Found</h1><h3>{$url} not found.</h3>")
        ->send();
});
```

## 405 Method Not Allowed Handler

```php
use flight\net\Route;

Flight::map('methodNotFound', function(Route $route) {
    $url = Flight::request()->url;
    $methods = implode(', ', $route->methods);
    $this->response()
        ->clearBody()
        ->status(405)
        ->setHeader('Allow', $methods)
        ->write("<h1>405 Method Not Allowed</h1><p>Allowed: {$methods}</p>")
        ->send();
});
```

## Route Aliasing

```php
Flight::route('/users/@id', function($id) { echo 'user:'.$id; }, false, 'user_view');
// or
Flight::route('/users/@id', function($id) { echo 'user:'.$id; })->setAlias('user_view');

// Generate URL from alias
$url = Flight::getUrl('user_view', [ 'id' => 5 ]); // returns '/users/5'
Flight::redirect($url);
```

Works in groups too:

```php
Flight::group('/users', function() {
    Flight::route('/@id', function($id) { echo 'user:'.$id; })->setAlias('user_view');
});
```

## Route Grouping

```php
Flight::group('/api/v1', function () {
  Flight::route('/users', function () { /* /api/v1/users */ });
  Flight::route('/posts', function () { /* /api/v1/posts */ });
});
```

Nested groups:

```php
Flight::group('/api', function () {
  Flight::group('/v1', function () {
    Flight::route('GET /users', function () { /* GET /api/v1/users */ });
    Flight::post('/posts', function () { /* POST /api/v1/posts */ });
  });
  Flight::group('/v2', function () {
    Flight::route('GET /users', function () { /* GET /api/v2/users */ });
  });
});
```

### Grouping with Object Context (Preferred)

```php
$app = Flight::app();
$app->group('/api/v1', function (Router $router) {
  $router->get('/users', function () { /* GET /api/v1/users */ });
  $router->post('/posts', function () { /* POST /api/v1/posts */ });
});
```

### Grouping with Middleware

```php
Flight::group('/api/v1', function () {
  Flight::route('/users', function () { /* /api/v1/users */ });
}, [ MyAuthMiddleware::class ]);
```

## Inspecting Route Information

### Via executedRoute

```php
Flight::route('/', function() {
  $route = Flight::router()->executedRoute;
  $route->methods;    // Array of HTTP methods
  $route->params;     // Named parameters
  $route->regex;      // Matching regex
  $route->splat;      // Wildcard contents
  $route->pattern;    // URL pattern
  $route->middleware;  // Assigned middleware
  $route->alias;      // Route alias
});
```

Note: `executedRoute` is NULL before a route executes.

### Via Route Parameter (pass `true`)

```php
Flight::route('/', function(\flight\net\Route $route) {
  $route->methods;
  $route->params;
  $route->regex;
  $route->splat;
  $route->pattern;
  $route->middleware;
  $route->alias;
}, true); // <-- this enables it
```

## Dependency Injection in Routes

```php
use flight\database\PdoWrapper;

class Greeting {
    protected PdoWrapper $pdoWrapper;
    public function __construct(PdoWrapper $pdoWrapper) {
        $this->pdoWrapper = $pdoWrapper;
    }
    public function hello(int $id) {
        $name = $this->pdoWrapper->fetchField("SELECT name FROM users WHERE id = ?", [ $id ]);
        echo "Hello, {$name}!";
    }
}

$dice = new \Dice\Dice();
$dice = $dice->addRule('flight\database\PdoWrapper', [
    'shared' => true,
    'constructParams' => [ 'mysql:host=localhost;dbname=test', 'root', 'password' ]
]);

Flight::registerContainerHandler(function($class, $params) use ($dice) {
    return $dice->create($class, $params);
});

Flight::route('/hello/@id', [ 'Greeting', 'hello' ]);
// or Flight::route('/hello/@id', 'Greeting->hello');
// or Flight::route('/hello/@id', 'Greeting::hello');
Flight::start();
```

## Resource Routing

Creates RESTful routes for a resource:

```php
Flight::resource('/users', UsersController::class);
```

Generates these routes:

| Method   | URL                | Alias            | Controller Method |
|----------|--------------------|------------------|-------------------|
| GET      | /users             | users.index      | index()           |
| GET      | /users/create      | users.create     | create()          |
| POST     | /users             | users.store      | store()           |
| GET      | /users/@id         | users.show       | show($id)         |
| GET      | /users/@id/edit    | users.edit       | edit($id)         |
| PUT      | /users/@id         | users.update     | update($id)       |
| DELETE   | /users/@id         | users.destroy    | destroy($id)      |

### Customizing Resource Routes

```php
// Change alias base
Flight::resource('/users', UsersController::class, [ 'aliasBase' => 'user' ]);

// Whitelist only certain routes
Flight::resource('/users', UsersController::class, [ 'only' => [ 'index', 'show' ] ]);

// Blacklist certain routes
Flight::resource('/users', UsersController::class, [ 'except' => [ 'create', 'store', 'edit', 'update', 'destroy' ] ]);

// Add middleware
Flight::resource('/users', UsersController::class, [ 'middleware' => [ MyAuthMiddleware::class ] ]);
```

## Streaming Responses

Requires `flight.v2.output_buffering` set to `false`.

### Stream with Manual Headers

```php
Flight::route('/@filename', function($filename) {
    $response = Flight::response();
    $fileNameSafe = basename($filename);
    header('Content-Disposition: attachment; filename="'.$fileNameSafe.'"');
    $filePath = '/some/path/to/files/'.$fileNameSafe;
    if (!is_readable($filePath)) {
        Flight::halt(404, 'File not found');
    }
    header('Content-Length: '.filesize($filePath));
    readfile($filePath);
})->stream();
```

### Stream with Headers

```php
Flight::route('/stream-users', function() {
    $users_stmt = Flight::db()->query("SELECT id, first_name, last_name FROM users");
    echo '{';
    while($user = $users_stmt->fetch(PDO::FETCH_ASSOC)) {
        echo json_encode($user);
        if(--$user_count > 0) { echo ','; }
        ob_flush();
    }
    echo '}';
})->streamWithHeaders([
    'Content-Type' => 'application/json',
    'Content-Disposition' => 'attachment; filename="users.json"',
    'status' => 200
]);
```

## Troubleshooting

- Route parameters match by order, not by name.
- `Flight::get()` gets variables, not routes. Use `Flight::route('GET /...')` or `$router->get()`.
- `executedRoute` is NULL before a route executes.
- Streaming requires `flight.v2.output_buffering = false`.
- Returning a value from a route callback passes to the next route. Use `echo` instead of `return` to output content.
- Returning `true` from a callback passes execution to the next matching route (deprecated, use middleware instead).
