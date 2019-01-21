% author Nikolaos Bezirgiannis
% date 22/10/2018
% title Manual of High-level Schemas and Credentials

# Introduction

The Indy project defines a form of schemas and credentials to be used in the self-sovereign identity blockchain.

The Indy schemas are very low-level; they are comprised of:

- a name
- a version
- a list of attribute names

The Indy schemas are immutable (stored on the ledger), and if they need to be evolved, a new schema with a different version has to be created.
Indy does not do any check that the version is monotonically increasing.

An Indy schema does not declare types for its values. Furthermore, a schema cannot re-use attributes of another schema (schema inheritance).

An Indy credential always refers to a single Indy schema and "fills" the values of all the schema's attributes.
The values of the attributes of the credentials provided by Indy cannot be type-checked, since the Indy schemas are untyped to begin with.

# The high-level schema language

We try to introduce to these schemas a) types and b) schema inheritance , both in a **backwards-compatible** manner to the current Indy (low-level) schemas and
Indy tools (`indy-sdk`, ledger, etc.). For this reason we

- define a statically-typed domain-specific language to write "higher-level" schemas than Indy schemas
- provide a typechecker to check the consistency of these high-level schemas
- provide a compiler to generate low-level Indy schemas from these high-level schemas

## High-level Schemas

A single high-level schema is defined with the syntax :

```
schema Name Version ParentName? ParentVersion? { 
   Attributes....
}
```

`Name` and `Version` refer to the schema about-to-be defined, with its attributes following inside the curly brackets.
`ParentName` and `ParentVersion` are optional and refer to a single, specific parent schema to inherit its attributes from.

If a parent schema is declared, all the attributes of the parent schema and its ancestors are included in the currently-defined schema.
Any inherited attributes cannot be overriden, but can be refer to in `AttrExpr`s (see below on Expressions).

The `Name` and `ParentName` are case-sensitive identifiers to Schema, and follow the syntax of C variable names:

> A schema-name can have non-Unicode letters (both uppercase and lowercase letters, case-sensitive), digits and underscores only.
> The first letter of a schema-name should be either a letter or an underscore.	

([link about C variable naming](https://www.programiz.com/c-programming/c-variables-constants))

The `Version` and `ParentVersion` syntax has a major code and a minor code (separated by a dot `.`),
e.g. `0.0`, `0.1`, `0.100000`, `00003.14`. The major and minor code can contain any number of digits. Both major and minor codes are required.
Although this coding scheme looks like a "floating-point number", the language does not treat codes semantically as floating-point values,
but only compares them lexicographically, (e.g. schema version `1.0` is different than version `1.0` and `0001.0000`).

## Attributes

A high-level schema attribute is defined as:

```
  AttributeName : AttributeType = AttributeExpr?
```

An `AttributeName` follows the naming style of schema-names (and c variables), see above.

The `AttributeType` is fixed and can only be one of `boolean`, `integer`, `string`, `date`, `unix_time`, `inverted_unix_time`.

- The `boolean` type encompasses the logical `true` and `false`.
- The `integer` type is for arbitrary-precision decimal integrals (i.e. base-10 integers, like Java's `Integer` class).
- The `string` is for any unicode text surrounded by the double-quote symbol `"`. 
  To escape the double-quote symbol inside the string use a backslash `\"`.
  To escape the backslash symbol inside the string use a double backslash `\\`
- The `date` is a datetime string formatted according to [ISO8601 international standard](https://en.wikipedia.org/wiki/ISO_8601).
- The `unix_time` is an arbitrary-precision integer, which points to a particular time (seconds) passed since the unix epoch (1/1/1970). 
- The `inverted_unix_time` is an arbitrary-precision integer, which points to a particular time (seconds) that comes before the unix epoch (1/1/1970).
Note: this is needed for Zero-Knowledge proofs (ZKP).

Attributes are separated by whitespace or newline, e.g:


```
schema S 0.1 {
	attr1 : type1 attr2 : type2 = expr2
attr3 : type3
}
```

## Expressions

An attribute inside a high-level schema can optionally be followed by the equals sign `=` together with an expression `AttrExpr`. 
This attribute then is called a "derived attribute", because its value is not user-inputted when filling-in a credential, but
automatically-derived by evaluating the expression in a specific context (for more about this, see the section on High-level Credentials).

An expression can be 

1. an attribute name (defined in the current schema or any ancestor schema)
1. a string, surrounded in double quotes, e.g. `"text"`
1. a date literal in ISO 8601 format, surrounded in `$` marks, e.g. `$2018-06-20T11:05:30.997+00:00$`  , `$2018-06-20T11:05:30.996Z$`
1. a date represented in UNIX time, which is the seconds since 1/1/1970 or before 1/1/1970 (inverted_unix_time) surrounded in `|` marks, e.g. `|838383838381843491|`  , `|3|`
1. a decimal integral number, e.g. `0`, `-273`, `1337`
1. constants `true` and `false`
1. binary arithmetic operators of expressions, `+ * / -`
1. comparators `== != < > >= <=`
1. boolean-logic operators `&& || not`
1. parenthesized expression, for overriding precedence, e.g. `(1+3)*4`

## Type system

The high-level schemas are statically typed with strong typing and single inheritance.

A high-level schema must be type-correct (pass the syntax & typechecker with 0 errors), 
before it is compiled down to low-level Indy schemas.

### Types of literals

- `true` : boolean
- `false` : boolean
- `...-2,-1,0,1,2,3...1` : integer   (a base-10 arbitrary-precision integer)
- `"text"` : string
- `$2018-06-20T11:05:30.997+00:00$` : date
- `|344|` : unix_time or inverted_unix_time

### Types of Operators

- `+` , `-`, `*`, `/` : (integer,integer) -> integer
- `+` : (string,string) -> string (string concatenation)
- `+` : (unix_time,unix_time) -> unix_time
- `==`, `!=` : (a,a) -> boolean
- `not` : boolean -> boolean
- `&&`, `||` : (boolean, boolean) -> boolean
- `< > >= <=` : (integer, integer) -> boolean
- `< > >= <=` : (date, date) -> boolean
- `< > >= <=` : (unix_time, unix_time) -> boolean

[//]: # "- `< > >= <=` : (inverted_unix_time, inverted_unix_time) -> boolean"

## Compiling to low-level Indy schemas

A high-level schema must be type-correct (pass the syntax & typechecker with 0 errors), 
before it is compiled down to low-level Indy schemas.

The compilation process is summarized as follows:

- Inherited attributes of ancestor schemas are textually included in the schema to be currently compiled.
- All the attribute expressions `AttrExpr` are stripped-off in the Indy schemas.
- The attribute type `AttrType` is packed inside the attribute name string of the low-level indy schema, e.g. (`"first_name@string"`, `"grade@integer"`).

## A complete example of compiling high-level schemas

We try to compile the following high-level schemas (inside a schema file):

```
schema degree 1.1 {

  first_name: string
  last_name: string

  graduation_date : date
  average_grade : integer
  cum_laude : boolean = average_grade >= 8

  university_domain : string = "uu.nl"

}

schema master_degree 0.5 : degree 1.1 {

	master_thesis_title : string
	master_thesis_grade : integer

	email_address : string = first_name + "." + last_name + "@" + university_domain
}
```

The generated low-level schemas by the compiler are the two schemas:

```
{"attr_names": ["first_name@string","last_name@string","graduation_date@date", "average_grade@integer", "cum_laude@boolean","university_domain@string"],
"version": "1.1",
"name": "degree"}
```

```
{"attr_names": ["first_name@string","last_name@string","graduation_date@date", "average_grade@integer", "cum_laude@boolean","university_domain@string", "master_thesis_title@string", "master_thesis_grade@integer"],
"version": "0.5",
"name": "master_degree"}
```

### Convention on how to show the schema names and attribute names

- Since schema names and attribute names cannot contain spaces, we use the convention of translating underscores `_` to spaces.
  when we want to show this to the user.
- Names in Indy-schemas are case-insensitive and are translated to lower-case; for that reason, we use the convention of only
  using lower-case names in higher-level schemas, and capitalize every first character of a word (which is separated by underscore `_`), when we show them to the user.

Examples:

- Schema name `master_degree` should be shown (rendered) to the user in the mobile-app and web-ui as `Master Degree`
- Attribute name `owner_bsn` should be shown (rendered) to the user in the mobile-app and web-ui as `Owner Bsn`


## Other Notes

- High-level schema-names and attribute-names do not accept unicode characters (by design); derived values of string type can be unicode however.
- The user is not allowed to extend the type system with new types.
- Similarly, the user-defined high-level schemas cannot appear as types themselves (i.e. schemas as datatypes).
- There is no module system and no namespaces. The schemas are inputted in a single file (when using the CLI, see `README.md`) or
stored/queried from a common table/view of a database (MongoDB in the case of `admin-ui` and `api` projects).
- There is currently no semantic versioning of high-level schemas. This would also require some changes to the schema-version syntax.
- Not to lead to confusion, we disallow for now the "self-inheritance" of schemas, e.g. `schema S 0.2 S 0.1 { ... }`, which would otherwise
mean the backwards-compatible extension (evolution) of a schema. This self-inheritance is disallowed in any level of ancestorship (S is parent, grandparent, etc.)
- The compiler checks for cycles in the inheritance chain and stops with an error.

# Credentials using high-level schemas

When using Indy credentials together with high-level schemas, you
get the benefit of

1. typechecking the values of your inputted credentials compared to the referred high-level schema
2. automatic evaluation of all the derived-attributes of the referred high-level schema

The syntax of the credentials remains the same as it was in Indy, which is a JSON structure.

An Indy credential is a JSON object, as seen in the following example:

```
{ "schema_id":"someDid:MSc:0.5"
, "values": {"firstName": {"raw": "hello", "encoded": "SHA_A"}, 
		     "lastName: {"raw": "world", "encoded": "SHA_B"}, 
		    ...
			 "issuance_time": {"raw": "124325413515", "encoded": "SHA_C"}
		    }
...
}
```

The `schema_id` is parsed to extract the schema-name and schema-version that this credential points to. Then this information is used
to find the high-level schema in a given collection of available high-level schemas (given as a file or database to the compiler over CLI/HTTP).

Each attribute in the credential has a name (e.g. "firstName"), an accompanied value ("raw"), and the "encoded" digest of the raw value (hashed using SHA256).

## Type system

The inputted credential will be checked to see if the inputted "raw" values of the attributes correspond with the expected type of the high-level schema.

Since the "raw" values are given just as "strings" (according to Indy specification documentation), we cannot know the intended type interpretation of the raw value. 
For this reason, we use the following procedure:

- If the expected-type of that attribute is `integer`. we try to parse its value as a decimal integral number.
- If the expected-type of that attribute is `unix_time` or `inverted_unix_time`. we try to parse its value as a decimal integral number (seconds since/before UNIX epoch 1/1/1970).
- If the expected-type is `boolean`, we try to parse it as the boolean values `true` or `false`.
- If the expected-type is `date`, we try to parse the value according to ISO 8601 format.
- If the expected-type is `string`, we always accept the value as type-correct, even it is e.g. "123", "false", "true".

In other words, if the expected type is a `string`, we always succeed with accepting the type of the inputted value. This is a necessary evil, since
inputted Indy credentials are completely untyped (raw values are always JSON strings).

The typechecker expects that all inputted credentials to-be checked come with a `issuance_time` attribute with its value expected to be of type `unix_time`.
This `issuance_time` attribute is an implicit, hidden attribute which does not have to be declared inside a high-level schema.

NB: The meaning of `issuance_time` refers only to the unix epoch time where the issuer acknowledges that the credential came to existence, and it does not
say anything about its validity/expiration time.

## Compiling to low-level credentials

The compiler expects an inputted credential that passes the above type-checker, i.e. the credential conforms to the specified high-level schema.
If indeed the credential is type-correct, the compiler will evaluate the "raw" values of the derived-attributes of its schema (and its ancestor schemas) 
and also compute the "encoded" value for those derived-attributes.

Note that the compiler does not check nor re-generate the encoded attributes of non-derived inputted attributes. This is supposedly already-done by the `indy-sdk`.

The resulting credential is a "complete" low-level credential, which can by passed back to the `indy-sdk` to be "handed" through the issuer's agent to the Credential Holder 
(user).

The compiler will complain with an error in the cases of:

1. missing required attributes, i.e. attributes that are expected by the high-level schema and its ancestors but not provided by the inputted credential.
1. extraneous attributes, i.e. attributes that appear in the credential but not on the corresponding high-level schema and its ancestors.
1. credential attributes that try to override the derived-attributes of the high-level schema.


## Other Notes

- Our compiler checks for the presence of `schema_id` and `values` in the inputted credential; the rest of fields of the credential (`signature`, `cred_def_id`,...)
are not (format) checked but ignored.


# Schemas to be used in the IDC Project Demo (DRAFT)


## Government Schema

Its high-level representation:

```
schema passport 1.0 {
    credential_offered: unix_time
    bsn: integer
    document_number: integer
    surname: string
    given_name: string
    gender: string
    nationality_code: string
    birth_date: unix_time
    birth_place: string
    authority: string
    date_of_issue: unix_time
    date_of_expiry: unix_time

}
```

And how it is compiled to low-level Indy schema by the Schema compiler:

```json
{"attr_names": ["issuance_time@unix_time","credential_offered@unix_time","bsn@integer","document_number@integer","surname@string","given_name@string","gender@string","nationality_code@string","birth_date@unix_time","birth_place@string","authority@string","date_of_issue@unix_time","date_of_expiry@unix_time"],
"version": "1.0",
"name": "passport"}
```


## KVK Schema

Its high-level representation:

```
schema company 1.0 {
    credential_offered: unix_time
    kvk_number: integer
    legal_name: string
    street_address: string
    address_locality: string
    postal_code: string
    establishment_number: integer
    registration_date: unix_time
    last_ownership_verification: unix_time
    owner_name: string
    owner_bsn: integer
}
```


And how it is compiled to low-level Indy schema by the Schema compiler:


```json
{"attr_names": ["issuance_time@unix_time","credential_offered@unix_time","kvk_number@integer","legal_name@string","street_address@string","address_locality@string","postal_code@string","establishment_number@integer","registration_date@unix_time","last_ownership_verification@unix_time","owner_name@string","owner_bsn@integer"],
"version": "1.0",
"name": "company"}
```