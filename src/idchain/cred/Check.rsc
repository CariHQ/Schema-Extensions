module idchain::cred::Check

import lang::json::\syntax::JSON;
import idchain::schema::Schema;
import idchain::Util;
import Map;
import Set;
import Message;
import List;
import Node;
import DateTime;
import String;

// we assume that Schemas inputted are already-typechecked using idchain::schema::Check::tc
set[Message] tc(start[JSONText] j, Schemas ss) = tc(j.top, ss);

set[Message] tc((JSONText)`<Object json>`, (Schemas)`<Schema* ss>`) {	
	set[Message] msgs = {};
	claimMap =  ( "<m.memberName>"[1..-1] : m.memberValue  | m <- json.members);
	if ("schema_id" notin claimMap || "values" notin claimMap) {
		if ("schema_id" notin claimMap)
			msgs += {error("JSON claim must contain a Schema identifier",getLoc(json))};
		if ("values" notin claimMap) 
			msgs += {error("JSON claim must contain a values field",getLoc(json))};
	}
	else if ((Value)`<Object attrMap>` := claimMap["values"] &&
			 (Value)`<StringLiteral schemaId>` := claimMap["schema_id"]) {
		
		map[tuple[str,str],Schema] schemaTable = ();
		try
			schemaTable = List::toMapUnique([<<"<s.name>","<s.version>">, s> | Schema s <- ss]);
		catch
			MultipleKey(_,_,_) : return {error("Schema with same name and same version already defined",getLoc(f))};
		sNameVersion = split(":", substring("<schemaId>"[1..-1],25));
		s = schemaTable[<sNameVersion[0],sNameVersion[1]>];
		list[Schema] hierarchy = [s];
		
		Schema i = s;
		while(true)
			if ((Schema)`schema <Id _> <Version _> : <Id extendsId> <Version extendsVer> { <Attr* _> }` := i) {
		  	  		i=schemaTable[<"<extendsId>","<extendsVer>">];
		  	  		hierarchy+=[i];
		  		}
			else break;

		
		// missing required attributes	
		set[str] requiredAttrs = {"<n>" | /(Attr)`<Id n> : <Type _>` := hierarchy} 
							   + {"issuance_time"}; // implicit issue time
		set[str] givenAttrs = {split("@", "<m.memberName>"[1..-1])[0] | m <- attrMap.members};
		msgs += {error("Missing attribute: <m>",getLoc(json)) | m <- requiredAttrs - givenAttrs};
		
		// overriding attributes
		set[str] derivedAttrs = {"<n>" | /(Attr)`<Id n> : <Type _> = <Expr e>` := hierarchy};
		msgs += { error("Attribute with same name <m.memberName> is already derived by schema.", getLoc(m.memberName))
			    | m <- attrMap.members, split("@", "<m.memberName>"[1..-1])[0] in derivedAttrs };		
	
		// extraneous attributes
		set[str] schemaAttrs = {"<a.name>" | /Attr a := hierarchy} 
						  + {"issuance_time"}; // implicit issue date
		msgs += { error("Inputted attribute <m.memberName> does not appear in schema.", getLoc(m.memberName))
		        | m <-attrMap.members, split("@", "<m.memberName>"[1..-1])[0] notin schemaAttrs};		

								
		// typecheck their associated values inside the claim
		for (m <- attrMap.members, split("@", "<m.memberName>"[1..-1])[0] in requiredAttrs) {
			if ((Value)`<Object attrValue>` := m.memberValue) {
			  	// check if "encoded" field is there and is an integer
			  	if (!([(Value)`<StringLiteral encodedStr>`] := [ a.memberValue | a <- attrValue.members, "encoded"=="<a.memberName>"[1..-1]]
			  	    && idchain::Util::parsep(#IntegerLiteral, "<encodedStr>"[1..-1])))
			  			msgs+= {error("Attribute value should contain a single integer \"encoded\" value", getLoc(attrValue))};
			  
				// check if "raw" field is there and is a string
				if ([(Value)`<StringLiteral rawValue>`] := [ a.memberValue | a <- attrValue.members, "raw"=="<a.memberName>"[1..-1] ]) {
				  					
					// TYPECHECK
					Type expectedType = head([ a.typ | /Attr a := hierarchy, "<a.name>"==split("@", "<m.memberName>"[1..-1])[0]] 
									  + [(Type)`unix_time`]); // if not found, that means it is the implicit Issue Time
					if ("<expectedType>" == split("@", "<m.memberName>"[1..-1])[1]) {
					  try { // try to read the value string (we do this because in Indy the values are all strings) 					
				
						switch(expectedType) {
							case (Type)`string`: continue;
							case (Type)`date`: parseDateTime("<rawValue>"[1..-1],dateFormatString);
							case (Type)`integer`: parseAlias(#IntegerLiteral, "<rawValue>"[1..-1]);
							case (Type)`unix_time`: parseAlias(#IntegerLiteral, "<rawValue>"[1..-1]);
							case (Type)`inverted_unix_time`: parseAlias(#IntegerLiteral, "<rawValue>"[1..-1]);
							case (Type)`boolean`: if ("<rawValue>"[1..-1] != "false" || "<rawValue>"[1..-1] != "true")
												    throw ParseError(getLoc(rawValue));
					   }
					  }
					    catch ParseError(_):
						    msgs += { error("Expected type <expectedType>, got <rawValue> instead.", getLoc(rawValue))};						
				   }
				   else
				     msgs+= {error("Attribute\'s type inside the credential <split("@", "<m.memberName>"[1..-1])[1]> does not match schema\'s expected type <expectedType>", getLoc(m.memberName))};
				} else msgs+= {error("Attribute value should contain a single \"raw\" value", getLoc(m.memberValue))};			  
				
			} else msgs+= {error("Wrong attribute format", getLoc(m.memberValue))};
		}	
	}
	else msgs += {error("Claim format error",getLoc(json))};
	
	return msgs;			
}
	

default set[Message] tc(start[JSONText] j, Schemas ss) = {error("Claim format error",getLoc(j))};