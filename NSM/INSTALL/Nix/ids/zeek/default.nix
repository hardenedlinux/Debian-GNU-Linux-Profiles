{stdenv, fetchurl, cmake, flex, bison, openssl, libpcap, perl, zlib, file, curl
, geoip, gperftools, python, swig }:

stdenv.mkDerivation rec {
  name = "bro-2.6.1";
  src = fetchurl {
    url = "https://www.zeek.org/downloads/${name}.tar.gz"
    sha256 = "d9718b83fdae0c76eea5254a4b9470304c4d1d3778687de9a4fe0b5dffea521b";
  };

  nativeBuildInputs = [ cmake flex bison file ];
  buildInputs = [ openssl libpcap perl zlib curl geoip gperftools python swig ];

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
