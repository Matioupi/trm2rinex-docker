#!/usr/bin/bash
#
# Dirty script to cleanup stage 2 filesystem before building the final docker image
# goal is to get a smaller final image size
#
# author : mathieu.peyrega@gmail.com
#

USER_NAME=$1
WINE_INSTALL_PREFIX=$2

# Remove post install temporary files
rm -rf /home/${USER_NAME}/.wine/drive_c/users/${USER_NAME}/Temp/*

# Requiered dll and exe can be identified running with first
# export WINEDEBUG=+loaddll,+pid
# this let us build a list of required dll and remove all the others
# ntdll.dll must be added anyway

list="ntdll.dll wineboot.exe kernelbase.dll kernel32.dll msvcrt.dll ucrtbase.dll sechost.dll advapi32.dll ws2_32.dll winemenubuilder.exe kernelbase.dll kernel32.dll msvcrt.dll ucrtbase.dll sechost.dll advapi32.dll win32u.dll gdi32.dll win32u.dll gdi32.dll rpcrt4.dll rpcrt4.dll version.dll setupapi.dll version.dll user32.dll combase.dll setupapi.dll user32.dll ole32.dll shcore.dll combase.dll shlwapi.dll shell32.dll ole32.dll shcore.dll shlwapi.dll shell32.dll imm32.dll start.exe kernelbase.dll kernel32.dll msvcrt.dll ucrtbase.dll sechost.dll advapi32.dll win32u.dll gdi32.dll rpcrt4.dll version.dll setupapi.dll user32.dll combase.dll ole32.dll shcore.dll shlwapi.dll shell32.dll conhost.exe kernelbase.dll kernel32.dll imm32.dll msvcrt.dll ucrtbase.dll sechost.dll advapi32.dll win32u.dll gdi32.dll rpcrt4.dll version.dll setupapi.dll user32.dll imm32.dll cmd.exe kernelbase.dll kernel32.dll msvcrt.dll ucrtbase.dll sechost.dll advapi32.dll win32u.dll gdi32.dll rpcrt4.dll version.dll setupapi.dll user32.dll combase.dll ole32.dll shcore.dll shlwapi.dll shell32.dll imm32.dll kernelbase.dll kernel32.dll msvcrt.dll ucrtbase.dll sechost.dll advapi32.dll dbghelp.dll win32u.dll gdi32.dll rpcrt4.dll version.dll setupapi.dll user32.dll combase.dll ole32.dll shcore.dll shlwapi.dll shell32.dll mscoree.dll imm32.dll uxtheme.dll oleaut32.dll mpr.dll ws2_32.dll wininet.dll urlmon.dll msxml3.dll bcrypt.dll msacm32.dll winmm.dll api-ms-win-crt-conio-l1-1-0.dll api-ms-win-crt-convert-l1-1-0.dll api-ms-win-crt-environment-l1-1-0.dll api-ms-win-crt-filesystem-l1-1-0.dll api-ms-win-crt-heap-l1-1-0.dll api-ms-win-crt-locale-l1-1-0.dll api-ms-win-crt-math-l1-1-0.dll api-ms-win-crt-private-l1-1-0.dll api-ms-win-crt-runtime-l1-1-0.dll api-ms-win-crt-stdio-l1-1-0.dll api-ms-win-crt-string-l1-1-0.dll api-ms-win-crt-time-l1-1-0.dll api-ms-win-crt-utility-l1-1-0.dll api-ms-win-crt-process-l1-1-0.dll vcruntime140.dll api-ms-win-crt-multibyte-l1-1-0.dll comctl32.dll"

cd /home/${USER_NAME}/.wine/drive_c/windows/system32
for i in *.{dll,exe}; do
    if [ -f $i ] && ! echo $list | grep -w -q $i >/dev/null; then
        #echo removing $i
        rm -f $i
        rm -f  ${WINE_INSTALL_PREFIX}/lib/wine/i386-windows/$i
    fi
done

# Those files in the windows/system32 directory can also be removed
rm *.vxd *.drv *.tlb *.ocx *.nls *.mod *.acm

# Clean ${WINE_INSTALL_PREFIX}/lib directories

cd ${WINE_INSTALL_PREFIX}/lib/wine/i386-unix
rm -f *.dll16.*
rm -f *.exe16.*
rm -f *.drv16.*
rm -f *.ocx.*
rm -f *.drv.*
rm -f *.sys.*
rm -f *.cpl.*

for i in *.{dll.so,exe.so}; do
    if [ -f $i ] && ! echo $list | grep -w -q "$([[ "$(${WINE_INSTALL_PREFIX}/bin/wine --version)" =~ (.*\.{dll|exe})\.so ]] &&  echo ${BASH_REMATCH[1]})"; then
        pref="$([[ "$i" =~ (.+\.(dll|exe){1})\.so ]] && echo ${BASH_REMATCH[1]})"
        if [ ${#pref} -ne 0 ] && ! echo $list | grep -w -q $pref >/dev/null; then
             rm $i
        fi
    fi
done

# Misc other cleaning
cd /home/${USER_NAME}/.wine/drive_c/windows
rm -rf twain*
rm *.exe
rm -rf resources
rm -rf globalization

# Used dll identification also show details of used "Mono" components
# this is a (very) dirty cleanup stage for the non used
cd /home/${USER_NAME}/.wine/drive_c/windows/mono/mono-2.0/lib/mono
rm -rf 2.0-api/ 3.5-api/ 4.0 4.0-api/ 4.5-api/ 4.5.1-api/ 4.5.2-api/ 4.6-api/ 4.6.1-api/ 4.6.2-api/ 4.7-api/ 4.7.1-api/ 4.7.2-api/ 4.8-api/ lldb/ mono-configuration-crypto/ monodoc/ msbuild/ xbuild/ xbuild-frameworks/

cd /home/${USER_NAME}/.wine/drive_c/windows/mono/mono-2.0/lib/mono/4.5
rm -rf Facades/ MSBuild/ Microsoft.* VBCS* csi* sql* xbuild.* vbc.* csc.* mono-shlib-cop.exe.config
mv mscorlib.dll mscorlib.keep
rm -f *.dll
rm -f *.exe
mv mscorlib.keep mscorlib.dll

cd /home/${USER_NAME}/.wine/drive_c/windows/mono/mono-2.0/
rm -rf support/

cd /home/${USER_NAME}/.wine/drive_c/windows/mono/mono-2.0/lib
rm -f *.dll
rm -rf x86 x86_64

mkdir /home/${USER_NAME}/keep
mv /home/${USER_NAME}/.wine/drive_c/windows/mono/mono-2.0/lib/mono/gac/System/4.0.0.0__b77a5c561934e089/System.dll /home/${USER_NAME}/keep/
mv /home/${USER_NAME}/.wine/drive_c/windows/mono/mono-2.0/lib/mono/gac/System.Windows.Forms/4.0.0.0__b77a5c561934e089/System.Windows.Forms.dll /home/${USER_NAME}/keep/
mv /home/${USER_NAME}/.wine/drive_c/windows/mono/mono-2.0/lib/mono/gac/System.Drawing/4.0.0.0__b03f5f7f11d50a3a/System.Drawing.dll /home/${USER_NAME}/keep/
mv /home/${USER_NAME}/.wine/drive_c/windows/mono/mono-2.0/lib/mono/gac/Accessibility/4.0.0.0__b03f5f7f11d50a3a/Accessibility.dll /home/${USER_NAME}/keep/
mv /home/${USER_NAME}/.wine/drive_c/windows/mono/mono-2.0/lib/mono/gac/System.Configuration/4.0.0.0__b03f5f7f11d50a3a/System.Configuration.dll /home/${USER_NAME}/keep/
mv /home/${USER_NAME}/.wine/drive_c/windows/mono/mono-2.0/lib/mono/gac/Mono.Security/4.0.0.0__0738eb9f132ed756/Mono.Security.dll /home/${USER_NAME}/keep/
mv /home/${USER_NAME}/.wine/drive_c/windows/mono/mono-2.0/lib/mono/gac/System.Xml/4.0.0.0__b77a5c561934e089/System.Xml.dll /home/${USER_NAME}/keep/
mv /home/${USER_NAME}/.wine/drive_c/windows/mono/mono-2.0/lib/mono/gac/I18N/4.0.0.0__0738eb9f132ed756/I18N.dll /home/${USER_NAME}/keep/
mv /home/${USER_NAME}/.wine/drive_c/windows/mono/mono-2.0/lib/mono/gac/I18N.West/4.0.0.0__0738eb9f132ed756/I18N.West.dll /home/${USER_NAME}/keep/
rm -rf /home/${USER_NAME}/.wine/drive_c/windows/mono/mono-2.0/lib/mono/gac/*

mkdir -p /home/${USER_NAME}/.wine/drive_c/windows/mono/mono-2.0/lib/mono/gac/System/4.0.0.0__b77a5c561934e089/
mv /home/${USER_NAME}/keep/System.dll /home/${USER_NAME}/.wine/drive_c/windows/mono/mono-2.0/lib/mono/gac/System/4.0.0.0__b77a5c561934e089/

mkdir -p /home/${USER_NAME}/.wine/drive_c/windows/mono/mono-2.0/lib/mono/gac/System.Windows.Forms/4.0.0.0__b77a5c561934e089/
mv /home/${USER_NAME}/keep/System.Windows.Forms.dll /home/${USER_NAME}/.wine/drive_c/windows/mono/mono-2.0/lib/mono/gac/System.Windows.Forms/4.0.0.0__b77a5c561934e089/

mkdir -p /home/${USER_NAME}/.wine/drive_c/windows/mono/mono-2.0/lib/mono/gac/System.Drawing/4.0.0.0__b03f5f7f11d50a3a/
mv /home/${USER_NAME}/keep/System.Drawing.dll /home/${USER_NAME}/.wine/drive_c/windows/mono/mono-2.0/lib/mono/gac/System.Drawing/4.0.0.0__b03f5f7f11d50a3a/

mkdir -p /home/${USER_NAME}/.wine/drive_c/windows/mono/mono-2.0/lib/mono/gac/Accessibility/4.0.0.0__b03f5f7f11d50a3a/
mv /home/${USER_NAME}/keep/Accessibility.dll /home/${USER_NAME}/.wine/drive_c/windows/mono/mono-2.0/lib/mono/gac/Accessibility/4.0.0.0__b03f5f7f11d50a3a/

mkdir -p /home/${USER_NAME}/.wine/drive_c/windows/mono/mono-2.0/lib/mono/gac/System.Configuration/4.0.0.0__b03f5f7f11d50a3a/
mv /home/${USER_NAME}/keep/System.Configuration.dll /home/${USER_NAME}/.wine/drive_c/windows/mono/mono-2.0/lib/mono/gac/System.Configuration/4.0.0.0__b03f5f7f11d50a3a/

mkdir -p /home/${USER_NAME}/.wine/drive_c/windows/mono/mono-2.0/lib/mono/gac/Mono.Security/4.0.0.0__0738eb9f132ed756/
mv /home/${USER_NAME}/keep/Mono.Security.dll /home/${USER_NAME}/.wine/drive_c/windows/mono/mono-2.0/lib/mono/gac/Mono.Security/4.0.0.0__0738eb9f132ed756/

mkdir -p /home/${USER_NAME}/.wine/drive_c/windows/mono/mono-2.0/lib/mono/gac/System.Xml/4.0.0.0__b77a5c561934e089/
mv /home/${USER_NAME}/keep/System.Xml.dll /home/${USER_NAME}/.wine/drive_c/windows/mono/mono-2.0/lib/mono/gac/System.Xml/4.0.0.0__b77a5c561934e089/

mkdir -p /home/${USER_NAME}/.wine/drive_c/windows/mono/mono-2.0/lib/mono/gac/I18N/4.0.0.0__0738eb9f132ed756/
mv /home/${USER_NAME}/keep/I18N.dll /home/${USER_NAME}/.wine/drive_c/windows/mono/mono-2.0/lib/mono/gac/I18N/4.0.0.0__0738eb9f132ed756/

mkdir -p /home/${USER_NAME}/.wine/drive_c/windows/mono/mono-2.0/lib/mono/gac/I18N.West/4.0.0.0__0738eb9f132ed756/
mv /home/${USER_NAME}/keep/I18N.West.dll /home/${USER_NAME}/.wine/drive_c/windows/mono/mono-2.0/lib/mono/gac/I18N.West/4.0.0.0__0738eb9f132ed756/

rm -rf /home/${USER_NAME}/keep

cd /home/${USER_NAME}/.wine/drive_c/
find . -name *.sys -delete
find . -name *.drv -delete

cd ${WINE_INSTALL_PREFIX}
find . -name *.sys -delete
find . -name *.drv -delete
find . -name *.dll -size 1032c -delete
find . -name *.exe -size 1032c -delete




