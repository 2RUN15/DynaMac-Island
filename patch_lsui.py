import re

path = "DynaMac Island 2.xcodeproj/project.pbxproj"
with open(path, "r") as f:
    content = f.read()

# Inject LSUIElement = YES
calendar_keys = """GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_LSUIElement = YES;"""

content = content.replace("GENERATE_INFOPLIST_FILE = YES;", calendar_keys)

with open(path, "w") as f:
    f.write(content)
