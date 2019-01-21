module idchain::cred::Plugin

import idchain::Util;
import idchain::cred::Check;
import idchain::cred::Expand;
import idchain::schema::Schema;
import ParseTree;
import util::IDE;
import Message;
import lang::json::\syntax::JSON;
import lang::json::ast::Implode;
import IO;

str LANG = "Cred JSON";

void main() {
	registerLanguage(LANG, "cred_json", start[JSONText](str src, loc org) {
		return parse(#start[JSONText], src, org);
		});
  
	registerContributions(LANG, {
	 annotator(Tree(Tree t) {
	   if (start[JSONText] pt := t) {
	     return t[@messages=tc(pt, parse(#start[Schemas], |project://identity-schema/src/idchain/schema/example.idschema|).top)];
	   }
	   return t[@messages={error("Not a json file", t@\loc)}];
	   
	 }),
	 builder(set[Message] (Tree t) {
	   if (start[JSONText] pt := t) {
	     Schemas cst = parse(#start[Schemas], |project://identity-schema/src/idchain/schema/example.idschema|).top;
	     msgs = tc(pt, cst);
	     if (msgs == {}) {
	        json = expand(buildAST(pt), cst);
	        writeFile(|project://identity-schema/src/idchain/cred/example.json|, jsonToString(json));
	     }
	     return msgs;
	   }
	   return {error("Not a json file", t@\loc)};
	 })
	});
}