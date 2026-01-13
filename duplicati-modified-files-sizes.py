import os
import subprocess
import re

# ------
# PARAMS
# ------


# which two backup versions to compare (0-indexed)
VERSION_NEW = 0
VERSION_OLD = 1


# ----------------------------
# GET DUPLICATI COMPARE OUTPUT
# ----------------------------

COMMAND = [
    "bash",
    "-c",
    # The remote login information in remote URL is _not_ needed.
    f"duplicati-cli compare 'ssh://backups.heider.org:22/michaelheider/LPT-009' '{VERSION_NEW}' '{VERSION_OLD}' --dbpath=/home/michael/.config/Duplicati/LPT-009.sqlite --force-locale=en --full-result",
]

result = subprocess.run(
    COMMAND,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
    text=True,
    check=True,
)
output = result.stdout


# -----------------------
# SPLIT LINES INTO ARRAYS
# -----------------------


lines = iter(output.splitlines())
lines = (line.strip() for line in lines)
lines = (line for line in lines if line != "")

added: list[str] = []
modified: list[str] = []
deleted: list[str] = []

for line in lines:
    if re.search(r"^\d+ added entries:$", line):
        break

for line in lines:
    if re.search(r"^\d+ modified entries:$", line):
        break
    added.append(line.lstrip("+ "))

for line in lines:
    if re.search(r"^\d+ deleted entries:$", line):
        break
    modified.append(line.lstrip("~ "))

for line in lines:
    if line.startswith("Added folders:"):
        break
    deleted.append(line.lstrip("- "))


# ------------
# POST PROCESS
# ------------


def splitDirectoryFiles(arr: list[str]) -> tuple[list[str], list[str]]:
    dirs = [path for path in arr if path.endswith("/")]
    files = [path for path in arr if not path.endswith("/")]
    return files, dirs


addedFiles, addedDirs = splitDirectoryFiles(added)
modifiedFiles, modifiedDirs = splitDirectoryFiles(modified)
deletedFiles, deletedDirs = splitDirectoryFiles(deleted)


modifiedFilesExisting = [f for f in modifiedFiles if os.path.exists(f)]
modifiedFilesNotExisting = [f for f in modifiedFiles if not os.path.exists(f)]

# Convert to set for faster lookup.
modifiedDirsSet = set(modifiedDirs)
# Keep only leave dirs, i.e. dirs that are not a parent of any other dir.
modifiedDirsLeaves = [
    p
    for p in modifiedDirsSet
    if not any(other != p and other.startswith(p) for other in modifiedDirsSet)
]
modifiedDirsLeavesExisting = [d for d in modifiedDirsLeaves if os.path.exists(d)]
modifiedDirsLeavesNotExisting = [d for d in modifiedDirsLeaves if not os.path.exists(d)]


# ---------
# GET SIZES
# ---------


def dirSize(directory: str) -> int:
    """Return total size of all files in a directory (recursively) in bytes."""
    totalSize = 0
    for dirpath, dirnames, filenames in os.walk(directory, followlinks=False):
        for f in filenames:
            fp = os.path.join(dirpath, f)
            try:
                if os.path.isfile(fp):
                    totalSize += os.path.getsize(fp)
            except OSError:
                # Skip files that can't be accessed.
                continue
    return totalSize


fileSizes = [(f, os.path.getsize(f)) for f in modifiedFilesExisting]
fileSizes.sort(key=lambda x: x[1])

dirSizes = [(d, dirSize(d)) for d in modifiedDirsLeavesExisting]
dirSizes.sort(key=lambda x: x[1])


# -----
# PRINT
# -----


# Function to convert bytes to human-readable format
def sizeHuman(sizeBytes: int) -> str:
    size: float = sizeBytes
    for unit in ["B  ", "KiB", "MiB", "GiB", "TiB"]:
        if size < 1024:
            return f"{size:.1f} {unit}"
        size /= 1024
    return f"{size:.1f} PiB"


print("MODIFIED")
print(f"modified files: {len(modifiedFiles)}, existing: {len(modifiedFilesExisting)}")
for file in modifiedFilesNotExisting:
    print(f"   ?.? B   {file}")
for file, size in fileSizes:
    print(f"{sizeHuman(size):>10} {file}")
print(f"total size of modified files: {sizeHuman(sum(size for _, size in fileSizes))}")

# print(f"modified dirs: {len(modifiedDirsLeaves)}, existing: {len(modifiedDirsLeavesExisting)}")
# for dir in modifiedDirsLeavesNotExisting:
#     print(f"   ?.? B   {dir}")
# for dir, size in dirSizes:
#     print(f"{sizeHuman(size):>10} {dir}")
# print(f"total size of modified dirs: {sizeHuman(sum(size for _, size in dirSizes))}")
