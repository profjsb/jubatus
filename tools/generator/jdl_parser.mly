/*
 Jubatus: Online machine learning framework for distributed environment
 Copyright (C) 2011,2012 Preferred Infrastructure and Nippon Telegraph and Telephone Corporation.

 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2.1 of the License, or (at your option) any later version.

 This library is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 Lesser General Public License for more details.

 You should have received a copy of the GNU Lesser General Public
 License along with this library; if not, write to the Free Software
 Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
*/

%{
open Printf
open Stree

let _ = Parsing.set_trace false;;
let debugprint = ref false;;

let print str = if !debugprint then print_endline str;;

let parse_error s = print ("parse_error->"^s);;

%}

%token TYPEDEF
%token MESSAGE
%token EXCEPTION
%token SERVICE

%token RRBRACE LRBRACE COMMA COLON
%token RBRACE LBRACE RBRACE2 LBRACE2
%token QUESTION
%token ENUM
%token EOF DEFINE

%token <int>    INT
/* TODO: %token <double> DOUBLE <float> FLOAT <bool> true, false, <string> "..." */
%token <string> LITERAL
%token <string> INCLUDE
%token <string> DECORATOR

%start input
%type <Stree.stree list> input

%%

input: 
     | input exp0 { print "adfsafsd"; $2::$1 }
     | exp0  { print ">>newline"; [$1] }
;
   
exp0:
	| typedef { $1 }
	| enum    { $1 }
	| msg     { $1 }
	| ex      { $1 }
	| service { $1 }

typedef:
	| TYPEDEF LITERAL DEFINE a_type{
	  let _ = Stree.add_known_types $2 in
	  Typedef($2, $4) }
;

a_type:
	| a_type QUESTION {
	  Nullable($1)
	}
	| LITERAL {
	  print ">anytype: LITERAL";
	  match $1 with
	    | "void" -> Void;
	    | "object" -> Object;
	    | "bool"   -> Bool;
	    | "byte"   -> Byte;
	    | "short"  -> Short;
	    | "int" -> Int;
	    | "long" -> Long;
	    | "ubyte" -> Ubyte;
	    | "ushort" -> Ushort;
	    | "uint"   -> Uint;
	    | "ulong"  -> Ulong;
	    | "float"  -> Float;
 	    | "double" -> Double
	    | "raw"    -> Raw;
	    | "string" -> String;
	    | s when Stree.check_type s ->
	      Struct(s);
	    | s ->
	      print ("unknown type: " ^ s);
	      raise (Stree.Unknown_type s)
	}
	| LITERAL LBRACE types RBRACE {
	  match $1 with
	    | "list" -> List( (List.hd $3) );
	    | "map"  ->
	      let left = List.hd $3 in
	      let right = List.hd (List.tl $3) in
	      Map(left, right);
	    | "tuple" -> Tuple($3);
	    (* user defined types?   hoge<hage, int> *)
	    | s ->
	      print ("unknown container: " ^ s);
	      raise (Stree.Unknown_type s)
	}
;

types:
	| a_type COMMA types { $1::$3 }
	| a_type { [$1] }

enum:
	| ENUM LITERAL LBRACE2 numbers RBRACE2 {
	  Stree.add_known_types $2;
	  Enum($2, $4)
	}
numbers:
	| INT COLON LITERAL {
	  [($1, $3)]
	}
	| INT COLON LITERAL numbers {
	  ($1, $3)::$4
	}

/* msg and ex: we shoudl implement type-param... (TODO) */
msg:
	| MESSAGE LITERAL LBRACE2 fields RBRACE2 {
	  Stree.add_known_types $2;
	  Message($2, $4)
	}
ex:
	| EXCEPTION LITERAL LBRACE2 fields RBRACE2 {
	  Exception($2, $4, "")
	}
	| EXCEPTION LITERAL LBRACE LITERAL LBRACE2 fields RBRACE2 {
	  Exception($2, $6, $4)
	}

fields:
	| field fields { $1::$2 }
	| field { [$1] }
;
field:
	| INT COLON a_type LITERAL {
	  Field($1, $3, $4)
	}
/* default value is not yet implemented | INT COLON a_type LITERAL DEFINE INT {
	  ($1, $3, $4, ) 
	} */
;
service: /* TODO: implement version and new RPC-spec */
	| SERVICE LITERAL LBRACE2 api_defs RBRACE2 {
	  print (" service > "^$2);
	  Service($2, $4)
	}
api_defs:
	| api_def { [$1] }
	| api_def api_defs { $1::$2 }
;
api_def: /* TODO: implement inherit syntax */
	| decorators a_type LITERAL LRBRACE RRBRACE
	    { Method($2, $3, [], $1) }
	| decorators a_type LITERAL LRBRACE cfields RRBRACE
	    { Method($2, $3, $5, $1) }
	| a_type LITERAL LRBRACE RRBRACE
	    { Method($1, $2, [], []) }
	| a_type LITERAL LRBRACE cfields RRBRACE
	    { Method($1, $2, $4, []) }

decorators:
	| DECORATOR { [$1] }
	| DECORATOR decorators { $1::$2 }

/* comma separated fields */
cfields:
	| field COMMA cfields { $1::$3 }
	| field { [$1] }

/* TODO: include "hoge.rdl"
	| INCLUDE LBRACE LITERAL RBRACE   {
	  print ("ignoring inclusion " ^ $3); Nothing
	}
*/
;

%%
