module idchain::CLI

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
import IO;
import List;

void main(str schema="", str cred="", str odir="", bool help=false, bool checkSchema=false, bool checkCred=false, bool compileSchema=false, bool compileCred=false) {
	if (help) {
		print("
Typechecker & Compiler of High-level Schemas/Credentials to low-level Indy schemas/credentials

--help                      (this message)
--schema \<filepath\>       The inputted file containing the higher-level schema(s)
--cred \<filepath\>         The inputted file containing the unfinished credentials given by the issuer
--checkSchema               Syntax-check and type-check the inputted schema
--checkCred                 Syntax-check and type-check the inputted credential
--compileSchema             Compile the inputted higher-level schema(s) to (lower-level) Indy schemas
--compileCred               Compile the unfinished inputted credential to a full Indy credential
--odir \<directory\>        Where to put the output files (default: current directory)
");
		return;
	}
	
	loc schemaPath = schema == "" ? |file:///dev/null| : find(schema, [|cwd:///|]);
	loc credPath = cred == "" ? |file:///dev/null| : find(cred, [|cwd:///|]);
	loc outPath = odir == "" ? |cwd:///| : find(odir, [|cwd:///|]);
	mkDirectory(outPath);

	start[Schemas] schemaCST;
	start[JSONText] credCST;
	
	if (checkSchema) {
		schemaCST = parse(#start[Schemas], schemaPath);
		set[Message] schemaMsgs = tc(schemaCST); // TODO: also print tcmsgs to stderr
		writeJSON(outPath + "schemaCheckMessages.json", schemaMsgs);
	}
	
	if (checkCred) {
		if (!checkSchema)
			schemaCST = parse(#start[Schemas], schemaPath);
		if ((Schemas)`<Schema* ss>` := schemaCST.top) {		
			credCST = parse(#start[JSONText], credPath);
			set[Message] credMsgs = idchain::cred::Check::tc(credCST, schemaCST.top); // TODO: also print tcmsgs to stderr
			writeJSON(outPath + "credCheckMessages.json", credMsgs);
		}
	}
	
	if (compileSchema) {
		if (!checkSchema && !checkCred)
			schemaCST = parse(#start[Schemas], schemaPath);
		jsons = compile(schemaCST);
		for (k <- jsons)
			writeFile(outPath + (k + ".json"), jsonToString(jsons[k])); // parens on .json are important
	}
	
	
	if (compileCred) {
		if (!checkSchema && !checkCred && !compileSchema)
			schemaCST = parse(#start[Schemas], schemaPath);
		if (!checkCred)
			credCST = parse(#start[JSONText], credPath);	
		JSON credAST = buildAST(credCST);
		writeFile(outPath + "compiled_cred.json", jsonToString(idchain::cred::Expand::expand(credAST,schemaCST.top)));
	}



}


