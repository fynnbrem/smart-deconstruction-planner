from datetime import datetime
import os
import sys
import time
import zipfile
from pathlib import Path
import platform
import subprocess
from typing import Literal
import json


# ─── EDIT THESE TWO PATHS BEFORE RUNNING ───────────────────────────────────────
SOURCE_FOLDER: Path = Path(".")  # ← change this to the folder you want to zip
DESTINATION_DIR: Path = Path(
    r"C:\Users\fynnb\AppData\Roaming\Factorio\mods"
)  # ← change this to where you want the ZIP file placed
# ─────────────────────────────────────────────────────────────────────────────
print(f"Archiving: {SOURCE_FOLDER.absolute()}")

def read_version(file_path: str | Path) -> str:
    """
    Read and return the "version" field from a JSON file.

    Args:
        file_path: Path (or string) to the JSON file.

    Returns:
        The version string found under the "version" key.

    Raises:
        FileNotFoundError: If the given file does not exist.
        json.JSONDecodeError: If the file is not valid JSON.
        KeyError: If the "version" key is missing in the parsed JSON.
        TypeError: If the "version" value is not a string.
    """
    path = Path(file_path)
    if not path.is_file():
        raise FileNotFoundError(f"No such file: {path!s}")

    with path.open("r", encoding="utf-8") as f:
        data = json.load(f)

    try:
        version_value = data["version"]
    except KeyError:
        raise KeyError("'version' key not found in JSON file")

    if not isinstance(version_value, str):
        raise TypeError(f"Expected 'version' to be a str, got {type(version_value).__name__!r}")

    return version_value


def zip_folder(source_folder: Path, destination_dir: Path) -> None:
    """
    Create a ZIP archive of `source_folder`, excluding all `.py` files.
    The archive will be named <foldername>.zip and placed inside `destination_dir`.
    Inside the ZIP, the top‐level entry will be the folder itself (not just its contents).

    :param source_folder: Path to the folder you want to zip.
    :param destination_dir: Path to the folder where the ZIP will be created.
    :raises FileNotFoundError: If source_folder does not exist or is not a directory.
    """
    source_folder = source_folder.resolve()
    if not source_folder.is_dir():
        raise FileNotFoundError(
            f"Source folder does not exist or is not a directory: {source_folder!s}"
        )

    # Ensure destination directory exists (create if necessary)
    destination_dir = destination_dir.resolve()
    if not destination_dir.exists():
        destination_dir.mkdir(parents=True, exist_ok=True)

    folder_name: str = source_folder.name + "_" + str(read_version("info.json"))
    zip_path: Path = destination_dir / f"{folder_name}.zip"

    # We want to store files under the archive so that the top‐level is `folder_name/…`.
    parent_dir: Path = source_folder.parent

    with zipfile.ZipFile(zip_path, mode="w", compression=zipfile.ZIP_DEFLATED) as zf:
        for root, dirs, files in os.walk(source_folder):
            root_path = Path(root)

            # Add empty directories explicitly (zipfile only stores files by default).
            rel_dir: Path = root_path.relative_to(parent_dir)
            if not files and not dirs:
                zf_info = zipfile.ZipInfo(str(rel_dir) + "/")
                zf.writestr(zf_info, b"")

            for file_name in files:
                if file_name.endswith(".py"):
                    # Skip any .py file
                    continue

                if file_name == "GOALS.md":
                    continue

                file_path: Path = root_path / file_name
                # Compute arcname so that the top‐level is <folder_name>/...
                arcname: Path = file_path.relative_to(parent_dir)
                zf.write(file_path, arcname=arcname)

    print(f"Created archive: {zip_path!s}")


def main() -> None:
    try:
        zip_folder(SOURCE_FOLDER, DESTINATION_DIR)
        print(f"Finished build at: {datetime.now().strftime("%H:%M:%S")}")
        time.sleep(0.5)
        launch_steam_game("427520")
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


def launch_steam_game(app_id: str) -> None:
    """
    Launch a Steam game given its AppID.

    This uses the Steam URI scheme (steam://run/<AppID>), which should work
    on Windows (via os.startfile), macOS (via 'open'), and Linux (via 'xdg-open').

    Parameters:
        app_id (str): The numeric AppID of the Steam game to launch.
    """
    # Build the Steam URI
    steam_uri: str = f"steam://run/{app_id}"

    system_name: Literal["Windows", "Darwin", "Linux", "Unknown"] = platform.system()  # type: ignore

    if system_name == "Windows":
        # On Windows, os.startfile will open the URI with the default handler (Steam).
        os.startfile(steam_uri)  # type: ignore

    elif system_name == "Darwin":
        # On macOS, use `open`
        subprocess.run(["open", steam_uri], check=False)

    elif system_name == "Linux":
        # On most Linux distros, use `xdg-open`
        subprocess.run(["xdg-open", steam_uri], check=False)

    else:
        # Fallback: try xdg-open, which may work on some BSDs or other Unices
        try:
            subprocess.run(["xdg-open", steam_uri], check=False)
        except FileNotFoundError:
            print(f"Unsupported platform: {system_name!r}. Cannot launch Steam URI.")


if __name__ == "__main__":
    main()
