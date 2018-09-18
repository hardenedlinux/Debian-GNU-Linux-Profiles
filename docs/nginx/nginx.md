
### This configuration gives A+ on ssllabs.com test and A+ on securityheaders.com

![ssllabs](https://github.com/hardenedlinux/Debian-GNU-Linux-Profiles/blob/master/docs/nginx/img/aplus.png)



###Features :

- [x] TLS configuration using ca-intermediate and fullchain files
- [x] OCSP Must Staple / OCSP stapling enabled
- [x] Modern ciphersuites (TLS-ECDHE-ECDSA-WITH-CHACHA20-POLY1305-SHA256 is prefered)
- [x] Security headers enabled :
	* Gives an example of Content-Security-Policy (CSP)
	* X-Frame Options
	* X-Content-Type Options
	* X-XSS Protection
	* Referrer Policy
	* HSTS

[nginx.conf](nginx.conf)
