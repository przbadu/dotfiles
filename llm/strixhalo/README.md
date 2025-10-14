## What is this?

This is a

## How to setup?

- First setup your strix halo mini pc using: <https://github.com/kyuz0/amd-strix-halo-toolboxes>
- You can also get more information about why we are doing this here: <https://github.com/kyuz0/amd-strix-halo-toolboxes>

After setting up the toolbox you always need to first enter the toolbox, than run the llama-server inside that container.

But because we are creating `llama-server` wrapper which performs both actions for us we can simply run:

```sh
./llama-server xxxx
```

from anywhere without entering to the toolbox first. default toolbox used is: `llama-vulkan-radv`, if you have created other toolbox containers like `llama-rocm`, etc, you can modify this shell script to use your container name

## Use cases

1. As mentioned above, you don't need to enter the toolbox and than run `llama-server`, you can do that directly using this wrapper script. You can also create script for `llama-server-radv` and `llama-server-rocm` which makes your life even easier to run multiple backend llama-server directly with one line command.
2. This script was originally introduced to fix the backend selection on Jan AI desktop application: <https://www.jan.ai/>. Because the backend they fallback to are not performing well, and Jan AI allow you to choose custom backend from custom directory.

## Examples

```sh
./dotfiles/llm/strixhalo/llama-server --alias qwen3-235b-a22b-instruct-2570 --host 0.0.0.0 --port 8081 --no-mmap -ngl 999 --ctx-size 65536 -fa on -m /mnt/data/lmstudio/lmstudio-community/Qwen3-235B-A22B-Instruct-2507-GGUF/Qwen3-235B-A22B-Instruct-2507-Q3_K_L-00001-of-00003.gguf
```

Should run your `qwen3-235b-a22b` model using vulkan radv backend.
