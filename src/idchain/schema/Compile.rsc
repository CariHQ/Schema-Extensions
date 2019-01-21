module idchain::schema::Compile

import idchain::schema::Schema;
import idchain::Util;
import lang::json::ast::JSON;
import Map;

map[str, JSON] compile(start[Schemas] s) = compile(s.top);

map[str, JSON] compile((Schemas)`<Schema* ss>`) {

	map[tuple[Id,Version],Schema] schemaTable = (<s.name,s.version> : s | Schema s <- ss); // DUP

	list[JSON] compileSchema((Schema)`schema <Id _> <Version _> : <Id e> <Version ev> { <Attr* as> }`) =
		compileSchema(schemaTable[<e,ev>]) + // compile parent and flatten
		 [ compileAttr(a) | a <- as];
			
	default list[JSON] compileSchema(Schema s) = [ compileAttr(a) | a <- s.attrs ]; 


	return ("<i>-<v>" : object(
						("name": string("<i>")
						,"version": string("<v>")
						,"attr_names" : array([compileAttr((Attr)`issuance_time:unix_time`)] // for every schema, generate implicit issuance_time attribute
											  + compileSchema(schemaTable[k]))
						)
					  ) 
		   | k:<i,v> <- schemaTable);
}

private JSON compileAttr(Attr a) = string("<a.name>@<a.typ>");


