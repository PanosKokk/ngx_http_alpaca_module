# ngx_http_alpaca_module

## Installation

This is an [nginx dynamic module](https://docs.nginx.com/nginx/admin-guide/dynamic-modules/dynamic-modules/) which can be used
with the nginx already installed in your system (you only need to compile the module, not nginx itself).

First, install cargo, OpenSSL and PCRE. On Ubuntu this can be done with:
```
sudo apt install cargo libssl-dev libpcre3-dev
```

Then get the module (with `--recursive` to also fetch `libalpaca`), compile and install:
```
git clone --recursive https://github.com/PanosKokk/ngx_http_alpaca_module
cd ngx_http_alpaca_module
make
sudo make install
```

You finally need to add `load_module` to `nginx.conf` (the exact directive will be printed by `make install`), eg:
```
load_module /usr/lib/nginx/modules/ngx_http_alpaca_module.so;
```

## Directives

- `alpaca_prob`

  `on` if you want to use the ALPaCA probabilistic version, `off` otherwise.

- `alpaca_deter`

  `on` if you want to use the ALPaCA deterministic version, `off` otherwise.

- `alpaca_dist_html_size`

  The distribution to be used for the probabilistic version in order to sample the size of the html.

- `alpaca_dist_obj_num`

  The distribution to sample the number of objects in the html from.

- `alpaca_dist_obj_size`

  The distribution to sample the size of each object in the html from.

- `alpaca_dist_total_size`

  The distribution to sample the total size of the page (html + objects) from.

- `alpaca_obj_num`

  The λ parameter for the deterministic version. The number of objects in the morphed html will be a multiple of it.

- `alpaca_obj_size`

  The σ parameter for the deterministic version. The sizes of objects in the morphed html will be a multiple of it.

- `alpaca_max_obj_size`

  The max_s parameter for the deterministic version. The size of an ALPaCa fake object cannot exceed this.

The argument for the `alpaca_dist_*` directives can be one of the following:
- A known distribution with its parameters from the list below:
  - `LogNormal/mean,variance`
  - `Normal/mean,variance`
  - `Exp/lambda`
  - `Poisson/lambda`
  - `Binomial/n,p`
  - `Gamma/shape,scale`
- A file which contains values and a probability for each value in ascending probability order. The file's extension has to 
  be `.dist` and its contents have to be like this:
  ```
  prob1 value1 
  prob2 value2
  probN valueN
  ```
  where values are integers and probabilities non-negative summing up to 1.
- Empty, which means to use the real value for the corresponding field.
- `Joint` (only for `alpaca_dist_obj_size`), which means that both html and object sizes are
  drawn from a joint distribution described in `alpaca_dist_html_size` (needs to be a `.dist` file).

## Example Configuration

ALPaCA can be used in both server and location contexts. It can also be used together with `fastcgi_pass`
(for dynamic content) and `proxy_pass` (for proxying upstream servers), but only if embeded images are
static and accessible locally. A sample `nginx.conf` is below:
```
server {
    listen       80;
    server_name  www.example.com;
    root /var/www;

    # alpaca can be configured at the server context
    #
    alpaca_prob on;                                   # Use the probabilistic method
    alpaca_dist_html_size   /dist/dist1.dist;         # Path to the distribution file, relative to root        
    alpaca_dist_obj_num  Normal/20.0,1.0;          # Known distribution
    alpaca_dist_obj_size    Normal/1071571.0,1000.0;  # Known distribution

    # but also at a location contenxt
    #
    location /foo/ {
        alpaca_deter on;                              # Use the deterministic method
        alpaca_obj_num 5;
        alpaca_obj_size 50000;
        alpaca_max_obj_size 100000;
    }

    # It works for dynamically generated content (but embedded images/css need to be static)
    #
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $request_filename;
    }

    # It also works with proxy_pass, however embedded images/css still need to be accessible in the local filesystem.
    #
    # IMPORTANT: Accept-Encoding should be set to "" so that the upstream server returns raw html
    #
    location /proxy/ {
        proxy_pass http://www.upstream.com/;
        proxy_set_header Accept-Encoding "";
    }
}
```



