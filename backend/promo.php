<?php
// promo.php - Serves the watermarked protection video / banner when an unauthorized stream request is detected.
header('Access-Control-Allow-Origin: *');
header('Cache-Control: no-cache, no-store, must-revalidate');
header('Pragma: no-cache');
header('Expires: 0');

// Path to promo video or stream fallback
$promo_video = __DIR__ . '/assets/promo_hrtv.mp4';

if (file_exists($promo_video)) {
    header('Content-Type: video/mp4');
    header('Content-Length: ' . filesize($promo_video));
    readfile($promo_video);
    exit();
} else {
    // Return HTML Player fallback with HR TV Banner and Trilingual Text
    header('Content-Type: text/html; charset=utf-8');
    ?>
    <!DOCTYPE html>
    <html lang="ar" dir="rtl">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>HR TV - البث محمي</title>
        <style>
            body {
                margin: 0;
                padding: 0;
                background-color: #0F172A;
                color: #FFFFFF;
                font-family: system-ui, -apple-system, sans-serif;
                display: flex;
                flex-direction: column;
                align-items: center;
                justify-content: center;
                min-height: 100vh;
                text-align: center;
            }
            .card {
                background: rgba(30, 41, 59, 0.95);
                border: 2px solid #3B82F6;
                padding: 25px;
                border-radius: 20px;
                box-shadow: 0 10px 30px rgba(59, 130, 246, 0.3);
                max-width: 420px;
                width: 90%;
            }
            .banner {
                width: 100%;
                border-radius: 14px;
                margin-bottom: 20px;
                box-shadow: 0 4px 15px rgba(0,0,0,0.5);
            }
            h1 { font-size: 24px; margin-bottom: 15px; color: #60A5FA; }
            .msg-box {
                font-size: 15px;
                color: #CBD5E1;
                line-height: 1.6;
                margin-bottom: 25px;
                text-align: right;
                background: rgba(15, 23, 42, 0.6);
                padding: 15px;
                border-radius: 12px;
                border-right: 4px solid #3B82F6;
            }
            .btn {
                background: linear-gradient(135deg, #2563EB, #1D4ED8);
                color: #FFFFFF;
                text-decoration: none;
                padding: 14px 28px;
                border-radius: 12px;
                font-weight: bold;
                font-size: 18px;
                display: inline-block;
                transition: transform 0.2s;
            }
            .btn:hover { transform: scale(1.05); }
        </style>
    </head>
    <body>
        <div class="card">
            <img src="assets/promo_banner.jpg" class="banner" alt="HR TV Protection Banner" onerror="this.style.display='none'">
            <h1>البث محمي حصرياً 🛡️</h1>
            
            <div class="msg-box">
                <p style="margin: 0 0 10px 0;">📌 <strong>العربية:</strong> هذا البث محمي، يرجى تحميل تطبيق HR TV لمشاهدة القنوات.</p>
                <p style="margin: 0 0 10px 0;">📌 <strong>Français:</strong> Ce flux est protégé. Téléchargez l'application HR TV pour regarder les chaînes.</p>
                <p style="margin: 0;">📌 <strong>English:</strong> Stream is protected. Download official HR TV App to watch channels.</p>
            </div>
            
            <a href="https://app.hr-tech.site/" class="btn">تحميل تطبيق HR TV 🚀</a>
        </div>
    </body>
    </html>
    <?php
}
?>
