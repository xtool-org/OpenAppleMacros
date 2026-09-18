#!/usr/bin/env python3

import json
import re
import sys


def normalize_context(match):
    try:
        payload = json.loads(match.group(1))
    except json.JSONDecodeError:
        return match.group(0)
    return 'animatableMacroContext: #"' + json.dumps(payload, sort_keys=True, separators=(",", ":")) + '"#'


text = sys.stdin.read()
text = re.sub(r'animatableMacroContext: #"(.*?)"#', normalize_context, text)
sys.stdout.write(text)
