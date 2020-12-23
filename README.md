# lzfse-cli

LZFSE compression CLI.  
The tool compress / decompress a single file and directory.


## Encode

Encode file.

```sh
$ ./lzfse-cli --encode -i alice29.txt
```

`alice29.txt.lzfse` is output.


Encode direcotry.

```sh
$ ./lzfse-cli --encode -i dir
```

`dir.aar` is output.


## Decode

Decode file.

```sh
$ ./lzfse-cli --decode -i alice29.txt.lzfse
```

`alice29.txt` is output.

Decode direcotry.

```sh
$ ./lzfse-cli --decode -i dir.aar
```

`dir` is output.
