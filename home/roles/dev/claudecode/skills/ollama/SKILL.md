---
name: ollama
description:
  This skill should be used whenever the user asks anything about Ollama, Ollama models, running
  local LLMs, Ollama API, pulling/pushing models, modelfiles, Ollama errors, or anything related to
  Ollama. Always consult https://docs.ollama.com to verify answers before providing information
  about Ollama. Make sure to use this skill whenever the user mentions Ollama, asks about local
  LLMs, runs models locally, uses the Ollama API, needs help with modelfiles, or encounters Ollama
  errors. This is the go-to skill for all things Ollama.
version: 1.0.0
---

# Ollama Skill

A skill for answering questions about Ollama, a tool for running large language models locally.

Always consult https://docs.ollama.com to verify answers before providing information about Ollama.

---

## Overview

Ollama is a cross-platform tool for running large language models (LLMs) locally on your machine. It
allows you to:

- Pull and run various LLM models (Llama, Mistral, CodeLlama, etc.)
- Interact with models via API or command-line
- Create custom models using modelfiles
- Run models locally for privacy and performance

---

## When This Skill Applies

This skill activates when the user's request involves:

- **Ollama commands**: `ollama pull`, `ollama run`, `ollama list`, `ollama rm`, etc.
- **Ollama models**: Questions about available models, model details, model parameters
- **Ollama API**: REST API endpoints, authentication, request/response format
- **Modelfiles**: Creating custom models, Modelfile syntax, Ollama modelfiles
- **Troubleshooting**: Ollama errors, startup issues, memory problems
- **Configuration**: Ollama configuration files, environment variables
- **Model management**: Pulling, pushing, tagging, pruning models
- **Local LLM running**: Setting up local inference, performance optimization

**Trigger phrases to watch for:**

- "how do I use Ollama"
- "ollama pull command"
- "run local LLM with Ollama"
- "Ollama API"
- "Ollama modelfile"
- "Ollama error"
- "pull Ollama model"
- "Ollama installation"

---

## Reference Documentation

For verification of all answers, always consult the official Ollama documentation:

- **Main Docs**: https://docs.ollama.com
- **API Reference**: https://docs.ollama.com/api
- **Model List**: https://ollama.com/library

When answering Ollama questions, cross-reference the official docs to ensure accuracy.

---

## Usage Guidelines

### Answering Ollama Questions

1. **Check the official docs first**: Before answering, verify information from
   https://docs.ollama.com
2. **Provide commands with examples**: When relevant, include actual `ollama` commands
3. **Clarify model names**: Different models have different capabilities and requirements
4. **Note memory requirements**: Some models require significant RAM/VRAM
5. **Mention alternatives**: If Ollama isn't the right solution, suggest alternatives

### Common Ollama Topics

- **Model Pulling**: `ollama pull <model-name>`
- **Running Models**: `ollama run <model-name>`
- **API Usage**: POST to `http://localhost:11434/api/chat`
- **Modelfiles**: Creating custom models with `FROM <base> MODelfile`
- **Environment Variables**: Setting `OLLAMA_HOST`, `OLLAMA_NUM_PARALLEL`

---

## Examples

**Example 1: Pulling a model**

Input: "How do I pull the Llama 3 model using Ollama?"

Output: To pull the Llama 3 model using Ollama, run:

```bash
ollama pull llama3
```

This will download the model to your local machine. After pulling, you can run it with
`ollama run llama3`.

See [official Ollama docs](https://docs.ollama.com) for the full list of available models.

---

**Example 2: Ollama API chat**

Input: "What's the Ollama API for sending a chat request?"

Output: Ollama provides a REST API for chat requests at `http://localhost:11434/api/chat`.

Send a POST request with this JSON body:

```json
{
  "model": "llama3",
  "messages": [
    {
      "role": "user",
      "content": "Hello!"
    }
  ]
}
```

See [Ollama API docs](https://docs.ollama.com/api) for the complete API reference.

---

**Example 3: Creating a custom model**

Input: "How do I create a custom Ollama model?"

Output: You can create custom models using modelfiles. First, create a `Modelfile`:

```dockerfile
FROM llama3
SYSTEM """You are a helpful assistant.""
```

Then build it:

```bash
ollama create my-custom-model -f Modelfile
```

Run `ollama list` to see available models.

---

## Troubleshooting

### Common Ollama Issues

- **"no space left on device"**: Delete unused models with `ollama rm <model>`
- **"pull failed"**: Check internet connection and firewall
- **"out of memory"**: Close other applications or use smaller models
- **"model not found"**: Pull the model first with `ollama pull <model>`

For error troubleshooting, see
[Ollama troubleshooting docs](https://docs.ollama.com/llm/troubleshooting).
