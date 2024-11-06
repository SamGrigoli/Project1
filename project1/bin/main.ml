(* main.ml *)

open Opium
open Domainslib
open Lwt.Infix

(* Import ParallelHashTable module from app.ml *)
module PHT = ParallelHashTable

(* Initialize the concurrent hash table with a specified size and number of domains *)
let hash_table = PHT.create 1024 4  (* Adjust size and number of domains as needed *)

(* Endpoint to add a key-value pair to the hash table *)
let add_key_value req =
  req
  |> App.json_of_body_exn
  >>= fun json ->
  let key = Yojson.Safe.Util.(json |> member "key" |> to_string) in
  let value = Yojson.Safe.Util.(json |> member "value" |> to_string) in
  (* Add key-value pair asynchronously *)
  PHT.add hash_table key value;
  Lwt.return (Response.of_json (`Assoc [ "status", `String "ok" ]))

(* Endpoint to retrieve a value from the hash table *)
let get_value req =
  let key = Router.param req "key" in
  (* Fetch value *)
  let value = Task.await hash_table.pool (fun () -> PHT.find hash_table key) in
  value
  >>= fun result ->
  match result with
  | v -> Lwt.return (Response.of_json (`Assoc [ "status", `String "ok"; "value", `String v ]))
  | exception Not_found -> Lwt.return (Response.of_json (`Assoc [ "status", `String "error"; "error", `String "key not found" ]))

(* Create and start the Opium app with routes for add and get *)
let () =
  let app =
    App.empty
    |> App.post "/add" add_key_value
    |> App.get "/get/:key" get_value
  in
  (* Run the Opium app *)
  App.run_command app
