安全 -- 上传、访问，均要求验证token

快速 -- 纯lua实现、独立于业务（jvm、php、python）、发挥nginx sendfile特性

分布式 -- 支持fastDFS存储

借助nginx的特性，任何改动、部署，无缝热重启!!!


业务通过私有token接口申请上传权限，后，业务凭借token向upload接口上传文件，校验通过后直接向dfs写入文件，并返回文件访问路径；

为了防止文件的非法访问，通过get接口访问文件时，同样需要先获取token。


高级特性持续完善中!!!


requirements

    fastdfs-nginx-module
    lua-nginx-module


system requirements

    nginx 1.12.x
    lua 5.1+
    fastDFS 5.12+


configure

configure arguments: --prefix=/usr/share/nginx --sbin-path=/usr/sbin/nginx --modules-path=/usr/lib64/nginx/modules --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --http-client-body-temp-path=/var/lib/nginx/tmp/client_body --http-proxy-temp-path=/var/lib/nginx/tmp/proxy --http-fastcgi-temp-path=/var/lib/nginx/tmp/fastcgi --http-uwsgi-temp-path=/var/lib/nginx/tmp/uwsgi --http-scgi-temp-path=/var/lib/nginx/tmp/scgi --pid-path=/run/nginx.pid --lock-path=/run/lock/subsys/nginx --user=nginx --group=nginx --with-file-aio --with-ipv6 --with-http_ssl_module --with-http_v2_module --with-http_realip_module --with-http_addition_module --with-http_xslt_module=dynamic --with-http_image_filter_module=dynamic --with-http_geoip_module=dynamic --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_random_index_module --with-http_secure_link_module --with-http_degradation_module --with-http_slice_module --with-http_stub_status_module --with-http_perl_module=dynamic --with-mail=dynamic --with-mail_ssl_module --with-pcre --with-pcre-jit --with-stream=dynamic --with-stream_ssl_module --with-google_perftools_module --add-module=/root/rpmbuild/BUILD/nginx-1.12.2/ngx_txid --add-module=/root/rpmbuild/BUILD/nginx-1.12.2/nginx-auth-ldap --with-debug --with-cc-opt='-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong --param=ssp-buffer-size=4 -grecord-gcc-switches -specs=/usr/lib/rpm/redhat/redhat-hardened-cc1 -m64 -mtune=generic' --with-ld-opt='-Wl,-z,relro -specs=/usr/lib/rpm/redhat/redhat-hardened-ld -Wl,-E' --add-module=/var/opt/dfs/fastdfs-nginx-module/src --add-module=/var/opt/dfs/lua-nginx-module


REST

    /upload

        public + token

    /token

        private

    /file

        public + token


usage

    curl http://127.0.0.1:81/upload -F "ffff=@abc.txt"

    response => {"code":200, "message":"file upload success", "data": "["M00\/00\/00\/fwAAAVqp8fmACxRpAAAACuwBvyw0671929"]"}


