# Project1
CS431 Project 1 Repository - Sam Grigoli &amp; Gabe Otero

# Sam Grigoli Research and Notes

Documentation for the hashtbl module
https://ocaml.org/docs/hash-tables

Documentation for Parallel Programing
https://ocaml.org/manual/5.2/parallelism.html#:~:text=Domainslib%20provides%20an%20async%2Fawait,mechanism%2C%20domainslib%20provides%20parallel%20iterators.


To run: 

dune exec ./_build/default/bin/app.exe

With the server running, test the /add endpoint. You can use curl to send a POST request with a JSON body:

curl -X POST http://localhost:3000/add -H "Content-Type: application/json" -d '{"key": "example_key", "value": "example_value"}'



