(***********************************************************************)
(*                                                                     *)
(*                         The CamlZip library                         *)
(*                                                                     *)
(*            Xavier Leroy, projet Cristal, INRIA Rocquencourt         *)
(*                                                                     *)
(*  Copyright 2001 Institut National de Recherche en Informatique et   *)
(*  en Automatique.  All rights reserved.  This file is distributed    *)
(*  under the terms of the GNU Library General Public License, with    *)
(*  the special exception on linking described in file LICENSE.        *)
(*                                                                     *)
(***********************************************************************)

(* $Id$ *)

open Printf

let list_entry e =
  let t = Unix.localtime e.Zip.mtime in
  printf "%6d  %6d  %c  %04d-%02d-%02d %02d:%02d  %c  %s\n"
    e.Zip.uncompressed_size
    e.Zip.compressed_size
    (match e.Zip.methd with Zip.Stored -> 's' | Zip.Deflated -> 'd')
    (t.Unix.tm_year + 1900) (t.Unix.tm_mon + 1) t.Unix.tm_mday
    t.Unix.tm_hour t.Unix.tm_min
    (if e.Zip.is_directory then 'd' else ' ')
    e.Zip.filename;
  if e.Zip.comment <> "" then
    printf "        %s\n" e.Zip.comment

let list (module Impl: Zip.READER) zipfile =
  let ic = Impl.open_in zipfile in
  if Impl.comment ic <> "" then printf "%s\n" (Impl.comment ic);
  List.iter list_entry (Impl.entries ic);
  Impl.close_in ic


let extract (module Impl: Zip.READER) zipfile =
  let ic = Impl.open_in zipfile in
  let extract_entry e =
    print_string e.Zip.filename; print_newline();
    if e.Zip.is_directory then begin
      try
        Unix.mkdir e.Zip.filename 0o777
      with Unix.Unix_error(Unix.EEXIST, _, _) -> ()
    end else begin
      Impl.copy_entry_to_file ic e e.Zip.filename
    end
  in
  List.iter extract_entry (Impl.entries ic);
  Impl.close_in ic

let create (module Impl: Zip.WRITER) zipfile files =
  let oc = Impl.open_out zipfile in
  let rec add_entry file =
    let s = Unix.stat file in
    match s.Unix.st_kind with
      Unix.S_REG ->
        printf "Adding file %s\n" file; flush stdout;
        Impl.copy_file_to_entry file oc ~mtime:s.Unix.st_mtime file
    | Unix.S_DIR ->
        printf "Adding directory %s\n" file; flush stdout;
        Impl.add_entry "" oc ~mtime:s.Unix.st_mtime
          (if Filename.check_suffix file "/" then file else file ^ "/");
        let d = Unix.opendir file in
        begin try
          while true do
            let e = Unix.readdir d in
            if e <> "." && e <> ".." then add_entry (Filename.concat file e)
          done
        with End_of_file -> ()
        end;
        Unix.closedir d
    | _ -> ()
  in
  Array.iter add_entry files;
  Impl.close_out oc

(* Read the whole file to memory first, then read from memory *)
module Zip_mem_reader = Zip.Make_reader(struct
  type t = {
    mutable ptr: int;
    buf : Buffer.t;
  }

  let open_in filename =
    let buf = Buffer.create 256 in
    let ic = open_in filename in
    let rec loop () =
      try
        Buffer.add_channel buf ic 128;
        loop ()
      with End_of_file ->
        close_in ic
    in
    loop ();
    { buf; ptr = 0 }

  let close_in _ = ()

  let input_byte t =
    if t.ptr >= Buffer.length t.buf
    then raise End_of_file
    else begin
      let c = Buffer.nth t.buf t.ptr in
      t.ptr <- t.ptr + 1;
      Char.code c
    end

  let input t dst ofs len =
    if ofs < 0 || len < 0 || ofs > Bytes.length dst - len
    then invalid_arg "input"
    else begin
      let len = min (Buffer.length t.buf - ofs) len in
      if len >= 0 then begin
        Buffer.blit t.buf t.ptr dst ofs len;
        t.ptr <- t.ptr + len;
        len
      end
      else 0
    end

  let really_input t dst ofs len =
    let input_len = input t dst ofs len in
    if input_len <> len
    then raise End_of_file
    else ()

  let length t = Int64.of_int (Buffer.length t.buf)
  let pos t = Int64.of_int t.ptr
  let seek t pos = t.ptr <- Int64.to_int pos
end)

(* Make all writes in memory, dumping to a file at the very end *)
module Zip_mem_writer = Zip.Make_writer(struct
  type t = {
    filename: string;
    buf: Buffer.t;
  }

  let open_out filename = { filename; buf = Buffer.create 10 }

  let close_out { filename;  buf } =
    let oc = Stdlib.open_out_bin filename in
    Stdlib.output_string oc (Buffer.contents buf);
    Stdlib.close_out oc

  let output_byte { buf; _} code =
    Buffer.add_char buf (Char.chr ((code mod 256 + 256) mod 256))

  let output_string { buf; _ } = Buffer.add_string buf
  let output_substring { buf; _ } = Buffer.add_substring buf
  let output { buf; _ } = Buffer.add_subbytes buf
  let pos { buf; _ } = Int64.of_int (Buffer.length buf)
end)


let usage() =
  prerr_string
"Usage:
  minizip t [-b] <zipfile>           show contents of <zipfile>
  minizip x [-b] <zipfile>           extract files from <zipfile>
  minizip c [-b] <zipfile> <file> .. create a <zipfile> with the given files

    -b Use in-memory buffer for read/write operations (testing functors) \n";

  exit 2

let _ =
  if Array.length Sys.argv < 3 then usage();
  let zipfile, (module Reader: Zip.READER), (module Writer: Zip.WRITER) =
    match Sys.argv.(2) with
    | "-b" ->
      if Array.length Sys.argv < 4 then usage();
      3, (module Zip_mem_reader), (module Zip_mem_writer)
    | _ -> 2, (module Zip), (module Zip)
  in
  match Sys.argv.(1) with
    "t" -> list (module Reader) Sys.argv.(zipfile)
  | "x" -> extract (module Reader) Sys.argv.(zipfile)
  | "c" -> create (module Writer) Sys.argv.(zipfile)
                  (Array.sub Sys.argv (zipfile + 1) (Array.length Sys.argv - zipfile - 1))
  | _ -> usage()
