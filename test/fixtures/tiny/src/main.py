#!/usr/bin/env python3
"""Tiny fixture source file with a known size for ctxc tests."""
import sys


def main(argv):
    for arg in argv[1:]:
        print(f"hello {arg}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
