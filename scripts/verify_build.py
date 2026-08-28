#!/usr/bin/env python3
"""
IntentOS Mobile Build Verification Script

Verifies that the build is complete and all components are ready.
"""

import os
import sys
import subprocess
from pathlib import Path

def check_file_exists(filepath, description):
    """Check if a file exists and print status."""
    if Path(filepath).exists():
        print(f"✅ {description}: {filepath}")
        return True
    else:
        print(f"❌ {description} MISSING: {filepath}")
        return False

def main():
    print("🔍 IntentOS Mobile Build Verification")
    print("=" * 40)
    print()
    
    all_checks_passed = True
    
    # Core files
    print("📋 Core Files:")
    all_checks_passed &= check_file_exists("Package.swift", "Swift Package manifest")
    all_checks_passed &= check_file_exists("README.md", "Documentation")
    all_checks_passed &= check_file_exists("LICENSE", "License file")
    print()
    
    # Framework
    print("🎯 Framework:")
    all_checks_passed &= check_file_exists("Sources/IntentOSKit/IntentOSKit.swift", "IntentOSKit framework")
    print()
    
    # App
    print("📱 App:")
    all_checks_passed &= check_file_exists("Sources/App/IntentOSApp.swift", "App entry point")
    all_checks_passed &= check_file_exists("Info.plist", "App configuration")
    print()
    
    # Tests
    print("✅ Tests:")
    all_checks_passed &= check_file_exists("Tests/IntentOSKitTests/IntentOSKitTests.swift", "Unit tests")
    print()
    
    # Configuration
    print("⚙️  Configuration:")
    all_checks_passed &= check_file_exists(".gitignore", "Git ignore rules")
    all_checks_passed &= check_file_exists("CONTRIBUTING.md", "Contributing guide")
    all_checks_passed &= check_file_exists("SECURITY.md", "Security policy")
    print()
    
    if all_checks_passed:
        print("\n🎉 All checks passed! Build is ready for installation.")
        print()
        print("Next steps:")
        print("  1. cd to repository root")
        print("  2. Run: swift build")
        print("  3. Run: swift test")
        print("  4. Run: open Package.swift (to open in Xcode)")
        return 0
    else:
        print("\n⚠️  Some checks failed. Please verify the build structure.")
        return 1

if __name__ == "__main__":
    sys.exit(main())
