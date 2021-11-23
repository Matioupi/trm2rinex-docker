#
# This Dockerfile build a small docker image packaging a minimal wine setup
# that allows running the Trimble "convertToRinex" utility in command line
# mode on an x86 Linux based system
#
# Official Trimble tool page : https://geospatial.trimble.com/trimble-rinex-converter
#
# Tested with the following versions of trimble required binaries :
# https://dl.trimble.com/osg/survey/gpsconfigfiles/21.9.27/trimblecfgupdate.exe
# https://trl.trimble.com/dscgi/ds.py/Get/File-869391/convertToRinex314.msi
#
# if still available at time when you'll build the image, the binaries will be
# automatically downloaded. Otherwise you may need to get the manually from
# another source and modify the lines 213 & 214 of this file accordingly
#
# The image build has 3 steps :
#
# - stage 1 : a minimal Wine 6.22 build (from source)
# - stage 2 : download and installation of the Trimble binaries
#           : cleanup of the filesystem to have a light final stage image
# - stage 3 : build the final stage image
#
# Author : mathieu.peyrega@gmail.com
#
# Variables that can be modified to match you needs are at the beginning of dockerfile :
# USER_NAME   : name of the non root user inside the container
# USER_PASSWD : password of that user
# USER_UID    : id of the user inside the container which may be matched to the id of user
#               on docker host in order to remove file access persmission issues
# USER_GID    : same idea as previous with group id
# MAKE_JN     : number of build cores used to compile Wine. Adapt to the computer where
#               you'll build the image
#
# DELAY_BETWEEN_INSTALL : this value in seconds is used to wait between some wine calls at
#                         stage2 whren installing the Windows binaries. I noticed a wait is
#                         needed in order to let wineserver and other wine process terminate
#                         cleanly. You may need to increase this value on slow machines
#
# For intellectual property reasons, unless Trimble provides me with a written authorization
# to do so, I will not provide a pre-build docker image because it would contain the Trimble
# binaries and I'm probably not allowed to do so. Even if no specific licence terms are
# provided at install stage
#

ARG BASE_IMAGE="ubuntu"
ARG TAG="focal"
ARG WINE_INSTALL_PREFIX="/opt/wine"
ARG WINE_TAG="986254d6c17ee1e5fb3aed6effcf2766bf1e787e"
ARG USER_NAME=trm2rinex
ARG USER_PASSWD=trm2rinex
ARG USER_UID=1000
ARG USER_GID=100
ARG MAKE_JN=8
ARG DELAY_BETWEEN_INSTALL=10

#
# Stage 1 : minimal Wine buid
#         : provided tag is the 6.22 devel-branch release tag
#

FROM ${BASE_IMAGE}:${TAG} AS stage1
SHELL ["/bin/bash", "-c"]
ARG WINE_INSTALL_PREFIX
ARG WINE_TAG
ARG USER_NAME
ARG USER_PASSWD
ARG USER_UID
ARG USER_GID
ARG MAKE_JN

# Install prerequisites
RUN dpkg --add-architecture i386 \
    && apt-get update \
    && DEBIAN_FRONTEND="noninteractive" apt-get full-upgrade -y \
    && DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends \    
        apt-transport-https \
        ca-certificates \
        cabextract \
        sudo \
        software-properties-common \
        git \
        gpg-agent \
        tzdata \
        unzip \        
        wget \
        winbind \        
        build-essential flex bison python3 git gcc-multilib g++-multilib \
    && DEBIAN_FRONTEND="noninteractive" apt-get clean -y \        
    && rm -rf /var/lib/apt/lists/* 
  
# Checkout Wine Release 6.22    
RUN git clone git://source.winehq.org/git/wine.git ~/wine-dirs/wine-source \
    && cd ~/wine-dirs/wine-source \
    && git checkout ${WINE_TAG}

# Install more build prerequisites
RUN dpkg --add-architecture i386 \
    && apt-get update \
    && DEBIAN_FRONTEND="noninteractive" apt-get full-upgrade -y \
    && DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends \    
	libpng-dev:i386 libtiff-dev:i386 libunwind-dev:i386 libxml2-dev:i386 \
	libxslt1-dev:i386 libjpeg-turbo8-dev:i386 liblcms2-dev:i386 \
    && DEBIAN_FRONTEND="noninteractive" apt-get clean -y \        
    && rm -rf /var/lib/apt/lists/* 

#
# Configuration step :
# I tried to disable as many options as possible while not preventing convertToRinex.exe to install and run
# in command line mode.
# This is mostly the result of an tedious trial & error iterative process
#

RUN cd ~/wine-dirs/wine-source \
&& ./configure --prefix=${WINE_INSTALL_PREFIX} --disable-tests --without-capi --without-alsa --without-gphoto --without-hal --without-dbus --without-oss --without-quicktime --without-v4l2 --without-mingw --without-gstreamer --without-coreaudio --without-cups --without-sane --without-udev --without-xrandr --without-xinerama --without-pcap --without-krb5 --without-openal --without-opencl --without-opengl --without-pulse --without-vkd3d --without-vulkan --without-gssapi --without-x --without-usb --without-fontconfig --without-freetype --without-osmesa --without-xcomposite --without-xcursor --without-xfixes --without-xxf86vm \
--disable-sc --disable-services --disable-xpsprint --disable-xpssvcs \
--disable-powershell --disable-wuauserv --disable-wusa \
--disable-progman \
--disable-winemine --disable-winedbg --disable-winegcc --disable-winemaker --disable-winebuild --disable-winedump \
--disable-taskmgr --disable-wmplayer --disable-wordpad --disable-notepad --disable-write --disable-msinfo32 \
--disable-rpcss \
--disable-winealsa_drv --disable-dmusic --disable-dmusic32 --disable-dpvoice --disable-winepulse_drv --disable-winecoreaudio_drv --disable-wineoss_drv \
--disable-plugplay --disable-progman  \
--disable-windows_media_devices --disable-windows_media_speech \
--disable-wineandroid_drv \
--disable-powrprof --disable-printui --disable-scsiport_sys --disable-serialui --disable-twain_32 --disable-usbd_sys --disable-wineusb_sys \
--disable-d3d8 --disable-d3d8thk --disable-d3d9 --disable-d3d10 --disable-d3d10_1 --disable-d3d10core --disable-d3d11 --disable-d3d12 \
--disable-windowscodecs --disable-windowscodecsext \
--disable-winejoystick_drv --disable-joy_cpl --disable-irprops_cpl \
--disable-windows_gaming_input --disable-windows_media_devices --disable-windows_media_speech \
--disable-wmphoto --disable-wmp --disable-wmvcore --disable-dxdiag --disable-winusb \
--disable-vulkan_1 --disable-wined3d --disable-winevulkan \
--disable-eject -disable-virtdisk \
--disable-bluetoothapis --disable-photometadatahandler \
--disable-d3drm --disable-drmclien --disable-msdrm \
--disable-schtasks --disable-inetcpl_cpl \
-disable-d3dx10_33 --disable-d3dx10_34 --disable-d3dx10_35 --disable-d3dx10_36 --disable-d3dx10_37 --disable-d3dx10_38 --disable-d3dx10_39 --disable-d3dx10_40 --disable-d3dx10_41 --disable-d3dx11_42 --disable-d3dx11_43 --disable-d3dx9_24 --disable-d3dx9_25 --disable-d3dx9_26 --disable-d3dx9_27 --disable-d3dx9_28 --disable-d3dx9_29 --disable-d3dx9_30 --disable-d3dx9_31 --disable-d3dx9_32 --disable-d3dx9_33 --disable-d3dx9_34 --disable-d3dx9_35 --disable-d3dx9_36 --disable-d3dx9_37 --disable-d3dx9_38 --disable-d3dx9_39 --disable-d3dx9_40 --disable-d3dx9_41 --disable-d3dx9_42 --disable-d3dx9_43 --disable-d3dxof   --disable-d3dcompiler_33 --disable-d3dcompiler_34 --disable-d3dcompiler_35 --disable-d3dcompiler_36 --disable-d3dcompiler_37 --disable-d3dcompiler_38 --disable-d3dcompiler_39 --disable-d3dcompiler_40 --disable-d3dcompiler_41 --disable-d3dcompiler_42 --disable-d3dcompiler_43 --disable-d3dcompiler_46 --disable-d3dcompiler_47 --disable-d3dim --disable-d3dim700 --disable-x3daudio1_0 --disable-x3daudio1_1 --disable-x3daudio1_2 --disable-x3daudio1_3 --disable-x3daudio1_4 --disable-x3daudio1_5 --disable-x3daudio1_6 --disable-x3daudio1_7 --disable-xactengine2_0 --disable-xactengine2_4 --disable-xactengine2_7 --disable-xactengine2_9 --disable-xactengine3_0 --disable-xactengine3_1 --disable-xactengine3_2 --disable-xactengine3_3 --disable-xactengine3_4 --disable-xactengine3_5 --disable-xactengine3_6 --disable-xactengine3_7 --disable-xapofx1_1 --disable-xapofx1_2 --disable-xapofx1_3 --disable-xapofx1_4 --disable-xapofx1_5 --disable-xaudio2_0 --disable-xaudio2_1 --disable-xaudio2_2 --disable-xaudio2_3 --disable-xaudio2_4 --disable-xaudio2_5 --disable-xaudio2_6 --disable-xaudio2_7 --disable-xaudio2_8 --disable-xaudio2_9 \
--disable-net --disable-netsh --disable-netstat --disable-ipconfig --disable-dism --disable-clock --disable-arp \
--disable-jpeg --disable-gsm --disable-dxerr8 --disable-dxerr9 \
--disable-msvcp100 --disable-msvcp110 --disable-msvcp120 --disable-msvcp120_app --disable-msvcp60 --disable-msvcp70 --disable-msvcp71 --disable-msvcp80 --disable-msvcp90 --disable-msvcr100 --disable-msvcr110 --disable-msvcr120 --disable-msvcr120_app --disable-msvcr70 --disable-msvcr71 --disable-msvcr80 --disable-msvcr90 --disable-msvcrt20 --disable-msvcrtd \
--disable-opencl --disable-opengl32 --disable-openal32 --disable-pwrshplugin --disable-windows_devices_enumeration --disable-winhlp32 \
--enable-start --disable-ping --disable-systeminfo --disable-taskkill --disable-robocopy  \
--disable-msgsm32_acm --disable-bthprops_cpl \
--disable-explorer --disable-iexplore --enable-server \
--disable-dx8vb --disable-dxdiagn --disable-dxgi --disable-dxtrans --disable-dxva2 \
--disable-ext_ms_win_authz_context_l1_1_0 --disable-ext_ms_win_domainjoin_netjoin_l1_1_0 --disable-ext_ms_win_dwmapi_ext_l1_1_0 --disable-ext_ms_win_gdi_dc_create_l1_1_0 --disable-ext_ms_win_gdi_dc_create_l1_1_1 --disable-ext_ms_win_gdi_dc_l1_2_0 --disable-ext_ms_win_gdi_devcaps_l1_1_0 --disable-ext_ms_win_gdi_draw_l1_1_0 --disable-ext_ms_win_gdi_draw_l1_1_1 --disable-ext_ms_win_gdi_font_l1_1_0 --disable-ext_ms_win_gdi_font_l1_1_1 --disable-ext_ms_win_gdi_render_l1_1_0 --disable-ext_ms_win_kernel32_package_current_l1_1_0 --disable-ext_ms_win_kernel32_package_l1_1_1 --disable-ext_ms_win_ntuser_dialogbox_l1_1_0 --disable-ext_ms_win_ntuser_draw_l1_1_0 --disable-ext_ms_win_ntuser_gui_l1_1_0 --disable-ext_ms_win_ntuser_gui_l1_3_0 --disable-ext_ms_win_ntuser_keyboard_l1_3_0 --disable-ext_ms_win_ntuser_message_l1_1_0 --disable-ext_ms_win_ntuser_message_l1_1_1 --disable-ext_ms_win_ntuser_misc_l1_1_0 --disable-ext_ms_win_ntuser_misc_l1_2_0 --disable-ext_ms_win_ntuser_misc_l1_5_1 --disable-ext_ms_win_ntuser_mouse_l1_1_0 --disable-ext_ms_win_ntuser_private_l1_1_1 --disable-ext_ms_win_ntuser_private_l1_3_1 --disable-ext_ms_win_ntuser_rectangle_ext_l1_1_0 --disable-ext_ms_win_ntuser_uicontext_ext_l1_1_0 --disable-ext_ms_win_ntuser_window_l1_1_0 --disable-ext_ms_win_ntuser_window_l1_1_1 --disable-ext_ms_win_ntuser_window_l1_1_4 --disable-ext_ms_win_ntuser_windowclass_l1_1_0 --disable-ext_ms_win_ntuser_windowclass_l1_1_1 --disable-ext_ms_win_oleacc_l1_1_0 --disable-ext_ms_win_ras_rasapi32_l1_1_0 --disable-ext_ms_win_rtcore_gdi_devcaps_l1_1_0 --disable-ext_ms_win_rtcore_gdi_object_l1_1_0 --disable-ext_ms_win_rtcore_gdi_rgn_l1_1_0 --disable-ext_ms_win_rtcore_ntuser_cursor_l1_1_0 --disable-ext_ms_win_rtcore_ntuser_dc_access_l1_1_0 --disable-ext_ms_win_rtcore_ntuser_dpi_l1_1_0 --disable-ext_ms_win_rtcore_ntuser_dpi_l1_2_0 --disable-ext_ms_win_rtcore_ntuser_rawinput_l1_1_0 --disable-ext_ms_win_rtcore_ntuser_syscolors_l1_1_0 --disable-ext_ms_win_rtcore_ntuser_sysparams_l1_1_0 --disable-ext_ms_win_security_credui_l1_1_0 --disable-ext_ms_win_security_cryptui_l1_1_0 --disable-ext_ms_win_shell_comctl32_init_l1_1_0 --disable-ext_ms_win_shell_comdlg32_l1_1_0 --disable-ext_ms_win_shell_shell32_l1_2_0 --disable-ext_ms_win_uxtheme_themes_l1_1_0 \
--disable-ipconfig --disable-sane_ds --disable-winemac_drv --enable-wininet \
--disable-acledit --disable-aclui --disable-dhcpcsvc --disable-dhcpcsvc6 --disable-tapi32 \
--disable-api_ms_win_security_audit_l1_1_1 --disable-api_ms_win_security_base_l1_1_0 --disable-api_ms_win_security_base_l1_2_0 --disable-api_ms_win_security_base_private_l1_1_1 --disable-api_ms_win_security_credentials_l1_1_0 --disable-api_ms_win_security_cryptoapi_l1_1_0 --disable-api_ms_win_security_grouppolicy_l1_1_0 --disable-api_ms_win_security_lsalookup_l1_1_0 --disable-api_ms_win_security_lsalookup_l1_1_1 --disable-api_ms_win_security_lsalookup_l2_1_0 --disable-api_ms_win_security_lsalookup_l2_1_1 --disable-api_ms_win_security_lsapolicy_l1_1_0 --disable-api_ms_win_security_provider_l1_1_0 --disable-api_ms_win_security_sddl_l1_1_0 --disable-api_ms_win_security_systemfunctions_l1_1_0 --disable-api_ms_win_service_core_l1_1_0 --disable-api_ms_win_service_core_l1_1_1 --disable-api_ms_win_service_management_l1_1_0 --disable-api_ms_win_service_management_l2_1_0 --disable-api_ms_win_service_private_l1_1_1 --disable-api_ms_win_service_winsvc_l1_1_0 --disable-api_ms_win_service_winsvc_l1_2_0 \
--disable-api_ms_win_downlevel_advapi32_l1_1_0 --disable-api_ms_win_downlevel_advapi32_l2_1_0 --disable-api_ms_win_downlevel_kernel32_l2_1_0 --disable-api_ms_win_downlevel_normaliz_l1_1_0 --disable-api_ms_win_downlevel_ole32_l1_1_0 --disable-api_ms_win_downlevel_shell32_l1_1_0 --disable-api_ms_win_downlevel_shlwapi_l1_1_0 --disable-api_ms_win_downlevel_shlwapi_l2_1_0 --disable-api_ms_win_downlevel_user32_l1_1_0 --disable-api_ms_win_downlevel_version_l1_1_0 --disable-api_ms_win_dx_d3dkmt_l1_1_0 --disable-api_ms_win_eventing_classicprovider_l1_1_0 --disable-api_ms_win_eventing_consumer_l1_1_0 --disable-api_ms_win_eventing_controller_l1_1_0 --disable-api_ms_win_eventing_legacy_l1_1_0 --disable-api_ms_win_eventing_provider_l1_1_0 --disable-api_ms_win_eventlog_legacy_l1_1_0 --disable-api_ms_win_gaming_tcui_l1_1_0 --disable-api_ms_win_gdi_dpiinfo_l1_1_0 --disable-api_ms_win_mm_joystick_l1_1_0 \
--disable-wmc --disable-wrc --disable-winmgmt --disable-wmic --disable-winebrowser \
--without-xinput --without-xinput2 --without-xshape --without-xshm \
--enable-bcrypt --enable-crypt32 \
--disable-ieframe --disable-ieproxy \
--disable-wlanapi --disable-wlanui \
--disable-netio_sys --disable-widl --disable-jscript

#
#  Installation & initial cleanup inside stage 1
#

RUN cd ~/wine-dirs/wine-source \
    && make -j${MAKE_JN} \
    && make install

RUN strip -s ${WINE_INSTALL_PREFIX}/lib/wine/i386-windows/* \
    && strip -s ${WINE_INSTALL_PREFIX}/lib/wine/i386-unix/* \
    && strip -s ${WINE_INSTALL_PREFIX}/bin/wine \
                ${WINE_INSTALL_PREFIX}/bin/wineserver \
                ${WINE_INSTALL_PREFIX}/bin/wine-preloader \
    && rm -rf ${WINE_INSTALL_PREFIX}/include \
    && rm -rf ${WINE_INSTALL_PREFIX}/lib/wine/i386-unix/*.a \
    && rm -rf ${WINE_INSTALL_PREFIX}/lib/wine/i386-windows/*.a \
    && rm -rf ${WINE_INSTALL_PREFIX}/share/man

#
# Stage 2 : copy/install wine from stage1
#           download and install the binary package from Trimble website
#           cleanup filesystem as much as possible
#
   
FROM ${BASE_IMAGE}:${TAG} as stage2
ARG WINE_INSTALL_PREFIX
ARG USER_NAME
ARG USER_PASSWD
ARG USER_UID
ARG USER_GID
ARG DELAY_BETWEEN_INSTALL
ENV PATH="${WINE_INSTALL_PREFIX}/bin:${PATH}"
ENV WINEDEBUG=-all,-err
SHELL ["/bin/bash", "-c"]

COPY --from=stage1 ${WINE_INSTALL_PREFIX} ${WINE_INSTALL_PREFIX}

# Install prerequisites
RUN dpkg --add-architecture i386 \
    && apt-get update \
    && DEBIAN_FRONTEND="noninteractive" apt-get full-upgrade -y \
    && DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends \
        libc6-x32 libx32gcc1 lib32stdc++6 \
        apt-transport-https \
        ca-certificates \
        wget \
        sudo \
        nano \
    && DEBIAN_FRONTEND="noninteractive" apt-get clean -y \        
    && rm -rf /var/lib/apt/lists/* 
       
RUN ldconfig

# Download mono installer
COPY download_mono.sh /tmp/download_mono.sh

ADD --chown=${USER_UID}:${USER_GID} https://dl.trimble.com/osg/survey/gpsconfigfiles/21.9.27/trimblecfgupdate.exe /tmp
ADD --chown=${USER_UID}:${USER_GID} https://trl.trimble.com/dscgi/ds.py/Get/File-869391/convertToRinex314.msi /tmp

RUN chmod 644 /tmp/download_mono.sh \
    && /tmp/download_mono.sh "$([[ "$(${WINE_INSTALL_PREFIX}/bin/wine --version)" =~ .*([0-9]{1}.[0-9]{2}) ]] &&  echo ${BASH_REMATCH[1]})" 
    
RUN useradd --shell /bin/bash --uid "${USER_UID}" --gid "${USER_GID}" --password "$(openssl passwd -1 -salt "$(openssl rand -base64 6)" ${USER_PASSWD})" --create-home --home-dir "/home/${USER_NAME}" "${USER_NAME}" \
    && usermod -aG sudo "${USER_NAME}"

USER ${USER_NAME}
RUN wine /tmp/trimblecfgupdate.exe /s /x /b"Z:\\tmp" /v"/qn" 2>/dev/null \
    && sleep ${DELAY_BETWEEN_INSTALL} \
    && wine cmd /c "msiexec /i Z:\\tmp\\TrimbleCFGUpdate.msi ProductLanguage=\"1033\" /quiet" 2>/dev/null \
    && sleep ${DELAY_BETWEEN_INSTALL} \
    && wine cmd /c "msiexec /i Z:\\tmp\\convertToRinex314.msi ProductLanguage=\"1033\" /quiet" 2>/dev/null

USER root
COPY clean.sh /home/${USER_NAME}/clean.sh
RUN chmod 644 /home/${USER_NAME}/clean.sh
RUN rm -rf /home/${USER_NAME}/.wine/drive_c/windows/Installer \
    && rm -rf /tmp/* \
    && /home/${USER_NAME}/clean.sh ${USER_NAME} ${WINE_INSTALL_PREFIX}

#
# Stage 3 : Final stage : use the minimal build filesystem in one step to get
#           a small image size
#

FROM ${BASE_IMAGE}:${TAG}
ARG WINE_INSTALL_PREFIX
ARG USER_NAME
ARG USER_PASSWD
ARG USER_UID
ARG USER_GID
ENV PATH="${WINE_INSTALL_PREFIX}/bin:${PATH}"
ENV WINEDEBUG=-all,-err
SHELL ["/bin/bash", "-c"]

COPY --from=stage2 ${WINE_INSTALL_PREFIX} ${WINE_INSTALL_PREFIX}

# Install prerequisites
RUN dpkg --add-architecture i386 \
    && apt-get update \
    && DEBIAN_FRONTEND="noninteractive" apt-get full-upgrade -y \
    && DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends \
        apt-transport-https \
        ca-certificates \    
        libc6-x32  lib32stdc++6 \
        sudo \
        nano \        
    && useradd --shell /bin/bash --uid ${USER_UID} --gid ${USER_GID} --password "$(openssl passwd -1 -salt "$(openssl rand -base64 6)" ${USER_PASSWD})" --create-home --home-dir /home/${USER_NAME} ${USER_NAME} \
    && usermod -aG sudo ${USER_NAME} \
    && DEBIAN_FRONTEND="noninteractive" apt-get clean -y \        
    && rm -rf /var/lib/apt/lists/* 
      
COPY entrypoint.sh /usr/bin/entrypoint
RUN chmod 644 /usr/bin/entrypoint
COPY --from=stage2 --chown=${USER_UID}:${USER_GID} /home/${USER_NAME}/.wine /home/${USER_NAME}/.wine

USER ${USER_NAME}
ENTRYPOINT ["/usr/bin/entrypoint"]

