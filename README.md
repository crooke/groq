# chatgpt

A CLI written in [V](https://vlang.io) for [ChatGPT](https://openai.com/blog/chatgpt).

## Building

After installing V, run `make`.

## Usgae

Run `./chatgpv login` to add your OpenAI API key to the macOS Keychain.
Then run `./chatgpv <prompt>` to talk to ChatGPT. e.g. `./chatgpv What is the average air speed velocity of an unladen swallow?`.
Chat sessions are saved per terminal session in an SQLite database at `~/.local/share/chatgpt/db`
so that you can continue the conversation, e.g. `./chatgpv Can they carry coconuts?`.
