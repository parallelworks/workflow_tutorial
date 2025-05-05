import requests
import sys
import json
from urllib.parse import urlencode
from concurrent.futures import ThreadPoolExecutor

port = sys.argv[1]

def fetch_and_save(prompt, i):
    params = {'prompt': prompt}
    url = f"http://127.0.0.1:{port}/imagine?{urlencode(params)}"

    try:
        resp = requests.get(url)
        resp.raise_for_status()
        print(f"Writing response to `prompt_{i}.png`.")
        with open(f"prompt_{i}.png", "wb") as f:
            f.write(resp.content)
    except Exception as e:
        print(f"Error with prompt {i}: {e}")

def main():
    with open('inputs.json', 'r') as file:
        inputs = json.load(file)

    with ThreadPoolExecutor(max_workers=5) as executor:  # adjust workers if needed
        for i, prompt in enumerate(inputs['prompts']):
            executor.submit(fetch_and_save, prompt["prompt"], i)

if __name__ == "__main__":
    main()
