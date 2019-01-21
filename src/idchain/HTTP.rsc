module idchain::HTTP

import idchain::schema::Schema;
import idchain::schema::Check;
import idchain::schema::Compile;
import idchain::Util;
import idchain::cred::Check;
import idchain::cred::Expand;

import lang::json::\syntax::JSON;
import lang::json::ast::JSON;
import lang::json::ast::Implode;
import lang::json::IO;

import ParseTree;
import Set;
import Message;
import List;
import util::Webserver;
import IO;

Response handle(get("/types")) =
	response(ok(),"application/json", (), "[\"date\",\"integer\",\"string\",\"boolean\", \"unix_time\", \"inverted_unix_time\"]"); // TODO: not hardcoded but use reflection

Response handle(post(str urlPath, Body contents)) {

  start[Schemas] schemaCST;
  start[JSONText] credCST;

  str jsonInput = contents(#str);

  switch(urlPath) {
    
    case "/schema": {      
      str schemaStr;
      try {
        JSON jsonInputAST = buildAST(parse(#start[JSONText], jsonInput));
        schemaStr = jsonToSchemaText(jsonInputAST);
      }
      catch: 
      	return jsonResponse(badRequest(), (), [error("Schema input not in correct JSON structure")]);
      
      try {
      	schemaCST = parse(#start[Schemas], schemaStr);
      }
      catch ParseError(loc l):
      	return jsonResponse(badRequest(), (), [error("Schema input not in correct structure", l)]);
      	
      set[Message] schemaMsgs = tc(schemaCST); // TODO: also print tcmsgs to stderr
      if (schemaMsgs=={}) {
        jsons = compile(schemaCST);
        return response(ok(), "application/json", (), jsonToString(array([jsons[k]|k<-jsons])));
      }
      else return jsonResponse(badRequest(), (), schemaMsgs);
    }

    case "/cred": {
 	  str schemaStr;
 	  start[JSONText] jsonInputCST;
      try {
        jsonInputCST = parse(#start[JSONText], jsonInput);
        JSON jsonInputAST = buildAST(jsonInputCST);
      	schemaStr = jsonToSchemaText(jsonInputAST.properties["schemas"]);
      }
      catch: 
      	return jsonResponse(badRequest(), (), [error("Input not in correct JSON structure")]);
      
      try {
      	schemaCST = parse(#start[Schemas], schemaStr);
      }
      catch ParseError(loc l):
      	return jsonResponse(badRequest(), (), [error("Schema input not in correct structure", l)]);
 
	  start[JSONText] credCST;
	  top-down-break visit(jsonInputCST) {
		  case (Member)`"credential" : <Object credentialContents>`: credCST = (start[JSONText])`<Object credentialContents>`;
	  }
	  
      //credCST = parse(#start[JSONText], params["cred"]);
      set[Message] credMsgs = idchain::cred::Check::tc(credCST, schemaCST.top); // TODO: also print tcmsgs to stderr
      if (credMsgs=={}) {
          JSON credAST = buildAST(credCST);
          return response(ok(), "application/json", (), jsonToString(idchain::cred::Expand::expand(credAST,schemaCST.top)));
      }
      else return jsonResponse(badRequest(), (), credMsgs);
    }

    default: fail;
  }
}


default Response handle(_) = jsonResponse(badRequest(), (), [error("Bad request")]);

void main(bool help=false, str host="localhost", int port=8000) {
  if (help)
    print("
Web Server for Typechecker & Compiler of High-level Schemas/Credentials to low-level Indy schemas/credentials

--help                              (this message)
GET /schema?schema=[SCHEMA_JSON]         (Takes high-level schemas defined in a JSON encoded format, typechecks then compiles them to low-level indy-schemas)
GET /cred?schema=[SCHEMA_JSON]&cred=[CRED_JSON] (typechecks a credential compared to given collection of high-level schemas, and fills up the credential with derived values taken from those schemas)
GET /types (returns a JSON array of the built-in types of high-level schema language available for typechecking)
");
  else serve(|http://<host>:<"<port>">|, handle, asDaemon=false);
}

private str jsonToSchemaText(JSON schemaList) {
  // to str
  str output = "";
  
  for (schema <- schemaList.values) { 
  	ps = schema.properties;
  	attrStr = ("" | it + (attr.properties)["name"].s + " : " + (attr.properties)["type"].s + " " | attr <- ps["attributes"].values);
  	output += "parentSchemaName" in ps ?
  			  "schema <ps["name"].s> <ps["version"].s> : <ps["parentSchemaName"].s> <ps["parentSchemaVersion"].s> { <attrStr> }":
  			  "schema <ps["name"].s> <ps["version"].s> { <attrStr> }";
  			}
  return output;
}


// [{"name": "S", "version": "0.1", "parentSchemaName": "S2", "parentSchemaVersion": "0.1", "attributes": [{"name":"firstName", "type": "string"}]}, {"name":"S2", "version": "0.1", "attributes": []}]