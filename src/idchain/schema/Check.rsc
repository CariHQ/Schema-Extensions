module idchain::schema::Check

import idchain::schema::Schema;
import idchain::Util;
import Map;
import Set;
import List;
import Message;

alias SymbolTable = map[Id,Type];


set[Message] tc(start[Schemas] s) = tc(s.top);

private set[Message] tc(f:(Schemas)`<Schema* ss>`) {
	map[tuple[Id,Version],Schema] schemaTable =();
	try
		schemaTable = List::toMapUnique([<<s.name,s.version>, s> | Schema s <- ss]);
	catch
		MultipleKey(_,_,_) : return {error("Schema with same name and same version already defined",getLoc(f))};
	
	set[Message] msgs = {};


	bool hasCycles() {
	  for (Schema s <- ss)
		findCycles(<s.name,s.version>, s, {s.name});
	  return !Set::isEmpty(msgs);  // if no (error) messages are produced then it is safe to continue typechecking
	}
	
	// checks based on schema-names only (and not versions) if there is an ancestor with the same name as the currently-defined schema
	void findCycles(<Id beginId, Version beginVer>, Schema current, set[Id] visited) {
		switch(current) {
			case (Schema)`schema <Id _> <Version _> : <Id extendsId> <Version extendsVer> {<Attr* attrs>}`:
				{
				if (extendsId in visited)
					msgs+= { error("Schema cycle detected inside schema <beginId> with version <beginVer>", getLoc(beginId)) };
				else
					try findCycles(<beginId,beginVer>, schemaTable[<extendsId,extendsVer>], visited + extendsId);
						catch NoSuchKey(_): msgs+= { error("No such schema <extendsId> with version <extendsVer>", getLoc(extendsId)) };	
				}
			default: return;
		}
	}
	
	SymbolTable computeLocalST((Schema)`schema <Id _> <Version _> : <Id extendsId> <Version extendsVer> {<Attr* attrs>}`) {
		parentLRel = toList(computeLocalST(schemaTable[<extendsId,extendsVer>]));
		myLRel = [<a.name, a.typ> | Attr a <- attrs];
		return List::toMapUnique(parentLRel + myLRel);
	}
	default SymbolTable computeLocalST(Schema s) = List::toMapUnique([<a.name, a.typ> | Attr a <- s.attrs]); 


	void tc(Schema s) {	
	
		SymbolTable st;
		try
			st = computeLocalST(s);
		catch
			MultipleKey(a,_,_) : {
				msgs+={error("Schema <s.name> has duplicate attribute <a>",getLoc(s))};
				return; // does not make much sense to continue the typechecking of this schema
			}
	
		// typechecking attributes
		void tc((Attr)`<Id n> : <Type t> = <Expr e>`) { 
			if ("<n>" == "issuance_time")
			    msgs += { error("The attribute \"issuance_time\" is implicit for every schema and must not be explicitly provided", getLoc(n)) };    
			else if (t != tc(e))
				msgs += { error("Type of <n> does not match type of its expression", getLoc(e)) };
		}
		void tc((Attr)`<Id n> : <Type t>`) {
			if ("<n>" == "issuance_time") // DUP
			    msgs += { error("The attribute \"issuance_time\" is implicit for every schema and must not be explicitly provided", getLoc(n)) };    
		}
	
		// typechecking expressions
		//
		
		// Literals
		Type tc(var(id)) {
			Type t = (Type)`integer`; // return arbitrary type
			try t = st[id];
				catch NoSuchKey(_): msgs+= { error("No such attribute <id>", getLoc(id)) }; 
			return t;
		}
		Type tc(\true) = (Type)`boolean`;
		Type tc(\false) = (Type)`boolean`;
		Type tc(stringS(_)) = (Type)`string`;
		Type tc(numberS(_)) = (Type)`integer`;
		Type tc(dateS(_)) = (Type)`date`;
		Type tc(unixS(_)) = (Type)`unix_time`;
		// parens
		Type tc((Expr) `(<Expr e>)`) = tc(e);
	
		Type tc(not(e)) {
			t = tc(e);
			if (t != (Type)`boolean`)
				msgs += { error("Expected type of boolean, but got <t> instead", getLoc(e))};
			return t;
		}
	
		// equality operators
		Type tc(eq(e1,e2)) = tcEq(e1,e2);
		Type tc(neq(e1,e2)) = tcEq(e1,e2);
		
		// bool operators
		Type tc(or(e1,e2)) = tcBool(e1,e2);
		Type tc(and(e1,e2)) = tcBool(e1,e2);
		
		// ordering operators
		Type tc(lt(e1,e2)) = tcOrd(e1,e2);
		Type tc(leq(e1,e2)) = tcOrd(e1,e2);
		Type tc(gt(e1,e2)) = tcOrd(e1,e2);
		Type tc(geq(e1,e2)) = tcOrd(e1,e2);
		
		// arithmetic operators
		Type tc(mul(e1,e2)) = tcArithm(e1,e2);
		Type tc(div(e1,e2)) = tcArithm(e1,e2);
		Type tc(sub(e1,e2)) = tcArithm(e1,e2);
		Type tc(add(e1,e2)) {
			t1 = tc(e1);
			if (t1==tc(e2)&&t1==(Type)`string`) // override for plus on strings
				return t1;
			else return tcArithm(e1,e2);
		}
		
		
		
		// Helper functions
		
		Type tcEq(e1,e2) {
			t1 = tc(e1);
			t2 = tc(e2);
			if (t1 != t2)
				msgs+= { error("Type mismatch between the two sides of (in)equality expression", getLoc(e1)) };
			return (Type)`boolean`;
		}
		
		
		Type tcOrd(e1,e2) {
			switch(tc(e1)) {
				case (Type)`integer`: if (!((Type)`integer` := tc(e2))) msgs += { error("Expected type of integer", getLoc(e2))};
				case (Type)`date`:if (!((Type)`date` := tc(e2))) msgs += { error("Expected type of date", getLoc(e2))};
				case (Type)`unix_time`:if (!((Type)`unix_time` := tc(e2))) msgs += { error("Expected type of unix_time", getLoc(e2))};
				default: msgs += { error("Expected type of integer or date or unix_time", getLoc(e1))};
			}
			return (Type)`boolean`;
		}
		
		Type tcArithm(e1,e2) {
			t1 = tc(e1);
			t2 = tc(e2);
			if (t1 != (Type)`integer` || t2 != (Type)`integer`)
				msgs += { error("Expected type of integer", getLoc(e1))};
			return t1;
		}
		
		Type tcBool(e1,e2) {
			t1 = tc(e1);
			t2 = tc(e2);
			if (t1 != (Type)`boolean` || t2 != (Type)`boolean`)
				msgs += { error("Expected type of boolean", getLoc(e1))};
			return t1;
		}
		
		
		for (Attr a <- s.attrs)
			tc(a);
	}

	if (!hasCycles())
		for (Schema s <- ss) 
			tc(s);

	return msgs;
}




