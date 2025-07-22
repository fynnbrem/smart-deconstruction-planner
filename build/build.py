import fnmatch
from datetime import datetime
import os
import sys
import time
import urllib.parse
import zipfile
from pathlib import Path
import platform
import subprocess
from typing import Literal, Iterable, Union
import json

import urllib

CONFIG_FILE = Path() / "build" / "build-config.json"
if not CONFIG_FILE.exists():
    raise ValueError(
        "You have not created a `build-config.json` yet. Copy the `build-config.json.example` to get started."
    )

CONFIG = json.load(CONFIG_FILE.open())


def read_value(dict_: dict, key: str, expected_type: type) -> any:
    """Reads the value with the `key` from the `dict_` and asserts that it has the expected type."""
    assert isinstance(
        dict_[key], expected_type
    ), f"Your config has an invalid value for `{key}`. Expected `{expected_type}` but got `{type(dict_[key]).__name__}`"
    return dict_[key]


STEAM_EXE: str | None = read_value(CONFIG, "steam-exe", str)
"""The path to the factorio executable."""
SAVE_FILE: str | None = read_value(CONFIG, "save-file", Union[str, None])
"""The save file you want to load into. Can be omitted."""
LOAD_INTO_SAVE: bool = read_value(CONFIG, "load-into-save", bool)
"""Whether you want to load into the save file defined above."""
MOD_FOLDER: str = read_value(CONFIG, "mod-folder", str)
"""The Factorio mods folder. The mod will be placed there, ready to be used."""
EXCLUDED_PATTERNS: list[str] = read_value(CONFIG, "excluded-patterns", list)
"""Glob patterns for files and folders that should not be bundled."""


def read_mod_info(info_file: str | Path) -> tuple[str, str]:
    """Reads the name and version defined in the `.info.json` at the specified path."""
    path = Path(info_file)
    if not path.is_file():
        raise FileNotFoundError(f"No such file: {path.absolute()}")

    with path.open("r", encoding="utf-8") as f:
        data = json.load(f)

    version = data["version"]
    name = data["name"]
    return name, version


def bundle_mod(
        source_folder: Path,
        destination_dir: Path,
        exclude_patterns: Iterable[str] = tuple(),
) -> None:
    """
    Bundles the mod into a ZIP-archive ready to be used in Factorio.

    :param source_folder: Path to the folder you want to zip.
    :param destination_dir: Path to the folder where the ZIP will be created.
    :param exclude_patterns: Glob patterns for files and folders to be excluded.
    """
    print(f"Creating archive from: {source_folder.absolute()}")

    if not source_folder.is_dir():
        raise FileNotFoundError(
            f"Source folder does not exist or is not a directory: {source_folder!s}"
        )

    # Ensure destination directory exists (create if necessary)
    destination_dir = destination_dir.resolve()
    if not destination_dir.exists():
        destination_dir.mkdir(parents=True, exist_ok=True)

    mod_name, mod_version = read_mod_info("info.json")
    folder_name: str = mod_name + "_" + mod_version
    zip_path: Path = destination_dir / f"{folder_name}.zip"

    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zipf:
        for path in source_folder.rglob("*"):
            # Only archive files
            if not path.is_file():
                continue

            # Compute the path relative to the root folder.

            rel_path = path.relative_to(source_folder)

            # Skip anything matching an exclude pattern
            if any(fnmatch.fnmatch(str(rel_path), pat) for pat in exclude_patterns):
                continue

            # Add the mod folder in front of it the zip contains the entire folder, not just the content,
            # then convert to posix.
            rel_str = (mod_name / rel_path).as_posix()

            # Write the file, preserving directory structure
            zipf.write(path, arcname=rel_str)
    print(f"Created archive at: {zip_path.absolute()}")


def main() -> None:
    source_folder = Path()

    bundle_mod(source_folder, Path(MOD_FOLDER), EXCLUDED_PATTERNS)
    print(f"Finished build at: {datetime.now().strftime("%H:%M:%S")}")
    # Wait a moment to everything to finish up before launching steam.
    time.sleep(0.5)
    # launch_game(FACTORIO_EXE, SAVE_FILE)
    launch_factorio(STEAM_EXE, SAVE_FILE)



def launch_factorio(steam_exe: Path | str, save_file: Path | str | None) -> None:
    """Launch factorio via the `steam_exe` and open it into the `save_file` (If defined).
    """
    app_id = "427520"
    if save_file is None:
        args = ""
    else:
        args = f'--load-game "{Path(save_file).absolute()}"'

    # This is the only way to circumvent steams confirmation windows when trying to launch a game with arguments.
    # Running it using `steam://run` or the game `.exe` would cause it to appear.
    url = f'"{steam_exe}" -applaunch {app_id} {args}'.strip()
    subprocess.run(url)


if __name__ == "__main__":
    main()