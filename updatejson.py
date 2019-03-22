import json
from jsonpatch import JsonPatch
import argparse
import sys
import os


CONFIG_ROOT = os.getenv('CONFIG_ROOT')
GREEN_TXT = "\033[92m"
RED_TXT = "\033[31m"
RESET_TXT = "\033[0;0m"


def printstr(s, success=True):
    color = GREEN_TXT if success else RED_TXT
    sys.stdout.write(color)
    sys.stdout.write(s + '\n')
    sys.stdout.write(RESET_TXT)


def handle(patch_filepath):
    with open(patch_filepath) as f:
        patch_file_contents = f.read()
    if not patch_file_contents.strip():
        printstr('JSON patch file [{}] is empty. Ignoring...'.format(patch_filepath))
        return
    try:
        patch_file_json = json.loads(patch_file_contents)
    except ValueError:
        printstr('Patch file [{}] cannot be parsed as JSON.'.format(patch_filepath), success=False)
        raise
    for target_filename, patch_json in patch_file_json.items():
        target_filepath = os.path.join(CONFIG_ROOT, target_filename)
        with open(target_filepath) as f:
            target_file_json = json.loads(f.read())
        patch = JsonPatch(patch_json)
        result = patch.apply(target_file_json)
        with open(target_filepath, 'w') as f:
            json.dump(result, f, indent=2, sort_keys=True)
        printstr('Updated JSON config [{}] with patch file [{}]'.format(target_filepath, patch_filepath))


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("patch_filepath", help="Path to the patch JSON file")
    args = parser.parse_args()
    handle(args.patch_filepath)
