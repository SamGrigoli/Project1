open Opium
open Domainslib

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

  let find t key =
    Task.async t.pool (fun () ->
      Mutex.lock t.mutex;
      let result = Hashtbl.find t.table key in
      Mutex.unlock t.mutex;
      result)

  let destroy t =
    Task.teardown_pool t.pool
end
