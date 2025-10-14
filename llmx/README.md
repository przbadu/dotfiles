# llmx - LLM wrapper with system prompts

A powerful command-line wrapper for the [llm](https://llm.datasette.io/) CLI tool that enables context-aware AI assistance through reusable system prompts. Pipe any command output to `llmx` and ask questions in natural language.

## Features

- 🚀 **Natural language to command** - Convert questions to executable commands
- 📚 **Reusable system prompts** - Organize prompts for different contexts (unix, docker, kubernetes, writing, etc.)
- 🔧 **Extensible** - Add your own system prompts for any use case
- 🎯 **Context-aware** - Analyzes piped input to provide accurate responses
- 💻 **Multi-format support** - Prompts in Markdown, text, XML, JSON, YAML

## Installation

### Prerequisites

1. Install [llm](https://llm.datasette.io/) CLI tool:
```bash
pip install llm
```

2. Configure your LLM provider (OpenAI, Anthropic, local models, etc.):
```bash
# For OpenAI
llm keys set openai

# For other providers, see: https://llm.datasette.io/
```

### Install llmx

```bash
# Clone the repository
git clone https://github.com/przbadu/dotfiles
cd dotfiles/llmx

# Make the script executable
chmod +x bin/llmx

# Option 1: Add to PATH (recommended)
sudo ln -s $(pwd)/bin/llmx /usr/local/bin/llmx

# Option 2: Add bin directory to PATH
echo 'export PATH="'$(pwd)'/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

## Usage

### Basic usage

```bash
# Get specific git command
git --help | llmx "undo all staged and unstaged changes"
# Output: git reset --hard HEAD

# Navigate vim
man vim | llmx "save and quit"
# Output: :wq

# Docker operations
docker ps -a | llmx "remove all stopped containers"
# Output: docker container prune -f
```

### Using different system prompts

```bash
# Use a specific prompt with -p or --prompt
kubectl --help | llmx "list all pods" -p kubernetes
cat email.txt | llmx "make it more formal" --prompt writing
cat recipe.txt | llmx "make it vegetarian" -p cooking
```

### List available prompts

```bash
llmx --list
# Available system prompts:
#   - unix (md)
#   - docker (md)
#   - writing (txt)
```

## System Prompts

System prompts are stored in the `system-prompts/` directory. Each prompt is a text file that defines the AI's behavior and expertise for a specific context.

### Default prompt: unix

The default `unix` prompt is optimized for command-line operations:
- Analyzes command help output
- Generates single, executable commands
- No explanations or multiple options
- Focuses on the most common/safe approach

### Creating custom prompts

1. Create a new file in `system-prompts/` with any supported extension:
   - `.md` - Markdown (recommended for readability)
   - `.txt` - Plain text
   - `.xml` - XML structured prompts
   - `.json` - JSON formatted prompts
   - `.yml`/`.yaml` - YAML format

2. Example: Create `system-prompts/docker.md`:

```markdown
# Docker Expert

You are a Docker and containerization expert.

## Instructions
- Analyze Docker command output and documentation
- Provide precise Docker commands
- Output only executable commands, no explanations
- Use best practices for container management

## Constraints
- Single command output
- Prefer docker compose when applicable
- Include necessary flags for safety
```

3. Use your custom prompt:
```bash
docker --help | llmx "remove unused images" -p docker
```

## Examples

### Git operations
```bash
git status | llmx "stage only .py files"
git log --oneline | llmx "show last 5 commits with details"
git branch -a | llmx "delete local branch named feature-x"
```

### File operations
```bash
ls -la | llmx "find all .log files modified today"
df -h | llmx "show only filesystems over 80% full"
ps aux | llmx "kill all python processes"
```

### Text processing
```bash
cat data.json | llmx "extract all email addresses"
cat log.txt | llmx "show only error lines"
cat config.yml | llmx "convert to JSON format" -p converter
```

### Using with different LLM models

Since `llmx` uses the `llm` CLI tool, you can use any configured model:

```bash
# Use a specific model
echo "test" | llm "translate to Spanish" -m claude-3-opus

# llmx inherits your llm configuration
git --help | llmx "undo changes"  # Uses your default model
```

## Project Structure

```
llmx/
├── bin/
│   └── llmx              # Main executable script
├── system-prompts/       # System prompt library
│   ├── unix.md          # Default Unix/Linux commands prompt
│   ├── docker.md        # Docker-specific prompt
│   ├── kubernetes.md    # Kubernetes operations
│   └── ...              # Add your own prompts
└── README.md            # This file
```

## Advanced Usage

### Chaining commands

```bash
# Find and analyze specific files
find . -name "*.py" | llmx "create tar archive of these files"

# Process and transform data
curl -s api.example.com/data | llmx "extract user emails" -p json
```

### Interactive workflows

```bash
# Get help, then execute
kubectl get pods | llmx "restart the nginx pod" -p kubernetes
# Review the command, then execute it

# Debug issues
systemctl status nginx | llmx "diagnose why service failed"
```

## Tips

1. **Keep prompts focused**: Each system prompt should be an expert in one domain
2. **Use descriptive names**: Name prompts by their expertise area (git, docker, aws, etc.)
3. **Test prompts**: Verify prompt behavior with various inputs
4. **Share prompts**: Create a prompts repository for your team

## Contributing

Contributions are welcome! Feel free to:
- Add new system prompts for different tools and contexts
- Improve existing prompts
- Share your custom prompts
- Report issues or suggest features

## License

MIT License - See LICENSE file for details

## Acknowledgments

- Built on top of [llm](https://llm.datasette.io/) by Simon Willison
- Inspired by the Unix philosophy of composable tools
- Thanks to the open-source community

## Related Tools

- [llm](https://llm.datasette.io/) - The underlying LLM CLI tool
- [jq](https://stedolan.github.io/jq/) - JSON processor
- [fzf](https://github.com/junegunn/fzf) - Fuzzy finder
- [tldr](https://tldr.sh/) - Simplified man pages

---

**Pro tip**: Create an alias for common operations:
```bash
alias githelp='git --help | llmx'
alias dockerhelp='docker --help | llmx'

# Usage
githelp "undo last commit"
dockerhelp "stop all containers"
```

