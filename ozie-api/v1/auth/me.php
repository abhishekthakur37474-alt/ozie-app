<?php
if (!defined('OZIE_API')) { http_response_code(403); exit; }

$user = require_auth();
ok(session_payload(db(), $user));
