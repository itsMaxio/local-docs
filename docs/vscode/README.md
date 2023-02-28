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

## Sources

Inspired and based on [How can you export the Visual Studio Code extension list?](https://stackoverflow.com/questions/35773299/how-can-you-export-the-visual-studio-code-extension-list)