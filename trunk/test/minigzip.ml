let buffer = String.create 4096

let _ =
  if Array.length Sys.argv >= 2 && Sys.argv.(1) = "-d" then begin
    (* decompress *)
    let ic = Gzip.open_in_chan stdin in
    let rec decompress () =
      let n = Gzip.input ic buffer 0 (String.length buffer) in
      if n = 0 then () else begin output stdout buffer 0 n; decompress() end
    in decompress(); Gzip.dispose ic
  end else begin
    (* compress *)
    let oc = Gzip.open_out_chan stdout in
    let rec compress () =
      let n = input stdin buffer 0 (String.length buffer) in
      if n = 0 then () else begin Gzip.output oc buffer 0 n; compress() end
    in compress(); Gzip.flush oc
  end
