<?php

use Illuminate\Support\Facades\Route;

Route::get('/', fn () => response()->json([
    'name' => 'TaskFlow API',
    'status' => 'ok',
]));
