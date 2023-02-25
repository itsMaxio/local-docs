# No login extension sync 

My extension [list](list.txt)

## How to export

### Unix

```bash
code --list-extensions | xargs -L 1 echo code --install-extension
```


### Windows

```shell
code --list-extensions | % { "code --install-extension $_" }
```

## How to import

Copy and paste the echo output into console