FROM openjdk:8

ENV IDC_SCHEMA_IP="0.0.0.0"
ENV IDC_SCHEMA_PORT="9000"


# Install environment
RUN apt-get update -y && apt-get install -y \
	curl

RUN mkdir -p bin && curl -o bin/idchain.jar https://update.rascal-mpl.org/console/rascal-shell-unstable.jar

RUN mkdir -p bin/idchain/cred/ && \
	mkdir -p bin/org/rascalmpl/library/ && \
 	mkdir -p src 

COPY src src

RUN	 javac -cp bin/idchain.jar src/idchain/cred/SHA256.java -d bin/ 
RUN cp -r src/idchain bin/org/rascalmpl/library/ && \
	cd /bin &&  \
	jar uf idchain.jar idchain/cred/ && \
	jar uf idchain.jar org/rascalmpl/library/idchain/


CMD java -jar bin/idchain.jar "idchain::HTTP" --host $IDC_SCHEMA_IP --port $IDC_SCHEMA_PORT


