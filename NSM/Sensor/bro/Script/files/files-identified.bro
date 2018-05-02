
@load base/frameworks/files
@load frameworks/files/hash-all-files

module Files;

export {
	redef record Files::Info += {
		## A protocol specific "description" for the file.
		file_ident_descr: string &optional &log;

		## Ports used on the server side.
		file_ident_ports: set[count] &optional &log;
	};
	
	## Files that are to have descriptions included in the
	## log and filtered into the new log.
	const identified_files = /application\/x-dosexec/
	                       | /application\/vnd.ms-cab-compressed/
	                       | /application\/x-gzip/
	                       | /application\/bzip2/
	                       | /application\/zip/
	                       | /application\/java-byte-code/
	                       | /application\/x-java-applet/
	                       | /application\/jar/
	                       | /application\/x-script/
	                       | /application\/pdf/
	                       | /application\/x-executable/;
}

event bro_init()
	{
	Log::add_filter(Files::LOG, [$name = "files-identified",
	                             $path = "files_identified",
	                             $pred(rec: Files::Info) = 
	                             	{ return rec?$file_ident_descr; },
	                             $include = set("ts", "conn_uids", "fuid", "tx_hosts", "rx_hosts", "source", "mime_type", "filename", "file_ident_descr", "file_ident_ports", "seen_bytes", "total_bytes", "md5", "sha1")
	                             ]);

	}

event file_state_remove(f: fa_file) &priority=-3
	{
	if ( f?$mime_type && identified_files in f$mime_type )
		{
		f$info$file_ident_descr = Files::describe(f);
		for ( id in f$conns )
			{
			if ( ! f$info?$file_ident_ports )
				f$info$file_ident_ports = set(port_to_count(id$resp_p));
			else
				add f$info$file_ident_ports[port_to_count(id$resp_p)];
			}
		}
	}
