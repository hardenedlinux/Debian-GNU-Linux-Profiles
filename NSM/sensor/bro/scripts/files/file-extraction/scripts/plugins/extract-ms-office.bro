@load ../__load__.bro

module FileExtraction;

const office_types: set[string] = { "application/msword",
									"application/vnd.openxmlformats-officedocument.wordprocessingml.document",
									"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
									"application/vnd.openxmlformats-officedocument.presentationml.presentation",
								  };

hook FileExtraction::extract(f: fa_file, meta: fa_metadata) &priority=5
	{
	if ( meta$mime_type in office_types )
		break;
	}
