@load ../__load__.bro
@load policy/frameworks/files/hash-all-files

event file_state_remove(f: fa_file)
	{

	if ( !f$info?$extracted || !f$info?$md5 || FileExtraction::path == "" )
		return;

	local orig = f$info$extracted;
	
	local split_orig = split_string(f$info$extracted, /\./);
	local extension = split_orig[|split_orig|-1];

	local dest = fmt("%s%s-%s.%s", FileExtraction::path, f$source, f$info$md5, extension);

	local cmd = fmt("mv %s %s", orig, dest);
	when ( local result = Exec::run([$cmd=cmd]) )
		{
		}
	f$info$extracted = dest;

	}
