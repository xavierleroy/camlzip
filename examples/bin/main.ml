(* CamlZip Zlib and Zip examples *)

(* Camlzip comes with large examples in the tests directory, which show much
   more complete code for Zip and GZip. Here, we give simplistic ones for
   experimenting with. *)

(* Load a file as a string *)
let contents_of_file filename =
  let ch = open_in_bin filename in
    try
      let s = really_input_string ch (in_channel_length ch) in
        close_in ch;
        s
    with
      e -> close_in ch; raise e

(* The compress and uncompress functions take input as available, and produce
output when available. We pass two functions, one to return the amount of input
data required, one to write output data as produced. *)
let f_zlib_in fh_in b = input fh_in b 0 (Bytes.length b)
let f_zlib_out fh_out b l = output fh_out b 0 l

(* Compress data using raw zlib. *)
let zlib_compress filename_in filename_out =
  let fh_in = open_in_bin filename_in in
  let fh_out = open_out_bin filename_out in
    Zlib.compress (f_zlib_in fh_in) (f_zlib_out fh_out);
    close_in fh_in;
    close_out fh_out

(* Uncompress raw zlib data *)
let zlib_uncompress filename_in filename_out =
  let fh_in = open_in_bin filename_in in
  let fh_out = open_out_bin filename_out in
    Zlib.uncompress (f_zlib_in fh_in) (f_zlib_out fh_out);
    close_in fh_in;
    close_out fh_out

(* Zip some files into a .zip file *)
let zip_files filename_out filenames_in =
  let zip = Zip.open_out filename_out in
    List.iter
      (fun filename_in ->
         Zip.add_entry (contents_of_file filename_in) zip filename_in)
      filenames_in;
    Zip.close_out zip

(* List the entries in a zip file *)
let zip_list filename_in =
  let zip = Zip.open_in filename_in in
    List.iter
      (fun {Zip.filename; Zip.uncompressed_size; Zip.compressed_size; _} ->
        Printf.printf "File %s, %i bytes (originally %i bytes)\n" filename compressed_size uncompressed_size)
      (Zip.entries zip);
    Zip.close_in zip

let () =
  match Array.to_list Sys.argv with
  | [_; "zlibcompress"; filename_in; filename_out] -> zlib_compress filename_in filename_out
  | [_; "zlibuncompress"; filename_in; filename_out] -> zlib_uncompress filename_in filename_out
  | _::"zipfiles"::filename_out::filenames_in -> zip_files filename_out filenames_in
  | [_; "ziplist"; filename_in] -> zip_list filename_in
  | _ -> Printf.eprintf "camlzip example: unknown command line\n"
