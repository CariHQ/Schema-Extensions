<img src="https://id-chain.github.io/square-logo300x300.png" align="left" height="140px" style="margin-right: 30px;" />

# IdentityChain Schema Extensions - </br> High Level Schemas

</br>
Welcome to the Schema Extensions repository, please see our documentation site for more information.

# Getting prerequisites

A recent version of Java JRE and JDK (>=7) must be installed.

To download required libraries, run once the first time inside the repo:

```sh
make update
```

## (Re)Building the Schema/Credential compiler

After a latest `git pull` of this repo, run:

```sh
make
```

## Running the Schema/Credential compiler as a Server

In the repo directory run:

```sh
java -jar bin/idchain.jar idchain/HTTP --help
java -jar bin/idchain.jar idchain/HTTP --host 127.0.0.1 --port 8000 # the arguments are optional, defaults to localhost:8000
```

To hit the Server from the client side, run:

```sh
curl -X POST 'http://localhost:8000/schema' -H 'Content-Type: application/json' -d '<SCHEMAS_JSON>'
```

, validates and compiles the high-level schema to low-level Indy schema.

```sh
curl -X POST 'http://localhost:8000/cred' -H 'Content-Type: application/json' -d '{"schemas": <SCHEMAS_JSON>, "credential": <CREDENTIAL_JSON>}'
```

, validates the high-level schema and credential and returns the filled-in Indy credential.

```sh
curl -G "http://localhost:8000/types"
```

, returns a list of types supported in the high-level schema.

## Running the Schema/Credential compiler from CommandLine

Take a look at the help-message output (`java -jar bin/idchain.jar idchain/CLI --help`):


    Typechecker & Compiler of High-level Schemas/Credentials to low-level Indy schemas/credentials

    --help                      (this message)
    --schema <filepath>         The inputted file containing the higher-level schema(s)
    --cred <filepath>           The inputted file containing the unfinished credentials given by the issuer
    --checkSchema               Syntax-check and type-check the inputted schema
    --checkCred                 Syntax-check and type-check the inputted credential
    --compileSchema             Compile the inputted higher-level schema(s) to (lower-level) Indy schemas
    --compileCred               Compile the unfinished inputted credential to a full Indy credential
    --odir <directory>          Where to put the output files (default: current directory)


Also take a look at `make test` inside the Makefile for a running example:


```sh
make test
```