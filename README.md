# rtokenize
Ruby tool to tokenise YAML, JSON and other files
`./rtokenize.rb [-y|--yaml|-j|--json] < file > output_file`

- `-j|--json` - tokenize JSON file
- `-y|--yaml` - tokenize YAML file
- `-h|--header` - Generate `begin_unit` header and `end_unit` footer
- `-n|--numbers` - Generate numeric stats (first number is Nth call of recursive tokenizer, second number is Nth token within single call)

Tool reads from standard input and writes to standard output.
Eventual errors are written to standard error.

`./check.sh` - this is a check on all Kubernetes YAML files - to see if parser works for all of them.

