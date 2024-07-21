import file_streams/file_stream
import page

pub type DbInfo {
  DbInfo(page_size: Int, table_count: Int)
}

pub fn new(database_file_path: String) -> DbInfo {
  // Get a file handle to the database file, and skip the first 16 bytes
  let assert Ok(stream) = file_stream.open_read(database_file_path)
  let assert Ok(_) = file_stream.read_bytes_exact(stream, 16)

  // The next 2 bytes hold the page size in big-endian format
  let assert Ok(page_size) = file_stream.read_uint16_be(stream)

  let table_count = page.new(stream, 1, 4096) |> page.count_rows

  DbInfo(page_size, table_count)
}
