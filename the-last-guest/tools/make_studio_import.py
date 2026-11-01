"""Builds the Roblox Studio import files (.rbxmx) from the scripts in src/.

Run this from the the-last-guest folder after changing any script:
    python3 tools/make_studio_import.py

It writes three files to studio-import/. Each one is imported into one place in Studio
(right-click the service > Insert from File...), so nothing has to be copied and pasted by hand.
"""
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "src"
OUT = ROOT / "studio-import"

# (output file, [(source file, name in Studio, Roblox class)])
GROUPS = [
    ("1-ReplicatedStorage.rbxmx", [
        ("ReplicatedStorage/GameConfig.luau", "GameConfig", "ModuleScript"),
        ("ReplicatedStorage/GhostModel.luau", "GhostModel", "ModuleScript"),
    ]),
    ("2-ServerScriptService.rbxmx", [
        ("ServerScriptService/GameManager.server.luau", "GameManager", "Script"),
        ("ServerScriptService/Ghost.luau", "Ghost", "ModuleScript"),
        ("ServerScriptService/HotelBuilder.luau", "HotelBuilder", "ModuleScript"),
        ("ServerScriptService/PlayerData.luau", "PlayerData", "ModuleScript"),
    ]),
    ("3-StarterPlayerScripts.rbxmx", [
        ("StarterPlayer/StarterPlayerScripts/HUD.client.luau", "HUD", "LocalScript"),
        ("StarterPlayer/StarterPlayerScripts/Cutscene.client.luau", "Cutscene", "LocalScript"),
    ]),
]


def cdata(text):
    # "]]>" would end the CDATA block early, so split it if it ever appears
    return "<![CDATA[" + text.replace("]]>", "]]]]><![CDATA[>") + "]]>"


def build(items):
    parts = [
        '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" '
        'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
        'xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">',
        '<Meta name="ExplicitAutoJoints">true</Meta>',
    ]
    for index, (source_file, name, class_name) in enumerate(items):
        source = (SRC / source_file).read_text(encoding="utf-8")
        parts.append(f'<Item class="{class_name}" referent="RBX{index}">')
        parts.append("<Properties>")
        parts.append(f'<string name="Name">{name}</string>')
        parts.append(f'<ProtectedString name="Source">{cdata(source)}</ProtectedString>')
        parts.append("</Properties>")
        parts.append("</Item>")
    parts.append("</roblox>")
    return "\n".join(parts) + "\n"


def main():
    OUT.mkdir(exist_ok=True)
    for filename, items in GROUPS:
        xml = build(items)
        (OUT / filename).write_text(xml, encoding="utf-8")

        # Check the file is valid XML and every script came through unchanged
        tree = ET.fromstring(xml)
        found = {item.find("Properties/string[@name='Name']").text: item for item in tree.findall("Item")}
        for source_file, name, class_name in items:
            item = found[name]
            assert item.get("class") == class_name, (name, item.get("class"))
            original = (SRC / source_file).read_text(encoding="utf-8")
            assert item.find("Properties/ProtectedString").text == original, name
        print(f"{filename}: " + ", ".join(f"{n} ({c})" for _, n, c in items))


if __name__ == "__main__":
    main()
