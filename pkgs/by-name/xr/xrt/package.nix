{
  lib,
  stdenv,
  fetchFromGitHub,
  python3Packages,
  cmake,
  pkg-config,
  removeReferencesTo,
  makeBinaryWrapper,
  boost,
  libdrm,
  ocl-icd,
  protobuf,
  rapidjson,
  opencl-headers,
  ncurses,
  openssl,
  curl,
  libuuid,
  libsystemtap,
  systemdLibs,
  bash,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "xrt";
  version = "2.21.75";

  src = fetchFromGitHub {
    owner = "Xilinx";
    repo = "XRT";
    tag = finalAttrs.version;
    fetchSubmodules = true;
    hash = "sha256-sujiSRZuIelhvUew7yeCfApAmp/Pf2+F38KO9cxI2HE=";
  };

  sourceRoot = "${finalAttrs.src.name}/src";

  postPatch = ''
    substituteInPlace python/pybind11/CMakeLists.txt \
      --replace-fail "/usr/bin/python3" "${lib.getExe python3Packages.python}"

    ## Correct reference to $lib (for module/shim)
    #substituteInPlace src/runtime_src/core/common/detail/linux/xilinx_xrt.h \
    #  --replace-fail "sfs::path(XRT_INSTALL_PREFIX);" "sfs::path(\"$lib\");"

    substituteInPlace CMake/icd.cmake \
      --replace-fail "/etc/OpenCL/vendors" "$out/etc/OpenCL/vendors"
    substituteInPlace CMake/dkms.cmake \
      --replace-fail 'XRT_DKMS_INSTALL_DIR "/usr/src/xrt' 'XRT_DKMS_INSTALL_DIR "'"$dkms/src/xrt"

    patchShebangs --build \
      runtime_src/core/common/aiebu/specification/spec_tool.py
  '';

  patches = [
    # Fixing tons of non-standard prefixes
    #./fix_install_path.patch
    #./aiebu_fix_install_path.patch

    #./fix_dynamic_loading.patch
  ];

  outputs = [
    "out"
    "dev"
    #"lib"
    ## kernel module source
    #"dkms"
  ];

  nativeBuildInputs = [
    cmake
    pkg-config
    removeReferencesTo
    makeBinaryWrapper
  ];

  buildInputs = [
    boost
    libdrm
    ocl-icd
    protobuf
    rapidjson
    opencl-headers
    ncurses
    openssl
    curl
    libuuid
    libsystemtap
    systemdLibs
    bash
    python3Packages.python
    python3Packages.pybind11
  ];

  strictDeps = true;

  cmakeFlags = [
    # they are expected to be relative
    (lib.cmakeFeature "CMAKE_INSTALL_BINDIR" "bin")
    (lib.cmakeFeature "CMAKE_INSTALL_INCLUDEDIR" "include")
    (lib.cmakeFeature "CMAKE_INSTALL_LIBDIR" "lib")
    #(lib.cmakeBool "XRT_SYSTEM_INSTALL" true)
    #(lib.cmakeFeature "XRT_DKMS_INSTALL_DIR" "${placeholder "out"}/src/xrt-${finalAttrs.version}")

    # Don't download dependencies
    (lib.cmakeBool "XRT_UPSTREAM_DEBIAN" true)
    #(lib.cmakeBool "XRT_AIE_BUILD" true)
    #(lib.cmakeBool "XRT_ALVEO" true) # when true: CMake/version.cmake sets XRT_DKMS_INSTALL_DIR...
    # build/build.sh: "-npu, -alveo, -base are mutually exclusive"
    # https://github.com/Xilinx/XRT/blob/4eb1f4392a012b4e6eca759762389c612537f7c7/build/build.sh#L276
    (lib.cmakeBool "XRT_NPU" true)
    (lib.cmakeBool "XRT_ENABLE_WERROR" false)
    (lib.cmakeFeature "CMAKE_BUILD_TYPE" "Release")
  ];

  postInstall = ''
    #mkdir -p $dkms
    #mv $out/src/* $dkms/
    #rm -r $out/src
    #rm -r $out/license
    #rm $out/version.json
  '';

  postFixup = ''
    ## Fix path in auto-generated cmake file
    #substituteInPlace $dev/lib/cmake/{AIEBU/aiebu-targets.cmake,XRT/xrt-targets.cmake} \
    #  --replace-fail "set(_IMPORT_PREFIX \"$out\")" "set(_IMPORT_PREFIX \"$dev\")"

    #substituteInPlace $out/bin/xbtop \
    #  --replace-fail "python3" "${lib.getExe python3Packages.python}" \
    #  --replace-fail "../python" "../share/XRT/python"
  '';

  meta = {
    description = "Run Time for AIE and FPGA based platforms";
    longDescription = ''
      Xilinx Runtime (XRT) is implemented as as a combination
      of userspace and kernel driver components. XRT supports
      both PCIe based boards like U30, U50, U200, U250, U280,
      VCK190 and MPSoC based embedded platforms. XRT provides
      a standardized software interface to Xilinx FPGA. The
      key user APIs are defined in xrt.h header file.
    '';
    homepage = "https://xilinx.github.io/XRT";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ aleksana ];
    platforms = lib.platforms.linux;
  };
})
