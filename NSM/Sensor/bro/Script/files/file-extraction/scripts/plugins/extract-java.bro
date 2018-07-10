@load ../__load__.bro

module FileExtraction;

const java_types: set[string] = { 
								"application/java-archive",
					   			"application/x-java-applet",
					   			"application/x-java-jnlp-file"
								};

hook FileExtraction::extract(f: fa_file, meta: fa_metadata) &priority=5
	{
	if ( meta$mime_type in java_types )
		break;
	}
