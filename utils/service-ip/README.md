# Service IP

This module helps to retrieve the domain, IP, and ports of a Kubernetes service.

If `service` ends up being `null`, all the outputs of the module will be null as well.

If `service` is an headless service, the `ip` output will be null. You can use the `host` output to have the IP of the service if it exists, or the domain name of the service otherwise.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## Example


```{toctree}
:maxdepth: 4
:glob:

examples/**
```

