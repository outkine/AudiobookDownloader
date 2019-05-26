open Core
open Mechaml
module M = Agent.Monad
module HTTPResponse = Agent.HttpResponse
open M.Infix

(* implementation *)

let ( // ) a b = a ^ "/" ^ b

let fetch dest json_path =
  let json = Audiobook_j.root_of_string @@ In_channel.read_all json_path in
  let books = Audiobook_j.books_of_string json.aItems in
  books
  |> List.map ~f:(fun book -> Agent.get book.mp3)
  |> List.zip_exn books
  |> M.List.iter_p (fun ((book : Audiobook_t.book), req) ->
         req
         >|= fun resp ->
         print_endline book.title;
         Out_channel.write_all (dest // book.title)
           ~data:(HTTPResponse.content resp) )

(* CLI *)

let folder =
  Command.Arg_type.create (fun name ->
      match Sys.is_directory name with
      | `Yes -> name
      | `No | `Unknown ->
          eprintf "'%s' is not a folder" name;
          exit 1 )

let file =
  Command.Arg_type.create (fun name ->
      match Sys.file_exists name with
      | `Yes -> name
      | `No | `Unknown ->
          eprintf "'%s' is not a file" name;
          exit 1 )

let () =
  let open Command.Let_syntax in
  Command.basic
    ~summary:"Downloads all files for an audiobook from audioknigi.club"
    [%map_open
      let dest = anon ("dest" %: folder)
      and json_path = anon ("json_path" %: file) in
      fun () -> M.run (Agent.init ()) (fetch dest json_path) |> ignore]
  |> Command.run
