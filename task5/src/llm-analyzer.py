#!/usr/bin/env python3
import argparse
import datetime
import os
import sys
import google.generativeai as genai
from dotenv import load_dotenv

load_dotenv()

# ✅ API key from environment
# export GOOGLE_API_KEY="your_gemini_api_key"
genai.configure(api_key=os.getenv("GOOGLE_API_KEY"))

def analyze_logs(log_file: str, prompt_file: str, temperature: float, top_p: float):
    """Reads logs, loads prompt template from file, and sends to Gemini with adjustable parameters."""
    if not os.path.exists(log_file):
        print(f"[ERROR] Log file '{log_file}' not found.")
        sys.exit(1)

    if not os.path.exists(prompt_file):
        print(f"[ERROR] Prompt file '{prompt_file}' not found.")
        sys.exit(1)

    with open(log_file, "r") as f:
        logs = f.read().strip()

    if not logs:
        print(f"[INFO] Log file '{log_file}' is empty.")
        return

    with open(prompt_file, "r") as f:
        prompt_template = f.read().strip()

    if "{logs}" not in prompt_template:
        print("[ERROR] Prompt file must contain '{logs}' placeholder.")
        sys.exit(1)

    prompt = prompt_template.format(logs=logs)

    try:
        # Create Gemini model
        model = genai.GenerativeModel("models/gemini-2.0-flash")

        response = model.generate_content(
            prompt,
            generation_config={
                "temperature": temperature,
                "top_p": top_p,
            },
        )

        print(f"\n--- Analysis Result ({datetime.datetime.now()}) ---")
        print(response.text)
        print("-------------------------------------------------\n")

    except Exception as e:
        print(f"[ERROR] Failed to analyze logs: {e}")


def main():
    parser = argparse.ArgumentParser(
        description="Analyze Nginx logs with Gemini LLM and custom prompts."
    )
    parser.add_argument("--logfile", required=True, help="Path to log file (e.g. file3 or file4)")
    parser.add_argument("--promptfile", required=True, help="Path to a file containing prompt template with {logs} placeholder")
    parser.add_argument("--temperature", type=float, default=0.2, help="Controls randomness (0.0–2.0)")
    parser.add_argument("--top_p", type=float, default=1.0, help="Nucleus sampling probability (0.0–1.0)")

    args = parser.parse_args()

    analyze_logs(args.logfile, args.promptfile, args.temperature, args.top_p)


if __name__ == "__main__":
    main()
