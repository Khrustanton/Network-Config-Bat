@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: Определяем активный сетевой адаптер через PowerShell
for /f "tokens=*" %%i in ('powershell -Command "Get-NetAdapter -Physical | Where-Object {$_.Status -eq 'Up' -and $_.MediaType -eq '802.3'} | Select-Object -First 1 | %%{ $_.Name }"') do (
    set "AdapterName=%%i"
)

:: Если адаптер не найден, ищем любой активный
if "%AdapterName%"=="" (
    for /f "tokens=*" %%i in ('powershell -Command "Get-NetAdapter -Physical | Where-Object {$_.Status -eq 'Up'} | Select-Object -First 1 | %%{ $_.Name }"') do (
        set "AdapterName=%%i"
    )
)

:: Если адаптер все еще не найден, выводим ошибку
if "%AdapterName%"=="" (
    echo Ошибка: Не удалось определить активный сетевой адаптер
    pause
    exit /b 1
)

echo Найден адаптер: %AdapterName%

:: Применяем сетевые настройки
echo Применение сетевых настроек...
netsh interface ip delete dns "%AdapterName%" all
if errorlevel 1 (
    echo Предупреждение: Не удалось очистить DNS-настройки
)

netsh interface ip set address "%AdapterName%" static 192.168.0.155 255.255.252.0 192.168.0.254
if errorlevel 1 (
    echo Ошибка: Не удалось установить IP-адрес и шлюз
    pause
    exit /b 1
)

netsh interface ip set dns "%AdapterName%" static 192.168.3.1 primary
if errorlevel 1 (
    echo Ошибка: Не удалось установить DNS-сервер
    pause
    exit /b 1
)

:: Отключаем IPv6 для всех адаптеров
echo Отключение IPv6...
powershell -Command "Disable-NetAdapterBinding -Name '*' -ComponentID ms_tcpip6"
if errorlevel 1 (
    echo Предупреждение: Не удалось отключить IPv6
)

echo.
echo ========================================
echo Настройки успешно применены!
echo Адаптер: %AdapterName%
echo IP-адрес: 192.168.0.155
echo Маска: 255.255.252.0
echo Шлюз: 192.168.0.254
echo DNS: 192.168.3.1
echo IPv6: отключен
echo ========================================
echo.

pause