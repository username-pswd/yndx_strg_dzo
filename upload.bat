@echo off

chcp 65001 > nul

setlocal enabledelayedexpansion

set "folderPath=E:\Local\upload"
set "hashOutputFile=E:\Local\hash\hashes.txt"
set "uploadedFolder=E:\Local\uploaded"
set "filesSize=E:\Local\filesSize.txt"
set totalSize=0
set partSize=25
set "fileList=E:\Local\uploaded_files.txt"
set "storagePath=C:\mnt\yandex_storage"

type nul > "%hashOutputFile%"
type nul > "%filesSize%"
type nul > "%fileList%"

for /r "%folderPath%" %%F in (*) do (
    certutil -hashfile "%%F" MD5 | findstr /r "^[0-9a-fA-F]" | findstr /v "CertUtil" >> "%hashOutputFile%"
    echo %%~nxF >> "%fileList%"
    set /a totalSize+=%%~zF
)
echo !totalSize! > "%filesSize%"

set /a threshold100MB=100 * 1024 * 1024
set /a threshold1GB=1 * 1024 * 1024 * 1024
set /a threshold10GB=10 * 1024 * 1024 * 1024
set /a threshold1000GB=1000 * 1024 * 1024 * 1024


if !totalSize! lss !threshold100MB! (
    set partSize=5
    echo Общий размер меньше 100 МБ, часть будет 5 МБ
) else if !totalSize! lss !threshold1GB! (
    set partSize=50
    echo Общий размер меньше 1 ГБ, часть будет 50 МБ
) else if !totalSize! lss !threshold10GB! (
    set partSize=500
    echo Общий размер меньше 10 ГБ, часть будет 500 МБ
) else if !totalSize! lss !threshold1000GB! (
    set partSize=5000
    echo Общий размер меньше 1000 ГБ, часть будет 5000 МБ
) else (
    set partSize=10000
    echo Общий размер больше или равен 1000 ГБ, часть будет 10000
)

taskkill /IM geesefs.exe /F
start C:\Users\Тимур\Downloads\Installer\geesefs.exe --part-sizes !partSize! test-bucket1 C:\mnt\yandex_storage

timeout /t 10 /nobreak

set "finalHashFile=C:\mnt\yandex_storage\metaStorage\final_hashes.txt"

aws s3 cp "%hashOutputFile%" s3://test-bucket1/metaLocal/

echo Хеш-суммы сохранены в файл: %hashOutputFile%

set "folderName=E:\Local\uploaded"

if not exist "%uploadedFolder%" (
    echo Создаю папку "%uploadedFolder%"
    mkdir "%uploadedFolder%"
)

xcopy "%folderPath%"\*.* "C:\mnt\yandex_storage\important_files\" /s /i

robocopy "E:\Local\upload" "E:\Local\uploaded" *.* /mov /e

type nul > "%finalHashFile%"

for /f "delims=" %%F in (%fileList%) do (
    set "filePath=C:\mnt\yandex_storage\important_files\%%F"
    if exist "!filePath!" (
        certutil -hashfile "!filePath!" MD5 | findstr /r "^[0-9a-fA-F]" | findstr /v "CertUtil" >> "%finalHashFile%"
    )
)

xcopy "%finalHashFile%" "E:\Local\hash\" /Y

fc  E:\Local\hash\final_hashes.txt E:\Local\hash\hashes.txt

pause
