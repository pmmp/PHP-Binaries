param (
    [string]$target = $(if((Get-WmiObject -Class Win32_ComputerSystem).SystemType -match "(x64)"){ "x64" }else{ "x86" }),
    [switch]$debug = $false,
    [string]$path = $(Split-Path $script:MyInvocation.MyCommand.Path),
    [switch]$zip = $false
)

if($PSVersionTable.PSVersion.Major -lt 5){
    Write-Host "This script requires PowerShell version 5 or later" -ForegroundColor Red -BackgroundColor Black
    exit 1
}

$PHP_VERSION = "7.0.22"
$parts = $PHP_VERSION.Split(".")
$PHP_VERSION_BASE = $parts[0] + "." + $parts[1]
$PHP_IS_BETA = $false

$PTHREADS_VERSION = "3.1.6"
$XDEBUG_VERSION = "2.5.5"
$WEAKREF_VERSION = "0.3.3"
$YAML_VERSION = "2.0.0"


echo "[PocketMine] PHP Windows binary builder"
echo "[opt] Set target to $target"
if($debug){
    echo "[opt] Will include and enable xdebug"
}
echo "[opt] Creating build in $path"

$tmp_path = $path + "\install_data\"

if((Test-Path $tmp_path) -eq $true){
    echo "[PHP] cleaning old install data..."
    rm -r -Force $tmp_path
}

(mkdir $tmp_path) > $null

$wc = New-Object System.Net.WebClient

function download_file{
    param(
        [string] $url,
        [string] $saveFile
    )

    try{
        $wc.DownloadFile("$url", "$tmp_path" + "$saveFile")
    }catch [System.Net.WebException]{
        Write-Host ("[ERROR] " + $_.Exception.Message) -ForegroundColor Red -BackgroundColor Black
        Write-Host "Please check the version you are trying to download is still available from the download server. ($url)" -ForegroundColor Red -BackgroundColor Black
        exit 1
    }
}

echo "[PHP] Downloading $PHP_VERSION..."

if($PHP_IS_BETA){
    download_file "http://windows.php.net/downloads/qa/php-$PHP_VERSION-Win32-VC14-$target.zip" "php.zip"
}else{
    download_file "http://windows.php.net/downloads/releases/php-$PHP_VERSION-Win32-VC14-$target.zip" "php.zip"
}

#php
echo "[PHP] Extracting..."
Expand-Archive ($tmp_path + "php.zip") -DestinationPath ($path + "\bin\php") -Force

if($debug){
    echo "[PHP] Downloading debugging symbols..."
    if($PHP_IS_BETA){
        download_file "http://windows.php.net/downloads/qa/php-debug-pack-$PHP_VERSION-Win32-VC14-$target.zip" "php-debug-pack.zip"
    }else{
        download_file "http://windows.php.net/downloads/releases/php-debug-pack-$PHP_VERSION-Win32-VC14-$target.zip" "php-debug-pack.zip"
    }

    echo "[PHP] Extracting debugging symbols..."
    Expand-Archive ($tmp_path + "php-debug-pack.zip") -DestinationPath ($path + "\bin\php\symbols") -Force
}



#pthreads
echo "[pthreads] Downloading $PTHREADS_VERSION..."
download_file "http://windows.php.net/downloads/pecl/releases/pthreads/$PTHREADS_VERSION/php_pthreads-$PTHREADS_VERSION-$PHP_VERSION_BASE-ts-vc14-$target.zip" "pthreads.zip"

echo "[pthreads] Extracting..."
Expand-Archive ($tmp_path + "pthreads.zip") -DestinationPath ($tmp_path + "pthreads") -Force

echo "[pthreads] Copying required files..."
Copy-Item ($tmp_path + "pthreads\pthreadVC2.dll") -Destination ($path + "\bin\php")
Copy-Item ($tmp_path + "pthreads\php_pthreads.dll") -Destination ($path + "\bin\php\ext")
if($debug){
    Copy-Item ($tmp_path + "pthreads\php_pthreads.pdb") -Destination ($path + "\bin\php\symbols")
    Copy-Item ($tmp_path + "pthreads\pthreadVC2.pdb") -Destination ($path + "\bin\php\symbols")
}



#yaml
echo "[yaml] Downloading $YAML_VERSION..."
download_file "http://windows.php.net/downloads/pecl/releases/yaml/$YAML_VERSION/php_yaml-$YAML_VERSION-$PHP_VERSION_BASE-ts-vc14-$target.zip" "yaml.zip"

echo "[yaml] Extracting..."
Expand-Archive ($tmp_path + "yaml.zip") -DestinationPath ($tmp_path + "yaml") -Force

echo "[yaml] Copying required files..."
Copy-Item ($tmp_path + "yaml\yaml.dll") -Destination ($path + "\bin\php")
Copy-Item ($tmp_path + "yaml\php_yaml.dll") -Destination ($path + "\bin\php\ext")
if($debug){
    Copy-Item ($tmp_path + "yaml\php_yaml.pdb") -Destination ($path + "\bin\php\symbols")
    #Copy-Item ($tmp_path + "yaml\yaml.pdb") -Destination ($path + "\bin\php\symbols") YAML doesn't ship with debug symbols >_<
}


#weakref
echo "[weakref] Downloading $WEAKREF_VERSION..."
download_file "http://windows.php.net/downloads/pecl/releases/weakref/$WEAKREF_VERSION/php_weakref-$WEAKREF_VERSION-$PHP_VERSION_BASE-ts-vc14-$target.zip" "weakref.zip"

echo "[weakref] Extracting..."
Expand-Archive ($tmp_path + "weakref.zip") -DestinationPath ($tmp_path + "weakref") -Force

echo "[weakref] Copying required files..."
Copy-Item ($tmp_path + "weakref\php_weakref.dll") -Destination ($path + "\bin\php\ext")
if($debug){
    Copy-Item ($tmp_path + "weakref\php_weakref.pdb") -Destination ($path + "\bin\php\symbols")
}


#xdebug
if($debug -ne $false){
    echo "[xdebug] Downloading $XDEBUG_VERSION..."
    download_file "http://windows.php.net/downloads/pecl/releases/xdebug/$XDEBUG_VERSION/php_xdebug-$XDEBUG_VERSION-$PHP_VERSION_BASE-ts-vc14-$target.zip" "xdebug.zip"

    echo "[xdebug] Extracting..."
    Expand-Archive ($tmp_path + "xdebug.zip") -DestinationPath ($tmp_path + "xdebug") -Force

    echo "[xdebug] Copying required files..."
    Copy-Item ($tmp_path + "xdebug\php_xdebug.dll") -Destination ($path + "\bin\php\ext")

    Copy-Item ($tmp_path + "xdebug\php_xdebug.pdb") -Destination ($path + "\bin\php\symbols")
}

echo "[PHP] Creating php.ini..."
$php_ini = $path + "\bin\php\php.ini"
(rm -Force $php_ini) 2> $null
(New-Item $php_ini) > $null

function write_php_ini{
    param([string]$line)
    $line | Out-File -filePath $php_ini -Append -Encoding ascii
}

write_php_ini(";Custom PocketMine php.ini file")
write_php_ini("zend.enable_gc=On")
write_php_ini("max_execution_time=0")
write_php_ini("memory_limit=256M")
write_php_ini("error_reporting=-1")
write_php_ini("display_errors=stderr")
write_php_ini("display_startup_errors=On")
write_php_ini("register_argc_argv=On")
write_php_ini('default_charset="UTF-8"')
write_php_ini('include_path=".;.\ext"')
write_php_ini('extension_dir="./ext/"')
write_php_ini("enable_dl=On")
write_php_ini("allow_url_fopen = On")

write_php_ini("extension=php_weakref.dll")
write_php_ini("extension=php_curl.dll")
write_php_ini("extension=php_mysqli.dll")
write_php_ini("extension=php_openssl.dll")
write_php_ini("extension=php_sqlite3.dll")
write_php_ini("extension=php_sockets.dll")
write_php_ini("extension=php_mbstring.dll")
write_php_ini("extension=php_yaml.dll")
write_php_ini("extension=php_pthreads.dll")
write_php_ini("extension=php_com_dotnet.dll")
write_php_ini("extension=php_gd2.dll")
write_php_ini("extension=php_gmp.dll")
write_php_ini("zend_extension=php_opcache.dll")
if($debug){
    write_php_ini("zend_extension=php_xdebug.dll")
}
write_php_ini("cli_server.color=On")
write_php_ini("phar.readonly=Off")
write_php_ini("phar.require_hash=On")
write_php_ini("opcache.enable=1")
write_php_ini("opcache.enable_cli=1")
write_php_ini("opcache.memory_consumption=128")
write_php_ini("opcache.interned_strings_buffer=8")
write_php_ini("opcache.max_accelerated_files=4000")
write_php_ini("opcache.save_comments=1")
write_php_ini("opcache.load_comments=1")
write_php_ini("opcache.fast_shutdown=0")
write_php_ini("opcache.optimization_level=0xffffffff")

if($debug){
    write_php_ini("zend.assertions=1")
}else{
    write_php_ini("zend.assertions=-1")

}

#TIMEZONE=$(date +%Z)
#write_php_ini("date.timezone=$TIMEZONE")

echo "[PHP] Cleaning up temporary files..."
rm -r -Force $tmp_path
echo "[PHP] Checking PHP build works..."

$cmd = "& `"$path\bin\php\php.exe`" --version"
$output = [string] (iex $cmd)
if($output -match "PHP"){
    echo "[PHP] Done!"
}else{
    Write-Host "[PHP] Failed to run PHP. You may need to install Microsoft Visual C++ Redistributable 2015 runtime. This can be downloaded from the Microsoft website." -ForegroundColor Red -BackgroundColor Black
    exit 1
}

if($zip){
    $zipPath = $path + "\php-$PHP_VERSION-$target" + $(if($debug){ "-debug" }) + ".zip"
    if(Test-Path $zipPath){
        echo "Removing old zip..."
        rm $zipPath
    }
    $source = $path + "\bin"
    echo "Creating zipped build..."
    Compress-Archive -Path $source -DestinationPath $zipPath
    echo $("Created zipped build on " + $zipPath)
}
