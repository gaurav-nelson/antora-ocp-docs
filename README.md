# antora-ocp-docs

Based on https://github.com/stackrox/docs-tools/

Run the transformation script:

```bash
./ocp-transform.sh -d build -b enterprise-4.10
```

To do:
1. ~~Use the `patch-files` script to patch xrefs in the generated files.~~
1. ~~Use the `generate-nav` script to generate the navigation.~~
1. Add `product-title` and `product-version` variables in the common attributes
file.
1. Use an Antora playbook yml with the default UI bundle to generate the site.
1. Add indexing and search capabilities.
