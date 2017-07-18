# rtokenize
Ruby tool to tokenise YAML, JSON and other files
`./rtokenize.rb [-y|--yaml|-j|--json] < file > output_file`

- `-j|--json` - tokenize JSON file
- `-y|--yaml` - tokenize YAML file

Tool reads from standard input and writes to standard output.
Eventual errors are written to standard error.

`./check.sh` - this is a check on all Kubernetes YAML files - to see if parser works for all of them.

