@load ../__load__.bro
@load policy/frameworks/files/hash-all-files

event file_sniff(f: fa_file, meta: fa_metadata)
	{

	if ( meta?$mime_type && !hook FileExtraction::extract(f, meta) )
		{

		if ( !hook FileExtraction::ignore(f, meta) )
			return;

		Files::add_analyzer(f, Files::ANALYZER_SHA256);

		}

	}

event file_state_remove(f: fa_file)
	{

	if ( !f$info?$extracted || !f$info?$sha256 || FileExtraction::path == "" )
		return;

	local orig = f$info$extracted;

	local split_orig = split_string(f$info$extracted, /\./);
	local extension = split_orig[|split_orig|-1];

	local dest = fmt("%s%s-%s.%s", FileExtraction::path, f$source, f$info$sha256, extension);

	local cmd = fmt("mv %s %s", orig, dest);
	when ( local result = Exec::run([$cmd=cmd]) )
		{
		}
	f$info$extracted = dest;

	}
