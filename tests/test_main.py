#!/usr/bin/env python3
"""
Tests for RNA virus pipeline main module
"""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

import main

def test_main_execution():
    """Test main function executes without errors"""
    try:
        main.main()
        assert True
    except Exception as e:
        assert False, f"Main function failed: {e}"

if __name__ == "__main__":
    test_main_execution()
    print("All tests passed!")