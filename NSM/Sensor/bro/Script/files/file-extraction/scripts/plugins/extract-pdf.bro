@load ../__load__.bro

module FileExtraction;

const pdf_types: set[string] = { "application/pdf" };

hook FileExtraction::extract(f: fa_file, meta: fa_metadata) &priority=5
	{
	if ( meta$mime_type in pdf_types )
		break;
	}
