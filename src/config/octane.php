<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Octane Server
    |--------------------------------------------------------------------------
    |
    | This value determines the default Octane server that will be used by
    | the application. Laravel Octane ships with "swoole", "roadrunner",
    | and "frankenphp" servers.
    |
    */

    'server' => env('OCTANE_SERVER', 'swoole'),

    /*
    |--------------------------------------------------------------------------
    | Force HTTPS
    |--------------------------------------------------------------------------
    |
    | When this configuration value is set to "true", Octane will inform the
    | framework that all absolute URLs should be generated using the HTTPS
    | protocol. Otherwise your links may be generated using plain HTTP.
    |
    */

    'https' => env('OCTANE_HTTPS', false),

    /*
    |--------------------------------------------------------------------------
    | Octane Listeners
    |--------------------------------------------------------------------------
    |
    | All of the event listeners for Octane's events are defined below. These
    | listeners are responsible for resetting your application's state after
    | each request. You may even add your own listeners to this array.
    |
    */

    'listeners' => [
        \Laravel\Octane\Listeners\WorkerStarting::class => [
            \Laravel\Octane\Listeners\EnsureUploadedFilesAreValid::class,
            \Laravel\Octane\Listeners\EnsureUploadedFilesCanBeMoved::class,
        ],

        \Laravel\Octane\Listeners\RequestReceived::class => [
            \Laravel\Octane\Listeners\DisconnectFromDatabases::class,
            \Laravel\Octane\Listeners\DisconnectFromRedis::class,
        ],

        \Laravel\Octane\Listeners\RequestHandled::class => [
            \Laravel\Octane\Listeners\StopWorkerIfNecessary::class,
            \Laravel\Octane\Listeners\DisconnectFromDatabases::class,
            \Laravel\Octane\Listeners\DisconnectFromRedis::class,
            \Laravel\Octane\Listeners\FlushLocaleState::class,
            \Laravel\Octane\Listeners\FlushSessionState::class,
            \Laravel\Octane\Listeners\FlushAuthenticationState::class,
            \Laravel\Octane\Listeners\FlushBroadcastingState::class,
            \Laravel\Octane\Listeners\FlushLogsState::class,
            \Laravel\Octane\Listeners\FlushQueueState::class,
            \Laravel\Octane\Listeners\FlushUploadedFiles::class,
        ],

        \Laravel\Octane\Listeners\TaskReceived::class => [
            \Laravel\Octane\Listeners\DisconnectFromDatabases::class,
            \Laravel\Octane\Listeners\DisconnectFromRedis::class,
        ],

        \Laravel\Octane\Listeners\TaskHandled::class => [
            \Laravel\Octane\Listeners\DisconnectFromDatabases::class,
            \Laravel\Octane\Listeners\DisconnectFromRedis::class,
            \Laravel\Octane\Listeners\FlushLocaleState::class,
            \Laravel\Octane\Listeners\FlushSessionState::class,
            \Laravel\Octane\Listeners\FlushAuthenticationState::class,
            \Laravel\Octane\Listeners\FlushBroadcastingState::class,
            \Laravel\Octane\Listeners\FlushLogsState::class,
            \Laravel\Octane\Listeners\FlushQueueState::class,
        ],

        \Laravel\Octane\Listeners\TickReceived::class => [
            \Laravel\Octane\Listeners\DisconnectFromDatabases::class,
            \Laravel\Octane\Listeners\DisconnectFromRedis::class,
            \Laravel\Octane\Listeners\FlushLocaleState::class,
            \Laravel\Octane\Listeners\FlushSessionState::class,
            \Laravel\Octane\Listeners\FlushAuthenticationState::class,
            \Laravel\Octane\Listeners\FlushBroadcastingState::class,
            \Laravel\Octane\Listeners\FlushLogsState::class,
            \Laravel\Octane\Listeners\FlushQueueState::class,
        ],

        \Laravel\Octane\Listeners\WorkerErrorOccurred::class => [
            \Laravel\Octane\Listeners\StopWorkerIfNecessary::class,
        ],

        \Laravel\Octane\Listeners\WorkerStopping::class => [],
    ],

    /*
    |--------------------------------------------------------------------------
    | Warm / Flush Bindings
    |--------------------------------------------------------------------------
    |
    | The bindings listed below will either be pre-warmed when a worker boots
    | or they will be flushed before every new request. Flushing a binding
    | will force the container to resolve that binding again when asked.
    |
    */

    'warm' => [
        'auth',
        'auth.driver',
        'blade.compiler',
        'cache',
        'cache.store',
        'config',
        'db',
        'db.factory',
        'encrypter',
        'files',
        'hash',
        'hash.driver',
        'log',
        'redis',
        'redis.connection',
        'router',
        'session',
        'session.store',
        'translator',
        'url',
        'view',
        'view.engine.resolver',
    ],

    'flush' => [
        'auth.guards',
        'auth.user_providers',
        'broadcaster',
        'events',
        'mail.manager',
        'queue',
        'queue.connection',
    ],

    /*
    |--------------------------------------------------------------------------
    | Octane Cache Table
    |--------------------------------------------------------------------------
    |
    | While using Octane, you may leverage the Octane cache, which is powered
    | by a Swoole table. You may set the maximum number of rows as well as
    | the number of bytes per row using the configuration options below.
    |
    */

    'cache' => [
        'rows' => 1000,
        'bytes' => 10000,
    ],

    /*
    |--------------------------------------------------------------------------
    | Octane Tables
    |--------------------------------------------------------------------------
    |
    | While using Octane, you may leverage Swoole tables to store data that
    | needs to be shared between workers. You may register your tables here.
    |
    */

    'tables' => [
        'example:1000' => [
            'name' => 'string:1000',
            'votes' => 'int',
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | File Watching
    |--------------------------------------------------------------------------
    |
    | The following list of files and directories will be watched when using
    | the --watch option offered by Octane. If any of the directories and
    | files are changed, Octane will automatically reload your workers.
    |
    */

    'watch' => [
        'app',
        'bootstrap',
        'config',
        'database',
        'resources/**/*.php',
        'routes',
        '.env',
    ],

    /*
    |--------------------------------------------------------------------------
    | Garbage Collection Threshold
    |--------------------------------------------------------------------------
    |
    | When executing long-lived PHP applications, such as Octane, memory can
    | build up before being cleared by PHP. You can force Octane to run a
    | full garbage collection on every request if you determine it is needed.
    |
    */

    'garbage' => 50,

    /*
    |--------------------------------------------------------------------------
    | Maximum Execution Time
    |--------------------------------------------------------------------------
    |
    | The following setting configures the maximum execution time for requests
    | handled by Octane. You may set this value to 0 to disable the timeout
    | or specify the timeout in seconds for long running operations.
    |
    */

    'max_execution_time' => 30,

    /*
    |--------------------------------------------------------------------------
    | Swoole Configuration
    |--------------------------------------------------------------------------
    |
    | If you are planning to use Swoole to serve your Laravel application, you
    | may specify additional Swoole configuration options here. Swoole has
    | many features to offer beyond the basic server. So you may use those.
    |
    */

    'swoole' => [
        'options' => [
            'log_file' => storage_path('logs/swoole_http.log'),
            'log_level' => 0,
            'reactor_num' => 2,
            'worker_num' => auto,
            'task_worker_num' => auto,
            'enable_coroutine' => true,
            'max_coroutine' => 100000,
            'open_http2_protocol' => true,
            'open_http_protocol' => true,
            'document_root' => public_path(),
            'enable_static_handler' => true,
            'static_handler_locations' => ['/'],
            'open_tcp_nodelay' => true,
            'package_max_length' => 10 * 1024 * 1024,
            'buffer_output_size' => 10 * 1024 * 1024,
            'socket_buffer_size' => 128 * 1024 * 1024,
            'max_request' => 500,
            'reload_async' => true,
            'max_wait_time' => 60,
            'enable_reuse_port' => true,
            'heartbeat_check_interval' => 60,
            'heartbeat_idle_time' => 600,
        ],
    ],

];
