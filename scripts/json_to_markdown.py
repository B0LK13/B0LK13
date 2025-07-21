import argparse
import json
from pathlib import Path
from datetime import datetime
import re


def slugify(value: str) -> str:
    value = value.lower()
    value = re.sub(r"[^a-z0-9]+", "-", value)
    return value.strip("-")


def extract_messages(conversation: dict):
    messages = []
    mapping = conversation.get("mapping", {})
    for msg in mapping.values():
        message = msg.get("message")
        if not message:
            continue
        author = message.get("author", {}).get("role")
        if author == "system":
            continue
        content = "\n".join(message.get("content", {}).get("parts", []))
        time = message.get("create_time")
        messages.append({"author": author, "content": content, "time": time})
    messages.sort(key=lambda m: m.get("time") or 0)
    return messages


def conversation_to_markdown(conversation: dict) -> str:
    title = conversation.get("title", "Conversation")
    create_time = conversation.get("create_time")
    date = (
        datetime.fromtimestamp(create_time).strftime("%Y-%m-%d")
        if create_time
        else ""
    )
    md_lines = [f"# {title}"]
    if date:
        md_lines.append(f"_Date: {date}_\n")
    for msg in extract_messages(conversation):
        role = "User" if msg["author"] == "user" else "ChatGPT"
        md_lines.append(f"**{role}:** {msg['content']}\n")
    return "\n".join(md_lines)


def write_conversation_md(conversation: dict, output_dir: Path):
    title = conversation.get("title", "conversation")
    create_time = conversation.get("create_time")
    date = (
        datetime.fromtimestamp(create_time).strftime("%Y-%m-%d")
        if create_time
        else ""
    )
    slug = slugify(title) or "conversation"
    filename = f"{date}-{slug}.md" if date else f"{slug}.md"
    output_path = output_dir / filename
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(conversation_to_markdown(conversation))


def main():
    parser = argparse.ArgumentParser(description="Convert ChatGPT JSON export to Markdown files")
    parser.add_argument("json_file", type=Path, help="Path to conversations.json")
    parser.add_argument("output_dir", type=Path, help="Directory to store Markdown files")
    args = parser.parse_args()

    with open(args.json_file, "r", encoding="utf-8") as f:
        data = json.load(f)

    args.output_dir.mkdir(parents=True, exist_ok=True)
    for convo in data:
        write_conversation_md(convo, args.output_dir)


if __name__ == "__main__":
    main()
