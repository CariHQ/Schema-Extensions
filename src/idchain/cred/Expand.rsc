module idchain::cred::Expand

import idchain::Util;
import idchain::schema::Schema;
import lang::json::ast::JSON;
import String;
import DateTime;
import IO;
import List;
import Map;

// We assume that the schemas and claims are already typechecked.
JSON expand(object(claimMap), (Schemas)`<Schema* ss>`) {
	if (object(attrMap) := claimMap["values"] &&
		string(schemaId) := claimMap["schema_id"]) {
		
		// FIXME: overrides
		attrMap_ = mapper(attrMap, str (str y){return split("@",y)[0];}, JSON (JSON y) { return y;});
	
		// TODO remove duplicated code
		map[tuple[str,str],Schema] schemaTable = ();
		try
			schemaTable = List::toMapUnique([<<"<s.name>","<s.version>">, s> | Schema s <- ss]);
		catch
			MultipleKey(_,_,_) : return {error("Schema with same name and same version already defined",getLoc(f))};
		sNameVersion = split(":", substring(schemaId,25));
		s = schemaTable[<sNameVersion[0],sNameVersion[1]>];
		list[Schema] hierarchy = [s];
		Schema i = s;
		while(true)
			if ((Schema)`schema <Id _> <Version _> : <Id extendsId> <Version extendsVer> { <Attr* _> }` := i) {
		  	  		i=schemaTable[<"<extendsId>","<extendsVer>">];
		  	  		hierarchy+=[i];
		  		}
			else break;
	
		map[str,Expr] derivedAttrs = ("<n>":e | /(Attr)`<Id n> : <Type _> = <Expr e>` := hierarchy);
		
		map[str,Type] allAttrTypes = ("<a.name>":a.typ | /Attr a := hierarchy) 
								     + ("issuance_time":(Type)`unix_time`);

		JSON eval((Expr)`<Id i>`) = ("<i>" in attrMap_ && object(rawOrEncoded) := attrMap_["<i>"]) ? 
									readJSON(allAttrTypes["<i>"],rawOrEncoded["raw"]) : eval(derivedAttrs["<i>"]);
		JSON eval((Expr)`<Number n>`) = number(toReal("<n>"));
		JSON eval((Expr)`|<Number n>|`) = number(toReal("<n>"));
		JSON eval((Expr)`<String s>`) = string("<s>"[1..-1]); // by Paul, remove the extra quotes
		JSON eval((Expr)`<DateAndTime d>`) = string("<d>"[1..-1]); // remove the surrounding $ quotes
		JSON eval((Expr)`true`) = boolean(true);
		JSON eval((Expr)`false`) = boolean(false);
		JSON eval((Expr)`( <Expr e> )`) = eval(e);
		JSON eval((Expr)`! <Expr e>`) = (boolean(r) := eval(e)) ? boolean(!r) : undefined ;
		JSON eval((Expr)`<Expr e1> && <Expr e2>`) = (<boolean(r1),boolean(r2)> := <eval(e1),eval(e2)>) ? boolean(r1&&r2) : undefined;
		JSON eval((Expr)`<Expr e1> || <Expr e2>`) = (<boolean(r1),boolean(r2)> := <eval(e1),eval(e2)>) ? boolean(r1||r2) : undefined;
		JSON eval((Expr)`<Expr e1> * <Expr e2>`) = (<number(r1),number(r2)> := <eval(e1),eval(e2)>) ? number(r1*r2) : undefined;
		JSON eval((Expr)`<Expr e1> / <Expr e2>`) = (<number(r1),number(r2)> := <eval(e1),eval(e2)>) ? number(r1/r2) : undefined;
		JSON eval((Expr)`<Expr e1> - <Expr e2>`) = (<number(r1),number(r2)> := <eval(e1),eval(e2)>) ? number(r1-r2) : undefined;														

		JSON eval((Expr)`<Expr e1> + <Expr e2>`) =
			(<number(r1),number(r2)> := res) ? number(r1+r2) : 	
				(<string(s1),string(s2)> := res) ? string(s1+s2) : undefined
					when res := <eval(e1),eval(e2)> ;
		
		
		JSON eval((Expr)`<Expr e1> \< <Expr e2>`) = 
			(<number(r1),number(r2)> := res) ? boolean(r1<r2) :
				(<string(s1),string(s2)> := res) ? boolean(parseDateTime(s1,dateFormatString)<parseDateTime(s2,dateFormatString)) : undefined
					when res := <eval(e1),eval(e2)> ;
		JSON eval((Expr)`<Expr e1> \<= <Expr e2>`) = 
			(<number(r1),number(r2)> := res) ? boolean(r1<=r2) :
				(<string(s1),string(s2)> := res) ? boolean(parseDateTime(s1,dateFormatString)<=parseDateTime(s2,dateFormatString)) : undefined
					when res := <eval(e1),eval(e2)> ;
		JSON eval((Expr)`<Expr e1> \> <Expr e2>`) = 
			(<number(r1),number(r2)> := res) ? boolean(r1>r2) :
				(<string(s1),string(s2)> := res) ? boolean(parseDateTime(s1,dateFormatString)>parseDateTime(s2,dateFormatString)) : undefined
					when res := <eval(e1),eval(e2)> ;
		JSON eval((Expr)`<Expr e1> \>= <Expr e2>`) = 
			(<number(r1),number(r2)> := res) ? boolean(r1>=r2) :
				(<string(s1),string(s2)> := res) ? boolean(parseDateTime(s1,dateFormatString)>=parseDateTime(s2,dateFormatString)) : undefined
					when res := <eval(e1),eval(e2)> ;															

		JSON eval((Expr)`<Expr e1> == <Expr e2>`) = boolean(eval(e1)==eval(e2));
		JSON eval((Expr)`<Expr e1> != <Expr e2>`) = boolean(eval(e1)!=eval(e2));
		
				

		for (derivedAttr <- derivedAttrs) {
			JSON rawRes = eval(derivedAttrs[derivedAttr]);
			str encodedRes = "m";
			switch(rawRes) {
				case boolean(true): encodedRes = "2";
				case boolean(false): encodedRes = "1";
				case number(n):  encodedRes = "<n>";
				case string(d): encodedRes = "<toSHA256(d)>";
			}
			attrMap["<derivedAttr>@<allAttrTypes[derivedAttr]>"] = object(("raw" : rawRes, "encoded": string(encodedRes)));
		}
				
		claimMap["values"] = object(attrMap);
		return stringifyRaw(object(claimMap));
		
	}

}

// fuction used to stringify some raw values because of Indy's low-level json claims
private JSON stringifyRaw(JSON expanded) =
	visit(expanded) {
		case JSON x:number(n) => string(jsonToString(x))
		case JSON x:boolean(n) => string(jsonToString(x))
		case JSON x:null() => string(jsonToString(x))
	};

// the opposite of stringifyRaw
private JSON readJSON((Type)`string`, string(s)) = string(s);
private JSON readJSON((Type)`date`, string(s)) = string(s);
private JSON readJSON((Type)`integer`, string(s)) = number(toReal("<s>"));
private JSON readJSON((Type)`unix_time`, string(s)) = number(toReal("<s>"));
private JSON readJSON((Type)`inverted_unix_time`, string(s)) = number(toReal("<s>"));
private JSON readJSON((Type)`boolean`, string("true")) = boolean(true);
private JSON readJSON((Type)`boolean`, string("false")) = boolean(false);

@javaClass{idchain.cred.SHA256}
public java int toSHA256(str originalString);

