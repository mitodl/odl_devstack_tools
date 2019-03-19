### Using mitxpro as an OAuth2 provider for LMS

The files in this example directory will help you to configure LMS to use 
[mitxpro](https://github.com/mitodl/mitxpro) (with [social-auth-mitxpro](https://github.com/mitodl/social-auth-mitxpro)) as a third party OAuth2 provider. 

Copy the yml file to the root of this repo and the JSON patch file into the `configpatch`
directory. From there, follow the instructions in the main `README` to run devstack
with `docker-compose-socialxpro.yml` as one of the docker-compose config files.
