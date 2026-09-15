import re

path = "DynaMac Island 2.xcodeproj/project.pbxproj"
with open(path, "r") as f:
    content = f.read()

# We look for GENERATE_INFOPLIST_FILE = YES; and add the calendar descriptions below it.
calendar_keys = """GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_NSCalendarsUsageDescription = "Takviminizi görmek için izninize ihtiyacımız var.";
				INFOPLIST_KEY_NSCalendarsFullAccessUsageDescription = "Takviminizi görmek için izninize ihtiyacımız var.";"""

content = content.replace("GENERATE_INFOPLIST_FILE = YES;", calendar_keys)

with open(path, "w") as f:
    f.write(content)
