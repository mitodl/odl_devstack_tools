import json
import yaml
from jsonpatch import JsonPatch
import argparse
import sys
import os


# CONFIG_ROOT should be set in the env after `source /edx/app/edxapp/edxapp_env` is run within the container
CONFIG_ROOT = os.getenv("CONFIG_ROOT", "/edx/app/edxapp")
YAML_CONFIG_ROOT = os.getenv("YAML_CONFIG_ROOT", "/edx/etc")
USE_YAML_CONFIG = os.getenv("USE_YAML_CONFIG", False)
GREEN_TXT = "\033[92m"
RED_TXT = "\033[31m"
RESET_TXT = "\033[0;0m"


def printstr(s, success=True):
    color = GREEN_TXT if success else RED_TXT
    sys.stdout.write(color)
    sys.stdout.write(s + '\n')
    sys.stdout.write(RESET_TXT)


def should_use_yaml_config():
    if isinstance(USE_YAML_CONFIG, bool):
        return USE_YAML_CONFIG
    elif isinstance(USE_YAML_CONFIG, str):
        return USE_YAML_CONFIG.lower().strip() not in {"0", "", "false"}
    elif isinstance(USE_YAML_CONFIG, int):
        return USE_YAML_CONFIG != 0


def update_yaml_configs(target_filename, patch_json):
    assert "lms." in target_filename or "cms." in target_filename
    yaml_target_filename = "lms.yml" if "lms." in target_filename else "studio.yml"
    target_filepath = os.path.join(YAML_CONFIG_ROOT, yaml_target_filename)
    with open(target_filepath) as f:
        target_file_config = yaml.load(f.read())
    patch = JsonPatch(patch_json)
    result = patch.apply(target_file_config)
    with open(target_filepath, "w") as f:
        yaml.dump(result, f, indent=2, sort_keys=True)
    return target_filepath


def update_json_configs(target_filename, patch_json):
    target_filepath = os.path.join(CONFIG_ROOT, target_filename)
    with open(target_filepath) as f:
        target_file_config = json.loads(f.read())
    patch = JsonPatch(patch_json)
    result = patch.apply(target_file_config)
    with open(target_filepath, "w") as f:
        json.dump(result, f, indent=2, sort_keys=True)
    return target_filepath


def update_config_files(patch_filepath):
    with open(patch_filepath) as f:
        patch_file_contents = f.read()
    if not patch_file_contents.strip():
        printstr("Patch file [{}] is empty. Ignoring...".format(patch_filepath))
        return
    try:
        patch_file_json = json.loads(patch_file_contents)
    except ValueError:
        printstr("Patch file [{}] cannot be parsed as JSON.".format(patch_filepath), success=False)
        raise
    for target_filename, patch_json in patch_file_json.items():
        if should_use_yaml_config():
            updated_config_filepath = update_yaml_configs(target_filename, patch_json)
        else:
            updated_config_filepath = update_json_configs(target_filename, patch_json)
        printstr("Updated config file [{}] with patch file [{}]".format(updated_config_filepath, patch_filepath))


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("patch_filepath", help="Path to the patch JSON file")
    args = parser.parse_args()
    update_config_files(args.patch_filepath)
