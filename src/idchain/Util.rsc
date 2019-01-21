module idchain::Util

import ParseTree;
import lang::json::ast::JSON;
import Map;
import List;
import String;

loc getLoc(Tree t) = t@\loc;

str jsonToString(null()) =  "null";
str jsonToString(string(s)) = "\"<s>\"";
str jsonToString(number(n)) = endsWith("<n>",".") ? "<n>"[..-1] : "<n>"; // JSON does not allow . in the end, whereas rascal allows it
str jsonToString(boolean(b)) = "<b>";
str jsonToString(array(as)) = ("[" 
							  | it + j 
							  | str j <- intersperse("," , [jsonToString(a)| a <- as]) 
							  ) + "]";
str jsonToString(object(m)) = ("{" 
							  | it + j 
							  | str j <- intersperse(",\n" , ["\"<k>\": <jsonToString(v)>" 
							  								 | <str k, JSON v> <- Map::toList(m)]
							  						)
							  ) + "}";
str jsonToString(ivalue(_,_)) = undefined;

public str dateFormatString = "yyyy-MM-dd\'T\'HH:mm:ss.SSSX";  // iso8061, ref: https://docs.oracle.com/javase/7/docs/api/java/text/SimpleDateFormat.html

bool parsep(begin, input) {
   try parse(begin,input);
   catch ParseError(_): return false;
   return true;
}

&T<:Tree parseAlias(type[&T<:Tree] begin, str input) = parse(begin,input); 