(* Auto-generated from "audiobook.atd" *)
[@@@ocaml.warning "-27-32-35-39"]

type root = Audiobook_t.root = { aItems: string }

type book = Audiobook_t.book = { title: string; mp3: string }

type books = Audiobook_t.books

val write_root :
  Bi_outbuf.t -> root -> unit
  (** Output a JSON value of type {!root}. *)

val string_of_root :
  ?len:int -> root -> string
  (** Serialize a value of type {!root}
      into a JSON string.
      @param len specifies the initial length
                 of the buffer used internally.
                 Default: 1024. *)

val read_root :
  Yojson.Safe.lexer_state -> Lexing.lexbuf -> root
  (** Input JSON data of type {!root}. *)

val root_of_string :
  string -> root
  (** Deserialize JSON data of type {!root}. *)

val write_book :
  Bi_outbuf.t -> book -> unit
  (** Output a JSON value of type {!book}. *)

val string_of_book :
  ?len:int -> book -> string
  (** Serialize a value of type {!book}
      into a JSON string.
      @param len specifies the initial length
                 of the buffer used internally.
                 Default: 1024. *)

val read_book :
  Yojson.Safe.lexer_state -> Lexing.lexbuf -> book
  (** Input JSON data of type {!book}. *)

val book_of_string :
  string -> book
  (** Deserialize JSON data of type {!book}. *)

val write_books :
  Bi_outbuf.t -> books -> unit
  (** Output a JSON value of type {!books}. *)

val string_of_books :
  ?len:int -> books -> string
  (** Serialize a value of type {!books}
      into a JSON string.
      @param len specifies the initial length
                 of the buffer used internally.
                 Default: 1024. *)

val read_books :
  Yojson.Safe.lexer_state -> Lexing.lexbuf -> books
  (** Input JSON data of type {!books}. *)

val books_of_string :
  string -> books
  (** Deserialize JSON data of type {!books}. *)

