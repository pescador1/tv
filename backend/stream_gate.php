<?php
// stream_gate.php - Anti-Sniffing Stream Gatekeeper & Protection Proxy
error_reporting(0);
ini_set('display_errors', '0');

require_once __DIR__ . '/config.php';

// Secret HMAC key for signing tokens
define('STREAM_SECRET_KEY', 'HR_TV_SECURE_TOKEN_SECRET_2026');

$channel_id = isset($_GET['id']) ? intval($_GET['id']) : 0;
$token = isset($_GET['token']) ? trim($_GET['token']) : '';
$user_agent = $_SERVER['HTTP_USER_AGENT'] ?? '';
$referer = $_SERVER['HTTP_REFERER'] ?? '';

// 1. Detect external players & stream sniffers (VLC, MXPlayer, Web Video Caster, ffmpeg, curl, etc.)
$blacklisted_agents = [
    'vlc', 'webvideocaster', 'mxplayer', 'ffmpeg', 'curl', 'wget', 'python',
    'lavf', 'libmpv', 'exoplayer', 'justplayer', 'iptv', 'cast', 'dlna', 'gstreamer'
];

$is_sniffer = false;
$ua_lower = strtolower($user_agent);

foreach ($blacklisted_agents as $agent) {
    if (strpos($ua_lower, $agent) !== false && strpos($ua_lower, 'paneltv_official') === false && strpos($ua_lower, 'hrtv_app') === false) {
        $is_sniffer = true;
        break;
    }
}

// 2. Validate Dynamic Token (Token is valid for 1 hour based on Channel ID, IP, and Date)
$client_ip = $_SERVER['REMOTE_ADDR'] ?? '';
$expected_token = md5($channel_id . '_' . date('Y-m-d-H') . '_' . $client_ip . '_' . STREAM_SECRET_KEY);
$expected_token_prev = md5($channel_id . '_' . date('Y-m-d-H', time() - 3600) . '_' . $client_ip . '_' . STREAM_SECRET_KEY);

$is_token_valid = ($token === $expected_token || $token === $expected_token_prev);

// Check if request is coming from authorized app or domain
$is_authorized_app = (strpos($user_agent, 'PanelTV_Official') !== false || strpos($user_agent, 'HRTV_App') !== false || strpos($referer, 'app.hr-tech.site') !== false || strpos($referer, 'localhost') !== false);

// 3. IF SNIFFER DETECTED OR INVALID TOKEN / UNAUTHORIZED -> SERVE PROMO VIDEO!
if ($is_sniffer || !$is_authorized_app || !$is_token_valid) {
    // Serve the Promo Video / Banner Page
    require_dir_promo:
    require_once __DIR__ . '/promo.php';
    exit();
}

// 4. AUTHORIZED ACCESS -> Fetch Channel Stream URL from Database
if ($channel_id <= 0) {
    header("Location: promo.php");
    exit();
}

$stmt = $pdo->prepare("SELECT stream_url FROM channels WHERE id = ? AND status_online != 0 AND is_hidden = 0");
$stmt->execute([$channel_id]);
$channel = $stmt->fetch();

if (!$channel || empty($channel['stream_url'])) {
    header("Location: promo.php");
    exit();
}

$stream_url = $channel['stream_url'];

// Redirect to player.php or proxy stream URL
header("Location: " . $stream_url);
exit();
?>
