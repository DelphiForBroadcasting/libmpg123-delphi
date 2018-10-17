(*
	libmpg123: MPEG Audio Decoder library

	separate header just for audio format definitions not tied to
	library code

	copyright 1995-2015 by the mpg123 project
	free software under the terms of the LGPL 2.1
	see COPYING and AUTHORS files in distribution or http://mpg123.org
*)

unit fmt123;

{$MINENUMSIZE 4}

interface

uses
  System.SysUtils;

(** \file fmt123.h Audio format definitions. *)

(** \defgroup mpg123_enc mpg123 PCM sample encodings
 *  These are definitions for audio formats used by libmpg123 and
 *  libout123.
 *
 * @{
 *)

type
  (** An enum over all sample types possibly known to mpg123.
   *  The values are designed as bit flags to allow bitmasking for encoding
   *  families.
   *  This is also why the enum is not used as type for actual encoding variables,
   *  plain integers (at least 16 bit, 15 bit being used) cover the possible
   *  combinations of these flags.
   *
   *  Note that (your build of) libmpg123 does not necessarily support all these.
   *  Usually, you can expect the 8bit encodings and signed 16 bit.
   *  Also 32bit float will be usual beginning with mpg123-1.7.0 .
   *  What you should bear in mind is that (SSE, etc) optimized routines may be
   *  absent for some formats. We do have SSE for 16, 32 bit and float, though.
   *  24 bit integer is done via postprocessing of 32 bit output -- just cutting
   *  the last byte, no rounding, even. If you want better, do it yourself.
   *
   *  All formats are in native byte order. If you need different endinaness, you
   *  can simply postprocess the output buffers (libmpg123 wouldn't do anything
   * else). The macro MPG123_SAMPLESIZE() can be helpful there.
   *)
  TMpg123_enc_enum =
  (
    (* 0000 0000 0000 1111 Some 8 bit  integer encoding. *)
    MPG123_ENC_8      = $00f
    (* 0000 0000 0100 0000 Some 16 bit integer encoding. *)
  ,	MPG123_ENC_16     = $040
    (* 0100 0000 0000 0000 Some 24 bit integer encoding. *)
  ,	MPG123_ENC_24     = $4000
    (* 0000 0001 0000 0000 Some 32 bit integer encoding. *)
  ,	MPG123_ENC_32     = $100
    (* 0000 0000 1000 0000 Some signed integer encoding. *)
  ,	MPG123_ENC_SIGNED = $080
    (* 0000 1110 0000 0000 Some float encoding. *)
  ,	MPG123_ENC_FLOAT  = $e00
    (* 0000 0000 1101 0000 signed 16 bit *)
  ,	MPG123_ENC_SIGNED_16   = (MPG123_ENC_16 or MPG123_ENC_SIGNED or $10)
    (* 0000 0000 0110 0000 unsigned 16 bit *)
  ,	MPG123_ENC_UNSIGNED_16 = (MPG123_ENC_16 or $20)
    (* 0000 0000 0000 0001 unsigned 8 bit *)
  ,	MPG123_ENC_UNSIGNED_8  = $01
    (* 0000 0000 1000 0010 signed 8 bit *)
  ,	MPG123_ENC_SIGNED_8    = (MPG123_ENC_SIGNED or $02)
    (* 0000 0000 0000 0100 ulaw 8 bit *)
  ,	MPG123_ENC_ULAW_8      = $04
    (* 0000 0000 0000 1000 alaw 8 bit *)
  ,	MPG123_ENC_ALAW_8      = $08
    (* 0001 0001 1000 0000 signed 32 bit *)
  ,	MPG123_ENC_SIGNED_32   = MPG123_ENC_32 or MPG123_ENC_SIGNED or $1000
    (* 0010 0001 0000 0000 unsigned 32 bit *)
  ,	MPG123_ENC_UNSIGNED_32 = MPG123_ENC_32 or $2000
    (* 0101 0000 1000 0000 signed 24 bit *)
  ,	MPG123_ENC_SIGNED_24   = MPG123_ENC_24 or MPG123_ENC_SIGNED or $1000
    (* 0110 0000 0000 0000 unsigned 24 bit *)
  ,	MPG123_ENC_UNSIGNED_24 = MPG123_ENC_24 or $2000
    (* 0000 0010 0000 0000 32bit float *)
  ,	MPG123_ENC_FLOAT_32    = $200
    (* 0000 0100 0000 0000 64bit float *)
  ,	MPG123_ENC_FLOAT_64    = $400
    (* Any possibly known encoding from the list above. *)
  ,	MPG123_ENC_ANY = ( MPG123_ENC_SIGNED_16     or  MPG123_ENC_UNSIGNED_16
                      or  MPG123_ENC_UNSIGNED_8 or  MPG123_ENC_SIGNED_8
                      or  MPG123_ENC_ULAW_8     or  MPG123_ENC_ALAW_8
                      or  MPG123_ENC_SIGNED_32  or  MPG123_ENC_UNSIGNED_32
                      or  MPG123_ENC_SIGNED_24  or  MPG123_ENC_UNSIGNED_24
                      or  MPG123_ENC_FLOAT_32   or  MPG123_ENC_FLOAT_64)
  );

  (** Get size of one PCM sample with given encoding.
   *  This is included both in libmpg123 and libout123. Both offer
   *  an API function to provide the macro results from library
   *  compile-time, not that of you application. This most likely
   *  does not matter as I do not expect any fresh PCM sample
   *  encoding to appear. But who knows? Perhaps the encoding type
   *  will be abused for funny things in future, not even plain PCM.
   *  And, by the way: Thomas really likes the ?: operator.
   * \param enc the encoding (mpg123_enc_enum value)
   * \return size of one sample in bytes
   *)
function MPG123_SAMPLESIZE(enc: Integer): Cardinal;
  //#define MPG123_SAMPLESIZE(enc) ( \
  //  (enc) & MPG123_ENC_8 \
  //  ?	1 \
  //  :	( (enc) & MPG123_ENC_16 \
  //    ?	2 \
  //    :	( (enc) & MPG123_ENC_24 \
  //      ?	3 \
  //      :	( (  (enc) & MPG123_ENC_32 \
  //          || (enc) == MPG123_ENC_FLOAT_32 ) \
  //        ?	4 \
  //        :	( (enc) == MPG123_ENC_FLOAT_64 \
  //          ?	8 \
  //          :	0 \
  //)	)	)	)	)

type
  (** Structure defining an audio format.
   *  Providing the members as individual function arguments to define a certain
   *  output format is easy enough. This struct makes is more comfortable to deal
   *  with a list of formats.
   *  Negative values for the members might be used to communicate use of default
   *  values.
   *)
  TMpg123_fmt = record
	  rate: longint;    (**< sampling rate in Hz  *)
	  channels: integer; (**< channel count *)
	  (** encoding code, can be single value or bitwise or of members of
	  *  mpg123_enc_enum *)
	  encoding : integer;
  end;

implementation

function MPG123_SAMPLESIZE(enc: Integer): Cardinal;
begin

  if ((enc and Integer(MPG123_ENC_8)) = 1) then
    result:= 1
  else if ((enc and Integer(MPG123_ENC_16)) = 1) then
    result:= 2
  else if ((enc and Integer(MPG123_ENC_24)) = 1) then
    result:= 3
  else if (((enc and Integer(MPG123_ENC_32)) = 1) or (enc = Integer(MPG123_ENC_FLOAT_32))) then
    result:= 4
  else if (enc = Integer(MPG123_ENC_FLOAT_64)) then
    result:= 8
  else
    result := 0;
end;

end.

