
# Copyright (C) 2016, Missouri Cyber Team
# All Rights Reserved
# See the file "LICENSE" in the main distribution directory for details

# This policy extracts all SMTP bodies (from client side) seen in traffic.

# NOTE: On a heavy SMTP segment, this will generate a lot of files!
event protocol_confirmation (c: connection, atype: Analyzer::Tag, aid: count)
{
  if ( atype == Analyzer::ANALYZER_SMTP )
  {
    local body_file = generate_extraction_filename(Conn::extraction_prefix, c, "client.txt");
    local body_f = open(body_file);
    set_contents_file(c$id, CONTENTS_ORIG, body_f);
  }
}
