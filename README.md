# ngx_http_alpaca_module

## Installation

Before installing the module, you have to compile the [libalpaca](https://github.com/chatziko/libalpaca) library,
and get the libalpaca.so file.

```
./configure --add-dynamic-module=$PATH_TO_MODULE --with-ld-opt="-L. $PATH_TO_libalpaca.so"
make
sudo make install
```
Then add the the `load_module` directive in the top of your `nginx.conf` configuration file:

`load_module modules/ngx_http_alpaca_module.so;`

## Directives

- `alpaca_root`: Provide the nginx root, it has to be the same as the `root` directive.
- `alpaca_prob`: `on` if you want to use the ALPaCA probabilistic version, `off` otherwise.
- `alpaca_deter`: `on` if you want to use the ALPaCA deterministic version, `off` otherwise.
- `alpaca_dist_html_size`: The distribution to be used for the probabilistic version in order to sample the size of
the html.
- `alpaca_dist_obj_number`: The distribution to be used for the probabilistic version in order to sample the number 
of objects in the html.
- `alpaca_dist_obj_size`: The distribution to be used for the probabilistic version in order to sample the size of each
object in the html.
- `alpaca_obj_num`: The λ parameter for the deterministic version. The number of objects in the morphed html will be 
a multiple of it.
- `alpaca_obj_size`: The σ parameter for the deterministic version. The sizes of objects in the morphed html will be 
a multiple of it.
- `alpaca_max_obj_size`: The max_s parameter for the deterministic version. The size of an ALPaCa fake object cannot
exceed this.

The argument for each of the 3 distributions' directives can either be a known distribution with its parameters from the list below:
- LogNormal/mean,std_dev**2
- Normal/mean,std_dev**2
- Exp/lambda
- Poisson/lambda
- Binomial/n,p
- Gamma/shape,scale

or a file which contains values and a probability for each value in ascending probability order. The file's extension has to 
be `.dist` and its contents have to be like this:
```
value1 prob1
value2 prob2
valuen probn
```
where values are integers and each probability cannot be larger than 1.0.

For example:
```
4 0.04
7 0.05
12 0.06
18 0.1
24 0.14
29 0.15
35 0.16
5000 0.3
```

## Example Configurations

ALPaCA can be used in any context.

If you want to use ALPaCA in a server context the `nginx.conf` file should look like this:
```
server {
        listen       80;
        server_name  Name;
        root /my/nginx/root;
         
     
        alpaca_root /my/nginx/root;
        
        alpaca_prob off;  // Change to 'on' to use the probabilistic method
        alpaca_dist_html_size   /dist/dist1.dist;  //Path to the distribution file, relative to root        
        alpaca_dist_obj_number  Normal/20.0,1.0;  // Known distribution
        alpaca_dist_obj_size    Normal/1071571.0,1000.0;  // Known distribution
        
        alpaca_deter on; // The deterministic version is used
        alpaca_obj_num 5;
        alpaca_obj_size 50000;
        alpaca_max_obj_size 100000;
}
```



