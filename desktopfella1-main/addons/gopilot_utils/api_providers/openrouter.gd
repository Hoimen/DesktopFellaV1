extends GopilotApiHandler
class_name OpenRouterApiHandler

var _client: HTTPClient = HTTPClient.new()
var _buf: String = ""
var _accum: String = ""

const HOST := "openrouter.ai"
const CHAT := "/api/v1/chat/completions"
const MODELS := "/api/v1/models"

# ---------- Defaults pushed into ChatRequester when set_provider(..., true) ----------
func _get_default_properties() -> Dictionary:
	return {
		"host": HOST,
		"port": 443,
		"model": "openai/gpt-4o-mini",
		"temperature": 0.2,
		"options": {}
	}

# ---------- TLS ----------
func _tls() -> TLSOptions:
	return TLSOptions.client()

# ---------- Headers ----------
func _headers() -> PackedStringArray:
	var h: PackedStringArray = []
	h.append("Content-Type: application/json")
	if chat_requester and str(chat_requester.api_key) != "":
		h.append("Authorization: Bearer %s" % chat_requester.api_key)
	# Optional attribution
	if chat_requester and chat_requester.options.has("http_referer"):
		h.append("HTTP-Referer: %s" % str(chat_requester.options["http_referer"]))
	if chat_requester and chat_requester.options.has("x_title"):
		h.append("X-Title: %s" % str(chat_requester.options["x_title"]))
	return h

# ---------- Helpers to extract text from OpenRouter/OpenAI shapes ----------
func _extract_text_from_message(msg_v: Variant) -> String:
	if msg_v is Dictionary:
		var msg := msg_v as Dictionary
		if msg.has("content"):
			var c: Variant = msg["content"]  # <— typed Variant (was 'var c :=')
			if typeof(c) == TYPE_STRING:
				return c as String
			if c is Array:
				var out := ""
				for part in (c as Array):
					if part is Dictionary:
						var pd := part as Dictionary
						if pd.has("text"):
							out += str(pd["text"])
						elif pd.has("content"):
							out += str(pd["content"])
				return out
	return ""

func _extract_text_from_delta(delta_v: Variant) -> String:
	if delta_v is Dictionary:
		var d := delta_v as Dictionary
		if d.has("content"):
			var c: Variant = d["content"]  # <— typed Variant (was 'var c :=')
			if typeof(c) == TYPE_STRING:
				return c as String
			if c is Array:
				var out := ""
				for part in (c as Array):
					if part is Dictionary and (part as Dictionary).has("text"):
						out += str((part as Dictionary)["text"])
				return out
		if d.has("text"):
			return str(d["text"])
	return ""

# ---------- Main send ----------
func _send_conversation_request(conversation: Array[Dictionary], streaming: bool, json_mode: bool) -> void:
	_accum = ""
	_buf = ""

	var payload: Dictionary = {
		"model": chat_requester.model,
		"messages": conversation,
		"stream": streaming
	}
	# Temperature
	if chat_requester.temperature >= 0.0:
		payload["temperature"] = chat_requester.temperature
	# Extra options (skip attribution keys which are headers)
	if chat_requester.options:
		for k in chat_requester.options.keys():
			if k in ["http_referer", "x_title"]:
				continue
			payload[k] = chat_requester.options[k]
	# JSON mode
	if json_mode:
		payload["response_format"] = {"type": "json_object"}

	# Connect (TLS)
	var err: int = _client.connect_to_host(HOST, 443, _tls())
	if err != OK:
		emit_new_word("[OpenRouter connect error: %s]" % err)
		emit_message_end("")
		return

	while _client.get_status() in [HTTPClient.STATUS_CONNECTING, HTTPClient.STATUS_RESOLVING]:
		_client.poll()
		await Engine.get_main_loop().create_timer(0.01).timeout

	if _client.get_status() != HTTPClient.STATUS_CONNECTED:
		emit_new_word("[OpenRouter: couldn't connect]")
		emit_message_end("")
		return

	err = _client.request(HTTPClient.METHOD_POST, CHAT, _headers(), JSON.stringify(payload))
	if err != OK:
		emit_new_word("[OpenRouter request error: %s]" % err)
		emit_message_end("")
		return

	while true:
		_client.poll()
		var st := _client.get_status()
		if st == HTTPClient.STATUS_BODY:
			var chunk := _client.read_response_body_chunk()
			if chunk.size() > 0:
				var s: String = chunk.get_string_from_utf8()
				if streaming:
					_handle_sse(s)
				else:
					_buf += s
		elif st == HTTPClient.STATUS_CONNECTED:
			break
		await Engine.get_main_loop().create_timer(0.01).timeout

	if streaming:
		emit_message_end(_accum)
	else:
		var parsed: Variant = JSON.parse_string(_buf)
		if typeof(parsed) == TYPE_DICTIONARY:
			var dict := parsed as Dictionary
			# Error payloads
			if dict.has("error"):
				emit_new_word("[OpenRouter error] " + str(dict["error"]))
			# Choices
			if dict.has("choices") and dict["choices"] is Array and (dict["choices"] as Array).size() > 0:
				var msg_v: Variant = (dict["choices"] as Array)[0].get("message")
				var txt := _extract_text_from_message(msg_v)
				if txt != "":
					emit_new_word(txt)
					_accum = txt
		emit_message_end(_accum)

# ---------- SSE streaming ----------
func _handle_sse(text: String) -> void:
	_buf += text
	var nl := _buf.find("\n")
	while nl != -1:
		var line: String = _buf.substr(0, nl).strip_edges()
		_buf = _buf.substr(nl + 1)
		# Ignore keep-alives/comments
		if line == "" or line.begins_with(":"):
			nl = _buf.find("\n")
			continue
		if line.begins_with("data:"):
			var data: String = line.substr(5).strip_edges()
			if data == "[DONE]":
				nl = _buf.find("\n")
				continue
			var obj_v: Variant = JSON.parse_string(data)
			if typeof(obj_v) == TYPE_DICTIONARY:
				var obj := obj_v as Dictionary
				# Error mid-stream
				if obj.has("error"):
					emit_new_word("[OpenRouter error] " + str(obj["error"]))
					nl = _buf.find("\n")
					continue
				if obj.has("choices") and obj["choices"] is Array and (obj["choices"] as Array).size() > 0:
					var delta_v: Variant = (obj["choices"] as Array)[0].get("delta")
					var piece := _extract_text_from_delta(delta_v)
					if piece != "":
						emit_new_word(piece)
						_accum += piece
		nl = _buf.find("\n")

# ---------- Extra entry points ----------
func _send_fill_in_the_middle_request(prefix: String, suffix: String, streaming: bool) -> void:
	var conv := [
		{"role":"system","content":"Fill in the missing middle between <prefix> and <suffix> while preserving style."},
		{"role":"user","content":"<prefix>\n%s\n</prefix>\n<suffix>\n%s\n</suffix>\n<insert_here>\n" % [prefix, suffix]}
	]
	await _send_conversation_request(conv, streaming, false)

func _send_raw_completion_request(prompt: String, stream: bool) -> void:
	var conv := [{"role":"user","content":prompt}]
	await _send_conversation_request(conv, stream, false)

# ---------- Model list ----------
func _get_models() -> PackedStringArray:
	var out: PackedStringArray = []
	var c := HTTPClient.new()
	if c.connect_to_host(HOST, 443, TLSOptions.client()) != OK:
		return out
	while c.get_status() in [HTTPClient.STATUS_CONNECTING, HTTPClient.STATUS_RESOLVING]:
		c.poll()
		await Engine.get_main_loop().create_timer(0.01).timeout
	var err := c.request(HTTPClient.METHOD_GET, MODELS, _headers())
	if err != OK:
		return out
	var buf: String = ""
	while true:
		c.poll()
		if c.get_status() == HTTPClient.STATUS_BODY:
			var ch := c.read_response_body_chunk()
			if ch.size() > 0:
				buf += ch.get_string_from_utf8()
		elif c.get_status() == HTTPClient.STATUS_CONNECTED:
			break
		await Engine.get_main_loop().create_timer(0.01).timeout
	var parsed: Variant = JSON.parse_string(buf)
	if typeof(parsed) == TYPE_DICTIONARY:
		var dict := parsed as Dictionary
		if dict.has("data") and dict["data"] is Array:
			for m in (dict["data"] as Array):
				if m is Dictionary and (m as Dictionary).has("id"):
					out.append((m as Dictionary)["id"])
	return out

# ChatRequester still calls this; not used because we manage our own client.
func _handle_incoming_package(_package: String) -> void:
	pass

func _get_hidden_properties():
	return ["host", "port"]
