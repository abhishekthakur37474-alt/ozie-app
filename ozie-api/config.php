<?php
// Copy this file to config.php and fill values. NEVER commit config.php.
return [
    'db' => [
        'host' => 'localhost',
        'user' => 'ordereze1_simharaorderezee',
        'pass' => '1_mxe>5GF-vw',
        'name' => 'ordereze1_demo_orderezee',
    ],

    'timezone' => 'Asia/Kolkata',
    'db_timezone_offset' => '+05:30',

    // API token life (days)
    'token_ttl_days' => 90,

    // CORS: '*' ok for mobile apps. Set your domain if Flutter Web is used.
    'cors_origin' => '*',

    // Firebase Web API key (same value as apiKey in login.php firebaseConfig)
    'firebase_api_key' => 'AIzaSyBMgaDf51X0QY8l-Dwgssoa_OAoMNCwG9U',

    // Forgot password: link sent to user (token is appended)
    'reset_link_base' => 'https://demo.orderezee.com/forgot-password.php?token=',

    // Existing file that defines sendPasswordResetEmail($email, $link, $name)
    'mail_config_path' => dirname(__DIR__) . '/mail_config.php',

    // WhatsApp (Pinbot / Smartping) for reset link
    'whatsapp' => [
        'api_key'         => 'CHANGE_ME',
        'phone_number_id' => 'CHANGE_ME',
        'template'        => 'forgot_password_link',
        'language'        => 'en',
    ],
];
