@echo off
echo 🔥 Desplegando reglas de Firestore...
echo.

REM Verificar si Firebase CLI está instalado
firebase --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Firebase CLI no está instalado
    echo Instala Firebase CLI con: npm install -g firebase-tools
    pause
    exit /b 1
)

REM Desplegar reglas
echo 📋 Desplegando reglas de Firestore...
firebase deploy --only firestore:rules

if %errorlevel% equ 0 (
    echo ✅ Reglas de Firestore desplegadas exitosamente
) else (
    echo ❌ Error desplegando reglas de Firestore
)

echo.
echo   Reglas aplicadas:
echo - Usuarios autenticados pueden leer/escribir sus propios datos
echo - Subcolecciones protegidas por UID del usuario
echo - Acceso general para usuarios autenticados
echo.
pause 