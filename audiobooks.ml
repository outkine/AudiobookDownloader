open Core
open Lwt
open Cohttp
open Cohttp_lwt_unix

(* implementation *)

let ( >> ) f g x = g (f x)

let ( >>>= ) f g x = f x >>= g

let ( >>|= ) f g x = f x >|= g

let root_uri =
  "http://get10.aknigi.club/b/9876/nx41REIfDlTxin7V4_wI6goCVwcHgg0s0ohUhpqYoE4,"

let file_name (chapter, section) = sprintf "%i0%i.mp3" chapter section

let full_uri path = Uri.of_string @@ root_uri ^ "/" ^ file_name path

let write_file path data = Out_channel.write_all path ~data

let rec scrape chapter section =
  Client.head @@ full_uri (chapter, section)
  >>= fun resp ->
  if resp |> Response.status |> Code.code_of_status = 404 then
    if section = 0 then Lwt.return [] else scrape (chapter + 1) 0
  else Lwt.map (List.cons (chapter, section)) (scrape chapter (section + 1))

let fetch =
  scrape 0 0
  >|= Lwt_list.map_p
        ( full_uri >> Client.get
        >>>= (snd >> Cohttp_lwt.Body.to_string >>|= write_file "fuck") )

let () = Lwt_main.run fetch |> ignore
