@load base/protocols/http
@load base/protocols/ftp

redef HTTP::default_capture_password = T;
redef FTP::default_capture_password = T;