#!/usr/bin/env python3
"""
Package Name Change Script
This script helps change the package name from com.example.pivot to your actual package name.
"""

import os
import re
import sys
from pathlib import Path

def change_package_name(old_package, new_package):
    """
    Change package name in all relevant files.
    """
    if not new_package or new_package == old_package:
        print("❌ Please provide a valid new package name")
        return False
    
    # Files to update
    files_to_update = [
        "android/app/build.gradle.kts",
        "android/app/src/main/AndroidManifest.xml", 
        "android/app/proguard-rules.pro",
        "linux/CMakeLists.txt",
        "macos/Runner/Configs/AppInfo.xcconfig",
        "android/app/google-services.json"
    ]
    
    # Also update iOS and macOS project files
    ios_files = [
        "ios/Runner.xcodeproj/project.pbxproj",
        "macos/Runner.xcodeproj/project.pbxproj"
    ]
    
    files_to_update.extend(ios_files)
    
    updated_files = 0
    
    for file_path in files_to_update:
        if not Path(file_path).exists():
            print(f"⚠️  File not found: {file_path}")
            continue
            
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Replace package name
            new_content = content.replace(old_package, new_package)
            
            if new_content != content:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                print(f"✅ Updated: {file_path}")
                updated_files += 1
            else:
                print(f"ℹ️  No changes needed: {file_path}")
                
        except Exception as e:
            print(f"❌ Error updating {file_path}: {e}")
    
    # Update MainActivity.kt file path
    old_activity_path = f"android/app/src/main/kotlin/{old_package.replace('.', '/')}/MainActivity.kt"
    new_activity_path = f"android/app/src/main/kotlin/{new_package.replace('.', '/')}/MainActivity.kt"
    
    if Path(old_activity_path).exists():
        # Create new directory structure
        new_dir = Path(new_activity_path).parent
        new_dir.mkdir(parents=True, exist_ok=True)
        
        # Move the file
        Path(old_activity_path).rename(new_activity_path)
        print(f"✅ Moved MainActivity.kt to: {new_activity_path}")
        
        # Update package declaration in MainActivity.kt
        try:
            with open(new_activity_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            new_content = content.replace(f"package {old_package}", f"package {new_package}")
            
            if new_content != content:
                with open(new_activity_path, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                print(f"✅ Updated package declaration in MainActivity.kt")
        except Exception as e:
            print(f"❌ Error updating MainActivity.kt: {e}")
    
    print(f"\n📊 Summary:")
    print(f"   Files updated: {updated_files}")
    print(f"   Old package: {old_package}")
    print(f"   New package: {new_package}")
    
    if updated_files > 0:
        print(f"\n✅ Package name changed successfully!")
        print(f"💡 Remember to:")
        print(f"   1. Update your Firebase project configuration")
        print(f"   2. Update google-services.json with new package name")
        print(f"   3. Test the app to ensure everything works")
    else:
        print(f"\n⚠️  No files were updated")
    
    return updated_files > 0

def main():
    """
    Main function to change package name.
    """
    old_package = "com.example.pivot"
    
    print("🔧 Package Name Change Script")
    print(f"Current package: {old_package}")
    print()
    
    # Get new package name from command line argument or user input
    if len(sys.argv) > 1:
        new_package = sys.argv[1].strip()
        print(f"Using package name from command line: {new_package}")
    else:
        new_package = input("Enter your new package name (e.g., com.yourcompany.pivot): ").strip()
    
    if not new_package:
        print("❌ No package name provided")
        return
    
    # Validate package name format
    if not re.match(r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$', new_package):
        print("❌ Invalid package name format. Use format like: com.yourcompany.pivot")
        return
    
    print(f"\n🔄 Changing package name from '{old_package}' to '{new_package}'...")
    
    success = change_package_name(old_package, new_package)
    
    if success:
        print(f"\n🎉 Package name change completed!")
    else:
        print(f"\n❌ Package name change failed!")

if __name__ == "__main__":
    main()
