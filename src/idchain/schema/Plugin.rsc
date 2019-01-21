module idchain::schema::Plugin

import idchain::schema::Schema;
import idchain::schema::Check;
import idchain::schema::Compile;
import idchain::Util;
import ParseTree;
import util::IDE;
import Message;
import IO;

str LANG = "IdentitySchema";


void main() {
  registerLanguage(LANG, "idschema", start[Schemas](str src, loc org) {
    return parse(#start[Schemas], src, org);
  });
  
  registerContributions(LANG, {
     annotator(Tree(Tree t) {
       if (start[Schemas] pt := t) {
         return t[@messages=tc(pt)];
       }
       return t[@messages={error("Not a schema file", t@\loc)}];
       
     }),
     builder(set[Message] (Tree t) {
       if (start[Schemas] pt := t) {
         msgs = tc(pt);
         if (msgs == {}) {
            jsons = compile(pt);
            for (str name <- jsons) {
              loc l = t@\loc.top;
              l.file = "<name>.json";
              writeFile(l, jsonToString(jsons[name]));
            } 
         }
         return msgs;
       }
       return {error("Not a schema file", t@\loc)};
     })
     
     
     });
}