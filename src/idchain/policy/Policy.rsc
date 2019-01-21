module idchain::policy::Policy

extend lang::std::Layout;
extend lang::std::Id;

start syntax Policy
  = "policy" Id "with" Binding* "require" Expr;

syntax Binding
  = Id var "=" Id schema Version version
  | Id var "=" Key
  ;
  
lexical Key
  = [0-9a-f]+ !>> [0-9a-f];

syntax Version
  = Nat "." Nat;  

syntax Attr
  = @category="Variable" Id \ "issuer" \ "date";

lexical Issuer = "$" Id;

syntax Expr 
  = Id "." Attr //  attr
  | Id "." "issuer"
  | Id "." "date"
  | Issuer  
  | @category="Constant" Int 
  | Bool 
  | @category="StringLiteral" Str 
  | @category="Constant" Date
  | "{" {Expr ","}* "}" 
  | "proof" "(" Expr ")"
  | Int ".." Int 
  | bracket "(" Expr ")"
  > "!" Expr
  >  non-assoc (
    non-assoc Expr "\<" Expr
    | non-assoc Expr "\<=" Expr
    | non-assoc Expr "\>=" Expr
    | non-assoc Expr "\>" Expr
    | non-assoc Expr "=" Expr
    | non-assoc Expr "!=" Expr
    | non-assoc Expr "in" Expr
  )
  > left Expr "and" Expr
  > left Expr "or" Expr
  > right Expr "implies" Expr
  ;  


lexical Date = [0-9][0-9][0-9][0-9] "-" [01][0-9] "-" [0-9][0-9]; 

lexical Str = "\"" ![\"]* "\"";

syntax Bool = "true" | "false";

lexical Int = [\-]* Nat;

lexical Nat = [0-9]+ !>> [0-9];


  
