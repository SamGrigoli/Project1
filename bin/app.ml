open Domainslib
open Opium
open Lwt.Infix
open Yojson.Safe.Util

(* ParallelHashTable module *)
module ParallelHashTable = struct
  type ('k, 'v) t = {
    table : ('k, 'v) Hashtbl.t;
    pool : Task.pool;
    mutex : Mutex.t;
  }

  let create size num_domains =
    let table = Hashtbl.create size in
    let pool = Task.setup_pool ~num_domains () in
    let mutex = Mutex.create () in
    { table; pool; mutex }

  let add t key value =
    Task.async t.pool (fun () ->
      Mutex.lock t.mutex;
      Hashtbl.add t.table key value;
      Mutex.unlock t.mutex)
end

(* Initialize the concurrent hash table *)
let hash_table = ParallelHashTable.create 1024 4

(* Convert Task to Lwt for easier handling *)
let task_to_lwt pool f =
  let promise = Task.async pool f in
  ignore (Task.await pool promise);
  Lwt.return_unit

(* Endpoint to add a key-value pair to the hash table *)
let add_key_value req =
  Opium.Request.to_plain_text req
  >>= fun body ->
  let json = Yojson.Safe.from_string body in
  match json with
  | `Assoc lst ->
      begin
        try
          let key = List.assoc "key" lst |> to_string in
          let value = List.assoc "value" lst |> to_string in
          
          (* Use task_to_lwt to handle the async task in Lwt *)
          task_to_lwt hash_table.pool (fun () -> ParallelHashTable.add hash_table key value)
          >>= fun () ->
          Lwt.return (Response.of_json (`Assoc [ "status", `String "ok" ]))
        with _ ->
          (* Handle missing "key" or "value" *)
          Lwt.return (Response.of_json (`Assoc [ "status", `String "error"; "error", `String "invalid_json" ]))
      end
  | _ -> Lwt.return (Response.of_json (`Assoc [ "status", `String "error"; "error", `String "invalid_json" ]))

(* Set up and run the Opium app *)
let () =
  let app =
    App.empty
    |> App.post "/add" add_key_value
  in
  App.run_command app
