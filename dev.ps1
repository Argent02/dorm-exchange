# ─── DormExchange Dev Launcher (Windows PowerShell) ────────
# Starts the database, backend, and optionally the Flutter app.
#
# Usage: .\dev.ps1 [device]
#   .\dev.ps1              → starts DB + backend only
#   .\dev.ps1 chrome       → starts DB + backend + Flutter on Chrome
#   .\dev.ps1 <device-id>  → starts DB + backend + Flutter on a specific device

param([string]$Device = "")

$ErrorActionPreference = "Stop"

# Load local device config
if (Test-Path ".dev.config.ps1") {
    . .\.dev.config.ps1
}

# Map friendly names
if ($Device -eq "iphone") {
    if (-not $env:IPHONE_DEVICE_ID) {
        Write-Host "⚠  No iPhone device ID configured." -ForegroundColor Yellow
        Write-Host "   Create a .dev.config.ps1 file in the project root with:"
        Write-Host ""
        Write-Host '   $env:IPHONE_DEVICE_ID = "your-device-id"'
        Write-Host ""
        Write-Host "   Find your device ID by running: flutter devices"
        exit 1
    }
    $Device = $env:IPHONE_DEVICE_ID
}

Write-Host "▸ Starting DormExchange dev environment..." -ForegroundColor Green

# ─── Preflight checks ────────────────────────────────────
foreach ($cmd in @("docker", "node", "npm", "flutter")) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Write-Host "✗ Required tool '$cmd' is not installed." -ForegroundColor Red
        exit 1
    }
}

# ─── 1. Database ───────────────────────────────────────────
$running = docker ps --format "{{.Names}}" 2>$null | Select-String "dormexchange-db"
if ($running) {
    Write-Host "✓ Database already running" -ForegroundColor Green
} else {
    Write-Host "▸ Starting database..." -ForegroundColor Yellow
    docker start dormexchange-db 2>$null
    if ($LASTEXITCODE -ne 0) {
        docker compose up -d
    }
    # Wait for Postgres
    Write-Host -NoNewline "  Waiting for database"
    for ($i = 1; $i -le 15; $i++) {
        $ready = docker exec dormexchange-db pg_isready -U postgres 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "✓ Database started" -ForegroundColor Green
            break
        }
        if ($i -eq 15) {
            Write-Host ""
            Write-Host "✗ Database failed to start within 15s" -ForegroundColor Red
            exit 1
        }
        Write-Host -NoNewline "."
        Start-Sleep -Seconds 1
    }
}

# ─── 2. Update local IP for physical device testing ───────
$localIp = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {
    $_.InterfaceAlias -notmatch "Loopback" -and $_.PrefixOrigin -eq "Dhcp"
} | Select-Object -First 1).IPAddress

$apiService = "lib\services\api_service.dart"
if ($localIp -and (Test-Path $apiService)) {
    $content = Get-Content $apiService -Raw
    if ($content -match "static const String _localIp = '([^']*)'") {
        $currentIp = $Matches[1]
        if ($currentIp -ne $localIp) {
            $content = $content -replace "static const String _localIp = '[^']*'", "static const String _localIp = '$localIp'"
            Set-Content $apiService $content -NoNewline
            Write-Host "▸ Updated _localIp: $currentIp → $localIp" -ForegroundColor Yellow
        } else {
            Write-Host "✓ Local IP up to date ($localIp)" -ForegroundColor Green
        }
    }
} else {
    Write-Host "▸ Could not detect local IP — physical device testing may not work" -ForegroundColor Yellow
}

# ─── 3. Backend setup ─────────────────────────────────────

# Auto-create .env
if (-not (Test-Path "backend\.env")) {
    if (Test-Path "backend\.env.example") {
        Copy-Item "backend\.env.example" "backend\.env"
        Write-Host "▸ Created backend\.env from .env.example" -ForegroundColor Yellow
    } else {
        Write-Host "✗ backend\.env.example not found" -ForegroundColor Red
        exit 1
    }
}

# Install npm dependencies
if (-not (Test-Path "backend\node_modules")) {
    Write-Host "▸ Installing backend dependencies..." -ForegroundColor Yellow
    Push-Location backend; npm install; Pop-Location
}

# Generate Prisma client
if (-not (Test-Path "backend\src\generated\prisma")) {
    Write-Host "▸ Generating Prisma client..." -ForegroundColor Yellow
    Push-Location backend; npx prisma generate; Pop-Location
}

# Apply migrations
Write-Host "▸ Applying database migrations..." -ForegroundColor Yellow
Push-Location backend
try {
    $migrateOutput = npx prisma migrate deploy 2>&1
} finally {
    Pop-Location
}
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Database schema up to date" -ForegroundColor Green
} else {
    Write-Host "✗ Migration failed" -ForegroundColor Red
    Write-Host ""
    $migrateOutput | ForEach-Object { Write-Host "  $_" }
    Write-Host ""
    Write-Host "How to fix:" -ForegroundColor Yellow
    Write-Host "  • Database connection refused? Ensure Docker is running and Postgres is up:"
    Write-Host "    docker compose up -d"
    Write-Host ""
    Write-Host "  • Wrong credentials? Check backend\.env DATABASE_URL matches docker-compose.yml"
    Write-Host "    (postgres:postgres@localhost:5432/dormexchange)"
    Write-Host ""
    Write-Host "  • First-time setup or schema drift? Create/apply migrations manually:"
    Write-Host "    cd backend; npx prisma migrate dev --name <migration_name>"
    exit 1
}

# ─── 4. Backend server ───────────────────────────────────
Write-Host "▸ Starting backend..." -ForegroundColor Yellow
$backendJob = Start-Job -ScriptBlock {
    Set-Location "$using:PWD\backend"
    npm run dev
}

# Wait for backend
Write-Host -NoNewline "  Waiting for API"
for ($i = 1; $i -le 30; $i++) {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3000/health" -UseBasicParsing -TimeoutSec 1 -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            Write-Host ""
            Write-Host "✓ Backend running on http://localhost:3000" -ForegroundColor Green
            break
        }
    } catch {}
    if ($i -eq 30) {
        Write-Host ""
        Write-Host "✗ Backend failed to start within 30s" -ForegroundColor Red
        exit 1
    }
    Write-Host -NoNewline "."
    Start-Sleep -Seconds 1
}

# ─── 5. Flutter (optional) ────────────────────────────────
if ($Device) {
    Write-Host "▸ Launching Flutter on device: $Device" -ForegroundColor Yellow
    flutter run -d $Device
} else {
    Write-Host ""
    Write-Host "✓ Dev environment ready!" -ForegroundColor Green
    Write-Host "  Run 'flutter run -d <device>' in another terminal to launch the app."
    Write-Host ""
    Receive-Job $backendJob -Wait
}
