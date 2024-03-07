module main

import net.http
import os
import json
import time
import db.sqlite
import cli

#flag -I @VMODROOT/src
#flag @VMODROOT/src/keychain.o
#include "keychain.h"
#flag -framework Security
#flag -framework CoreFoundation

fn C.save_api_key(&char) &char
fn C.get_api_key() &char

fn main() {
	mut app := cli.Command{
		name: 'chatgpt'
		description: "A command-line interface to Groq's Chat API"
		execute: fn (cmd cli.Command) ! {
			api_key := get_api_key()
			if api_key == "" {
				println('Missing Groq API Key. Try the login command.')
				exit(1)
			}
			chat(api_key)!
		}
		commands: [
			cli.Command{
				name: 'login'
				execute: fn (cmd cli.Command) ! {
					login()!
				}
			},
		]
	}
	app.setup()
	app.parse(os.args)
}

fn login() ! {
	api_key := os.input_password('Enter Groq API Key: ')!
	// TODO: free memory??
	result := C.save_api_key(api_key.str)
	if result == 0 {
		return
	}
	err := unsafe { cstring_to_vstring(result) }
	return error(err)
}

fn get_api_key() string {
	// TODO: free memory??
	result := C.get_api_key()
	api_key := unsafe { cstring_to_vstring(result) }
	return api_key
}

fn chat(api_key string) ! {
	db := get_db()!

	// Get the previous conversation messages from this terminal session
	mut messages := get_current_convo(db)!

	user_prompt := os.args[1..].join(' ')

	user_message := Message{
		role: 'user'
		content: user_prompt
	}

	messages << user_message

	request := ChatRequest{
		model: 'mixtral-8x7b-32768' // or llama2-70b-4096
		messages: messages
	}

	response := send_chatgpt_message(request, api_key)!

	response_msg := response.choices[0].message

	// Print response to stdout
	println(response_msg.content)

	messages << response_msg

	save_current_convo(db, messages)!
}

fn send_chatgpt_message(request ChatRequest, api_key string) !ChatResponse {
	mut headers := http.Header{}
	headers.add(http.CommonHeader.content_type, 'application/json')
	headers.add(http.CommonHeader.authorization, 'Bearer ' + api_key)

	response := http.fetch(http.FetchConfig{
		method: .post
		url: 'https://api.groq.com/openai/v1/chat/completions'
		header: headers
		// data: '{"model": "gpt-3.5-turbo", "messages": [{"role": "user", "content": "${prompt}"}]}'
		data: json.encode(request)
	})!

	if response.status() != .ok {
		panic(response.body)
	}

	chat := json.decode(ChatResponse, response.body)!

	return chat
}

fn get_db() !sqlite.DB {
	data_dir := get_data_dir()
	app_dir := data_dir + '/groq'
	if !os.exists(app_dir) {
		os.mkdir_all(app_dir) or { panic('Failed to create dir: ${err}') }
	}
	mut db := sqlite.connect(app_dir + '/db')!
	return db
}

fn get_current_convo(db sqlite.DB) ![]Message {
	// Create the table for storing messages
	sql db {
		create table Conversation
	}!

	convo_id := current_convo_id()

	convos := sql db {
		select from Conversation where id == convo_id
	}!

	mut convo := if convos.len == 0 {
		Conversation{
			id: convo_id
			messages: '[]'
		}
	} else {
		convos.first()
	}

	messages := json.decode([]Message, convo.messages)!
	return messages
}

fn save_current_convo(db sqlite.DB, messages []Message) ! {
	mut convo := Conversation{
		id: current_convo_id()
		messages: '[]'
	}

	convo.messages = json.encode(messages)

	// Save the latest message
	// (V ORM doesn't support sqlite "INSERT OR REPLACE")
	sql db {
		insert convo into Conversation
	} or {
		sql db {
			update Conversation set messages = convo.messages where id == convo.id
		}!
	}
}

fn current_convo_id() string {
	// Get the previous conversation messages from this terminal session
	ppid := os.getppid()

	// Add the current date to help avoid collisions (not guaranteed since PIDs can be recycled)
	today := time.now().ymmdd()
	convo_id := '${today}_${ppid}'
	return convo_id
}

fn get_data_dir() string {
	dir := os.getenv_opt('XDG_DATA_HOME') or {
		home := os.getenv_opt('HOME') or { panic('Missing HOME environment variable.') }
		return home + '/.local/share'
	}
	return dir
}

struct ChatRequest {
	model    string
	messages []Message
}

struct ChatResponse {
	id      string
	object  string
	created int
	model   string
	usage   Usage
	choices []Choice
}

struct Choice {
	message       Message
	finish_reason string
	index         int
}

struct Message {
	role    string
	content string
}

struct Usage {
	prompt_tokens     int
	completion_tokens int
	total_tokens      int
}

@[table: 'convos']
struct Conversation {
	id string @[primary; sql_type: 'TEXT']
mut:
	messages string @[sql_type: 'TEXT']
}
