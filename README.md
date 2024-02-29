# groq

A CLI written in [V](https://vlang.io) for the [Groq](https://groq.com) AI chat service.

## Building

After installing V, run `make`.

## Usage

Run `./groq` to add your Groq API key to the macOS Keychain.
Then run `./groq <prompt>` to talk to Groq. e.g. `./groq What is the average air speed velocity of an unladen swallow?`.
Chat sessions are saved per terminal session in an SQLite database at `~/.local/share/groq/db`
so that you can continue the conversation, e.g. `./groq Can they carry coconuts?`.
