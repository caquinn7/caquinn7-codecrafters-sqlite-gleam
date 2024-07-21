-module(sqlite_ffi).
-export([
    chunk_bin/2
]).

chunk_bin(Bin, ChunkSize) ->
    do_chunk_bin(Bin, ChunkSize, []).

do_chunk_bin(<<>>, _, Acc) ->
    lists:reverse(Acc);

do_chunk_bin(Bin, ChunkSize, Acc) when ChunkSize =< 0 ->
    do_chunk_bin(Bin, 1, Acc);

do_chunk_bin(Bin, ChunkSize, Acc) when byte_size(Bin) =< ChunkSize ->
    lists:reverse([Bin | Acc]);

do_chunk_bin(Bin, ChunkSize, Acc) ->
    <<Chunk:ChunkSize/binary, Rest/binary>> = Bin,
    do_chunk_bin(Rest, ChunkSize, [Chunk | Acc]).