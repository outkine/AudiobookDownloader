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
  let paths =
    soup |> Soup.select episode_tag |> Soup.to_list
    |> List.map ~f:(Soup.texts >> List.hd_exn)
  in
  paths

let fetch dest uri root_uri =
  scrape uri
  >>= fun paths ->
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
      let dest = anon ("dest" %: folder)
      and uri = anon ("URI" %: string)
      and root_uri = anon ("download URI" %: string) in
      fun () -> M.run (Agent.init ()) (fetch dest uri root_uri) |> ignore]
  |> Command.run
