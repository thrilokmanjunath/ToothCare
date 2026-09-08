import os

files_to_update = [
    "README.md",
    "BiteMap.xcodeproj/project.pbxproj",
    "BiteMap/DentalChartViewModel.swift",
    "BiteMap/BiteMapApp.swift"
]

for filepath in files_to_update:
    if os.path.exists(filepath):
        with open(filepath, 'r') as f:
            content = f.read()
        
        # We also need to change BiteMapApp to ToothCareApp
        content = content.replace("BiteMap", "ToothCare")
        content = content.replace("Bitemap", "ToothCare")
        
        with open(filepath, 'w') as f:
            f.write(content)

os.rename("BiteMap/BiteMapApp.swift", "BiteMap/ToothCareApp.swift")
os.rename("BiteMap", "ToothCare")
os.rename("BiteMap.xcodeproj", "ToothCare.xcodeproj")

print("Renaming completed.")
