module idchain::schema::Schema

extend lang::std::Layout;
extend lang::std::Id;

start syntax Schemas = Schema*; 

syntax Schema = "schema" Id name Version version Extends? "{" Attr* attrs "}";

syntax Extends = ":" Id Version;

syntax Attr
  = Id name ":" Type typ
  | Id name ":" Type typ "=" Expr
  ;

syntax Type
  = @category="Type" "boolean"
  | @category="Type" "string"
  | @category="Type" "integer"
  | @category="Type" "date"
  | @category="Type" "unix_time"
  | @category="Type" "inverted_unix_time"
  ;
lexical String = [\"] StrChar* [\"];

lexical StrChar
  = ![\"\\]
  | [\\][\\\"nfbtr]
  ;

lexical Number =  [\-]? [0-9]+ !>> [0-9];

lexical Version = [0-9]+ "." [0-9]+ !>> [0-9];

syntax Expr
  = @category="Variable" var: Id \ Keywords
  | @category="Constant" numberS: Number
  | @category="StringLiteral" stringS: String
  | @category="DateLiteral" dateS: DateAndTime
  | @category="DateLiteral" unixS: "|" Number "|"
  | \true: "true"
  | \false: "false"
  | bracket "(" Expr ")"
  > not: "!" Expr
  > left (
      mul: Expr "*" Expr
    | div: Expr "/" Expr
  )
  > left (
      add: Expr "+" Expr
    | sub: Expr "-" Expr
  )
  > non-assoc (
      lt: Expr "\<" Expr
    | leq: Expr "\<=" Expr
    | gt: Expr "\>" Expr
    | geq: Expr "\>=" Expr
    | eq: Expr "==" Expr
    | neq: Expr "!=" Expr
  )
  > left and: Expr "&&" Expr
  > left or: Expr "||" Expr
  ;
  
keyword Keywords = "true" | "false" ;

// taken from std::lang::rascal::\syntax::Rascal
lexical DateAndTime
	= "$" DatePart "T" TimePartNoTZ !>> [+\-] "$"
	| "$" DatePart "T" TimePartNoTZ TimeZonePart "$";
lexical DatePart
	= [0-9] [0-9] [0-9] [0-9] "-" [0-1] [0-9] "-" [0-3] [0-9] 
	| [0-9] [0-9] [0-9] [0-9] [0-1] [0-9] [0-3] [0-9] ;
lexical TimePartNoTZ
	= [0-2] [0-9] [0-5] [0-9] [0-5] [0-9] ([, .] [0-9] ([0-9] [0-9]?)?)? 
	| [0-2] [0-9] ":" [0-5] [0-9] ":" [0-5] [0-9] ([, .] [0-9] ([0-9] [0-9]?)?)? 
	;
lexical TimeZonePart
	= [+ \-] [0-1] [0-9] ":" [0-5] [0-9] 
	| "Z" 
	| [+ \-] [0-1] [0-9] 
	| [+ \-] [0-1] [0-9] [0-5] [0-9] 
	;
