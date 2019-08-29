{stdenv, fetchurl, cmake, flex, bison, openssl, libpcap, perl, zlib, file, curl
, geoip, gperftools, python, swig }:

stdenv.mkDerivation rec {
  version = "3.0.0-rc2";
  name = "zeek-${version}";
  src = fetchurl {
    url = "https://www.zeek.org/downloads/${name}.tar.gz";
    sha256 = "1a71d5b800d0a4c9699f6ef09bc36a9fefea0525a37de9e68abbcd95d9dbc101";
  };

  nativeBuildInputs = [ cmake flex bison file ];
  buildInputs = [ openssl libpcap perl zlib curl geoip gperftools python swig ];

  # Indicate where to install the python bits, since it can't put them in the "usual"
  # locations as those paths are read-only.
  cmakeFlags = [ "-DPY_MOD_INSTALL_DIR=${placeholder "out"}/${python.sitePackages}" ];
  
  enableParallelBuilding = true;

   configureFlags = [
     "--with-geoip=${geoip}"
  ];
  meta = with stdenv.lib; {
    description = "Powerful network analysis framework much different from a typical IDS";
    homepage = https://www.zeek.org/;
    license = licenses.bsd3;
    maintainers = with maintainers; [ pSub ];
    platforms = with platforms; linux;
  };
}
