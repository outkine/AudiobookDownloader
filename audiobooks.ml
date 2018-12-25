open Core
open Mechaml
module M = Agent.Monad
module HTTPResponse = Agent.HttpResponse
open M.Infix

(* implementation *)

let ( >> ) f g x = g (f x)

let ( // ) a b = a ^ "/" ^ b

let regex regex s = Re.Group.get (Re.exec (Re.Posix.compile_pat regex) s) 0

let write_file path data = Out_channel.write_all path ~data

let audio_tag = "#jp_audio_0"

let episode_tag = ".jp-playlist-item"

let scrape uri =
  Agent.get uri
  >|= fun resp ->
  let soup = resp |> HTTPResponse.page |> Page.soup in
  let root_uri =
    match Soup.select_one audio_tag soup with
    | Some node -> (
      match Soup.attribute "src" node with
      | Some src -> regex ".*/" src
      | None -> failwith "no src attribute on root tag" )
    | None -> failwith "root tag does not exist"
  in
  let paths =
    soup |> Soup.select episode_tag |> Soup.to_list
    |> List.map ~f:(Soup.texts >> List.hd_exn)
  in
  (root_uri, paths)

let fetch dest uri =
  scrape uri
  >>= fun (root_uri, paths) ->
  paths
  |> List.map ~f:(( ^ ) root_uri >> Agent.get)
  |> List.zip_exn paths
  |> M.List.iter_p (fun (path, req) ->
         req
         >|= fun resp -> write_file (dest // path) @@ HTTPResponse.content resp
     )

(* CLI *)

let folder =
  Command.Arg_type.create (fun name ->
      match Sys.is_directory name with
      | `Yes -> name
      | `No | `Unknown ->
          eprintf "'%s' is not a folder" name ;
          exit 1 )

let () =
  let open Command.Let_syntax in
  Command.basic
    ~summary:"Downloads all files for an audiobook from audioknigi.club"
    [%map_open
      let dest = anon ("dest" %: folder) and uri = anon ("URI" %: string) in
      fun () -> M.run (Agent.init ()) (fetch dest uri) |> ignore]
  |> Command.run
