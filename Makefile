.PHONY: clean default update test

default:
	-mkdir -p bin/idchain/cred/
	-mkdir -p bin/org/rascalmpl/library/
	javac -cp bin/idchain.jar src/idchain/cred/SHA256.java -d bin/
	cp -r src/idchain bin/org/rascalmpl/library/
	cd bin/; jar uf idchain.jar idchain/cred/
	cd bin/; jar uf idchain.jar org/rascalmpl/library/idchain/

update:
	-mkdir bin/
	curl -o bin/idchain.jar https://update.rascal-mpl.org/console/rascal-shell-unstable.jar

test:
	-mkdir test_results/
	java -jar bin/idchain.jar idchain/CLI --help > test_results/help.out
	java -jar bin/idchain.jar idchain/CLI --checkSchema --schema src/idchain/schema/example.idschema --odir test_results/
	java -jar bin/idchain.jar idchain/CLI --compileSchema --schema src/idchain/schema/example.idschema --odir test_results/
	java -jar bin/idchain.jar idchain/CLI --checkCred --cred src/idchain/cred/example.cred_json --schema src/idchain/schema/example.idschema --odir test_results/
	java -jar bin/idchain.jar idchain/CLI --compileCred --cred src/idchain/cred/example.cred_json --schema src/idchain/schema/example.idschema --odir test_results/

clean:
	-rm -r bin/ test_results/