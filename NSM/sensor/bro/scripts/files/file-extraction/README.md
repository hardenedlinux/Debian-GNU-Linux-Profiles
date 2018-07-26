# Bro Module for File Extraction

This is a Bro package that provides convenient extraction of files.

As a secondary goal, this script performs additional commonly requested file extraction and logging tasks, such as naming extracted files after their calculated file checksum or naming the file with its common file extension.

## Installing with bro-pkg (preferred)

This package can be installed through the [bro package manager](http://bro-package-manager.readthedocs.io) by utilizing the following commands:

```sh
bro-pkg install bro/hosom/file-extraction

# you must separately load the package for it to actually do anything
bro-pkg load bro/hosom/file-extraction
```

## Installing manually

While not preferred, this package can also be installed manually. To do this, follow the tasks below:

```
cd <prefix>/share/bro/site

git clone git://github.com/hosom/file-extraction file-extraction

echo "@load file-extraction" >> local.bro
```

## Configuration

The package installs with the **extract-common-exploit-types.bro** policy, however, additional functionality may be desired. 

Configuration must **always be done within the config.bro** file. Failure to isolate configuration to **config.bro** will result in your configuration being overwritten.

### Advanced Configuration

For advanced configuration of file extraction, the best option available is to hook the FileExtraction::extract hook. For examples of this, look at the scripts in the plugins directory.

## Plugins

### extract-all-files.bro

Attaches the extract files analyzer to every file that has a mime_type detected.

### extract-java.bro

Attaches the extract files analyzer to every JNLP and Java Archive file detected.

### extract-pe.bro

Attaches the extract files analyzer to every PE file detected.

### extract-ms-office.bro

Attaches the extract files analyzer to every ms office file detected.

### extract-pdf.bro

Attaches the extract files analyzer to every PDF file detected.

### extract-common-exploit-types.bro

Loads the following plugins:
- extract-java.bro
- extract-pe.bro
- extract-ms-office.bro
- extract-pdf.bro

### store-files-by-md5.bro

Uses file_state_remove to rename extracted files based on the md5 checksum whenever it is available.

### store-files-by-sha1.bro

Uses file_state_remove to rename extracted files based on the sha1 checksum whenever it is available.

### store-files-by-sha256.bro

Uses file_state_remove to rename extracted files based on the sha256 checksum whenever it is available.
