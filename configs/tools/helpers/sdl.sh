#!/bin/bash
# configs/tools/helpers/sdl2.sh
# Prebuild arg translator for SDL2: translates --no-audio, --static, etc.
# Loaded automatically by helper_loader.sh when using kosaio * sdl2

KOSAIO_TRANSLATED_ARGS=()

function kosaio_translate_sdl_args() {
	KOSAIO_TRANSLATED_ARGS=()
	local build_system="${1:?}"
	shift

	for arg in "$@"; do
		[ "$arg" == "--" ] && continue
		case "$arg" in
			--no-audio|--disable-audio)
				if [ "$build_system" == "configure" ]; then
					KOSAIO_TRANSLATED_ARGS+=("--disable-audio")
				else
					KOSAIO_TRANSLATED_ARGS+=("-DSDL_AUDIO=OFF")
				fi
				;;
			--enable-audio)
				if [ "$build_system" == "configure" ]; then
					KOSAIO_TRANSLATED_ARGS+=("--enable-audio")
				else
					KOSAIO_TRANSLATED_ARGS+=("-DSDL_AUDIO=ON")
				fi
				;;
			--no-video|--disable-video)
				if [ "$build_system" == "configure" ]; then
					KOSAIO_TRANSLATED_ARGS+=("--disable-video")
				else
					KOSAIO_TRANSLATED_ARGS+=("-DSDL_VIDEO=OFF")
				fi
				;;
			--enable-video)
				if [ "$build_system" == "configure" ]; then
					KOSAIO_TRANSLATED_ARGS+=("--enable-video")
				else
					KOSAIO_TRANSLATED_ARGS+=("-DSDL_VIDEO=ON")
				fi
				;;
			--no-joystick|--disable-joystick)
				if [ "$build_system" == "configure" ]; then
					KOSAIO_TRANSLATED_ARGS+=("--disable-joystick")
				else
					KOSAIO_TRANSLATED_ARGS+=("-DSDL_JOYSTICK=OFF")
				fi
				;;
			--enable-joystick)
				if [ "$build_system" == "configure" ]; then
					KOSAIO_TRANSLATED_ARGS+=("--enable-joystick")
				else
					KOSAIO_TRANSLATED_ARGS+=("-DSDL_JOYSTICK=ON")
				fi
				;;
			--no-haptic|--disable-haptic)
				if [ "$build_system" == "configure" ]; then
					KOSAIO_TRANSLATED_ARGS+=("--disable-haptic")
				else
					KOSAIO_TRANSLATED_ARGS+=("-DSDL_HAPTIC=OFF")
				fi
				;;
			--enable-haptic)
				if [ "$build_system" == "configure" ]; then
					KOSAIO_TRANSLATED_ARGS+=("--enable-haptic")
				else
					KOSAIO_TRANSLATED_ARGS+=("-DSDL_HAPTIC=ON")
				fi
				;;
			--no-opengl|--disable-opengl)
				if [ "$build_system" == "configure" ]; then
					KOSAIO_TRANSLATED_ARGS+=("--disable-opengl")
				else
					KOSAIO_TRANSLATED_ARGS+=("-DSDL_OPENGL=OFF")
				fi
				;;
			--enable-opengl)
				if [ "$build_system" == "configure" ]; then
					KOSAIO_TRANSLATED_ARGS+=("--enable-opengl")
				else
					KOSAIO_TRANSLATED_ARGS+=("-DSDL_OPENGL=ON")
				fi
				;;
			--no-pthreads|--disable-pthreads)
				if [ "$build_system" == "configure" ]; then
					KOSAIO_TRANSLATED_ARGS+=("--disable-pthreads")
				else
					KOSAIO_TRANSLATED_ARGS+=("-DSDL_PTHREADS=OFF")
				fi
				;;
			--enable-pthreads)
				if [ "$build_system" == "configure" ]; then
					KOSAIO_TRANSLATED_ARGS+=("--enable-pthreads")
				else
					KOSAIO_TRANSLATED_ARGS+=("-DSDL_PTHREADS=ON")
				fi
				;;
			--no-timers|--disable-timers)
				if [ "$build_system" == "configure" ]; then
					KOSAIO_TRANSLATED_ARGS+=("--disable-timers")
				else
					KOSAIO_TRANSLATED_ARGS+=("-DSDL_TIMER_UNIX=OFF")
				fi
				;;
			--enable-timers)
				if [ "$build_system" == "configure" ]; then
					KOSAIO_TRANSLATED_ARGS+=("--enable-timers")
				else
					KOSAIO_TRANSLATED_ARGS+=("-DSDL_TIMER_UNIX=ON")
				fi
				;;
			--no-render|--disable-render)
				if [ "$build_system" == "configure" ]; then
					KOSAIO_TRANSLATED_ARGS+=("--disable-render")
				else
					KOSAIO_TRANSLATED_ARGS+=("-DSDL_RENDER=OFF")
				fi
				;;
			--enable-render)
				if [ "$build_system" == "configure" ]; then
					KOSAIO_TRANSLATED_ARGS+=("--enable-render")
				else
					KOSAIO_TRANSLATED_ARGS+=("-DSDL_RENDER=ON")
				fi
				;;
			--no-events|--disable-events)
				if [ "$build_system" == "configure" ]; then
					KOSAIO_TRANSLATED_ARGS+=("--disable-events")
				else
					KOSAIO_TRANSLATED_ARGS+=("-DSDL_EVENTS=OFF")
				fi
				;;
			--enable-events)
				if [ "$build_system" == "configure" ]; then
					KOSAIO_TRANSLATED_ARGS+=("--enable-events")
				else
					KOSAIO_TRANSLATED_ARGS+=("-DSDL_EVENTS=ON")
				fi
				;;
			--no-power|--disable-power)
				if [ "$build_system" == "configure" ]; then
					KOSAIO_TRANSLATED_ARGS+=("--disable-power")
				else
					KOSAIO_TRANSLATED_ARGS+=("-DSDL_POWER=OFF")
				fi
				;;
			--enable-power)
				if [ "$build_system" == "configure" ]; then
					KOSAIO_TRANSLATED_ARGS+=("--enable-power")
				else
					KOSAIO_TRANSLATED_ARGS+=("-DSDL_POWER=ON")
				fi
				;;
			--no-sensor|--disable-sensor)
				KOSAIO_TRANSLATED_ARGS+=("-DSDL_SENSOR=OFF")
				;;
			--enable-sensor)
				KOSAIO_TRANSLATED_ARGS+=("-DSDL_SENSOR=ON")
				;;
			--no-hidapi|--disable-hidapi)
				KOSAIO_TRANSLATED_ARGS+=("-DSDL_HIDAPI=OFF")
				;;
			--enable-hidapi)
				KOSAIO_TRANSLATED_ARGS+=("-DSDL_HIDAPI=ON")
				;;
			--no-filesystem|--disable-filesystem)
				if [ "$build_system" == "configure" ]; then
					KOSAIO_TRANSLATED_ARGS+=("--disable-filesystem")
				else
					KOSAIO_TRANSLATED_ARGS+=("-DSDL_FILESYSTEM=OFF")
				fi
				;;
			--enable-filesystem)
				if [ "$build_system" == "configure" ]; then
					KOSAIO_TRANSLATED_ARGS+=("--enable-filesystem")
				else
					KOSAIO_TRANSLATED_ARGS+=("-DSDL_FILESYSTEM=ON")
				fi
				;;
			--no-tests|--disable-tests)
				if [ "$build_system" == "configure" ]; then
					KOSAIO_TRANSLATED_ARGS+=("--disable-tests")
				else
					KOSAIO_TRANSLATED_ARGS+=("-DSDL_TESTS=OFF")
				fi
				;;
			--enable-tests)
				if [ "$build_system" == "configure" ]; then
					KOSAIO_TRANSLATED_ARGS+=("--enable-tests")
				else
					KOSAIO_TRANSLATED_ARGS+=("-DSDL_TESTS=ON")
				fi
				;;
			--static|--no-shared|--disable-shared)
				if [ "$build_system" == "configure" ]; then
					KOSAIO_TRANSLATED_ARGS+=("--disable-shared")
				else
					KOSAIO_TRANSLATED_ARGS+=("-DSDL_SHARED=OFF")
				fi
				;;
			--enable-shared)
				if [ "$build_system" == "configure" ]; then
					KOSAIO_TRANSLATED_ARGS+=("--enable-shared")
				else
					KOSAIO_TRANSLATED_ARGS+=("-DSDL_SHARED=ON")
				fi
				;;
			--no-gpu|--disable-gpu)
				KOSAIO_TRANSLATED_ARGS+=("-DSDL_GPU=OFF")
				;;
			--enable-gpu)
				KOSAIO_TRANSLATED_ARGS+=("-DSDL_GPU=ON")
				;;
			--no-camera|--disable-camera)
				KOSAIO_TRANSLATED_ARGS+=("-DSDL_CAMERA=OFF")
				;;
			--enable-camera)
				KOSAIO_TRANSLATED_ARGS+=("-DSDL_CAMERA=ON")
				;;
			--no-dialog|--disable-dialog)
				KOSAIO_TRANSLATED_ARGS+=("-DSDL_DIALOG=OFF")
				;;
			--enable-dialog)
				KOSAIO_TRANSLATED_ARGS+=("-DSDL_DIALOG=ON")
				;;
			--no-tray|--disable-tray)
				KOSAIO_TRANSLATED_ARGS+=("-DSDL_TRAY=OFF")
				;;
			--enable-tray)
				KOSAIO_TRANSLATED_ARGS+=("-DSDL_TRAY=ON")
				;;
			--no-sh4zam|--disable-sh4zam)
				KOSAIO_TRANSLATED_ARGS+=("-DSDL_SH4ZAM=OFF")
				;;
			--enable-sh4zam)
				KOSAIO_TRANSLATED_ARGS+=("-DSDL_SH4ZAM=ON")
				;;
			--no-vulkan|--disable-vulkan)
				KOSAIO_TRANSLATED_ARGS+=("-DSDL_VULKAN=OFF")
				;;
			--enable-vulkan)
				KOSAIO_TRANSLATED_ARGS+=("-DSDL_VULKAN=ON")
				;;
			--no-openvr|--disable-openvr)
				KOSAIO_TRANSLATED_ARGS+=("-DSDL_OPENVR=OFF")
				;;
			--enable-openvr)
				KOSAIO_TRANSLATED_ARGS+=("-DSDL_OPENVR=ON")
				;;
			--no-render-gpu|--disable-render-gpu)
				KOSAIO_TRANSLATED_ARGS+=("-DSDL_RENDER_GPU=OFF")
				;;
			--enable-render-gpu)
				KOSAIO_TRANSLATED_ARGS+=("-DSDL_RENDER_GPU=ON")
				;;
			--gpf-settings)
				KOSAIO_TRANSLATED_ARGS+=( \
					-DSDL_PTHREADS=ON -DSDL_TIMER_UNIX=ON \
					-DSDL_OPENGL=ON -DSDL_HAPTIC=ON \
					-DSDL_TESTS=OFF \
				)
				;;
			*)
				KOSAIO_TRANSLATED_ARGS+=("$arg")
				;;
		esac
	done
}
