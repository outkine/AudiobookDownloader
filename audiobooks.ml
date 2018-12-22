open Core
open Lwt
open Cohttp
open Cohttp_lwt_unix

(* implementation *)

let ( >> ) f g x = g (f x)

let ( // ) a b = a ^ "/" ^ b

let file_name (chapter, section) = sprintf "0%i0%i.mp3" chapter section

let full_uri root_uri path = Uri.of_string @@ (root_uri // file_name path)

let write_file path data = Out_channel.write_all path ~data

let rec scrape root_uri chapter section =
  let%lwt resp = Client.head @@ full_uri root_uri (chapter, section) in
  if resp |> Response.status |> Code.code_of_status = 404 then
    if section = 1 then Lwt.return [] else scrape root_uri (chapter + 1) 1
  else
    let%lwt paths = scrape root_uri chapter (section + 1) in
    Lwt.return ((chapter, section) :: paths)

let fetch dest root_uri =
  let%lwt paths = scrape root_uri 1 1 in
  paths
  |> List.map ~f:(full_uri root_uri >> Client.get)
  |> List.zip_exn paths
  |> Lwt_list.map_p (fun (path, request) ->
         let%lwt _resp, body = request in
         Cohttp_lwt.Body.to_string body >|= write_file (dest // file_name path)
     )

(* CLI *)

let folder =
  Command.Arg_type.create (fun name ->
      match Sys.is_directory name with
      | `Yes -> name
      | `No | `Unknown ->
          print_endline name ;
          eprintf "'%s' is not a folder" name ;
          exit 1 )

let () =
  let open Command.Let_syntax in
  Command.basic
    ~summary:"Downloads all files for an audiobook from audioknigi.club"
    [%map_open
      let dest = anon ("dest" %: folder) and uri = anon ("URI" %: string) in
      fun () -> Lwt_main.run @@ fetch dest uri |> ignore]
  |> Command.run
